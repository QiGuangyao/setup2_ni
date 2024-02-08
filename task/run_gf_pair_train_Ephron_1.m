function run_gf_pair_train_Ephron_1()

cd 'C:\Users\setup2\source\setup2_ni\deps\network-events\Resources\Matlab';

m2_eye_roi = [];

try
% load the latest far plane calibrations
[m1_calib, m2_calib] = get_latest_far_plane_calibrations( dsp3.datedir );

% eye roi target width and height padding
m2_eye_roi_padding_x = 0;
m2_eye_roi_padding_y = 100;
m2_eye_roi = get_eye_roi_from_calibration_file( ...
  m1_calib, m2_eye_roi_padding_x, m2_eye_roi_padding_y );
m2_eye_roi = get_face_roi_from_calibration_file( m1_calib, 0, 0 );
fprintf( 'm2 eye roi: %d %d %d %d', m2_eye_roi );
% m2_face_roi = get_face_roi_from_calibration_file( m1_calib, 0, 0 );

catch roi_err
  warning( roi_err.message );
end

% need parpool for async video interface. the pool should be
% initialized before the call to parfeval(), since it usually takes a task inter
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
max_num_trials = 100;

draw_m2_eye_roi = false;
draw_m1_gaze = false;
draw_m2_gaze = false;
draw_m2_eye_cue = false;
always_draw_spatial_rule_outline = false;
enable_remap = true;
verbose = false;

%{
  timing parameters
%}
timing = struct();
%%% stages of the task
% 1 fixation with block rule
enbale_fixation_with_block_rule = true;
timing.initial_fixation_duration_m1 = 0;
timing.initial_fixation_duration_m2 = 0.5;
timing.initial_fixation_state_duration = 1.5;

timing.initial_reward_m1 = 0;
timing.initial_reward_m2 = 0;
timing.init_reward_m1_m2 = 0.0;

% 2 spatial rule
% if always_draw_spatial_rule_outline
%   enable_spatial_rule = false; 
% else
%   enable_spatial_rule = true; 
% end
enable_spatial_rule = false;
timing.spatial_rule_fixation_duration = 0.15;
timing.spatial_rule_state_duration = 0.50;
timing.spatial_rule_reward_m1 = 0.2;
timing.spatial_rule_reward_m2 = 0.2;
timing.spatial_rule_reward_m1_m2 = 0.4;


% 3 gaze_delay
enable_gaze_triggered_delay = false;
timing.gaze_triggered_delay = 1;
timing.gaze_delay_reward_m1 = 0.2;
timing.gaze_delay_reward_m2 = 0.2;
timing.gaze_delay_reward_m1_m2 = 0.4;
timing.gaze_delay_fixation_time = 0.4;


% 4 spatial cue
enable_spatial_cue = true;
timing.spatial_cue_state_duration = 1.5;
timing.spatial_cue_state_chooser_duration = 0.8;
timing.spatial_cue_reward_m1 = 0;
timing.spatial_cue_reward_m2 = 0.8;
timing.spatial_cue_reward_m1_m2 = 0;


% 5 fixation_delay
enable_fix_delay = false;
timing.fixation_delay_duration = 0.2;
timing.fixation_delay_state_duration = 1;
timing.fixation_delay_reward_m1 = 0.2;
timing.fixation_delay_reward_m2 = 0.2;
timing.fixation_delay_reward_m1_m2 = 0.4;


% 6 actor response
enable_actor_response = false;
timing.actor_response_state_duration = 3;
timing.actor_response_state_chooser_duration = 0.1;


% 7 feedback & reward
enable_response_feedback = false;
timing.iti_duration = 1.2;
timing.error_duration = 1.4; % timeout in case of failure to fixate
timing.feedback_duration = 1;
timing.waitSecs = 0.05;


% how long m1 and m2 can be overlapping in their target bounds before state
% exits
timing.overlap_duration_to_exit = nan;

