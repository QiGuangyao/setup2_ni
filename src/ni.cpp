#include "ni.hpp"
#include "ringbuffer.hpp"

#ifdef __APPLE__
#include "ni_stub.h"
#else
#include <NIDAQmx.h>
#endif

#include <vector>
#include <cassert>
#include <optional>
#include <atomic>
#include <mutex>
#include <string>

namespace {

using namespace ni;

/*
 * config
 */

struct Config {
  static constexpr int input_sample_buffer_ring_buffer_capacity = 16;
  static constexpr uint64_t input_sample_index_sync_interval = 10000;
};

/*
 * types
 */

struct NIInputSampleSyncPoints {
  void clear() {
    time_points.clear();
  }

  std::vector<ni::TriggerTimePoint> time_points;
};

struct OutputPulseQueue {
  struct Pulse {
    int channel;
    float time_remaining;
  };

  void clear() {
    pulses.clear();
  }

  void push(int channel, float time_left) {
    for (auto& pulse : pulses) {
      if (pulse.channel == channel) {
        pulse.time_remaining = time_left;
        return;
      }
    }

    auto& pulse = pulses.emplace_back();
    pulse.channel = channel;
    pulse.time_remaining = time_left;
  }

  std::vector<Pulse> pulses;
};

struct StaticSampleBufferArray {
  void clear() {
    num_buffers = 0;
  }

  void push(ni::SampleBuffer buff) {
    assert(num_buffers < Config::input_sample_buffer_ring_buffer_capacity);
    buffers[num_buffers++] = buff;
  }

  std::optional<ni::SampleBuffer> pop_back() {
    if (num_buffers > 0) {
      return buffers[--num_buffers];
    } else {
      return std::nullopt;
    }
  }

  ni::SampleBuffer buffers[Config::input_sample_buffer_ring_buffer_capacity]{};
  int num_buffers{};
};

struct NITask {
  TaskHandle task{nullptr};
  bool started{};
};

/*
 * globals
 */

struct {
  NITask ni_input_export_task{};

  std::vector<double> daq_sample_buffer;
  int num_samples_per_input_channel{};
  int num_analog_input_channels{};
  uint64_t ni_num_input_samples_acquired{};

  NITask ni_analog_output_task;
  ni::ChannelDescriptor analog_output_channel_descs[32]{};
  int num_analog_output_channels{};
  int num_samples_per_output_channel{};
  std::vector<double> analog_output_buffer;

  NITask ni_counter_output_tasks[32]{};
  int num_counter_output_tasks{};

  RingBuffer<ni::SampleBuffer, Config::input_sample_buffer_ring_buffer_capacity> send_to_ni_daq;
  StaticSampleBufferArray received_from_ni{};

  RingBuffer<ni::SampleBuffer, Config::input_sample_buffer_ring_buffer_capacity> send_from_ni_daq;
  StaticSampleBufferArray available_to_send_to_ui{};

  std::vector<std::unique_ptr<double[]>> sample_buffer_data;
  time::TimePoint time0{};
  bool initialized{};

  OutputPulseQueue output_pulse_queue;
  time::TimePoint last_time{};
  bool first_time{};

