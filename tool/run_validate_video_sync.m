task_data_p = 'C:\Users\setup2\source\setup2_ni\task\data';
npxi_data_p = 'C:\Users\setup2\Documents\Open Ephys\data\test';

npxi_sesh = 'latest';
npxi_exper = '';
task_sesh = 'latest';

if ( strcmp(task_sesh, 'latest') )
  task_seshs = shared_utils.io.filenames( ...
    shared_utils.io.find(task_data_p, 'folders') );
  task_sesh = datetime( strrep(task_seshs, '_', ':') );
  [~, mi] = max( task_sesh );
  task_sesh = task_seshs{mi};
end

if ( strcmp(npxi_sesh, 'latest') )
  % sessions
  npxi_sesh = shared_utils.io.filenames( ...
    shared_utils.io.find(npxi_data_p, 'folders') );
  npxi_dates = datetime( datestr(datenum(npxi_sesh, 'yyyy-mm-dd_HH-MM-SS')) );
  [~, mi] = max( npxi_dates );
  npxi_sesh = npxi_sesh{mi};
  % experiments
  expers = shared_utils.io.filenames( ...
    shared_utils.io.find(fullfile(npxi_data_p, npxi_sesh, 'Record Node 101'), 'folders') );
  exper_nums = cellfun( @(x) str2double(strrep(x, 'experiment', '')), expers );
  [~, mi] = max( exper_nums );
  npxi_exper = fullfile( expers{mi}, 'recording1' );
end

task_data_p = fullfile( task_data_p, task_sesh );
npxi_data_p = fullfile( ...
  npxi_data_p, npxi_sesh ...
  , 'Record Node 101', npxi_exper, 'continuous\Neuropix-PXI-100.ProbeA-AP' ...
);

validate_npxi_video_sync( ...
    fullfile(task_data_p, 'video_1.mp4') ...
  , fullfile(task_data_p, 'video_2.mp4') ...
  , fullfile(task_data_p, 'ni.bin') ...
  , fullfile(npxi_data_p, 'continuous.dat') ...
);