%{
name of monkeys
%}
name_of_m1 ='M1_lynch';% 'lynch';%'M1_simu';
name_of_m2 ='M2_Ephron';% 'Hitch';

%{
  stimuli parameters
%}
fix_cross_size = 100; % px
fix_target_size = 100; % px
fix_circular_size = 100;
error_square_size = 100;
lr_eccen = 0; % px amount to shift left and right targets towards screen edges

% add +/- target_padding
target_padding = 120;
cross_padding = 100;
circular_padding = 50;

% sptial rule width
spatial_rule_width = 8;

%{
  reward parameters
%}

dur_key = 0.1;

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
  win_m1 = open_window( 'screen_index', 1, 'screen_rect', [] );% 1 for M1 
  win_m2 = open_window( 'screen_index', 2, 'screen_rect', [] );% 3 for M2
else
  win_m1 = open_window( 'screen_index', 4, 'screen_rect', [0, 0, 400, 400] );
  win_m2 = open_window( 'screen_index', 4, 'screen_rect', [400, 0, 800, 400] );
end

%{
  remap target and stimuli
%}
screen_height = 8.3;% cm
monitor_height = 27.3;% cm
if enable_remap
%   prompt = {'Enter left screen height (cm):'};
%   dlg_title = 'Input';
%   num_lines = 1;
%   defaultans = {'0'};
%   screen_height = str2double(cell2mat(inputdlg(prompt,dlg_title,num_lines,defaultans)));
  y_axis_screen = screen_height/(2*27.3);%0.25;%
  y_axis_remap = (27.3-(screen_height/2-2.2))/27.3;%x/(2*27.3);%0.25;%
  
  if screen_height == 0
    y_axis_screen = 0.5;
    y_axis_remap = 0.5;
  end
  center_screen_m1 = [0.5*win_m1.Width,y_axis_screen*win_m1.Height];
  center_screen_m2 = [0.5*win_m2.Width,y_axis_screen*win_m2.Height];
  center_remap_m1 = [0.5*win_m1.Width,y_axis_remap*win_m1.Height];
  center_remap_m2 = [0.5*win_m2.Width,y_axis_remap*win_m2.Height];
end

% task interface
t0 = datetime();
task_interface = TaskInterface( t0, save_p, {win_m1, win_m2} );
initialize( task_interface );

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
task_params.screen_height = screen_height;
task_params.monitor_height = monitor_height;
task_params.center_screen_m1 = center_remap_m1;
task_params.center_screen_m1 = center_remap_m1;
task_params.fix_cross_size = fix_cross_size;
task_params.fix_target_size = fix_target_size;
task_params.fix_circular_size = fix_circular_size;
task_params.error_square_size = error_square_size;
task_params.target_padding = target_padding;
task_params.cross_padding = cross_padding;
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
task_params.enable_spatial_rule = enable_spatial_rule;
task_params.enable_spatial_cue = enable_spatial_cue;
task_params.enable_gaze_triggered_delay = enable_gaze_triggered_delay;
task_params.enable_fix_delay = enable_fix_delay;
task_params.enable_actor_response = enable_actor_response;
task_params.enable_response_feedback = enable_response_feedback;
task_params.enable_remap = enable_remap;
task_params.verbose = verbose;
task_params.m1 = name_of_m1;
task_params.m2 = name_of_m2;

if ( bypass_trial_data )
  trial_data = [];
else
  trial_data = TaskData( ...
    save_p, 'task_data.mat' ...
    , task_interface.video_interface ...
    , task_interface.matlab_time ...
    , task_params ...
  );
end

% @NOTE: register trial data with task interface
task_interface.task_data = trial_data;

% task
%
% 
cross_im = ptb.Image( win_m1, imread(fullfile(proj_p_image, 'images/cross.jpg')));
% rotated_cross_im = ptb.Image( win_m1, imread(fullfile(proj_p, 'images/rotated_cross.jpg')));

