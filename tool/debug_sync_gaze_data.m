data_dir = 'C:\Users\setup2\source\setup2_ni\task\data\21-Dec-2023 13_16_56';
td = load( fullfile(data_dir, 'task_data.mat') );
ni = read_ni_data( fullfile(data_dir, 'ni.bin') );
%%

sync_chan = ni(:, end);
is_pos = sync_chan > 0.99;
[npxi_isles, npxi_durs] = shared_utils.logical.find_islands( is_pos );

%%

vid_ts = datetime( td.saveable_data.video_data.vs1.Value.vid_time );
sync_ts = npxi_isles(1:2:end);
sync_ts = sync_ts(1:size(vid_ts, 1));

% clock_t0 is the canonical t0 for task events
vid_t_offset = vid_ts - td.saveable_data.matlab_time.clock_t0;
sec_offset = seconds( vid_t_offset );

% choose the desired alignment time (in this case, the start of the fixation
% with block rule state)
gaze_chunk_begin = ...
  td.saveable_data.trials(31).fixation_with_block_rule.fixation_state_m1.t0(1);
chunk_dur = 5;
ni_fs = 1e3;

% find the nearest synchronization timepoint to the desired alignment event
% (in this case, the start of the fixation with block rule state)
off = gaze_chunk_begin - sec_offset;
[~, nearest_beg] = min( abs(off) );
err = off(nearest_beg) * ni_fs;
% index into the array of ni samples using the synchronization pulse onset
% corresponding to the closest synchronization time point to the desired
% alignment event -- add the error between these
abs_beg = floor( sync_ts(nearest_beg) + err );
abs_end = abs_beg + chunk_dur * ni_fs;

look_back = -1e3;
look_ahead = 0;
t = look_back:chunk_dur*ni_fs+look_ahead;

xy = ni(abs_beg+look_back:abs_end+look_ahead, 1:2);
figure(1); clf;
plot( t, xy(:, 1), 'DisplayName', 'x' ); hold on;
plot( t, xy(:, 2), 'DisplayName', 'y' ); legend;
title( 'Gaze data' );

%%

n_sync_samples = 200;
figure(2); clf;
% subplot( 1, 2, 1 );
plot( is_pos(npxi_isles(1):npxi_isles(1)+n_sync_samples) ); hold on;
title( 'NI sync points' );

first_sync = 8e3;
sync_ib = (first_sync - 1) + find( sync_ts - sync_ts(1) < n_sync_samples );

for i = 1:numel(sync_ib)
  vid_t = vid_ts(sync_ib(i), :);
  text( gca, sync_ts(sync_ib(i)) - sync_ts(first_sync), 1 - i * 0.3, string(vid_t) );
end

% subplot( 1, 2, 2 );
plot( ni(npxi_isles(first_sync):npxi_isles(first_sync)+n_sync_samples, 1:2) );