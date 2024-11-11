function run_gf_pair_train_L_E_stage2_6()

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
useEyeROI = false;
m2_eye_roi_padding_x = 100;
m2_eye_roi_padding_y = 100;
m2_face_roi_padding_x = 100;
m2_face_roi_padding_y = 100;
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
proj_p = 'D:\tempData';

bypass_trial_data = false ;    
save_data = true;
full_screens = true;
max_num_trials = 30
;
rng("shuffle")
draw_m2_eye_roi = false;
draw_m1_gaze = false;
draw_m2_gaze = false;
draw_m2_eye_cue = false;
always_draw_spatial_rule_outline = true;
enable_remap = true;
verbose = false;
%{
  timing parameters
%}
timing = struct();
%%% stages of the task
% 1 fixation with block rule
enbale_fixation_with_block_rule = true;
timing.initial_fixation_duration_m1 = 0.05;
timing.initial_fixation_duration_m2 = 0.0;
timing.initial_fixation_state_duration = 2;
timing.initial_reward_m1 = 0.00;
timing.initial_reward_m2 = 0.00;
timing.init_reward_m1_m2 = 0.00;

% 2 gaze_triggered_actor_choice with actor response
enable_gaze_triggered_actor_choice = true;
gaze_triggered_actor_choice_break_upon_m2_wrong_choice = true;

% m2 state time
timing.gaze_triggered_actor_choice_m2_choice_duration = 1.5; % @TODO


timing.enable_gaze_triggered_actor_choice_time_m2 = 0.2; % @TODO
timing.enable_gaze_triggered_actor_choice_m2_timeout_duration = 0.2;  % @TODO
timing.enable_gaze_triggered_actor_choice_reward_m2 = 0.2; % @TODO


% m1 state time
timing.gaze_triggered_actor_choice_m1_remaining_time =1;

timing.enable_gaze_triggered_actor_choice_time_m1 = 0.05; % @TODO
timing.enable_gaze_triggered_actor_maintain_time_m1 = 0.05; % @TODO
timing.enable_gaze_triggered_actor_choice_reward_m1 = 0.75; % @TODO
timing.enable_gaze_triggered_actor_choice_m1_face_fix_time = 0.05;
timing.enable_gaze_triggered_actor_choice_break_on_m1_first_choice = true;
timing.gaze_triggered_actor_choice_m1_feedback_duration = 1;

% make the m1'gaze to face time longer and variable
timing.enable_gaze_triggered_actor_choice_m1_face_fix_time_low_bound = 0.2;
timing.enable_gaze_triggered_actor_choice_m1_face_fix_time_up_bound = 0.3;

% make the m1 wait randomly for showing its targets
timing.m1_wait_time = 0;
timing.m1_wait_time_low_bound = 0.2;
timing.m1_wait_time_up_bound = 0.3;

% generate a random number between [a,b]:
% r = a + (b-a)*rand();

% 3 feedback & reward
enable_response_feedback = true;
timing.iti_duration = 1.5;
timing.error_duration = 1.5; % timeout in case of failure to fixate
timing.feedback_duration = 1;
timing.waitSecs = 0.05;


% sound 
% note: media player: paly wn, 10 
% system: 50

% Load audio data from a file
[y, Fs] = audioread('C:/Users/setup2/source/setup2_ni/deps/network-events/Resources/Matlab/lowSound500hz.wav');

% Create an audioplayer object
player = audioplayer(y, Fs);

% gaze delay block

gaze_delay_block = 8;
if gaze_delay_block == 1
  enable_gaze_triggered_delay = true;
  enable_spatial_cue = true;
  enable_fix_delay = false;
  enable_actor_response = false;
elseif gaze_delay_block==2
  enable_gaze_triggered_delay = false;
  enable_spatial_cue = true;
  enable_fix_delay = false;
  enable_actor_response = true;
elseif gaze_delay_block == 3
  enable_gaze_triggered_actor_choice = true;
  enable_gaze_triggered_delay = false;
  enable_spatial_cue = false;
  enable_fix_delay = false;
  enable_actor_response = false;
elseif gaze_delay_block ==7
  enable_gaze_triggered_actor_choice = false;
  enable_gaze_triggered_delay = false;
  enable_spatial_cue = true;
  enable_fix_delay = false;
  enable_actor_response = true;
elseif gaze_delay_block ==8
  enable_gaze_triggered_actor_choice = true;

end

% how long m1 and m2 can be overlapping in their target bounds before state
% exits
timing.overlap_duration_to_exit = nan;

%{
name of monkeys
%}
name_of_m1 ='M1_lynch';% 'lynch';%'M1_simu';
name_of_m2 ='M2_ephron';% 'Hitch';
%{
  stimuli parameters
%}

%{
  stimuli parameters
%}

fix_cross_visu_angl =6;%deg
visanglex = fix_cross_visu_angl;
visangley = fix_cross_visu_angl;

totdist_m1 = 450;%mm
totdist_m2 = 515;%mm
screen_height_left = 8.5;% cm after monitor down 



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
padding_angl = 5;
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

dur_key = 0.05;