% rewarded (correct) target
% for Ephron
targ1_im_m2 = ptb.Image( win_m2, imread(fullfile(proj_p_image, 'images/rotated_rect.jpg')));
% targ1_im_m2 = ptb.Image( win_m2, imread(fullfile(proj_p, 'images/rect.jpg')));
% opposite target
targ2_im_m2 = ptb.Image( win_m2, imread(fullfile(proj_p_image, 'images/rect.jpg')));
% targ2_im_m2 = ptb.Image( win_m2, imread(fullfile(proj_p, 'images/rotated_rect.jpg')));
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

  trial_rec.trial_descriptor = trial_desc;
  trial_rec.gaze_triggered_delay = struct();

  %{
    debug gaze-triggered delay
  %}

  if ( 0 )
    acq = state_gaze_triggered_delay( m2_eye_roi, timing.gaze_triggered_delay, false, timing.gaze_delay_fixation_time );
    if ( ~acq )
      % actor failed to look at signaler's eyes in time
      error_timeout_state( timing.error_duration,1,1);
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


    [trial_rec.fixation_with_block_rule, acquired_m1,acquired_m2] = state_fixation_with_block_rule();
    ['m1:';'m2:']
    m1_correct = m1_correct+acquired_m1;
    m2_correct = m2_correct+acquired_m2;
    m2_correct/trial_inde
  
%     if acquired_m1
%       ['m1 initial success']
%     end
    
    if acquired_m2
      ['m2 intial success']
    end
  
    if ( (~acquired_m1) || (~acquired_m2))
      % error
      error_timeout_state( timing.error_duration,1,1, ~acquired_m1, ~acquired_m2);
      continue
    end
  
    if acquired_m1 & acquired_m2
      ['both initial success']
      WaitSecs( max(timing.initial_reward_m1, timing.initial_reward_m2) + timing.waitSecs);
      deliver_reward( task_interface, 0:1, timing.init_reward_m1_m2);
    end
  end

  %{
    spatial rule
  %}
  % select gaze trial
  trial_desc.is_gaze_trial = true; % true just for gaze trials at current stage
  is_gaze_trial = trial_desc.is_gaze_trial;
  if (enable_spatial_rule) 
    [trial_rec.spatial_rule, acquired] = state_spatial_rule( is_gaze_trial );
%     if ( ~acquired )
%       % error
%       error_timeout_state( timing.error_duration,1,1);
%       continue
%     end
  end

  if ( 0 )
    state_iti();
  end

  %{
    gaze-triggered delay
  %}

  if ( enable_gaze_triggered_delay && rand() < trial_desc.prob_gaze_triggered_delay )
    [acq, m2_fixated] = state_gaze_triggered_delay( m2_eye_roi, timing.gaze_triggered_delay, is_gaze_trial, timing.gaze_delay_fixation_time );
    trial_rec.gaze_triggered_delay.acquired = acq;

    deliver_reward( task_interface, 1, timing.gaze_delay_reward_m2* m2_fixated);
    deliver_reward( task_interface, 0, timing.gaze_delay_reward_m1* acq);

    fprintf( '\n Gaze triggered delay m1 looked: %d\n', acq );
    fprintf( '\n Gaze triggered delay m2 fixated: %d\n', m2_fixated );
    
%     if ( m2_fixated )
%       WaitSecs( timing.init_reward_m1_m2 + timing.waitSecs);
%       deliver_reward( task_interface, 1, timing.gaze_delay_reward_m2 );
%     end
% 
%     if ( acq )
%       WaitSecs( timing.init_reward_m1_m2 + timing.waitSecs);
%       deliver_reward( task_interface, 0, timing.gaze_delay_reward_m1 );
%     else
% %       % actor failed to look at signaler's eyes in time
% %       error_timeout_state( timing.error_duration,1,1);
% %       continue
%     end
  end

  %{
    spatial cue
  %}
  
  spatial_cue_choice = [];
  if ( enable_spatial_cue )
    swap_signaler_dir = trial_desc.signaler_target_dir == 1;
    
    laser_index = trial_desc.laser_index;
    swap_signaler_dir
    [trial_rec.spatial_cue, spatial_cue_choice] = ...
      state_spatial_cue( swap_signaler_dir, laser_index, is_gaze_trial);

    
    if (spatial_cue_choice==2 & swap_signaler_dir) | (spatial_cue_choice==1 & ~swap_signaler_dir)
      ['m2_target_success']
