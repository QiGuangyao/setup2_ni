#pragma once

#include <vector>
#include <optional>
#include <chrono>

namespace ni {

namespace time {

using TimePoint = std::chrono::high_resolution_clock::time_point;
using Duration = std::chrono::duration<double>;

inline TimePoint now() {
  return std::chrono::high_resolution_clock::now();
}

inline double elapsed_time(const TimePoint &t0, const TimePoint &t1) {
  return Duration(t1 - t0).count();
}

} //  time

struct ChannelDescriptor {
  const char* name;
  double min_value;
  double max_value;
};

//  @NOTE: Cannot read from and write to the same terminal (channel name) simultaneously.
struct InitParams {
  double sample_rate;
  int num_samples_per_channel;
  const ChannelDescriptor* analog_input_channels;
  int num_analog_input_channels;
  const ChannelDescriptor* analog_output_channels;
  int num_analog_output_channels;
  std::optional<const char*> sample_clock_channel_name;
};

struct TriggerTimePoint {
  double elapsed_time;
  uint64_t sample_index;
};

struct SampleBuffer {
  double* data;
  int num_samples_per_channel;
  int num_channels;
  uint64_t sample0_index;
  double sample0_time;
};

bool init_ni(const InitParams& params);
void update_ni();
void terminate_ni();

int read_sample_buffers(const SampleBuffer** buffs);
void release_sample_buffers();

time::TimePoint read_time0();
std::vector<TriggerTimePoint> read_trigger_time_points();
std::vector<TriggerTimePoint> read_sync_time_points();

bool write_analog_pulse(int channel, float v, float time_high);

} //  ni