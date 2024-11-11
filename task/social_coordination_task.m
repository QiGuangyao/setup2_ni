% function social_coordination_task()
function social_coordination_task(useEyeROI, m2_eye_roi_padding_x, m2_eye_roi_padding_y, ...
                                  m2_face_roi_padding_x, m2_face_roi_padding_y,initial_fixation_state_duration, ...
                                  initial_fixation_duration_m1, initial_fixation_duration_m2, ...
                                  iti_duration, initial_reward_m1, initial_reward_m2, ...
                                  init_reward_m1_m2, error_duration, name_of_m1, name_of_m2, ...
                                  fix_cross_visu_angl, totdist_m1, totdist_m2, ...
                                  screen_height_left, padding_angl, enable_remap, save_data, full_screens, max_num_trials, play_feedback_sound,proj_p, block_type)
    % Example task implementation using the parameters from the GUI
    % The actual task function should be implemented here
    % Define the folder path
    
    % Check if the folder exists
    if isfolder(proj_p)
        disp('The folder exists.');
    else
        error('The folder does not exist. Please check it!'); 
    end
    
    % Display the values
    disp('Running social coordination task with the following parameters:');
    disp(['Use Eye ROI: ', num2str(useEyeROI)]);
    disp(['Eye ROI Padding X: ', num2str(m2_eye_roi_padding_x)]);
    disp(['Eye ROI Padding Y: ', num2str(m2_eye_roi_padding_y)]);
    disp(['Face ROI Padding X: ', num2str(m2_face_roi_padding_x)]);
    disp(['Face ROI Padding Y: ', num2str(m2_face_roi_padding_y)]);
    disp(['State duration: ', num2str(initial_fixation_state_duration)]);
    disp(['State duration: ', num2str(initial_fixation_state_duration)]);

    disp(['Initial Fixation Duration M1: ', num2str(initial_fixation_duration_m1)]);
    disp(['Initial Fixation Duration M2: ', num2str(initial_fixation_duration_m2)]);
    disp(['ITI Duration: ', num2str(iti_duration)]);
    disp(['Initial Reward M1: ', num2str(initial_reward_m1)]);
    disp(['Initial Reward M2: ', num2str(initial_reward_m2)]);
    disp(['Initial Reward M1 & M2: ', num2str(init_reward_m1_m2)]);
    disp(['Error Duration: ', num2str(error_duration)]);
    disp(['Name of M1: ', name_of_m1]);
    disp(['Name of M2: ', name_of_m2]);
    disp(['Fix Cross Visu Angl: ', num2str(fix_cross_visu_angl)]);
    disp(['Total Distance M1: ', num2str(totdist_m1)]);
    disp(['Total Distance M2: ', num2str(totdist_m2)]);
    disp(['Screen Height Left: ', num2str(screen_height_left)]);
    disp(['Padding Angle: ', num2str(padding_angl)]);
    disp(['Enable Remap: ', num2str(enable_remap)]);
    disp(['Save Data: ', num2str(save_data)]);
    disp(['Full Screens: ', num2str(full_screens)]);
    disp(['Max Number of Trials: ', num2str(max_num_trials)]);
    disp(['Play feedback sound: ', num2str(play_feedback_sound)]);
    
global prefer_center_y;
global prefer_relative_sizes;

prefer_center_y = true;
prefer_relative_sizes = true;

cd 'C:\Users\setup2\source\setup2_ni\deps\network-events\Resources\Matlab';

m2_eye_roi = [];
m2_eye_roi_real = [];

try
% load the latest far plane calibrations
[m1_calib, m2_calib] = get_latest_far_plane_calibrations( dsp3.datedir );

% eye roi target width and height padding
% useEyeROI = false;
% m2_eye_roi_padding_x = 50;
% m2_eye_roi_padding_y = 50;
% m2_face_roi_padding_x = 50;
% m2_face_roi_padding_y = 50;
if useEyeROI
  m2_eye_roi = get_eye_roi_from_calibration_file( ...
    m1_calib, m2_eye_roi_padding_x, m2_eye_roi_padding_y );
else
  m2_eye_roi = get_face_roi_from_calibration_file( m1_calib, m2_face_roi_padding_x, m2_face_roi_padding_y );
end
fprintf( 'm2 eye roi: %d %d %d %d', m2_eye_roi );
% m2_face_roi = get_face_roi_from_calibration_file( m1_calib, 0, 0 );

m2_eye_roi_real = get_eye_roi_from_calibration_file( ...
    m1_calib, m2_eye_roi_padding_x, m2_eye_roi_padding_y );
catch roi_err
  warning( roi_err.message );
end

% need parpool for async video interface. the pool should be
% initialized before the call to parfeval(), since it usually takes a 
% while to start.
pool = gcp( 'nocreate' );
if ( isempty(pool) )
  parpool( 2 );
end

proj_p_image = fileparts( which(mfilename) );
% proj_p = 'D:\tempData\coordination';

bypass_trial_data = false ;    
 save_data = true;
 full_screens = true;
% max_num_trials = 30;
rng("shuffle")
draw_m2_eye_roi = false;
draw_m1_gaze = false;
draw_m2_gaze = false;
draw_m2_eye_cue = false;
% always_draw_spatial_rule_outline = fasle;
 enable_remap = false;
verbose = false;
%{
  timing parameters
%}
timing = struct();
%%% stages of the task
% 1 fixation with block rule
enbale_fixation_with_block_rule = true;
%{
block type
  1: coordiantion task; 
  2: independent task;  
  3: cooperation task; 
  4: no-vision coordiantion task; 
  5: no-vision independent task; 
  6: no-vision cooperation task
%}
collM2Matr_shuffle = [];
if block_type<4
  enable_remap = enable_remap;
  if block_type ==1
  
    timing.initial_fixation_duration_m1 = initial_fixation_duration_m1;
    timing.initial_fixation_duration_m2 = initial_fixation_duration_m2;
    timing.initial_fixation_state_duration = initial_fixation_state_duration;
    timing.initial_reward_m1 = initial_reward_m1;
    timing.initial_reward_m2 = initial_reward_m2;
    timing.init_reward_m1_m2 = init_reward_m1_m2;
  elseif block_type == 2
    timing.initial_fixation_duration_m1 = initial_fixation_duration_m1;
    timing.initial_fixation_duration_m2 = initial_fixation_duration_m2;
    timing.initial_fixation_state_duration = initial_fixation_state_duration;
    timing.initial_reward_m1 = initial_reward_m1;
    timing.initial_reward_m2 = initial_reward_m2;
    timing.init_reward_m1_m2 = 0;
  elseif block_type == 3
    timing.initial_fixation_duration_m1 = initial_fixation_duration_m1;
    timing.initial_fixation_duration_m2 = initial_fixation_duration_m2;
    timing.initial_fixation_state_duration = initial_fixation_state_duration;
    initial_reward_m1 = 0;
    initial_reward_m2 = 0;
    timing.initial_reward_m1 = 0;
    timing.initial_reward_m2 = 0;
    timing.init_reward_m1_m2 = init_reward_m1_m2;
  end