  NIInputSampleSyncPoints input_sample_sync_points;

} globals;

/*
 * anon funcs
 */

template <typename T>
T clamp(const T& v, const T& lo, const T& hi) {
  return v < lo ? lo : v > hi ? hi : v;
}

void log_ni_error() {
  char err_buff[2048];
  memset(err_buff, 0, 2048);
  DAQmxGetExtendedErrorInfo(err_buff, 2048);
  printf("DAQmxError: %s\n", err_buff);
}

[[nodiscard]] uint32_t ni_read_data(TaskHandle task, double* read_buff, uint32_t num_samples, uint32_t num_channels) {
  int32 num_read{};
  const int32 status = DAQmxReadAnalogF64(
    task, num_samples, 100.0, DAQmx_Val_GroupByScanNumber,
    read_buff, num_samples * num_channels, &num_read, nullptr);
  if (status != 0) {
    log_ni_error();
  }

  assert(num_read <= num_samples);
  return uint32_t(num_read);
}

void ni_acquire_sample_buffers() {
  const int num_rcv = globals.send_to_ni_daq.size();
  for (int i = 0; i < num_rcv; i++) {
    globals.available_to_send_to_ui.push(globals.send_to_ni_daq.read());
  }
}

void ni_maybe_send_sample_buffer(
  const double* read_buff, uint32_t num_samples, uint64_t sample0_index, double sample0_time) {
  //
  if (globals.send_from_ni_daq.full()) {
    return;
  }

  const uint32_t num_channels = globals.num_analog_input_channels;
  if (auto opt_send = globals.available_to_send_to_ui.pop_back()) {
    auto& send = opt_send.value();
    const uint32_t tot_data_size = num_samples * num_channels;

    memcpy(send.data, read_buff, sizeof(double) * tot_data_size);
    send.num_samples_per_channel = num_samples;
    send.num_channels = num_channels;
    send.sample0_time = sample0_time;
    send.sample0_index = sample0_index;

    globals.send_from_ni_daq.write(send);
  }
}

int32 CVICALLBACK ni_input_sample_callback(TaskHandle task, int32, uInt32 num_samples, void*) {
  //
  assert(int(num_samples) == globals.num_samples_per_input_channel);
  assert(globals.daq_sample_buffer.size() == num_samples * globals.num_analog_input_channels);

  ni_acquire_sample_buffers();

  double* read_buff = globals.daq_sample_buffer.data();
  const uint32_t num_read = ni_read_data(task, read_buff, num_samples, globals.num_analog_input_channels);
  assert(num_read == num_samples);

  const uint64_t sample0_index = globals.ni_num_input_samples_acquired;
  double sample0_time = time::elapsed_time(globals.time0, time::now());

  ni_maybe_send_sample_buffer(read_buff, num_read, sample0_index, sample0_time);
  globals.ni_num_input_samples_acquired += uint64_t(num_read);

  return 0;
}

void init_input_data_handoff(int num_channels, int num_samples_per_channel) {
  assert(globals.sample_buffer_data.empty());

  const int total_num_samples = num_channels * num_samples_per_channel;
  globals.daq_sample_buffer.resize(total_num_samples);

  for (int i = 0; i < Config::input_sample_buffer_ring_buffer_capacity - 1; i++) {
    //  - 1 because ring buffer capacity is actually one less than
    //  `input_sample_buffer_ring_buffer_capacity`
    auto& dst = globals.sample_buffer_data.emplace_back();
    dst = std::make_unique<double[]>(total_num_samples);

    ni::SampleBuffer buff{};
    buff.data = dst.get();
    if (!globals.send_to_ni_daq.maybe_write(buff)) {
      assert(false);
    }
  }
}

bool start_outputs(const ni::InitParams& params) {
  {
    int32 status = DAQmxCreateTask("OutputTask", &globals.ni_analog_output_task.task);
    if (status != 0) {
      log_ni_error();
      return false;
    }
  }

  for (int i = 0; i < params.num_analog_output_channels; i++) {
    TaskHandle task_handle = globals.ni_analog_output_task.task;

    int32 status{};
    const auto& channel_desc = params.analog_output_channels[i];

    globals.analog_output_channel_descs[i] = channel_desc;

    status = DAQmxCreateAOVoltageChan(
      task_handle, channel_desc.name, "",
      channel_desc.min_value, channel_desc.max_value, DAQmx_Val_Volts, NULL);
    if (status != 0) {
      log_ni_error();
      return false;
    }

    status = DAQmxCfgSampClkTiming(
      task_handle, "", params.sample_rate,
      DAQmx_Val_Rising, DAQmx_Val_ContSamps, params.num_samples_per_channel);
    if (status != 0) {
      log_ni_error();
      return false;
    }
  }

  //  reserve space for writing samples.
  globals.num_analog_output_channels = params.num_analog_output_channels;
  globals.num_samples_per_output_channel = params.num_samples_per_channel;
  globals.analog_output_buffer.resize(
    globals.num_analog_output_channels * globals.num_samples_per_output_channel);

  {
    const int32 status = DAQmxStartTask(globals.ni_analog_output_task.task);
    if (status != 0) {
      log_ni_error();
      return false;
    } else {
      globals.ni_analog_output_task.started = true;
    }
  }

  return true;
}

bool start_counter_outputs(const ni::InitParams& params) {
  globals.num_counter_output_tasks = params.num_counter_output_channels;

  for (int i = 0; i < params.num_counter_output_channels; i++) {
    int32 status{};

    NITask& task = globals.ni_counter_output_tasks[i];
    auto& task_handle = task.task;
    auto& channel_desc = params.counter_output_channels[i];

    std::string task_name{"COTask"};
    task_name += std::to_string(i);
    status = DAQmxCreateTask(task_name.c_str(), &task_handle);
    if (status != 0) {
      log_ni_error();
      return false;
    }

    status = DAQmxCreateCOPulseChanFreq(
      task_handle, channel_desc.name, "", DAQmx_Val_Hz, DAQmx_Val_Low,
      channel_desc.initial_delay, channel_desc.freq, channel_desc.duty_cycle);
    if (status != 0) {
      log_ni_error();
      return false;
    }

#if 1
    status = DAQmxCfgImplicitTiming(task_handle, DAQmx_Val_ContSamps, params.num_samples_per_channel);
#else
    status = DAQmxCfgSampClkTiming(
      task_handle, "", params.sample_rate,
      DAQmx_Val_Rising, DAQmx_Val_ContSamps, params.num_samples_per_channel);
#endif
    if (status != 0) {
      log_ni_error();
      return false;
    }

    status = DAQmxStartTask(task_handle);
    if (status != 0) {
      log_ni_error();
      return false;
    } else {
      task.started = true;
    }
  }

  return true;
}

bool start_inputs_and_exports(const ni::InitParams& params) {
  const uint32_t num_samples = params.num_samples_per_channel;

  auto& task_handle = globals.ni_input_export_task.task;
  int32 status{};

  status = DAQmxCreateTask("Task0", &task_handle);
  if (status != 0) {
    log_ni_error();
    return false;
  }

  for (int i = 0; i < params.num_analog_input_channels; i++) {
    auto& channel_desc = params.analog_input_channels[i];
    status = DAQmxCreateAIVoltageChan(
      task_handle, channel_desc.name, "",
      DAQmx_Val_Cfg_Default, channel_desc.min_value, channel_desc.max_value, DAQmx_Val_Volts, NULL);
    if (status != 0) {
      log_ni_error();
      return false;
    }
  }

  if (params.sample_clock_channel_name) {
    status = DAQmxExportSignal(
      task_handle, DAQmx_Val_SampleClock, params.sample_clock_channel_name.value());
    if (status != 0) {
      log_ni_error();
      return false;
    }
  }

  status = DAQmxCfgSampClkTiming(
    task_handle, "", params.sample_rate,
    DAQmx_Val_Rising, DAQmx_Val_ContSamps, params.num_samples_per_channel);
  if (status != 0) {
    log_ni_error();
    return false;
  }

  status = DAQmxRegisterEveryNSamplesEvent(
    task_handle, DAQmx_Val_Acquired_Into_Buffer, num_samples, 0, ni_input_sample_callback, nullptr);
  if (status != 0) {
    log_ni_error();
    return false;
  }

  status = DAQmxStartTask(task_handle);
  if (status != 0) {
    log_ni_error();
    return false;
  } else {
    globals.ni_input_export_task.started = true;
  }

  return true;
}

void clear_task(NITask* task) {
  if (task->started) {
    DAQmxStopTask(task->task);
    task->started = false;
  }
  if (task->task) {
    DAQmxClearTask(task->task);
    task->task = nullptr;
  }
}

bool start_daq(const ni::InitParams& params) {
  if (!start_inputs_and_exports(params)) {
    return false;
  }

  if (!start_outputs(params)) {
    return false;
  }

  if (!start_counter_outputs(params)) {
    return false;
  }

  return true;
}

void stop_daq() {
  for (int i = 0; i < globals.num_counter_output_tasks; i++) {
    clear_task(&globals.ni_counter_output_tasks[i]);
  }

  std::this_thread::sleep_for(std::chrono::seconds(15));

  clear_task(&globals.ni_input_export_task);
  clear_task(&globals.ni_analog_output_task);
}

bool analog_write(int channel, float v) {
  assert(channel >= 0 && channel < globals.num_analog_output_channels);
  auto& ni_task = globals.ni_analog_output_task;
  if (!ni_task.started) {
    return false;
  }

  auto& channel_desc = globals.analog_output_channel_descs[channel];
  double write_v = clamp(double(v), channel_desc.min_value, channel_desc.max_value);

  const int offset = globals.num_samples_per_output_channel * channel;
  for (int i = 0; i < globals.num_samples_per_output_channel; i++) {
    globals.analog_output_buffer[i + offset] = write_v;
  }

  int32 samps_per_chan_written{};
  const int32 status = DAQmxWriteAnalogF64(
    ni_task.task, globals.num_samples_per_output_channel, true, 
    DAQmx_Val_WaitInfinitely, DAQmx_Val_GroupByChannel, 
    globals.analog_output_buffer.data(), &samps_per_chan_written, nullptr);
  assert(samps_per_chan_written == globals.num_samples_per_output_channel);

  if (status != 0) {
    log_ni_error();
    return false;
  }

  return true;
}

void release_sample_buffers() {
  while (true) {
    auto buff = globals.received_from_ni.pop_back();
    if (buff) {
      if (!globals.send_to_ni_daq.maybe_write(std::move(buff.value()))) {
        assert(false);
      }
    } else {
      break;
    }
  }
}

void update_output_pulses() {
  if (globals.first_time) {
    globals.last_time = time::now();
    globals.first_time = false;
  }

  auto curr_t = time::now();
  double dt = time::elapsed_time(globals.last_time, curr_t);
  globals.last_time = curr_t;

  //  set high terminals -> low
  auto pulse_it = globals.output_pulse_queue.pulses.begin();
  while (pulse_it != globals.output_pulse_queue.pulses.end()) {
    pulse_it->time_remaining = std::max(0.0, pulse_it->time_remaining - dt);
    if (pulse_it->time_remaining == 0.0) {
      analog_write(pulse_it->channel, 0.0f);
      pulse_it = globals.output_pulse_queue.pulses.erase(pulse_it);
    } else {
      ++pulse_it;
    }
  }
}

void update_sample_index_sync() {
  const SampleBuffer* buffs{};
  int num_buffs = std::min(1, read_sample_buffers(&buffs));
  if (num_buffs == 0) {
    return;
  }

  auto& buff = buffs[0];
  bool push_timepoint{};
  if (globals.input_sample_sync_points.time_points.empty()) {
    push_timepoint = true;
  } else {
    auto& last_timepoint = globals.input_sample_sync_points.time_points.back();
    if (buff.sample0_index - last_timepoint.sample_index >= Config::input_sample_index_sync_interval) {
      push_timepoint = true;
    }
  }

  if (push_timepoint) {
    auto& next_sync_point = globals.input_sample_sync_points.time_points.emplace_back();
    next_sync_point.sample_index = buff.sample0_index;
    next_sync_point.elapsed_time = buff.sample0_time;
  }
}

} //  anon

