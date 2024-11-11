addpath( genpath('/Users/Nick/repositories/changlab/setup2_ni') );
data_dir = '/Volumes/external3/data/changlab/guangyao-gaze-following/raw/19-Feb-2024 15_13_15';

td = load( fullfile(data_dir, 'task_data.mat') );
ni = read_ni_data( fullfile(data_dir, 'ni.bin') );

%%

% get m1's gaze position in pixels
m1_xy = convert_m1_gaze_position_to_pixels( ...
  td.saveable_data.params.gaze_coord_transform, get_m1_xy_from_ni_data(ni) );
% get m2's gaze position in pixels
m2_xy = convert_m2_gaze_position_to_pixels( ...
  td.saveable_data.params.gaze_coord_transform, get_m2_xy_from_ni_data(ni) );

% get timestamps for every sample of NI data, expressed in terms of
% matlab's (the task's) clock.
do_extrapolate = true;
ni_mat_t = transform_ni_clock_to_matlab_clock( ...
    get_sync_channel_from_ni_data(ni) ...
  , get_video_times_from_saveable_data(td.saveable_data) ...
  , get_matlab_t0_from_saveable_data(td.saveable_data) ...
  , do_extrapolate ...
);

%%

desired_trial = td.saveable_data.trials(2);
fs_m1 = desired_trial.fixation_with_block_rule.fixation_state_m1;
[~, ind] = min( abs(fs_m1.acquired_ts(1) - ni_mat_t) );

look_back_approx_ms = 1e3;
look_ahead_approx_ms = 1e3;

t_series = -look_back_approx_ms:look_ahead_approx_ms;
m1_aligned = m1_xy(ind-look_back_approx_ms:ind+look_ahead_approx_ms, :);

figure(1); clf; ax = gca; hold( ax, 'on' );
plot( ax, t_series, m1_aligned(:, 1), 'r', 'DisplayName', 'x' );
plot( ax, t_series, m1_aligned(:, 2), 'b', 'DisplayName', 'y' );