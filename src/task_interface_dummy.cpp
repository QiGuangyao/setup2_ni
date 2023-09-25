#include "task_interface.hpp"
#include <iostream>

namespace ni {

void task::start_ni(const InitParams& params) {
  std::cout << "Would start ni; using samples file: " << params.samples_file_p << std::endl;
}

void task::update_ni() {
  std::cout << "Would update ni" << std::endl;
}

task::Sample task::read_latest_sample() {
  task::Sample sample{};
  sample.x1 = 1.0f;
  sample.y1 = -1.0f;
  sample.pupil1 = 0.25f;
  sample.x2 = 2.0f;
  sample.y2 = -2.0f;
  sample.pupil2 = 0.5f;
  return sample;
}

void task::stop_ni() {
  std::cout << "Would stop ni" << std::endl;
}

void task::trigger_reward_pulse(int channel, float secs) {
  std::cout << "Would trigger on " << channel << " for " << secs << std::endl;
}

} //  ni