%{
  init
%}
save_ident = strrep( datestr(now), ':', '_' );
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
    y_axis_screen = 0.5;
    y_axis_remap = 0.5;
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
trial_generator = MyTrialGenerator( trial_number );

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

task_params.fix_target_size_m1 = fix_target_size_m1;
task_params.fix_target_size_m2 = fix_target_size_m2;
task_params.fix_circular_size = fix_circular_size;
task_params.error_square_size_m1 = error_square_size_m1;
task_params.error_square_size_m2 = error_square_size_m2;
task_params.padding_angl = padding_angl;
task_params.target_padding_m1 = target_padding_m1;
task_params.target_padding_m2 = target_padding_m2;
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
task_params.always_draw_spatial_rule_outline = always_draw_spatial_rule_outline;
task_params.enbale_fixation_with_block_rule = enbale_fixation_with_block_rule;
% task_params.enable_spatial_rule = enable_spatial_rule;
% task_params.enable_spatial_cue = enable_spatial_cue;
% task_params.enable_gaze_triggered_delay = enable_gaze_triggered_delay;
% task_params.enable_fix_delay = enable_fix_delay;
% task_params.enable_actor_response = enable_actor_response;
task_params.enable_gaze_triggered_actor_choice = enable_gaze_triggered_actor_choice;
task_params.break_on_m1_first_choice = timing.enable_gaze_triggered_actor_choice_break_on_m1_first_choice;

task_params.enable_response_feedback = enable_response_feedback;
task_params.enable_remap = enable_remap;
task_params.verbose = verbose;
task_params.m1 = name_of_m1;
task_params.m2 = name_of_m2;
task_params.m2_eye_roi = m2_eye_roi;
task_params.m2_eye_roi_real = m2_eye_roi_real;
task_params.gaze_delay_block = gaze_delay_block;
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
cross_im = ptb.Image( win_m1, imread(fullfile(proj_p_image, 'images/cross.jpg')));
% rotated_cross_im = ptb.Image( win_m1, imread(fullfile(proj_p, 'images/rotated_cross.jpg')));

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
m1_correct_gaze = 0;
m1_target_correct = 0;
m2_target_correct = 0;


m1_ini_rw = timing.initial_reward_m1;
m2_ini_rw = timing.initial_reward_m2;
m1_m1_ini_rw = timing.init_reward_m1_m2;
m1_corr_curr = 0;
while ( ~ptb.util.is_esc_down() && ...
      proceed(task_interface) && ...
      (isempty(trial_data) || num_entries(trial_data) < max_num_trials) )
  drawnow;
  trial_inde = trial_inde+1
  m1_corr_curr
  if ( isempty(trial_data) )
    trial_rec = TrialRecord();
  else
    trial_rec = push( trial_data );
  end
  trial_desc = next( trial_generator );
%   if m1_corr_curr ==1 || trial_inde == 0
%     trial_inde = trial_inde+1
%     
%   else
%     trial_inde = trial_inde+0
%   end

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
  trial_rec.gaze_triggered_delay = struct();
  trial_rec.trial_start = struct();
  trial_rec.trial_start.time = time_cb();
  



  default_trigger( task_interface.sync_interface, 0 );

  %{
    debug gaze-triggered delay
  %}

  if ( 0 )
    acq = state_gaze_triggered_delay( m2_eye_roi, timing.gaze_triggered_delay, false, timing.gaze_delay_fixation_time );
    if ( ~acq )
      % actor failed to look at signaler's eyes in time
      error_timeout_state( timing.error_duration,1,1);
      state_iti();
      continue
%     else
%       state_iti();
%       continue
    end
  end

  %{
    fixation with block rule
  %}
  
  if enbale_fixation_with_block_rule
    [trial_rec.fixation_with_block_rule, acquired_m1] = state_fixation_with_block_rule();

    ['m1 initial:']
    m1_correct = m1_correct+acquired_m1;
    m1_correct/trial_inde
  
    if acquired_m1
      ['m1 initial success']
    end
    
  
    if (~acquired_m1)
% %     if ((~acquired_m2))
%       % error
% %       tic
      error_timeout_state( timing.error_duration,1,0, ~(acquired_m1), false);
      state_iti();
% %       toc
      continue
%     end
%     if (~acquired_m1)
%       error_timeout_state( timing.error_duration,1,1, ~acquired_m1, ~acquired_m2);
    end
  end

%   pause(player)
  %{
    spatial rule
  %}

  is_gaze_trial = trial_desc.is_gaze_trial;

  if ( 0 )
    state_iti();
  end
  swap_signaler_dir = trial_desc.signaler_target_dir == 1;

 if ( enable_gaze_triggered_actor_choice )
    
    [res, m1_ever_chose, m1_ever_chose_maintain, m2_ever_chose,was_m1_correct,was_m1_maintain_correct,was_m2_correct] = state_gaze_triggered_actor_choice();
    trial_rec.gaze_triggered_actor_response = res;
    
    ['m1 target:';'m2 target:']
    was_m1_correct = sum(was_m1_correct);
    was_m1_maintain_correct = sum(was_m1_maintain_correct);
    if was_m1_correct
      m1_target_correct = m1_target_correct+1;
      m1_corr_curr = 1;
    else
      m1_corr_curr = 0;
    end

    if was_m2_correct
      m2_target_correct = m2_target_correct+1;
    end