else
  enable_remap = true;
  if block_type ==4
    timing.initial_fixation_duration_m1 = initial_fixation_duration_m1;
    timing.initial_fixation_duration_m2 = initial_fixation_duration_m2;
    timing.initial_fixation_state_duration = initial_fixation_state_duration;
    timing.initial_reward_m1 = initial_reward_m1;
    timing.initial_reward_m2 = initial_reward_m2;
    timing.init_reward_m1_m2 = init_reward_m1_m2;
  elseif block_type == 5
    timing.initial_fixation_duration_m1 = initial_fixation_duration_m1;
    timing.initial_fixation_duration_m2 = initial_fixation_duration_m2;
    timing.initial_fixation_state_duration = initial_fixation_state_duration;
    timing.initial_reward_m1 = initial_reward_m1;
    timing.initial_reward_m2 = initial_reward_m2;
    timing.init_reward_m1_m2 = 0;
  elseif block_type == 6
    timing.initial_fixation_duration_m1 = initial_fixation_duration_m1;
    timing.initial_fixation_duration_m2 = initial_fixation_duration_m2;
    timing.initial_fixation_state_duration = initial_fixation_state_duration;
    timing.initial_reward_m1 = 0;
    timing.initial_reward_m2 = 0;
    timing.init_reward_m1_m2 = init_reward_m1_m2;
  elseif block_type == 7
    collM2Matr = collM2Trials(1, name_of_m1,name_of_m2);
    % Get the number of columns
    numCols = size(collM2Matr, 2);
    % Generate a random permutation of column indices
    randomOrder = randperm(numCols);
    % Shuffle the columns of the array using the random permutation
    collM2Matr_shuffle = collM2Matr(:, randomOrder);
    
    timing.initial_fixation_duration_m1 = initial_fixation_duration_m1;
    timing.initial_fixation_duration_m2 = initial_fixation_duration_m2;
    timing.initial_fixation_state_duration = initial_fixation_state_duration;
    timing.initial_reward_m1 = initial_reward_m1;
    timing.initial_reward_m2 = initial_reward_m2;
    timing.init_reward_m1_m2 = init_reward_m1_m2;
  end

end




timing.initial_fixation_duration_m1 = initial_fixation_duration_m1;
timing.initial_fixation_duration_m2 = initial_fixation_duration_m2;
timing.initial_fixation_state_duration = initial_fixation_state_duration;

timing.initial_reward_m1 = initial_reward_m1;
timing.initial_reward_m2 = initial_reward_m2;
timing.init_reward_m1_m2 = init_reward_m1_m2;


% 2 feedback & reward
enable_response_feedback = true;
timing.iti_duration = iti_duration;
timing.error_duration =error_duration; % timeout in case of failure to fixate
timing.feedback_duration = 1;
timing.waitSecs = 0.5;


% sound 
% note: media player: paly wn, 10 
% system: 50

% Load audio data from a file
% play_feedback_sound = true;
[y, Fs] = audioread('C:/Users/setup2/source/setup2_ni/deps/network-events/Resources/Matlab/lowSound500hz.wav');

% Create an audioplayer object
player = audioplayer(y, Fs);

% how long m1 and m2 can be overlapping in their target bounds before state
% exits
timing.overlap_duration_to_exit = nan;

%{
name of monkeys
%}
block_type = block_type; % 1: coordiantion task; 2: independent task;  3: cooperation task; 4: no vision independent task; 5: no vision coordiantion task; 6: no-vision cooperation task




% name_of_m1 ='M1_lynch';% 'lynch';%'M1_simu';
% name_of_m2 ='M2_ephron';% 'Hitch';
%{
  stimuli parameters
%}

%{
  stimuli parameters
%}

% fix_cross_visu_angl =6;%deg
visanglex = fix_cross_visu_angl;
visangley = fix_cross_visu_angl;

% totdist_m1 = 450;%mm
% totdist_m2 = 515;%mm
% screen_height_left = 8.5;% cm after monitor down 

screenwidth = 338.66666667;%mm
screenres = 1280;%mm
[fix_cross_size_m1,sizey_m1] = visangle2stimsize(visanglex,visangley,totdist_m1,screenwidth,screenres);
[fix_cross_size_m2,sizey_m2] = visangle2stimsize(visanglex,visangley,totdist_m2,screenwidth,screenres);

% fix_cross_size_m1 = 161.72;%pix
% fix_cross_size_m2 = 169.97;%pix

fix_circular_size= fix_cross_size_m1;
error_square_size_m1 = fix_cross_size_m1;
error_square_size_m2 = fix_cross_size_m2;


% fix_target_size = 150; % px
fix_target_size_m1 = fix_cross_size_m1; % pxrr
fix_target_size_m2 = fix_cross_size_m2; % prr
% error_square_size = 150;
lr_eccen = 0; % px amount to shift left and right targets towards screen edges
lr_eccen_coll = [];

% add +/- target_padding
% padding_angl = 2;


% padding_angl = 0;
visanglex = padding_angl;
visangley = padding_angl;
[target_padding_m1,sizey_m1] = visangle2stimsize(visanglex,visangley,totdist_m1,screenwidth,screenres);
[target_padding_m2,sizey_m2] = visangle2stimsize(visanglex,visangley,totdist_m2,screenwidth,screenres);
% target_padding_m1 = 96.99;
% target_padding_m2 = 101.94;


cross_padding_m1 = target_padding_m1;
cross_padding_m2 = target_padding_m2;

circular_padding = target_padding_m1;

% sptial rule width
spatial_rule_width = 5;

%{
  reward parameters
%}

dur_key = 0.3;

%{
  init
%}

