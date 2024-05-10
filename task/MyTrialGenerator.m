classdef MyTrialGenerator < handle
  properties
    % [0, 1]: 0 is laser, 1 is gaze
    trial_types = []
    % [0, 1]: 0 is left, 1 is right
    % during the spatial cue, this determines the side of the screen (from 
    % the signaler's perspective) that the correct target shows on.
    signaler_target_dirs = [];
    trial_index = 1;
    % laser_index [0,1]: 0 is right, 1 is left
  end
  methods
    function obj = MyTrialGenerator(nt)
      obj.trial_types = randi( 2, nt, 1 ) - 1;
      obj.signaler_target_dirs = randi( 2, nt, 1 ) - 1;
%       % shuffle
      rng("shuffle")
%       rand
      temp_trial = [zeros( nt/2, 1 );ones( nt/2, 1 )];
      obj.signaler_target_dirs = temp_trial(randperm(length(temp_trial)));

%       obj.signaler_target_dirs = [randi( 2, nt/10, 1 ) - 1; zeros( nt-nt/10, 1 )];
%       obj.signaler_target_dirs = obj.signaler_target_dirs(randperm(length(obj.signaler_target_dirs)));

%       always left
%       obj.signaler_target_dirs = zeros( nt, 1 );

      % always right
%       obj.signaler_target_dirs = ones( nt, 1 );
% 
    end

    function td = next(obj)
      td = struct();
%       td.is_gaze_trial = obj.trial_types(obj.trial_index) == 1;
      td.is_gaze_trial = true;% for gaze follwing trial
      td.signaler_target_dir = obj.signaler_target_dirs(obj.trial_index);
      td.laser_index = double( rand() > 0.5 );
      td.prob_gaze_triggered_delay = 1;
      td.state_spatial_cue_with_response_signaler_timeout = 0;
      td.state_spatial_cue_with_response_actor_timeout = 0.8;

      if ( 0 )
        td.signaler_target_dir = 1;
        td.is_gaze_trial = true;
        td.laser_index = 0;
      end

      if ( td.is_gaze_trial )
        % congruent with signaler because they are opposing one another.
        td.correct_actor_response_dir = 1 - td.signaler_target_dir;
      else
        td.correct_actor_response_dir = td.signaler_target_dir;
      end

      obj.trial_index = mod( obj.trial_index, numel(obj.trial_types) ) + 1;
    end
  end
end