%     m2_target_correct = m2_target_correct+was_m2_correct;
    m1_target_correct/trial_inde
    m2_target_correct/trial_inde

    if ( ~m1_ever_chose || ~m2_ever_chose || ~was_m1_correct || ~ was_m2_correct|| ~ m1_ever_chose_maintain|| ~was_m1_maintain_correct)
      % error
      if was_m2_correct 
         error_timeout_state( timing.error_duration,~was_m1_correct,0 );
      else
         error_timeout_state( timing.error_duration,~was_m1_correct,~was_m2_correct );
      end
%         error_timeout_state( timing.error_duration,~was_m1_correct,~was_m2_correct );
      state_iti();
      continue
    end
  end
  
  if ( verbose )
    fprintf( '\n Signaler chose: %d; Actor chose: %d\n' ...
      , spatial_cue_choice, actor_resp_choice );
  end

  %{
    iti
  %}
%   'iti: '
%   tic
  state_iti();

%   if ( 1 )
%     state_iti();
%   end
%   toc
end

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

function [res, acquired_m1] = state_fixation_with_block_rule()
  send_message( task_interface.npxi_events, 'fixation_with_block_rule/enter' );

  loc_draw_cb = wrap_draw(...
    {@draw_fixation_crosses, @maybe_draw_gaze_cursors},1,0);
%   loc_draw_cb = @do_draw;

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
    deliver_reward(task_interface, 1, timing.initial_reward_m2);
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

function [res, acquired] = state_spatial_rule(is_gaze_trial)
  send_message( task_interface.npxi_events, 'spatial_rule/enter' );

  actor_win = win_m1;

  loc_draw_cb = wrap_draw({@draw_spatial_rule, @maybe_draw_gaze_cursors},1,1);
  [fs_m1, fs_m2] = static_fixation2( ...
    @time_cb, loc_draw_cb ...
  , @() rect_pad(m1_centered_rect_remap(fix_cross_size_m1), target_padding_m1), @get_m1_position ...
  , @() rect_pad(m2_centered_rect_remap(fix_cross_size_m2), target_padding_m2), @get_m2_position ...
  , @local_update, timing.spatial_rule_fixation_duration, timing.spatial_rule_state_duration );

  res = struct();
  res.fixation_state_m1 = fs_m1;
  res.fixation_state_m2 = fs_m2;

  acquired = fs_m1.acquired && fs_m2.acquired;

  %%%%%%%%
  function draw_spatial_rule()
    draw_spatial_rule_outline( actor_win, is_gaze_trial );
    draw_texture( win_m1, cross_im, m1_centered_rect_screen(fix_cross_size_m1) );
    draw_texture( win_m2, cross_im, m2_centered_rect_screen(fix_cross_size_m2) );
  end
end

function [actor_success, signaler_fixated,fix_state_actor,fix_state_signaler] = state_gaze_triggered_delay(trigger_roi, timeout, is_gaze_trial, fix_time)
  if ( isempty(trigger_roi) )
    trigger_roi = nan( 1, 4 );
  end
  actor_success = false;
  signaler_fixated = true;
  loc_draw_cb = wrap_draw({@draw, @maybe_draw_gaze_cursors},1,1);
  signaler_win = win_m2;
  actor_win = win_m1;
  signaler_rects = lr_rects( get(signaler_win.Rect), [fix_target_size_m2, fix_target_size_m2] );% [100,100];
%   signaler_rect = rect_pad(...
%       centered_rect(center_remap_m2, [fix_cross_size_m2, fix_cross_size_m2]), cross_padding_m2);
  
  
%   t0 = tic();
  t0 = time_cb();
  t00 = tic();
%   fix_state = FixationStateTracker( toc(t0) );
  fix_state_actor = FixationStateTracker(t0);
  fix_state_signaler = FixationStateTracker(t0);

  while ( toc(t00) < timeout )
    local_update();
    loc_draw_cb();

    actor_pos = get_m1_position();
    signal_pos = get_m2_position();

%     if ~( signal_pos(1) >= signaler_rect(1) && signal_pos(1) <= signaler_rect(3) && ...
%           signal_pos(2) >= signaler_rect(2) && signal_pos(2) <= signaler_rect(4) )
%       % not within fix bounds
%       signaler_fixated = false;
%     end

%     update( fix_state, actor_pos(1), actor_pos(2), toc(t00), fix_time, trigger_roi );
    update( fix_state_actor, actor_pos(1), actor_pos(2), time_cb(), fix_time, trigger_roi );

%     update( fix_state_signaler, signal_pos(1), signal_pos(2), time_cb(), fix_time, trigger_roi );

    if ( fix_state_actor.ever_acquired )
      % actor looked within m2's eyes
      actor_success = true;
      break
    end