% save_ident = strrep( datestr(now), ':', '_' );
save_ident = [strrep( datestr(now), ':', '_' ),'_block_type','_',num2str(block_type)];
if ( save_data )
  save_p = fullfile( proj_p, 'data', save_ident );
  shared_utils.io.require_dir( save_p );
else
  save_p = '';
end

% open windows before ni
if ( full_screens )
  win_m1 = open_window( 'screen_index', 1, 'screen_rect', [] );% 4 for M1 
  win_m2 = open_window( 'screen_index', 2, 'screen_rect', [] );% 1 for M2
else
  win_m1 = open_window( 'screen_index', 4, 'screen_rect', [0, 0, 400, 400] );
  win_m2 = open_window( 'screen_index', 4, 'screen_rect', [400, 0, 800, 400] );
end

debug_monitor_index = 1;
% debug_monitor_index = []; % disable by leaving the index empty
win_debug_m1 = [];
win_debug_m2 = [];
if ( ~isempty(debug_monitor_index) )
  screen_x_off = [ 1600, 0, 1600, 0 ];
  ar = win_m1.Height / win_m1.Width;
  new_w = 800;
  new_h = new_w * ar;

  win_debug_m1 = open_window( 'screen_index', debug_monitor_index, 'screen_rect', [0, 0, new_w, new_h] + screen_x_off );
  win_debug_m2 = open_window( 'screen_index', debug_monitor_index, 'screen_rect', [new_w, 0, new_w * 2, new_h] + screen_x_off );
end

%{
  remap target and stimuli
  monitor information
    Monitor: 1280 x 1024 pixels
    33.866666667 x 27.093333333 cm
%}

monitor_height = 27.093333333;% cm
moitor_screen_edge_to_table = 2.2;%cm
if enable_remap
%   prompt = {'Enter left screen height (cm):'};
%   dlg_title = 'Input';
%   num_lines = 1;
%   defaultans = {'0'};
%   screen_height = str2double(cell2mat(inputdlg(prompt,dlg_title,num_lines,defaultans)));
  y_axis_screen = screen_height_left/(2*monitor_height);%0.25;%
  y_axis_remap = (monitor_height-(screen_height_left/2-moitor_screen_edge_to_table))/monitor_height;%x/(2*27.3);%0.25;%
  
  if screen_height_left == 0
    y_axis_screen = 0.75;
    y_axis_remap = 0.75;
  end
  center_screen_m1 = [0.5*win_m1.Width,y_axis_screen*win_m1.Height];
  center_screen_m2 = [0.5*win_m2.Width,y_axis_screen*win_m2.Height];
  center_remap_m1 = [0.5*win_m1.Width,y_axis_remap*win_m1.Height];
  center_remap_m2 = [0.5*win_m2.Width,y_axis_remap*win_m2.Height];
else
  center_screen_m1 = win_m1.Center;
  center_screen_m2 = win_m2.Center;
  center_remap_m1 = center_screen_m1;
  center_remap_m2 = center_screen_m2;
end

% task interface
t0 = datetime();
task_interface = TaskInterface( t0, save_p, {win_m1, win_m2} );
initialize( task_interface );

t0 = datetime();
trigger( task_interface.sync_interface, 0, t0, tic );
task_interface.set_t0( t0 );

% trial data
% trial_generator = DefaultTrialGenerator();
%{
generate trials
%}

trial_number = max_num_trials;
trial_generator = MyTrialGenerator(trial_number );

% any data stored as a field of this struct will be saved.
task_params = struct( 'timing', timing );
task_params.center_screen_m1 = center_screen_m1;
task_params.center_screen_m2 = center_screen_m2;
task_params.trial_generator = trial_generator;
task_params.gaze_coord_transform = task_interface.gaze_tracker.gaze_coord_transform;
task_params.screen_height = screen_height_left;
task_params.monitor_height = monitor_height;
task_params.totdist_m1 = totdist_m1;
task_params.totdist_m2 = totdist_m2;
task_params.center_screen_m1 = center_remap_m1;
task_params.center_screen_m2 = center_remap_m2;
task_params.fix_cross_visu_angl = fix_cross_visu_angl;
task_params.fix_cross_size_m1 = fix_cross_size_m1;
task_params.fix_cross_size_m2 = fix_cross_size_m2;
task_params.fix_cross_jetter = 20;
task_params.social_coordination_task_block_type = block_type; % 1: coordiantion task; 2: independent task;  3: cooperation task; 4: no vision coordiantion task; 5: no vision independent task; 6: no-vision cooperation task

task_params.fix_target_size_m1 = fix_target_size_m1;
task_params.fix_target_size_m2 = fix_target_size_m2;
task_params.fix_circular_size = fix_circular_size;
task_params.error_square_size_m1 = error_square_size_m1;
task_params.error_square_size_m2 = error_square_size_m2;
task_params.padding_angl = padding_angl;
task_params.cross_padding_m1 = cross_padding_m1;
task_params.cross_padding_m2 = cross_padding_m2;
task_params.circular_padding = circular_padding;
task_params.trial_number = trial_number;
task_params.spatial_rule_width = spatial_rule_width;
task_params.bypass_trial_data = bypass_trial_data;
task_params.save_data = save_data;
task_params.full_screens = full_screens;
task_params.max_num_trials = max_num_trials;
task_params.draw_m1_gaze = draw_m1_gaze;
task_params.draw_m2_gaze = draw_m2_gaze;
task_params.draw_m2_eye_cue = draw_m2_eye_cue;
% task_params.always_draw_spatial_rule_outline = always_draw_spatial_rule_outline;
task_params.enbale_fixation_with_block_rule = enbale_fixation_with_block_rule;
% task_params.enable_gaze_triggered_actor_choice = enable_gaze_triggered_actor_choice;
% task_params.break_on_m1_first_choice = timing.enable_gaze_triggered_actor_choice_break_on_m1_first_choice;

task_params.enable_response_feedback = enable_response_feedback;
task_params.enable_remap = enable_remap;
task_params.verbose = verbose;
task_params.m1 = name_of_m1;
task_params.m2 = name_of_m2;
task_params.m2_eye_roi = m2_eye_roi;
task_params.m2_eye_roi_real = m2_eye_roi_real;
% task_params.gaze_delay_block = gaze_delay_block;
task_params.m2_eye_roi_padding_x = m2_eye_roi_padding_x;
task_params.m2_eye_roi_padding_y = m2_eye_roi_padding_y;
task_params.m2_eye_roi_padding_x = m2_face_roi_padding_x;
task_params.m2_eye_roi_padding_y = m2_face_roi_padding_y;
task_params.useEyeROI = useEyeROI;
task_params.screenres = screenres;
task_params.screenwidth = screenwidth;

