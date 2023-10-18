classdef MyTrialGenerator < handle
  properties
    % [0, 1]: 0 is laser, 1 is gaze
    trial_types = []
    % [0, 1]: 0 is left, 1 is right
    % during the spatial cue, this determines the side of the screen (from 
    % the signaler's perspective) that the correct target shows on.
    signaler_target_dirs = [];
    trial_index = 1;
  end
  methods
    function obj = MyTrialGenerator(nt)
      obj.trial_types = randi( 2, nt, 1 ) - 1;
      obj.signaler_target_dirs = randi( 2, nt, 1 ) - 1;

      % always left
%       obj.signaler_target_dirs = zeros( nt, 1 );

      % always right
%       obj.signaler_target_dirs = ones( nt, 1 );
    end

    function td = next(obj)
      td = struct();
      td.is_gaze_trial = obj.trial_types(obj.trial_index) == 1;
      td.signaler_target_dir = obj.signaler_target_dirs(obj.trial_index);
      td.laser_index = double( rand() > 0.5 );

      if ( 0 )
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

      obj.trial_index = mod( obj.trial_index, numel(obj.trial_types) ) + 1;
    end
  end
end