%     if ( actor_pos(1) >= trigger_roi(1) && actor_pos(1) <= trigger_roi(3) && ...
%          actor_pos(2) >= trigger_roi(2) && actor_pos(2) <= trigger_roi(4) )
%       % actor looked within m2's eyes
%       actor_success = true;
%       break
%     end
  end

  %%

  function draw()
%     draw_texture( signaler_win, cross_im, signaler_rect );
    
    if ( always_draw_spatial_rule_outline )
      draw_spatial_rule_outline( actor_win, is_gaze_trial );
    end

%     draw_texture( signaler_win, cross_im, m1_centered_rect_screen(fix_cross_size_m2) );
    if ( draw_m2_eye_roi )
      fill_rect( actor_win, [255, 255, 255], trigger_roi );
    end
  end


  function draw_spatial_cues()
    signaler_rects = lr_rects( get(signaler_win.Rect), [fix_target_size_m2, fix_target_size_m2] );% [100,100];
  
    if ( swap_signaler_dir )
      signaler_rects = fliplr( signaler_rects );
    end
  
    if ( always_draw_spatial_rule_outline )
      draw_spatial_rule_outline( actor_win, is_gaze_trial );
    end
  
    draw_texture(signaler_win, targ1_im_m2, signaler_rects{1})
    draw_texture(signaler_win, targ2_im_m2, signaler_rects{2})
  
  %     fill_oval( signaler_win, [255, 255, 255], signaler_rects{1} );
  %     fill_rect( signaler_win, [255, 255, 255], signaler_rects{2} );
  end
end

function [res, signaler_choice] = state_spatial_cue(swap_signaler_dir, laser_index, is_gaze_trial)
  send_message( task_interface.npxi_events, 'spatial_cue/enter' );

  actor_win = win_m1;
  signaler_win = win_m2;

  actor_pos = @get_m1_position;
  signaler_pos = @get_m2_position;

  loc_draw_cb = wrap_draw({@draw_spatial_cues, @maybe_draw_gaze_cursors},1,1);
  signaler_rects_cb = @() rect_pad(lr_rects_remap(get(signaler_win.Rect), [fix_target_size_m2, fix_target_size_m2]), target_padding_m2);
  actor_rects_cb = @() rect_pad(centered_rect(center_remap_m1, [fix_target_size_m1, fix_target_size_m1]), target_padding_m1);
%   actor_rects_cb = @() centered_rect(actor_win.Center, [100, 100]);

  chooser_time = timing.spatial_cue_state_chooser_duration;
  state_time = timing.spatial_cue_state_duration;
  trigger( task_interface.laser_interface, laser_index );

  [loc_signaler_choice, loc_actor_fixation] = state_choice(...
      @time_cb, @local_update, loc_draw_cb ...
    , signaler_pos, actor_pos ...
    , signaler_rects_cb, actor_rects_cb ...
    , chooser_time, state_time, state_time ...
    , 'on_chooser_choice', @do_deliver_reward_m2 ...
    );

  

  trigger( task_interface.laser_interface, laser_index );

  res = struct();
  res.signaler_choice = loc_signaler_choice;
  res.actor_fixation = loc_actor_fixation;

  signaler_choice = loc_signaler_choice.ChoiceIndex;

  function do_deliver_reward_m2()
%     WaitSecs( 0.3 );
%     if (spatial_cue_choice==2 & swap_signaler_dir) | (spatial_cue_choice==1 & ~swap_signaler_dir)
%       'test'
%       deliver_reward( task_interface, 1, timing.spatial_cue_reward_m2 );
%     end
  end

  function draw_spatial_cues()
    signaler_rects = lr_rects( get(signaler_win.Rect), [fix_target_size_m2, fix_target_size_m2] );% [100,100];

    if ( swap_signaler_dir )
      signaler_rects = fliplr( signaler_rects );
    end

    if ( always_draw_spatial_rule_outline )
      draw_spatial_rule_outline( actor_win, is_gaze_trial );
    end

    draw_texture(signaler_win, targ1_im_m2, signaler_rects{1})
    draw_texture(signaler_win, targ2_im_m2, signaler_rects{2})

%     fill_oval( signaler_win, [255, 255, 255], signaler_rects{1} );
%     fill_rect( signaler_win, [255, 255, 255], signaler_rects{2} );
  end