task_params.lr_eccen = lr_eccen;
task_params.test_room_light = 1;% 0: off; 1: on.

if ( bypass_trial_data )
  trial_data = [];
else
  trial_data = TaskData( ...
    save_p, 'task_data.mat' ...
    , task_interface.video_interface ...
    , task_interface.matlab_time ...
    , task_params ...
  );
  trial_data.sync_interface = task_interface.sync_interface;
end

% @NOTE: register trial data with task interface
task_interface.task_data = trial_data;

% task
%
% 
if block_type == 1 || block_type == 4||block_type == 7|| block_type == 3
  cross_im = ptb.Image( win_m1, imread(fullfile(proj_p_image, 'images/cross.jpg')));
elseif block_type == 2 || block_type == 5
  cross_im = ptb.Image( win_m1, imread(fullfile(proj_p_image, 'images/rotated_cross.jpg')));
end

% rewarded (correct) target
targ1_im_m2 = ptb.Image( win_m2, imread(fullfile(proj_p_image, 'images/rotated_rect.jpg')));
% opposite target
targ2_im_m2 = ptb.Image( win_m2, imread(fullfile(proj_p_image, 'images/rect.jpg')));
% m1 targets
% targ_im_m1 = ptb.Image( win_m1, imread(fullfile(proj_p, 'images/circle.jpg')));

reward_key_timers = ptb.Reference();
reward_key_timers.Value = struct( ...
    'timer', {nan, nan} ...
  , 'key', {ptb.keys.r, ptb.keys.t} ...
  , 'channel', {0, 1} ...
);

%{
  main trial sequence
%}
err = [];
try

trial_inde = 0;
m1_correct = 0;
m2_correct = 0;
m1_m2_correct = 0;



m1_ini_rw = timing.initial_reward_m1;
m2_ini_rw = timing.initial_reward_m2;
m1_m1_ini_rw = timing.init_reward_m1_m2;

%real_time_plot 
% Number of points to simulate
numPoints = max_num_trials;
    
% Preallocate arrays to store data

m1_m2_beha_sum = nan(9,max_num_trials);%trials, m1 CR, m2 CR, m1&m2 CR, m1 correct, m2 correct, m1&m2 correct, m1 response time, m2 response time, 

m1_m2_beha_sum(1,:) = nan(1, max_num_trials);
m1_m2_beha_sum(2,:) = nan(1, max_num_trials);

% 
% time = zeros(1, numPoints);
% data1 = zeros(1, numPoints); % For M1
% data2 = zeros(1, numPoints); % For M2
% data3 = zeros(1, numPoints); % For M2


% Create a figure for the plot
hFig = figure('Position', [100, 100, 800, 400]);
hold on;
hPlot1 = plot(m1_m2_beha_sum(1,:), m1_m2_beha_sum(2,:) , '-o', 'DisplayName', 'M1 Correct Rate', 'LineWidth', 1.5);
hPlot2 = plot(m1_m2_beha_sum(1,:), m1_m2_beha_sum(3,:) , '-o', 'DisplayName', 'M2 Correct Rate', 'LineWidth', 1.5);
hPlot3 = plot(m1_m2_beha_sum(1,:), m1_m2_beha_sum(4,:) , '-o', 'DisplayName', 'M1&M2 Correct Rate', 'LineWidth', 1.5);

legend('show');
xlabel('Time (s)');
ylabel('Correct Rate (%)');
title('Real-Time Plot of M1 and M2 Correct Rates');
grid on;
xlim([0 max_num_trials]);
ylim([0 100]);

while ( ~ptb.util.is_esc_down() && ...
      proceed(task_interface) && ...
      (isempty(trial_data) || num_entries(trial_data) < max_num_trials) )
  drawnow;

  trial_inde = trial_inde+1
  if ( isempty(trial_data) )
    trial_rec = TrialRecord();
  else
    trial_rec = push( trial_data );
  end
  trial_desc = next( trial_generator );

  if ( isempty(trial_desc) )
    break
  end

  lr_eccen = randi([35 35]);
  lr_eccen_coll = [lr_eccen_coll lr_eccen];

  task_params.lr_eccen_coll = lr_eccen_coll;
  % select gaze trial
  timing.initial_reward_m1 = m1_ini_rw;
  timing.initial_reward_m2 = m2_ini_rw;
  timing.init_reward_m1_m2 = m1_m1_ini_rw;
  
  trial_desc.is_gaze_trial = true; % true just for gaze trials at current stage
  trial_rec.trial_descriptor = trial_desc;
%   trial_rec.gaze_triggered_delay = struct();
  trial_rec.trial_start = struct();
  trial_rec.trial_start.time = time_cb();
  trial_rec.m1_m2_beha_sum = m1_m2_beha_sum;
  trial_rec.collM2Matr_shuffle = collM2Matr_shuffle;
  default_trigger( task_interface.sync_interface, 0 );

  %{
    fixation with block rule
  %}
  
  if enbale_fixation_with_block_rule
    [trial_rec.fixation_with_block_rule, acquired_m1,acquired_m2] = state_fixation_with_block_rule();
    
    m1_intial_enter = trial_rec.fixation_with_block_rule.fixation_state_m1.entered_ts;
    m2_intial_enter = trial_rec.fixation_with_block_rule.fixation_state_m2.entered_ts;



    if acquired_m1
      ['m1 initial success']
      m1_correct = m1_correct+1;
      m1_m2_beha_sum(5, trial_inde) = acquired_m1;
    elseif m1_intial_enter
      m1_m2_beha_sum(5, trial_inde) = 0;

    end

    if acquired_m2 == 1
      ['m2 initial success']
      m2_correct = m2_correct+1;
      m1_m2_beha_sum(6, trial_inde) = acquired_m2;
    elseif m2_intial_enter
      m1_m2_beha_sum(6, trial_inde) = 0;
    end


    % response time

    if m1_intial_enter
      m1_m2_beha_sum(8, trial_inde) = trial_rec.fixation_with_block_rule.fixation_state_m1.entered_ts(1) - trial_rec.fixation_with_block_rule.fixation_state_m1.t0;%,...%trials(1,t).fixation_with_block_rule.fixation_state_m1.entered_ts(1)-trials(1,t).fixation_with_block_rule.fixation_state_m1.t0(1),...
    end
    
    if m2_intial_enter
      m1_m2_beha_sum(9, trial_inde) = trial_rec.fixation_with_block_rule.fixation_state_m2.entered_ts(1) - trial_rec.fixation_with_block_rule.fixation_state_m2.t0;%,...%trials(1,t).fixation_with_block_rule.fixation_state_m2.entered_ts(1)-trials(1,t).fixation_with_block_rule.fixation_state_m2.t0(1),...
    end

    disp(['Correct Rate M1: ', num2str(m1_correct/trial_inde*100), '%']);
    disp(['Correct Rate M2: ', num2str(m1_correct/trial_inde*100), '%']);
    

    if (acquired_m1 && (acquired_m2==1))
      m1_m2_beha_sum(7, trial_inde) = 1;
      m1_m2_correct = m1_m2_correct+1;