bool ni::init_ni(const InitParams& params) {
  if (globals.initialized) {
    terminate_ni();
  }

  const auto t0 = time::now();
  globals.time0 = t0;

  globals.num_analog_input_channels = params.num_analog_input_channels;
  globals.num_samples_per_input_channel = params.num_samples_per_channel;

  init_input_data_handoff(params.num_analog_input_channels, params.num_samples_per_channel);

  if (!start_daq(params)) {
    terminate_ni();
    return false;
  } else {
    globals.initialized = true;
    return true;
  }
}

void ni::update_ni() {
  release_sample_buffers();
  update_output_pulses();
  update_sample_index_sync();
}

void ni::terminate_ni() {
  stop_daq();
  globals.daq_sample_buffer.clear();
  globals.num_samples_per_input_channel = 0;
  globals.num_analog_input_channels = 0;
  globals.num_analog_output_channels = 0;
  globals.num_counter_output_tasks = 0;
  globals.ni_num_input_samples_acquired = 0;
  globals.send_to_ni_daq.clear();
  globals.send_from_ni_daq.clear();
  globals.received_from_ni.clear();
  globals.available_to_send_to_ui.clear();
  globals.sample_buffer_data.clear();
  globals.time0 = {};
  globals.output_pulse_queue.clear();
  globals.input_sample_sync_points.clear();
  globals.initialized = false;
}

int ni::read_sample_buffers(const SampleBuffer** buffs) {
  int num_rcv = globals.send_from_ni_daq.size();
  for (int i = 0; i < num_rcv; i++) {
    globals.received_from_ni.push(globals.send_from_ni_daq.read());
  }

  *buffs = globals.received_from_ni.buffers;
  return globals.received_from_ni.num_buffers;
}

time::TimePoint ni::read_time0() {
  return globals.time0;
}

std::vector<ni::TriggerTimePoint> ni::read_sync_time_points() {
  return globals.input_sample_sync_points.time_points;
}

bool ni::write_analog_pulse(int channel, float val, float for_time) {
  if (!analog_write(channel, val)) {
    return false;
  }

  globals.output_pulse_queue.push(channel, for_time);
  return true;
}

bool ni::write_analog_pulse(int channel, bool hi, float for_time) {
  if (channel < 0 || channel >= globals.num_analog_output_channels) {
    return false;
  }

  auto& desc = globals.analog_output_channel_descs[channel];
  const float val = hi ? desc.max_value : desc.min_value;
  return write_analog_pulse(channel, val, for_time);
}