end

  function [res, m1_ever_chose, m1_ever_chose_maintain, m2_ever_chose,was_m1_correct,was_m1_maintain_correct,was_m2_correct] = state_gaze_triggered_actor_choice()
  %{
  - m2's targets appear, can make any number of saccades back and forth
  - m1 looks to m2's eyes to trigger m1's targets appearing, after which 
    they  can make the choice
  %}
  
  start_t = time_cb();
  
  state_duration =timing.gaze_triggered_actor_choice_m2_choice_duration;% 2.5; % @TODO
  choice_time_m1 = timing.enable_gaze_triggered_actor_choice_time_m1;%0.1; % @TODO
  maintain_time_m1 = timing.enable_gaze_triggered_actor_maintain_time_m1;%0.1; % @TODO
  choice_time_m2 = timing.enable_gaze_triggered_actor_choice_time_m2;%0.4; % @TODO
  m2_timeout_duration = timing.enable_gaze_triggered_actor_choice_m2_timeout_duration;%0.1;  % @TODO
  reward_m2 = timing.enable_gaze_triggered_actor_choice_reward_m2;%0.6; % @TODO
  reward_m1 = timing.enable_gaze_triggered_actor_choice_reward_m1;%0.6; % @TODO
  break_on_m1_first_choice =timing.enable_gaze_triggered_actor_choice_break_on_m1_first_choice; % @TODO
  fix_time = timing.enable_gaze_triggered_actor_choice_m1_face_fix_time;
  m1_remaining_time = timing.gaze_triggered_actor_choice_m1_remaining_time;
  m1_feedback_duration = timing.gaze_triggered_actor_choice_m1_feedback_duration;
  was_m1_correct = false;
  was_m2_correct = false;

  was_m1_maintain_correct = false;
  m1_ever_chose_maintain = false;

  is_m2_timeout = false;
  m2_timer = nan;
  triggered_m2_reward = false;
  
  m1_looked = false;
  m1_looked_eye = false;
  m2_ever_entered = false;
  enable_m1_targets = false;
  m1_looked_time = nan;

  use_more_than_2_targets = true;
  num_targets = 4;
    
  choice_m1 = ChoiceTracker( start_t, num_targets );
  choice_m2 = ChoiceTracker( start_t, num_targets );

  fix_state_actor = FixationStateTracker(start_t);
  fix_state_actor_eye = FixationStateTracker(start_t);


  m1_wait_time = 0.0;

  m1_ever_chose = false;
  m2_ever_chose = false;
  
  %{
  
  partition screen into N chunks, set m2's left target to one of N-1, call
  it M, then the right target is random in (M+2:N)
  
  %}

  im_m2s = {targ1_im_m2, targ2_im_m2};
  
  num_chunks = num_targets + 1;
  width_frac = 0.6;
  m1_choice_numb = 0;


  % remove center chunk (3)
  chunk_indices = setdiff( 1:num_chunks, 3);
%   chunk_indices = [1,5];
  


  m2_correct_target_index = randi( num_targets );
  m1_correct_target_index = (num_targets - m2_correct_target_index) + 1;

  if rand <0.5
    m2_correct_target_index = 1;
    m1_correct_target_index = 4;
  else
    m2_correct_target_index = 4;
    m1_correct_target_index = 1;

  end


%   m2_correct_target_index = randi( 2 );
%   m1_correct_target_index = (2 - m2_correct_target_index) + 1;



  m2_cxs = arrayfun( @(x) component_center_by_index(get(win_m2.Rect) ...
    , width_frac, x, num_chunks), chunk_indices );
  m1_cxs = arrayfun( @(x) component_center_by_index(get(win_m1.Rect) ...
    , width_frac, x, num_chunks), chunk_indices );

  im_m2s = repmat( {targ2_im_m2}, 1, numel(m2_cxs) );
  im_m2s{m2_correct_target_index} = targ1_im_m2;

  enable_m2_targets = true;
  enable_m1_targets = false;
  while ( time_cb() - start_t < state_duration )
    local_update();
    do_draw();
    
    m1_xy = get_m1_position();
    m2_xy = get_m2_position();
    
    curr_t = time_cb();
    
    % m2
    if ( is_m2_timeout )
      if ( toc(m2_timer) > m2_timeout_duration )
        is_m2_timeout = false;
        triggered_m2_reward = false;
        reset_acquired( choice_m2 );
      end
    else
      [m2_chose, m2_choice] = update( ...
        choice_m2, m2_xy(1), m2_xy(2), curr_t, choice_time_m2, m2_rects_remap() );

      if ( any_entered(choice_m2) )
        m2_ever_entered = true;
      end
      
      if ( m2_chose )
        is_m2_timeout = true;
        
        m2_timer = tic();
        m2_ever_chose = true;
        if m2_choice == 2
          m2_choice =1;
        elseif  m2_choice == 3
          m2_choice =4;
        end 
        was_m2_correct = check_is_m2_correct( m2_choice );

        if ( ~was_m2_correct && gaze_triggered_actor_choice_break_upon_m2_wrong_choice )
          break
        end

        if ( ~triggered_m2_reward && was_m2_correct )
          deliver_reward( task_interface, 1, reward_m2 );
          triggered_m2_reward = true;

        end
      end
    end
    
    % m1
    if ( ~isempty(m2_eye_roi) )
      update( fix_state_actor, m1_xy(1), m1_xy(2), time_cb(), fix_time, m2_eye_roi );
      update( fix_state_actor_eye, m1_xy(1), m1_xy(2), time_cb(), 0, m2_eye_roi_real );
    end

    if ( ~m1_looked )
      if ( m2_ever_entered && ...
          (isempty(m2_eye_roi) || rect_in_bounds(m2_eye_roi, m1_xy(1), m1_xy(2))) && ...
          (isempty(m2_eye_roi) || fix_state_actor.ever_acquired) )
        % 
        if  (rect_in_bounds(m2_eye_roi_real, m1_xy(1), m1_xy(2))) && ...
          (isempty(m2_eye_roi_real)) && (fix_state_actor_eye.ever_acquired)
          m1_looked_eye = true;