% %     if ((~acquired_m2))
%       % error
% %       tic
      WaitSecs(timing.initial_reward_m1);
      deliver_reward(task_interface, [0,1], [timing.init_reward_m1_m2, timing.init_reward_m1_m2]);
      if play_feedback_sound
        play(player);
      end
      WaitSecs(timing.init_reward_m1_m2);
      if play_feedback_sound
        pause(player);
      end
     
      disp(['Correct Rate M1 & M2: ', num2str(m1_m2_correct/trial_inde*100), '%']);
      state_iti();

      % Update data arrays
      m1_m2_beha_sum(1,trial_inde) = trial_inde;
      m1_m2_beha_sum(2,trial_inde) = m1_correct/trial_inde*100;
      m1_m2_beha_sum(3,trial_inde) = m2_correct/trial_inde*100;
      m1_m2_beha_sum(4,trial_inde) = m1_m2_correct/trial_inde*100;

      

      trial_rec.m1_m2_beha_sum = m1_m2_beha_sum;
      % Update plot data
      set(hPlot1, 'XData', m1_m2_beha_sum(1, 1:trial_inde), 'YData', m1_m2_beha_sum(2, 1:trial_inde));
      set(hPlot2, 'XData', m1_m2_beha_sum(1, 1:trial_inde), 'YData', m1_m2_beha_sum(3, 1:trial_inde));
      set(hPlot3, 'XData', m1_m2_beha_sum(1, 1:trial_inde), 'YData', m1_m2_beha_sum(4, 1:trial_inde));
      % Refresh plot
      drawnow;
      continue
    else
      disp(['Correct Rate M1 & M2: ', num2str(m1_m2_correct/trial_inde*100), '%']);
      if block_type == 7
        error_timeout_state( timing.error_duration,1,1, ~(acquired_m1), 0);
      else
        error_timeout_state( timing.error_duration,1,1, ~(acquired_m1), ~(acquired_m2));
      end
      state_iti();

      % Update data arrays
      m1_m2_beha_sum(1,trial_inde) = trial_inde;
      m1_m2_beha_sum(2,trial_inde) = m1_correct/trial_inde*100;
      m1_m2_beha_sum(3,trial_inde) = m2_correct/trial_inde*100;
      m1_m2_beha_sum(4,trial_inde) = m1_m2_correct/trial_inde*100;
      trial_rec.m1_m2_beha_sum = m1_m2_beha_sum;

      trial_rec.m1_m2_beha_sum = m1_m2_beha_sum;
      % Update plot data
      set(hPlot1, 'XData', m1_m2_beha_sum(1, 1:trial_inde), 'YData', m1_m2_beha_sum(2, 1:trial_inde));
      set(hPlot2, 'XData', m1_m2_beha_sum(1, 1:trial_inde), 'YData', m1_m2_beha_sum(3, 1:trial_inde));
      set(hPlot3, 'XData', m1_m2_beha_sum(1, 1:trial_inde), 'YData', m1_m2_beha_sum(4, 1:trial_inde));
      % Refresh plot
      drawnow;

      continue
    end
  end


%   pause(player)

  %{
    iti
  %}
%   'iti: '
%   tic
%   state_iti();

%   if ( 1 )
%     state_iti();
%   end
%   toc
end
close(hFig)
% clear(hFig)
% clf(hFig)

catch err
  
end

local_shutdown();

if ( ~isempty(err) )
  rethrow( err );
end

%{
  local functions
%}

%{
  states
%}

function [res, acquired_m1,acquired_m2] = state_fixation_with_block_rule()
  send_message( task_interface.npxi_events, 'fixation_with_block_rule/enter' );

  loc_draw_cb = wrap_draw(...
    {@draw_fixation_crosses, @maybe_draw_gaze_cursors},1,1);
%   loc_draw_cb = @do_draw;
  if block_type == 7 
    if collM2Matr_shuffle(6,trial_inde)==1
      timing.initial_fixation_duration_m2 = collM2Matr_shuffle(9,trial_inde);
    else
      if ~isnan(collM2Matr_shuffle(9,trial_inde))
        timing.initial_fixation_duration_m2 = collM2Matr_shuffle(9,trial_inde);
      else
        timing.initial_fixation_duration_m2 = timing.initial_fixation_state_duration+1;
      end
    end
  end
  [fs_m1, fs_m2] = joint_fixation2( ...
    @time_cb, loc_draw_cb ...
    , @m1_rect, @get_m1_position ...
    , @m2_rect, @get_m2_position ...
    , @local_update ...
    , timing.initial_fixation_duration_m1...
    , timing.initial_fixation_duration_m2...
    , timing.initial_fixation_state_duration ...
    , [] ...
    , 'm1_every_acq_callback', @m1_acquire_cb ...
    , 'm2_every_acq_callback', @m2_acquire_cb ...
    , 'overlap_duration_to_exit', timing.overlap_duration_to_exit ...
  );

  res.fixation_state_m1 = fs_m1;
  res.fixation_state_m2 = fs_m2;
  acquired_m1 = fs_m1.ever_acquired;

  acquired_m2 = fs_m2.ever_acquired;
  if block_type == 7
    acquired_m2 = collM2Matr_shuffle(6,trial_inde);
  end

  function r = m1_rect()
    r = rect_pad(m1_centered_rect_remap(fix_cross_size_m1), cross_padding_m1);
  end

  function r = m2_rect()
    r = rect_pad(m2_centered_rect_remap(fix_cross_size_m2), cross_padding_m2);
  end

  function do_draw()
    fill_rect( win_m1, [0, 255, 0], m1_rect() );
    fill_rect( win_m2, [0, 255, 0], m2_rect() );
    if ( 1 )
      fill_oval( win_m1, [255, 0, 255], centered_rect(get_m1_position(), 50) );
      fill_oval( win_m2, [255, 0, 255], centered_rect(get_m2_position(), 50) );
    end
    flip( win_m1, false );
    flip( win_m2, false );
    if ( ~isempty(win_debug_m1) )
      flip( win_debug_m1, false );
    end
    if ( ~isempty(win_debug_m2) )
      flip( win_debug_m2, false );
    end
  end

  function m1_acquire_cb()
