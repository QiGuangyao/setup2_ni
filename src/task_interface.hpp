#pragma once

#include <string>

namespace ni::task {

struct InitParams {
  std::string samples_file_p;
};

struct Sample {
  float pupil1;
  float x1;
  float y1;
  float pupil2;
  float x2;
  float y2;
};

void start_ni(const InitParams& params);
void update_ni();
void stop_ni();
Sample read_latest_sample();
void trigger_reward_pulse(int channel_index, float secs);
void trigger_pulse(int channel_index, float v, float secs);

}