%           m1_looked_eye
        end

        WaitSecs(m1_wait_time) 
        m1_looked = true;
%         enable_m1_targets = true;
        m1_looked_time = curr_t;
        
%         if ( 1 ) %  reset state clock to give m1 more time to choose
%           start_t = time_cb();
%           state_duration = m1_remaining_time;
%         end
      end
%     else
%       % if m1 looks at m2's face, then turn off sound.
% %       pause(player)
%       [m1_chose, m1_choice] = update( ...
%         choice_m1, m1_xy(1), m1_xy(2), curr_t, choice_time_m1, m1_rects_remap() );
% 
%       was_m1_correct = check_is_m1_correct( m1_choice );
%       m1_ever_chose = m1_ever_chose || m1_chose;
% 
%       if ( m1_chose )
% %         if ( was_m1_correct )
% %           deliver_reward( task_interface, 0, reward_m1 );
% %           deliver_reward( task_interface, 1, reward_m2 );
% %         end
%         if ( break_on_m1_first_choice || was_m1_correct )
%           break
%         end
%       end
    end
  end
  start_t_m1 = time_cb();

  enable_m2_targets = false;
  if m1_looked && sum(was_m2_correct)
    enable_m1_targets = true;
  end

  while ( time_cb() - start_t_m1 < m1_remaining_time ) && m1_looked && sum(was_m2_correct)
    local_update();
    do_draw();
    
    m1_xy = get_m1_position();
    m2_xy = get_m2_position();
    
    curr_t = time_cb();
    
%     % m2
%     if ( is_m2_timeout )
%       if ( toc(m2_timer) > m2_timeout_duration )
%         is_m2_timeout = false;
%         triggered_m2_reward = false;
%         reset_acquired( choice_m2 );
%       end
%     else
%       [m2_chose, m2_choice] = update( ...
%         choice_m2, m2_xy(1), m2_xy(2), curr_t, choice_time_m2, m2_rects_remap() );
% 
%       if ( any_entered(choice_m2) )
%         m2_ever_entered = true;
%       end
      
%       if ( m2_chose )
%         is_m2_timeout = true;
%         
%         m2_timer = tic();
%         m2_ever_chose = true;
%         was_m2_correct = check_is_m2_correct( m2_choice );
% 
%         if ( ~was_m2_correct && gaze_triggered_actor_choice_break_upon_m2_wrong_choice )
%           break
%         end
% 
%         if ( ~triggered_m2_reward && was_m2_correct )
% %           deliver_reward( task_interface, 1, reward_m2 );
%           triggered_m2_reward = true;
% 
%         end
%       end
    
    % m1
%     if ( ~isempty(m2_eye_roi) )
%       update( fix_state_actor, m1_xy(1), m1_xy(2), time_cb(), fix_time, m2_eye_roi );
%       update( fix_state_actor_eye, m1_xy(1), m1_xy(2), time_cb(), 0, m2_eye_roi_real );
%     end

%     if ( ~m1_looked )
%       if ( m2_ever_entered && ...
%           (isempty(m2_eye_roi) || rect_in_bounds(m2_eye_roi, m1_xy(1), m1_xy(2))) && ...
%           (isempty(m2_eye_roi) || fix_state_actor.ever_acquired) )
%         % 
%         if  (rect_in_bounds(m2_eye_roi_real, m1_xy(1), m1_xy(2))) && ...
%           (isempty(m2_eye_roi_real)) && (fix_state_actor_eye.ever_acquired)
%           m1_looked_eye = true;
% %           m1_looked_eye
%         end
% 
%         WaitSecs(m1_wait_time) 
%         m1_looked = true;
%         enable_m1_targets = true;
%         m1_looked_time = curr_t;
%         
%         if ( 1 ) %  reset state clock to give m1 more time to choose
%           start_t = time_cb();
%           state_duration = m1_remaining_time;
%         end
%       end
%     else
      % if m1 looks at m2's face, then turn off sound.
%       pause(player)
    [m1_chose, m1_choice] = update( ...
      choice_m1, m1_xy(1), m1_xy(2), curr_t, choice_time_m1, m1_rects_remap() );
    if m1_choice == 2
      m1_choice =1;
    elseif  m1_choice == 3
      m1_choice =4;
    end 
    was_m1_correct = check_is_m1_correct( m1_choice );
    m1_ever_chose = m1_ever_chose || m1_chose;

    if ( m1_chose )
      m1_choice_numb = m1_choice_numb+1;

        if ( was_m1_correct )
          deliver_reward( task_interface, 0, reward_m1 );
          'fixation'
%           deliver_reward( task_interface, 1, reward_m2 );
        end
      if ( break_on_m1_first_choice || was_m1_correct )
        break
      end


    end
  end

%   was_m1_correct = true;
  start_t_feedback = time_cb();
  sum(was_m2_correct) 
  if sum(was_m2_correct)  && m1_looked %sum(was_m1_correct) && 
