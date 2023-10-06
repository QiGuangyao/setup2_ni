classdef DefaultTrialGenerator < handle
  methods
    function td = next(obj)
      td = struct();
      td.is_gaze_trial = rand() > 0.5;
      td.swap_signaler_dir = rand() > 0.5;
      td.laser_index = double( rand() > 0.5 );
    end
  end
end