%       WaitSecs( timing.init_reward_m1_m2 + timing.waitSecs);
%       deliver_reward( task_interface, 1, 0);
      deliver_reward( task_interface, 1, timing.spatial_cue_reward_m2);
    else
      error_timeout_state( timing.error_duration,0,1 );
      continue
    end
%     if ( isempty(spatial_cue_choice))
%       % error
%       error_timeout_state( timing.error_duration );
%       continue
%     end
  end

%   swap_signaler_dir,spatial_cue_choice


%   if ( enable_spatial_cue && isempty(spatial_cue_choice) )
%     % error
%     error_timeout_state( timing.error_duration,0,1 );
%     continue
%   end

  %{
    fixation delay
  %}
  
  if ( enable_fix_delay )
    trial_rec.fixation_delay = state_fixation_delay( is_gaze_trial );
    
    if trial_rec.fixation_delay.fixation_state_m1.acquired
      ['m1_fixation_delay_success']
    end

    if trial_rec.fixation_delay.fixation_state_m2.acquired
      ['m1_fixation_delay_success']
    end

    if (~trial_rec.fixation_delay.fixation_state_m2.acquired | ~trial_rec.fixation_delay.fixation_state_m1.acquired)
      % error
      error_timeout_state( timing.error_duration, ...
        ~trial_rec.fixation_delay.fixation_state_m1.acquired, ...
        ~trial_rec.fixation_delay.fixation_state_m2.acquired );
      continue      
    end
  end
  


%   'success'
% 
%   deliver_reward( task_interface, 1, dur_m2);

  %{
    response
  %}
    
  actor_resp_choice = [];
  if ( enable_actor_response )
    [trial_rec.actor_response, actor_resp_choice] = state_actor_response( is_gaze_trial );
    fprintf( '\n\n Actor chose: %d\n\n', actor_resp_choice );
  end
  
  %{
    feedback
  %}
  
  if ( enable_actor_response & enable_response_feedback)    
    if ( 1 - actor_resp_choice == trial_desc.signaler_target_dir )
      % correct
      deliver_reward( task_interface, 0:1, [timing.initial_reward_m1, timing.initial_reward_m2] );%
    end

    state_response_feedback();
  end

  if ( verbose )
    fprintf( '\n Signaler chose: %d; Actor chose: %d\n' ...
      , spatial_cue_choice, actor_resp_choice );
  end

  %{
    iti
  %}

  state_iti();
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

