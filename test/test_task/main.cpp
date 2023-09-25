#include "../../src/task_interface.hpp"
#include "../../src/ni.hpp"
#include <thread>
#include <cstdio>

namespace {

using namespace ni;

} //  anon

int main(int, char**) {
  task::InitParams init_p{};
  init_p.samples_file_p = "";

  task::start_ni(init_p);

  auto t0 = time::now();
  while (time::Duration(time::now() - t0).count() < 5.0) {
    task::update_ni();

    auto samp = task::read_latest_sample();
    printf("%0.2f, %0.2f, %0.2f | %0.2f, %0.2f, %0.2f\n",
           samp.pupil1, samp.x1, samp.y1, samp.pupil2, samp.x2, samp.y2);

    std::this_thread::sleep_for(std::chrono::milliseconds(1));
  }

  task::stop_ni();
}