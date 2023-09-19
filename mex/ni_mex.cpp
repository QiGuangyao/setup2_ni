#include "mex.h"
#include "task_interface.hpp"
#include <optional>
#include <cstdio>

namespace {

using namespace ni;
  
const char* err_id = "ni_mex:main";

mxArray* make_sample_struct(const task::Sample& sample) {
  const char* fieldnames[6] = { 
    "pupil1", "x1", "y1",
    "pupil2", "x2", "y2",
  };
  
  mxArray* sample_array = mxCreateStructMatrix(1, 1, 6, fieldnames);

  mxArray* pupil1 = mxCreateDoubleScalar(sample.pupil1);
  mxArray* x1 = mxCreateDoubleScalar(sample.x1);
  mxArray* y1 = mxCreateDoubleScalar(sample.y1);
  
  mxArray* pupil2 = mxCreateDoubleScalar(sample.pupil2);
  mxArray* x2 = mxCreateDoubleScalar(sample.x2);
  mxArray* y2 = mxCreateDoubleScalar(sample.y2);

  mxSetFieldByNumber(sample_array, 0, 0, pupil1);
  mxSetFieldByNumber(sample_array, 0, 1, x1);
  mxSetFieldByNumber(sample_array, 0, 2, y1);
  
  mxSetFieldByNumber(sample_array, 0, 3, pupil2);
  mxSetFieldByNumber(sample_array, 0, 4, x2);
  mxSetFieldByNumber(sample_array, 0, 5, y2);
    
  return sample_array;
}

void check_input_outputs(
  int nlhs, int nrhs, 
  std::optional<int> req_lhs, std::optional<int> req_rhs) {
  //
  if (req_lhs && req_lhs.value() != nlhs) {
    std::string expect{std::to_string(req_lhs.value())};
    std::string msg = std::string{"Expected "} + expect + " outputs.";
    mexErrMsgIdAndTxt(err_id, msg.c_str());
  }
  
  if (req_rhs && req_rhs.value() != nrhs) {
    std::string expect{std::to_string(req_rhs.value())};
    std::string msg = std::string{"Expected "} + expect + " inputs.";
    mexErrMsgIdAndTxt(err_id, msg.c_str());
  }
}

void do_update(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  check_input_outputs(nlhs, nrhs, 1, 0);
  
  task::update_ni();
  
  const task::Sample sample = task::read_latest_sample();
  mxArray* sample_struct = make_sample_struct(sample);
  
  //  outputs
  plhs[0] = sample_struct;
}

void do_start(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  check_input_outputs(nlhs, nrhs, 0, 1);
  
  char dst_file_p[1024];
  if (mxGetString(prhs[0], dst_file_p, sizeof(dst_file_p))) {
    mexErrMsgIdAndTxt(err_id, "Failed to obtain destination file path.");
  }
  
  std::string str_file_p{dst_file_p};
  printf("\nOpening file: \"%s\"\n\n.", str_file_p.c_str());
  
  task::InitParams params{};
  params.samples_file_p = str_file_p;
  start_ni(params);
}

void do_stop(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  check_input_outputs(nlhs, nrhs, 0, 0);
}
  
} //  anon

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  if (nrhs == 0) {
    mexErrMsgIdAndTxt(err_id, "Expected at least 1 input.");
  }
  
  const mxArray* func_code = prhs[0];
  if (!mxIsScalar(func_code)) {
    mexErrMsgIdAndTxt(err_id, "Expected scalar function code.");
  }
  
  mxClassID func_code_class = mxGetClassID(func_code);
  if (func_code_class != mxUINT32_CLASS) {
    mexErrMsgIdAndTxt(err_id, "Expected uint32 function code.");
  }
  
  const uint32_t func = *(const uint32_t*)mxGetData(func_code);
  switch (func) {
    //  start
    case 0: {
      do_start(nlhs, plhs, nrhs - 1, prhs + 1);
      break;
    }
    
    //  update
    case 1: {
      do_update(nlhs, plhs, nrhs - 1, prhs + 1);
      break;
    }
    
    //  stop
    case 2: {
      do_stop(nlhs, plhs, nrhs - 1, prhs + 1);
      break;
    }
    
    default: {
      mexErrMsgIdAndTxt(err_id, "Unrecognized function code.");
    }
  }
}
  