function [res, acquired_m1,acquired_m2] = state_fixation_with_block_rule()
  send_message( task_interface.npxi_events, 'fixation_with_block_rule/enter' );

  loc_draw_cb = wrap_draw(...
    {@draw_fixation_crosses, @maybe_draw_gaze_cursors},1,1);

  deliver_reward_m1_cb = @() deliver_reward(task_interface, 0, timing.initial_reward_m1);
  deliver_reward_m2_cb = @() deliver_reward(task_interface, 1, timing.initial_reward_m2);

  [fs_m1, fs_m2] = joint_fixation2( ...
    @time_cb, loc_draw_cb ...
    , @() rect_pad(m1_centered_rect_remap(fix_cross_size), cross_padding), @get_m1_position ...
    , @() rect_pad(m2_centered_rect_remap(fix_cross_size), cross_padding), @get_m2_position ...
    , @local_update ...
    , timing.initial_fixation_duration_m1...
    , timing.initial_fixation_duration_m2...
    , timing.initial_fixation_state_duration ...
    , [] ...
    , 'm1_every_acq_callback', deliver_reward_m1_cb ...
    , 'm2_every_acq_callback', deliver_reward_m2_cb ...
    , 'overlap_duration_to_exit', timing.overlap_duration_to_exit ...
  );

  res.fixation_state_m1 = fs_m1;
  res.fixation_state_m2 = fs_m2;
  acquired_m1 = fs_m1.ever_acquired;
  acquired_m2 = fs_m2.ever_acquired;
  acquired = fs_m1.acquired && fs_m2.acquired;
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
    h = screen_height / monitor_height * (r(4) - r(2));
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
  , @() rect_pad(m1_centered_rect_remap(fix_cross_size), target_padding), @get_m1_position ...
  , @() rect_pad(m2_centered_rect_remap(fix_cross_size), target_padding), @get_m2_position ...
  , @local_update, timing.spatial_rule_fixation_duration, timing.spatial_rule_state_duration );

  res = struct();
  res.fixation_state_m1 = fs_m1;
  res.fixation_state_m2 = fs_m2;

  acquired = fs_m1.acquired && fs_m2.acquired;

  %%%%%%%%
  function draw_spatial_rule()
    draw_spatial_rule_outline( actor_win, is_gaze_trial );
    draw_texture( win_m1, cross_im, m1_centered_rect_screen(fix_cross_size) );
    draw_texture( win_m2, cross_im, m2_centered_rect_screen(fix_cross_size) );
  end
end

function [actor_success, signaler_fixated] = state_gaze_triggered_delay(trigger_roi, timeout, is_gaze_trial, fix_time)
  if ( isempty(trigger_roi) )
    trigger_roi = nan( 1, 4 );
  end
  actor_success = false;
  signaler_fixated = true;
  loc_draw_cb = wrap_draw({@draw, @maybe_draw_gaze_cursors},1,1);
  signaler_rect = rect_pad(...
      centered_rect(center_remap_m2, [fix_cross_size, fix_cross_size]), cross_padding);
  signaler_win = win_m2;
  actor_win = win_m1;
  t0 = tic();
  fix_state = FixationStateTracker( toc(t0) );

  while ( toc(t0) < timeout )
    local_update();
    loc_draw_cb();

    actor_pos = get_m1_position();
    signal_pos = get_m2_position();

    if ~( signal_pos(1) >= signaler_rect(1) && signal_pos(1) <= signaler_rect(3) && ...
          signal_pos(2) >= signaler_rect(2) && signal_pos(2) <= signaler_rect(4) )
      % not within fix bounds
      signaler_fixated = false;
    end

    update( fix_state, actor_pos(1), actor_pos(2), toc(t0), fix_time, trigger_roi );
    if ( fix_state.ever_acquired )
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

    draw_texture( signaler_win, cross_im, m1_centered_rect_screen(fix_cross_size) );
    if ( draw_m2_eye_roi )
      fill_rect( actor_win, [255, 255, 255], trigger_roi );
    end
  end
end

function [res, signaler_choice] = state_spatial_cue(swap_signaler_dir, laser_index, is_gaze_trial)
  send_message( task_interface.npxi_events, 'spatial_cue/enter' );

  actor_win = win_m1;
  signaler_win = win_m2;

  actor_pos = @get_m1_position;
  signaler_pos = @get_m2_position;

  loc_draw_cb = wrap_draw({@draw_spatial_cues, @maybe_draw_gaze_cursors},1,1);
  signaler_rects_cb = @() rect_pad(lr_rects_remap(get(signaler_win.Rect), [fix_target_size, fix_target_size]), target_padding);
  actor_rects_cb = @() rect_pad(centered_rect(center_remap_m1, [fix_target_size, fix_target_size]), target_padding);
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
%   while 1
%     if (spatial_cue_choice==2 & swap_signaler_dir) | (spatial_cue_choice==1 & ~swap_signaler_dir)
%       break
%     end
%   end

  function do_deliver_reward_m2()