%     while ( time_cb() - start_t_feedback < m1_feedback_duration)
%       do_draw_feedback()
%       curr_t = time_cb();
%       12
%       [m1_chose_maintain, m1_choice_maintain] = update( ...
%         choice_m1, m1_xy(1), m1_xy(2), curr_t,maintain_time_m1, m1_rects_remap() );
%   
%       was_m1_maintain_correct = check_is_m1_correct( m1_choice_maintain );
%       m1_ever_chose_maintain = m1_ever_chose_maintain || m1_chose_maintain;
% %       was_m1_maintain_correct
%       if ( m1_chose_maintain )
%         if ( was_m1_maintain_correct )
%           deliver_reward( task_interface, 0, reward_m1 );
%           "maintain"
%   %         deliver_reward( task_interface, 1, reward_m2 );
%         end
%         if ( break_on_m1_first_choice || was_m1_maintain_correct )
%           break
%         end
%       end
%     end
%   else
    while ( time_cb() - start_t_feedback <m1_feedback_duration)% m1_feedback_duration)
      do_draw_feedback()
    end
  end

  res = struct();
  res.choice_m1 = choice_m1;
  res.choice_m2 = choice_m2;
  res.m1_looked_time = m1_looked_time;
  res.m1_looked_eye = m1_looked_eye;
  res.m1_looked = m1_looked;
  res.was_m1_maintain_correct = was_m1_maintain_correct;
  res.m1_ever_chose_maintain = m1_ever_chose_maintain;
  res.was_m1_correct = was_m1_correct;
  res.m1_ever_chose = m1_ever_chose;
  res.m1_correct_chunk = m1_correct_target_index;
  res.m2_correct_chunk = m2_correct_target_index;
  res.m1_choice_numb = m1_choice_numb;
  % -----

  function tf = check_is_m1_correct(m1_choice)
    if ( use_more_than_2_targets )
      tf = m1_choice == m1_correct_target_index;
    else
      tf = (m1_choice==1 & swap_signaler_dir) | (m1_choice==2 & ~swap_signaler_dir);
    end
  end

  function tf = check_is_m2_correct(m2_choice)
    if ( use_more_than_2_targets )
      tf = m2_choice == m2_correct_target_index;
    else
      tf = (m2_choice==2 & swap_signaler_dir) | (m2_choice==1 & ~swap_signaler_dir);
    end
  end
  
  function do_draw()
    if ( ~is_m2_timeout )
      signaler_rects = m2_rects();

      if ( ~use_more_than_2_targets && swap_signaler_dir )
        signaler_rects = fliplr( signaler_rects );
      end
      
      if enable_m2_targets
        for i =[1,4]%i = 1:numel(im_m2s)
          draw_texture( win_m2, im_m2s{i}, signaler_rects{i} );
        end
      end
    end
    
    if ( enable_m1_targets )
      actor_rects = m1_rects();
      for i =[1,4]% 1:numel(actor_rects)
        fill_oval( win_m1, [255, 255, 255], actor_rects{i} );
      end
    end

    maybe_draw_gaze_cursors();
    
    flip( win_m1, false );
    flip( win_m2, false );
    if ( ~isempty(win_debug_m1) )
      flip( win_debug_m1, false );
    end
    if ( ~isempty(win_debug_m2) )
      flip( win_debug_m2, false );
    end
  end
  

  function do_draw_feedback()
%     if ( ~is_m2_timeout )
%       signaler_rects = m2_rects();
% 
%       if ( ~use_more_than_2_targets && swap_signaler_dir )
%         signaler_rects = fliplr( signaler_rects );
%       end
%       if enable_m2_targets
%         for i = 1:numel(im_m2s)
%   %         if i == m2_correct_target_index
%   %           draw_texture( win_m2, im_m2s{i}, signaler_rects{i} );
%   %         else
%           draw_texture( win_m2, im_m2s{i}, signaler_rects{i} );
%   %         end
%         end
%       end
%     end
    
    if ( 1 )
      actor_rects = m1_rects();
      for i =[1,4]%i = 1:numel(actor_rects)
        if i==m1_correct_target_index
          fill_oval( win_m1, [255, 255, 0], actor_rects{i} );
        else
          fill_oval( win_m1, [255, 255, 255], actor_rects{i} );
        end
      end
    end

    maybe_draw_gaze_cursors();
    
    flip( win_m1, false );
    flip( win_m2, false );
    if ( ~isempty(win_debug_m1) )
      flip( win_debug_m1, false );
    end
    if ( ~isempty(win_debug_m2) )
      flip( win_debug_m2, false );
    end
  end

%   left_right_locs = [[1,3]]

  function [left, right] = choose_chunks(num_chunks, min_space_between_targets)
    left = randi( num_chunks - min_space_between_targets );
    right = randi( [left + min_space_between_targets, num_chunks] );
    if ( 1 )
      while ( left == 3 || right == 3 )