%     default_trigger_async( task_interface.sync_interface, 0 );
    deliver_reward(task_interface, 0, timing.initial_reward_m1);
    timing.initial_reward_m1 = 0;
%     default_trigger_async( task_interface.sync_interface, 0 );
  end

  function m2_acquire_cb()
    if block_type == 7
      if collM2Matr_shuffle(6,trial_inde)
        deliver_reward(task_interface, 1, timing.initial_reward_m2);
      end
    else
      deliver_reward(task_interface, 1, timing.initial_reward_m2);
    end
    timing.initial_reward_m2 = 0;
  end
end

function draw_spatial_rule_outline(actor_win, is_gaze_trial)
  if ( is_gaze_trial )
    color = [0, 0, 255];
%     color = [255, 0, 0];
  else
    color = [255, 0, 0];
%     color = [0, 0, 255];
  end

  r = get( actor_win.Rect );
  if ( enable_remap )
%       fr = [ r(1), r(2), r(3), center_remap_m1(2) ];
    h = screen_height_left / monitor_height * (r(4) - r(2));
    fr = centered_rect( center_screen_m1, [r(3) - r(1), h ]);

  else
    fr = r;
  end

  frame_rect( actor_win, color, fr, spatial_rule_width );%
end

function state_response_feedback()
  send_message( task_interface.npxi_events, 'response_feedback/enter' );

  static_fixation2( ...
    @time_cb, wrap_draw({@maybe_draw_gaze_cursors},1,1) ...
  , @() rect_pad(m1_centered_rect_remap(fix_cross_size_m1), target_padding_m1), @get_m1_position ...
  , @() rect_pad(m2_centered_rect_remap(fix_cross_size_m2), target_padding_m2), @get_m2_position ...
  , @local_update, timing.feedback_duration, timing.feedback_duration );
end

function state_iti()
  send_message( task_interface.npxi_events, 'iti/enter' );

  static_fixation2( ...
    @time_cb, wrap_draw({@maybe_draw_gaze_cursors},1,1) ...
  , @() rect_pad(m1_centered_rect_remap(fix_cross_size_m1), target_padding_m1), @get_m1_position ...
  , @() rect_pad(m2_centered_rect_remap(fix_cross_size_m2), target_padding_m2), @get_m2_position ...
  , @local_update, timing.iti_duration, timing.iti_duration );
end

function error_timeout_state(duration,errorDrawWin1, errorDrawWin2, show_m1_error, show_m2_error)
  send_message( task_interface.npxi_events, 'error/enter' );

  if ( nargin < 5 )
    show_m2_error = true;
  end
  if ( nargin < 4 )
    show_m1_error = true;
  end

  % error
  draw_err = @() draw_error(show_m1_error, show_m2_error);
  static_fixation2( ...
    @time_cb, wrap_draw({draw_err, @maybe_draw_gaze_cursors},errorDrawWin1,errorDrawWin2) ...
  , @invalid_rect, @get_m1_position ...
  , @invalid_rect, @get_m2_position ...
  , @local_update, duration, duration );
end

%{
  utilities
%}

function r = time_cb()
  r = elapsed_time( task_interface );
end

function m1_xy = get_m1_position()
  m1_xy = task_interface.get_m1_position( win_m1,enable_remap,center_remap_m1 );
end

function m2_xy = get_m2_position()
  m2_xy = task_interface.get_m2_position( win_m2,enable_remap,center_remap_m2);
end

function s = get_m1_y_shift()
  s = center_screen_m1(2) - win_m1.Center(2);
end

function s = get_m2_y_shift()
  s = center_screen_m2(2) - win_m2.Center(2);
end

function r = m1_centered_rect(size)
 
  r = centered_rect( win_m1.Center, size );
%   r([2, 4]) = r([2, 4]) + 20; % shift target up by 20 px
end

function r = m2_centered_rect(size)
%   r = centered_rect( center_screen_m2, size );
  r = centered_rect( win_m2.Center, size );
end

function r = m1_centered_rect_screen(size)
  r = centered_rect( center_screen_m1, size );
%   r = centered_rect( win_m1.Center, size );
%   r([2, 4]) = r([2, 4]) + 20; % shift target up by 20 px
end

function r = m2_centered_rect_screen(size)
  r = centered_rect( center_screen_m2, size );
%   r = centered_rect( win_m2.Center, size );
end

function r = m1_centered_rect_remap(size)
  r = centered_rect( center_remap_m1, size );
%   r = centered_rect( win_m1.Center, size );
%   r([2, 4]) = r([2, 4]) + 20; % shift target up by 20 px
end

function r = m2_centered_rect_remap(size)
  r = centered_rect( center_remap_m2, size );
%   r = centered_rect( win_m2.Center, size );
end

function debug_win = get_debug_window_from_non_debug_window(win)
  if ( win == win_m1 )
    debug_win = win_debug_m1;
  else
    debug_win = win_debug_m2;
  end
end