%     WaitSecs( 0.3 );
%     deliver_reward( task_interface, 1, 0 );
    if (spatial_cue_choice==2 & swap_signaler_dir) | (spatial_cue_choice==1 & ~swap_signaler_dir)
        deliver_reward( task_interface, 1, timing.spatial_cue_reward_m2 );
    end
  end

  function draw_spatial_cues()
    signaler_rects = lr_rects( get(signaler_win.Rect), [fix_target_size, fix_target_size] );% [100,100];

    if ( swap_signaler_dir )
      signaler_rects = fliplr( signaler_rects );
    end

    if ( always_draw_spatial_rule_outline )
      draw_spatial_rule_outline( actor_win, is_gaze_trial );
    end
    % target
    draw_texture(signaler_win, targ1_im_m2, signaler_rects{1})
    

    %distractor
     draw_texture(signaler_win, targ2_im_m2, signaler_rects{2})

%     fill_oval( signaler_win, [255, 255, 255], signaler_rects{1} );
%     fill_rect( signaler_win, [255, 255, 255], signaler_rects{2} );
  end
end

function res = state_fixation_delay(is_gaze_trial)
  send_message( task_interface.npxi_events, 'fixation_delay/enter' );

  abort_on_break = false;
  loc_draw_cb = wrap_draw(...
    {@do_draw, @maybe_draw_gaze_cursors},1,1);
  [fs_m1, fs_m2] = joint_fixation2( ...
    @time_cb, loc_draw_cb ...
    , @() rect_pad(m1_centered_rect_remap(fix_cross_size), cross_padding), @get_m1_position ...
    , @() rect_pad(m2_centered_rect_remap(fix_cross_size), cross_padding), @get_m2_position ...
    , @local_update ...
    , timing.fixation_delay_duration...
    , timing.fixation_delay_duration...
    , timing.fixation_delay_state_duration ...
    , abort_on_break ...
    , 'm1_every_acq_callback', @deliver_reward_m1_cb ...
    , 'm2_every_acq_callback', @deliver_reward_m2_cb ...
    , 'overlap_duration_to_exit', timing.overlap_duration_to_exit ...
  );
  
  res = struct();
  res.fixation_state_m1 = fs_m1;
  res.fixation_state_m2 = fs_m2;
  acquired_m1 = fs_m1.ever_acquired;
  acquired_m2 = fs_m2.ever_acquired;
  acquired = fs_m1.acquired && fs_m2.acquired;

  function deliver_reward_m1_cb()
%     WaitSecs( 0.3 );
    deliver_reward(task_interface, 0, timing.fixation_delay_reward_m1);
  end

  function deliver_reward_m2_cb()
%     WaitSecs( 0.3 );  
    deliver_reward(task_interface, 1, timing.fixation_delay_reward_m2);
  end

  function do_draw()
    draw_fixation_crosses();
    if ( always_draw_spatial_rule_outline )
      draw_spatial_rule_outline( win_m1, is_gaze_trial );
    end
  end

%   [fs_m1, fs_m2] = static_fixation2( ...
%     @time_cb, loc_draw_cb ...
%     , @() rect_pad(centered_rect(center_remap_m1,[100, 100]), target_padding), @get_m1_position ...
%     , @() rect_pad(centered_rect(center_remap_m2, [100, 100]), target_padding), @get_m2_position ...
%     , @local_update, timing.fixation_delay_duration ...
%     , timing.fixation_delay_duration, abort_on_break );
% 
% 
% %   [fs_m1, fs_m2] = static_fixation2( ...
% %     @time_cb, loc_draw_cb ...
% %     , @() centered_rect(win_m1.Center, [100, 100]), @get_m1_position ...
% %     , @() centered_rect(win_m2.Center, [100, 100]), @get_m2_position ...
% %     , @local_update, timing.fixation_delay_duration ...
% %     , timing.fixation_delay_duration, abort_on_break );
% 
%   res = struct();
%   res.fixation_state_m1 = fs_m1;
%   res.fixation_state_m2 = fs_m2;
end

