function run_record_videos_only()

% how long (approximately) videos should be
record_time = 300;
save_data = true;
proj_p = 'D:\tempData';

win_m1 = ptb.Window();
win_m2 = ptb.Window();

save_ident = strrep( datestr(now), ':', '_' );
if ( save_data )
  save_p = fullfile( proj_p, 'data', save_ident );
  shared_utils.io.require_dir( save_p );
else
  save_p = '';
end

% task interface
t0 = datetime();
task_interface = TaskInterface( t0, save_p, {win_m1, win_m2} );
initialize( task_interface );

t0 = datetime();
trigger( task_interface.sync_interface, 0, t0, tic );
task_interface.set_t0( t0 );

if ( ~save_data )
  trial_data = [];
else
  trial_data = TaskData( ...
    save_p, 'task_data.mat' ...
    , task_interface.video_interface ...
    , task_interface.matlab_time ...
    , struct() ...
  );
  trial_data.sync_interface = task_interface.sync_interface;
end

% @NOTE: register trial data with task interface
task_interface.task_data = trial_data;

tic;
while ( toc < record_time && ~ptb.util.is_esc_down )
  update( task_interface );
end

shutdown( task_interface );

end