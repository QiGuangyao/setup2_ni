#include "task_interface.hpp"

namespace ni {

void task::start_ni(const InitParams&) {
  //
}

void task::update_ni() {
  //
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

} //  ni