function [dst_x0, dst_y0, dst_x1, dst_y1] = do_rect_remap(src_win_rect, dst_win_rect, rect, force_center_y, pref_rel_size)
  cx = mean( rect([1, 3]) );
  cy = mean( rect([2, 4]) );

  x01 = ( cx - src_win_rect(1) ) / diff( src_win_rect([1, 3]) );
  y01 = ( cy - src_win_rect(2) ) / diff( src_win_rect([2, 4]) );

  if ( force_center_y )
    y01 = 0.5;
  end

  srcw = diff( rect([1, 3]) );
  srch = diff( rect([2, 4]) );

  dstw = diff( dst_win_rect([1, 3]) );
  dsth = diff( dst_win_rect([2, 4]) );

  if ( ~pref_rel_size )
    dst_x0 = dstw * x01 - srcw * 0.5 + dst_win_rect(1);
    dst_x1 = dst_x0 + srcw;
    dst_y0 = dsth * y01 - srch * 0.5 + dst_win_rect(2);
    dst_y1 = dst_y0 + srch;
  else
    w01 = srcw / diff(src_win_rect([1, 3]));
    h01 = srch / diff(src_win_rect([2, 4]));

    dst_x0 = dstw * x01 - w01 * 0.5 * dstw + dst_win_rect(1);
    dst_x1 = dst_x0 + dstw * w01;
    dst_y0 = dsth * y01 - h01 * 0.5 * dsth + dst_win_rect(2);
    dst_y1 = dst_y0 + dsth * h01;
  end
end

function r = remap_rect_for_debug_window(src_win, dst_win, rect)
  if ( isempty(prefer_center_y) )
    prefer_center_y = true;
  end

  if ( isempty(prefer_relative_sizes) )
    prefer_relative_sizes = true;
  end

  src_win_rect = get( src_win.Rect );
  dst_win_rect = get( dst_win.Rect );

  [dst_x0, dst_y0, dst_x1, dst_y1] = do_rect_remap( src_win_rect, dst_win_rect, rect, prefer_center_y, prefer_relative_sizes );

  dst_win_rect_small = dst_win_rect;
  dst_win_rect_small(1) = dst_win_rect_small(1) + diff( dst_win_rect([1, 3]) ) * 0.125;
  dst_win_rect_small(3) = dst_win_rect_small(3) - diff( dst_win_rect([1, 3]) ) * 0.125;
  dst_win_rect_small(2) = dst_win_rect_small(2) + diff( dst_win_rect([2, 4]) ) * 0.125;
  dst_win_rect_small(4) = dst_win_rect_small(4) - diff( dst_win_rect([2, 4]) ) * 0.125;

  [dst_x0, dst_y0, dst_x1, dst_y1] = do_rect_remap( ...
    dst_win_rect, dst_win_rect_small, [dst_x0, dst_y0, dst_x1, dst_y1], false, prefer_relative_sizes );

  dst_x0 = max( min(dst_x0, dst_win_rect(3)), dst_win_rect(1) );
  dst_x1 = max( min(dst_x1, dst_win_rect(3)), dst_win_rect(1) );
  dst_y0 = max( min(dst_y0, dst_win_rect(4)), dst_win_rect(2) );
  dst_y1 = max( min(dst_y1, dst_win_rect(4)), dst_win_rect(2) );
  
  r = [ dst_x0, dst_y0, dst_x1, dst_y1 ];
end

function draw_texture(win, im, rect)
  Screen( 'DrawTexture', win.WindowHandle, im.TextureHandle, [], rect );
  dbg_win = get_debug_window_from_non_debug_window( win );
  if ( ~isempty(dbg_win) )
    Screen( 'DrawTexture', dbg_win.WindowHandle, im.TextureHandle, [] ...
      , remap_rect_for_debug_window(win, dbg_win, rect) );
  end
end

function fill_rect_debug(win, varargin)
  dbg_win = get_debug_window_from_non_debug_window( win );
  if ( ~isempty(dbg_win) )
    % Screen('FillRect', windowPtr [,color] [,rect] )
    varargin{2} = remap_rect_for_debug_window( win, dbg_win, varargin{2} );
    Screen( 'FillRect', dbg_win.WindowHandle, varargin{:} );
  end
end

function fill_rect(win, varargin)
  Screen( 'FillRect', win.WindowHandle, varargin{:} );
  fill_rect_debug( win, varargin{:} );
end

function fill_oval_debug(win, varargin)
  dbg_win = get_debug_window_from_non_debug_window( win );
  if ( ~isempty(dbg_win) )
    % Screen('FillRect', windowPtr [,color] [,rect] )
    varargin{2} = remap_rect_for_debug_window( win, dbg_win, varargin{2} );
    Screen( 'FillOval', dbg_win.WindowHandle, varargin{:} );
  end
end

function fill_oval(win, varargin)
  Screen( 'FillOval', win.WindowHandle, varargin{:} );
  fill_oval_debug( win, varargin{:} );
end

function frame_rect_debug(win, varargin)
  dbg_win = get_debug_window_from_non_debug_window( win );
  if ( ~isempty(dbg_win) )
    % Screen('FillRect', windowPtr [,color] [,rect] )
    varargin{2} = remap_rect_for_debug_window( win, dbg_win, varargin{2} );
    Screen( 'FrameRect', dbg_win.WindowHandle, varargin{:} );
  end
end

function frame_rect(win, varargin)  
  Screen( 'FrameRect', win.WindowHandle, varargin{:} );
  frame_rect_debug( win, varargin{:} );
end

function maybe_draw_gaze_cursors()
  if (draw_m2_eye_cue)
    fill_oval( win_m1, [255, 0, 255], centered_rect(get_m2_position(), 50) );
  end

  if ( draw_m1_gaze )
    fill_oval( win_m1, [255, 0, 255], centered_rect(get_m1_position(), 50) );
  end
  if ( draw_m2_gaze )
    fill_oval( win_m2, [255, 0, 255], centered_rect(get_m2_position(), 50) );
  end
  if ( draw_m2_eye_roi )
    fill_oval( win_m1, [255, 255, 255], m2_eye_roi );
  end

  curr_center_y = prefer_center_y;
  curr_pref = prefer_relative_sizes;

  prefer_center_y = false;
  m1_p = get_m1_position();
  m1_p(2) = m1_p(2) + get_m1_y_shift();
  m2_p = get_m2_position();
  m2_p(2) = m2_p(2) + get_m2_y_shift();
  fill_oval_debug( win_m1, [255, 0, 255], centered_rect(m1_p, 50) );
  fill_oval_debug( win_m2, [255, 0, 255], centered_rect(m2_p, 50) );

  if ( ~isempty(m2_eye_roi) )
    prefer_relative_sizes = true;
    draw_roi = m2_eye_roi;
    draw_roi([2, 4]) = m2_eye_roi([2, 4]) + get_m1_y_shift();
    frame_rect_debug( win_m1, [255, 255, 255], draw_roi );
    prefer_relative_sizes = curr_pref;
  end

  prefer_center_y = curr_center_y;