function [res, actor_resp_choice] = state_actor_response(is_gaze_trial)
  send_message( task_interface.npxi_events, 'actor_response/enter' );

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
  

  [signaler_choice, actor_fixation] = state_choice(...
      @time_cb, @local_update, loc_draw_cb ...
    , chooser_pos, fixator_pos ...
    , chooser_rects_cb, fixator_rects_cb ...
    , chooser_choice_time, state_time, state_time ...
  );

  res = struct();
  res.signaler_choice = signaler_choice;
  res.actor_fixation = actor_fixation;

  actor_resp_choice = signaler_choice.ChoiceIndex - 1;

  function draw_response()
    actor_rects = lr_rects( get(chooser_win.Rect), [fix_circular_size, fix_circular_size] );

    if ( always_draw_spatial_rule_outline )
      draw_spatial_rule_outline( chooser_win, is_gaze_trial );
    end

    fill_oval( chooser_win, [255, 255, 255], actor_rects{1} );
    fill_oval( chooser_win, [255, 255, 255], actor_rects{2} );
  end
end

function state_response_feedback()
  send_message( task_interface.npxi_events, 'response_feedback/enter' );

  static_fixation2( ...
    @time_cb, wrap_draw({@maybe_draw_gaze_cursors},1,1) ...
  , @() rect_pad(m1_centered_rect_remap(fix_cross_size), target_padding), @get_m1_position ...
  , @() rect_pad(m2_centered_rect_remap(fix_cross_size), target_padding), @get_m2_position ...
  , @local_update, timing.feedback_duration, timing.feedback_duration );
end

function state_iti()
  send_message( task_interface.npxi_events, 'iti/enter' );

  static_fixation2( ...
    @time_cb, wrap_draw({@maybe_draw_gaze_cursors},1,1) ...
  , @() rect_pad(m1_centered_rect_remap(fix_cross_size), target_padding), @get_m1_position ...
  , @() rect_pad(m2_centered_rect_remap(fix_cross_size), target_padding), @get_m2_position ...
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


function draw_texture(win, im, rect)
  Screen( 'DrawTexture', win.WindowHandle, im.TextureHandle, [], rect );
end

function fill_rect(win, varargin)
  Screen( 'FillRect', win.WindowHandle, varargin{:} );
end

function fill_oval(win, varargin)
  Screen( 'FillOval', win.WindowHandle, varargin{:} );
end

function frame_rect(win, varargin)  
  Screen( 'FrameRect', win.WindowHandle, varargin{:} );
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
%   fill_rect( win_m1, [255, 255, 0], m1_centered_rect_screen(error_square_size) );
%   fill_rect( win_m2, [255, 255, 0], m2_centered_rect_screen(error_square_size) );
  if ( show_m1 )
    fill_rect( win_m1, [0, 255, 0], m1_centered_rect_screen(error_square_size) );
  end
  if ( show_m2 )
    fill_rect( win_m2, [0, 255, 0], m2_centered_rect_screen(error_square_size) );
  end
end

function draw_fixation_crosses()

  draw_texture( win_m1, cross_im, m1_centered_rect_screen(fix_cross_size) );
  draw_texture( win_m2, cross_im, m2_centered_rect_screen(fix_cross_size) );
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
      r([1, 2]) = r([1, 2]) - target_padding;
      r([3, 4]) = r([3, 4]) + target_padding;
    else
      r([1, 2]) = r([1, 2]) - target_padding(1);
      r([3, 4]) = r([3, 4]) + target_padding(2);
    end
  end
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