%       while ( left == 1 || right == 5 || left == 5 || right == 1|| left == 3 || right == 3) % for lynch, just choose inside ones.
        [left, right] = choose_chunks( num_chunks, min_space_between_targets );
      end
    end
  end
  
  function r = recenter_on_positions(r, cxs)
    assert( numel(cxs) == numel(r) );
    for i = 1:numel(cxs)
      wl = diff( r{i}([1, 3]) );
      r{i}(1) = cxs(i) - wl * 0.5;
      r{i}(3) = cxs(i) + wl * 0.5;
    end
  end

  function cx = component_center_by_index(rect, w_frac, chunk, num_chunks)
    width = rect(3) - rect(1);
    off = width * (1 - w_frac) * 0.5;
    cx = off + (chunk-1) / (num_chunks-1) * width * w_frac;
  end
  
  function [left, right] = left_right_components(rect, w_frac, left_chunk, right_chunk, num_chunks)
    left = component_center_by_index( rect, w_frac, left_chunk, num_chunks );
    right = component_center_by_index( rect, w_frac, right_chunk, num_chunks );
  end

  function r = m2_rects_remap()
    if ( use_more_than_2_targets )
      r = rect_pad( centered_rect_remap(get(win_m2.Rect), fix_circular_size), circular_padding );
      r = repmat( {r}, 1, numel(m2_cxs) );
    else
      r = rect_pad( lr_rects_remap(get(win_m2.Rect), [fix_circular_size, fix_circular_size]), circular_padding );
    end
    r = recenter_on_positions( r, m2_cxs );
  end

  function r = m1_rects_remap()
    if ( use_more_than_2_targets )
      r = rect_pad( centered_rect_remap(get(win_m1.Rect), fix_circular_size), circular_padding );
      r = repmat( {r}, 1, numel(m1_cxs) );
    else
      r = rect_pad( lr_rects_remap(get(win_m1.Rect), [fix_circular_size, fix_circular_size]), circular_padding );
    end
    r = recenter_on_positions( r, m1_cxs );
  end
  
  function r = m2_rects()
    if ( use_more_than_2_targets )
      r = centered_rect_maybe_remap( get(win_m2.Rect), fix_circular_size, false );
      r = repmat( {r}, 1, numel(m2_cxs) );
    else
      r = lr_rects( get(win_m2.Rect), [fix_circular_size, fix_circular_size] );
    end
    r = recenter_on_positions( r, m2_cxs );
  end
  
  function r = m1_rects()
    if ( use_more_than_2_targets )
      r = centered_rect_maybe_remap( get(win_m1.Rect), fix_circular_size, false );
      r = repmat( {r}, 1, numel(m1_cxs) );
    else
      r = lr_rects( get(win_m1.Rect), [fix_circular_size, fix_circular_size] );
    end
    r = recenter_on_positions( r, m1_cxs );
  end

  end


function [res, actor_resp_choice] = state_actor_response(is_gaze_trial)
  send_message( task_interface.npxi_events, 'actor_response/enter' );

  on_fixator_fixation = @() deliver_reward( task_interface, 1, timing.actor_response_reward_m2 );
  signaler_fix_time = timing.actor_response_state_signaler_duration;

  chooser_win = win_m1;
  chooser_pos = @get_m1_position;

  fixator_win = win_m2;
  fixator_pos = @get_m2_position;

  chooser_choice_time = timing.actor_response_state_chooser_duration;
  state_time = timing.actor_response_state_duration;

  loc_draw_cb = wrap_draw({@draw_response, @maybe_draw_gaze_cursors},1,1);  
  chooser_rects_cb = @() rect_pad(lr_rects_remap(get(chooser_win.Rect), [fix_circular_size, fix_circular_size]), circular_padding);

  fixator_rects_cb = @() rect_pad(centered_rect(center_remap_m1, [fix_circular_size, fix_circular_size]), circular_padding);
%   fixator_rects_cb = @() centered_rect(fixator_win.Center, [100, 100]);
  

  [actor_choice, signaler_fixation] = state_choice(...
      @time_cb, @local_update, loc_draw_cb ...
    , chooser_pos, fixator_pos ...
    , chooser_rects_cb, fixator_rects_cb ...
    , chooser_choice_time, signaler_fix_time, state_time ...
    , 'on_fixator_fixation', on_fixator_fixation ...
  );

  res = struct();
  res.actor_choice = actor_choice;
  res.signaler_fixation = signaler_fixation;

  actor_resp_choice = actor_choice.ChoiceIndex - 1;

  function draw_response()
    actor_rects = lr_rects( get(chooser_win.Rect), [fix_circular_size, fix_circular_size] );

    if ( always_draw_spatial_rule_outline )
      draw_spatial_rule_outline( chooser_win, is_gaze_trial );
    end

    fill_oval( chooser_win, [255, 255, 255], actor_rects{1} );
    fill_oval( chooser_win, [255, 255, 255], actor_rects{2} );

%     draw_texture( fixator_win, cross_im, m2_centered_rect_screen(fix_cross_size) );
  end
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
  if ( show_m2 )
    fill_rect( win_m2, [0, 255, 0], m2_centered_rect_screen(error_square_size_m2) );
  end
end

function draw_fixation_crosses()
  draw_texture( win_m1, cross_im, m1_centered_rect_screen(fix_cross_size_m1) );
%   draw_texture( win_m2, cross_im, m2_centered_rect_screen(fix_cross_size_m2) );
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