end

function r = wrap_draw(fs,maybeDrawWin1,maybeDrawWin2)
  function do_draw()
%     can_draw = win_m1.CanDrawInto && win_m2.CanDrawInto;
    can_draw = true;
    
    if ( can_draw )
      if ( isa(fs, 'function_handle') )
        fs();
      else
        assert( iscell(fs) );
        for i = 1:numel(fs)
          fs{i}();
        end
      end
    end
    if maybeDrawWin1
      flip( win_m1, true );
    end
    if maybeDrawWin2
      flip( win_m2, true );
    end
    if ( ~isempty(win_debug_m1) )
      flip( win_debug_m1, false );
    end
    if ( ~isempty(win_debug_m2) )
      flip( win_debug_m2, false );
    end
  end
  r = @do_draw;
end

function draw_error(show_m1, show_m2)
  if ( nargin < 2 )
    show_m2 = true;
  end
  if ( nargin < 1 )
    show_m1 = true;
  end
%   fill_rect( win_m1, [255, 255, 0], m1_centered_rect_screen(error_square_size_m1) );
%   fill_rect( win_m2, [255, 255, 0], m2_centered_rect_screen(error_square_size_m2) );
  if ( show_m1 )
    fill_rect( win_m1, [0, 255, 0], m1_centered_rect_screen(error_square_size_m1) );
  end
  if ( show_m2 && (block_type ~= 7))
    fill_rect( win_m2, [0, 255, 0], m2_centered_rect_screen(error_square_size_m2) );
  end
end

function draw_fixation_crosses()

  draw_texture( win_m1, cross_im, m1_centered_rect_screen(fix_cross_size_m1) );
  
  if block_type ~= 7
    draw_texture( win_m2, cross_im, m2_centered_rect_screen(fix_cross_size_m2) );
  end
end


%{ 
  lifecycle
%}

function local_update()
  update( task_interface );

  % -----------------------------------------------------------------------
  % reward keys
  timers = reward_key_timers.Value;
  for i = 1:numel(timers)
    if ( ptb.util.is_key_down(timers(i).key) && ...
        (isnan(timers(i).timer) || toc(timers(i).timer) > 0.5) )
      deliver_reward( task_interface, timers(i).channel, dur_key );
      timers(i).timer = tic;
    end
  end
  reward_key_timers.Value = timers;
  % -----------------------------------------------------------------------
end

function local_shutdown()
  fprintf( '\n\n\n\n Shutting down ...' );

  task_interface.finish();
  delete( task_interface );
  close( win_m1 );
  close( win_m2 );
  
  fprintf( ' Done.' );
end

function rs = rect_pad(rs, target_padding)
  if ( iscell(rs) )
    rs = cellfun( @(r) do_pad(r, target_padding), rs, 'un', 0 );
  else
    rs = do_pad( rs, target_padding );
  end

  function r = do_pad(r, target_padding)
    if ( numel(target_padding) == 1 )
      r([1, 2]) = r([1, 2]) - target_padding * 0.5;
      r([3, 4]) = r([3, 4]) + target_padding * 0.5;
    else
      r([1, 2]) = r([1, 2]) - target_padding(1) * 0.5;
      r([3, 4]) = r([3, 4]) + target_padding(2) * 0.5;
    end
  end
end

function r = centered_rect_maybe_remap(win_rect, size, do_remap)
  if ( nargin < 3 )
    do_remap = false;
  end

  win_center = [ mean(win_rect([1, 3])), mean(win_rect([2, 4])) ];

  if do_remap && enable_remap
    win_center = center_remap_m1;
  elseif enable_remap
    win_center = center_screen_m1;
  end
  
  lx = mean( [win_center(1), win_rect(1)] ) - lr_eccen;  
  r = centered_rect( [lx, win_center(2)], size );
end

function r = centered_rect_remap(win_rect, size)
  r = centered_rect_maybe_remap( win_rect, size, true );
end

function rs = lr_rects_remap(win_rect, size)
  win_center = [ mean(win_rect([1, 3])), mean(win_rect([2, 4])) ];

  if enable_remap
    win_center = center_remap_m1;
  end
  
  lx = mean( [win_center(1), win_rect(1)] ) - lr_eccen;
  rx = mean( [win_center(1), win_rect(3)] ) + lr_eccen;
  
  rs = { ...
      centered_rect([lx, win_center(2)], size) ...
    , centered_rect([rx, win_center(2)], size) ...
  };
end

function rs = lr_rects(win_rect, size)
  win_center = [ mean(win_rect([1, 3])), mean(win_rect([2, 4])) ];

  if enable_remap
    win_center = center_screen_m1;
  end
  
  lx = mean( [win_center(1), win_rect(1)] ) - lr_eccen;
  rx = mean( [win_center(1), win_rect(3)] ) + lr_eccen;
  
  rs = { ...
      centered_rect([lx, win_center(2)], size) ...
    , centered_rect([rx, win_center(2)], size) ...
  };

end

end

function r = centered_rect(xy, size)
  if ( numel(size) == 2 )
    w = size(1);
    h = size(2);
  else
    w = size(1);
    h = size(1);
  end
  x0 = xy(1) - w * 0.5;
  y0 = xy(2) - h * 0.5;
  r = [ x0, y0, x0 + w, y0 + h ];
end

function r = invalid_rect()
  r = nan( 1, 4 );
end

function tf = rect_in_bounds(r, x, y)
  tf = x >= r(1) && x <= r(3) && y >= r(2) && y <= r(4);
end

function [sizex,sizey] = visangle2stimsize(visanglex,visangley,totdist,screenwidth,screenres)
  if nargin < 3
      % mm
  %     distscreenmirror=823;
  %     distmirroreyes=90;
      totdist=500;% mm
      screenwidth=338.66666667;%mm
      % pixels
      screenres=1280;% pixel
  end
  
  visang_rad = 2 * atan(screenwidth/2/totdist);
  visang_deg = visang_rad * (180/pi);
  pix_pervisang = screenres / visang_deg;
  sizex = visanglex * pix_pervisang;
%   sizex = round(visanglex * pix_pervisang);
  if nargin > 1
    sizey = visangley * pix_pervisang;
%       sizey = round(visangley * pix_pervisang);
  end
end
