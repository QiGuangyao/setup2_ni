classdef DefaultTrialGenerator < handle
  methods
    function td = next(obj)
      td = struct();
      td.is_gaze_trial = rand() > 0.5;
      td.signaler_target_dir = double( rand() > 0.5 );
      td.laser_index = double( rand() > 0.5 );

      if ( 1 )
        td.signaler_target_dir = 1;
        td.is_gaze_trial = true;
        td.laser_index = 0;
      end

      if ( td.is_gaze_trial )
        % congruent with signaler because they are opposing one another.
        td.correct_actor_response_dir = 1 - td.signaler_target_dir;
      else
        td.correct_actor_rseponse_dir = td.signaler_target_dir;
      end
    end
  end
end