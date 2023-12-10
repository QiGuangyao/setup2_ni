function run_gf_pair_train_copy_m1_m2_wins()

cd 'C:\Users\setup2\source\setup2_ni\deps\network-events\Resources\Matlab';

% need parpool for async video interface. the pool should be
% initialized before the call to parfeval(), since it usually takes a 
% while to start.
pool = gcp( 'nocreate' );
if ( isempty(pool) )
  parpool( 2 );
end

proj_p = fileparts( which(mfilename) );

bypass_trial_data = false;
save_data = true;
full_screens = true;
max_num_trials = 50;

draw_m1_gaze = true;
draw_m2_gaze = true;

enable_spatial_rule = false;
enable_spatial_cue = false;
enable_fix_delay = false;
enable_actor_response = false;
enable_response_feedback = true;
enable_remap = true;
verbose = true;



%{
  timing parameters
%}

timing = struct();
timing.initial_fixation_duration = 0.10;
timing.initial_fixation_state_duration = 4;
timing.spatial_rule_fixation_duration = 0.15;
timing.spatial_rule_state_duration = 0.5;
timing.spatial_cue_state_duration = 1;
timing.spatial_cue_state_chooser_duration = 0.1;
timing.actor_response_state_duration = 1;
timing.actor_response_state_chooser_duration = 0.1;
timing.fixation_delay_duration = 1;
timing.iti_duration = 0.8;
timing.error_duration = 1; % timeout in case of failure to fixate
timing.feedback_duration = 1;

%{
name of monkeys
%}
name_of_m1 = 'L';
name_of_m2 = 'H';



%{
  stimuli parameters
%}

fix_cross_size = 200; % px
fix_target_size = 100; % px
fix_circular_size = 100;
error_square_size = 80;

% add +/- target_padding
target_padding = 50;
cross_padding = 50;
circular_padding = 50;

% sptial rule width
spatial_rule_width = 8;

%{
  reward parameters
%}

reward_duration_s = 0.25;
dur_m1 = 0.25;
dur_m2 = 0.25;


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
  win_m2 = open_window( 'screen_index', 3, 'screen_rect', [] );% 3 for M2
  win_m1_copy = open_window( 'screen_index', 0, 'screen_rect', [0, 0, 800, 800] );
  win_m2_copy = open_window( 'screen_index', 0, 'screen_rect', [800, 0, 1600, 800] );
else
  win_m1 = open_window( 'screen_index', 0, 'screen_rect', [0, 0, 800, 800] );
  win_m2 = open_window( 'screen_index', 0, 'screen_rect', [800, 0, 1600, 800] );
end

%{
  remap target and stimuli
%}
screen_height = 7.5;% cm

monitor_height = 27.3;
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

% center_screen_m1,
% center_remap_m2

% task interface
%
% 
t0 = datetime();
task_interface = TaskInterface( t0, save_p, {win_m1, win_m2} );
initialize( task_interface );

% trial data
%
%

% trial_generator = DefaultTrialGenerator();
%{
generate trials
%}

trial_number = 50;
trial_generator = MyTrialGenerator( trial_number );

% any data stored as a field of this struct will be saved.
task_params = struct( 'timing', timing );
task_params.center_screen_m1 = center_screen_m1;
task_params.center_screen_m2 = center_screen_m2;
task_params.trial_generator = trial_generator;
task_params.gaze_coord_transform = task_interface.gaze_tracker.gaze_coord_transform;
task_params.screen_height = screen_height;
task_params.monitor_height = monitor_height;
task_params.reward_duration_s = reward_duration_s;
task_params.dur_m1 = dur_m1;
task_params.dur_m2 = dur_m2;

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
task_params.enable_spatial_rule = enable_spatial_rule;
task_params.enable_spatial_cue = enable_spatial_cue;


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
cross_im = ptb.Image( win_m1, imread(fullfile(proj_p, 'images/cross.jpg')));
% rotated_cross_im = ptb.Image( win_m1, imread(fullfile(proj_p, 'images/rotated_cross.jpg')));

% rewarded (correct) target
targ1_im_m2 = ptb.Image( win_m2, imread(fullfile(proj_p, 'images/rect.jpg')));
% opposite target
targ2_im_m2 = ptb.Image( win_m2, imread(fullfile(proj_p, 'images/rotated_rect.jpg')));
% m1 targets
% targ_im_m1 = ptb.Image( win_m1, imread(fullfile(proj_p, 'images/circle.jpg')));

%{
  main trial sequence
%}

err = [];

try

trial_inde = 0;
while ( ~ptb.util.is_esc_down() && ...
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

  %{
    fixation with block rule
  %}
%   [res, acquired_m1,acquired_m2]
  [trial_rec.fixation_with_block_rule, acquired_m1,acquired_m2] = state_fixation_with_block_rule();
%   [trial_rec.fixation_with_block_rule, acquired] = state_fixation_with_block_rule();
  
%   if ( ~acquired )
%     % error
%     error_timeout_state( timing.error_duration,1,1);
%     continue
%   end

  if ( (~acquired_m1) &  (~acquired_m2))
    % error
    error_timeout_state( timing.error_duration,1,1);
    continue
  end

  %{
    spatial rule
  %}
  
  is_gaze_trial = trial_desc.is_gaze_trial;
  if (enable_spatial_rule) 
    [trial_rec.spatial_rule, acquired] = state_spatial_rule( is_gaze_trial );
    if ( ~acquired )
      % error
      error_timeout_state( timing.error_duration,1,1);
      continue
    end
  end

  if ( 1 )  % bridge reward

    deliver_reward( task_interface, 0, dur_m1 );
    deliver_reward( task_interface, 1, dur_m2 );
%     deliver_reward( task_interface, 1, dur_m2 );
%     deliver_reward( task_interface, 0:1, reward_duration_s );
%     deliver_reward( task_interface, 0:1, [dur_m1, dur_m2] );
  end

  if ( 0 )
    state_iti();
  end

  %{
    spatial cue
  %}
  
  spatial_cue_choice = [];
  if ( enable_spatial_cue )
    swap_signaler_dir = trial_desc.signaler_target_dir == 1;
    laser_index = trial_desc.laser_index;
    [trial_rec.spatial_cue, spatial_cue_choice] = ...
      state_spatial_cue( swap_signaler_dir, laser_index );
%     if ( isempty(spatial_cue_choice))
%       % error
%       error_timeout_state( timing.error_duration );
%       continue
%     end
  end
  
  if ( enable_spatial_cue && isempty(spatial_cue_choice) )
    % error
    error_timeout_state( timing.error_duration,0,1 );
    continue
  end

  %{
    fixation delay
  %}
  
  if ( enable_fix_delay )
    trial_rec.fixation_delay = state_fixation_delay();

    if (~trial_rec.fixation_delay.fixation_state_m2.acquired)
      % error
      error_timeout_state( timing.error_duration,0,1 );
      continue
    end
  end
  
  %{
    response
  %}
    
  actor_resp_choice = [];
  if ( enable_actor_response )
    [trial_rec.actor_response, actor_resp_choice] = state_actor_response();
  end
  
  %{
    feedback
  %}
  
  if ( enable_response_feedback )    
    if ( actor_resp_choice - 1 == trial_desc.signaler_target_dir )
      % correct
%       deliver_reward( task_interface, 0, reward_duration_s );% 
%       deliver_reward( task_interface,1, dur_m2 );%
%       deliver_reward( task_interface,0, dur_m1 );%
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

  [fs_m1, fs_m2] = static_fixation2( ...
    @time_cb, loc_draw_cb ...
    , @() rect_pad(m1_centered_rect_remap(fix_cross_size), cross_padding), @get_m1_position ...
    , @() rect_pad(m2_centered_rect_remap(fix_cross_size), cross_padding), @get_m2_position ...
    , @local_update ...
    , timing.initial_fixation_duration, timing.initial_fixation_state_duration );

  res.fixation_state_m1 = fs_m1;
  res.fixation_state_m2 = fs_m2;
  acquired_m1 = fs_m1.acquired;
  acquired_m2 = fs_m2.acquired;
  acquired = fs_m1.acquired && fs_m2.acquired;
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
    if ( is_gaze_trial )
      color = [255, 0, 0];
    else
      color = [0, 0, 255];
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
    draw_texture( win_m1, cross_im, m1_centered_rect_screen(fix_cross_size) );
    draw_texture( win_m2, cross_im, m2_centered_rect_screen(fix_cross_size) );
  end
end

function [res, signaler_choice] = state_spatial_cue(swap_signaler_dir, laser_index)
  send_message( task_interface.npxi_events, 'spatial_cue/enter' );

  actor_win = win_m1;
  signaler_win = win_m2;

  actor_pos = @get_m1_position;
  signaler_pos = @get_m2_position;

  loc_draw_cb = wrap_draw({@draw_spatial_cues, @maybe_draw_gaze_cursors},1,1);
  signaler_rects_cb = @() rect_pad(lr_rects(get(signaler_win.Rect), [fix_target_size, fix_target_size]), target_padding);
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
  );

  trigger( task_interface.laser_interface, laser_index );

  res = struct();
  res.signaler_choice = loc_signaler_choice;
  res.actor_fixation = loc_actor_fixation;

  signaler_choice = loc_signaler_choice.ChoiceIndex;

  function draw_spatial_cues()
    signaler_rects = lr_rects( get(signaler_win.Rect), [fix_target_size, fix_target_size] );% [100,100];

    if ( swap_signaler_dir )
      signaler_rects = fliplr( signaler_rects );
    end

    draw_texture(signaler_win, targ1_im_m2, signaler_rects{1})
    draw_texture(signaler_win, targ2_im_m2, signaler_rects{2})

%     fill_oval( signaler_win, [255, 255, 255], signaler_rects{1} );
%     fill_rect( signaler_win, [255, 255, 255], signaler_rects{2} );
  end
end

function res = state_fixation_delay()
  send_message( task_interface.npxi_events, 'fixation_delay/enter' );

  abort_on_break = false;
  loc_draw_cb = wrap_draw( {@draw_fixation_crosses, @maybe_draw_gaze_cursors},0,1 );
  [fs_m1, fs_m2] = static_fixation2( ...
    @time_cb, loc_draw_cb ...
    , @() rect_pad(centered_rect(center_remap_m1,[100, 100]), target_padding), @get_m1_position ...
    , @() rect_pad(centered_rect(center_remap_m2, [100, 100]), target_padding), @get_m2_position ...
    , @local_update, timing.fixation_delay_duration ...
    , timing.fixation_delay_duration, abort_on_break );


%   [fs_m1, fs_m2] = static_fixation2( ...
%     @time_cb, loc_draw_cb ...
%     , @() centered_rect(win_m1.Center, [100, 100]), @get_m1_position ...
%     , @() centered_rect(win_m2.Center, [100, 100]), @get_m2_position ...
%     , @local_update, timing.fixation_delay_duration ...
%     , timing.fixation_delay_duration, abort_on_break );

  res = struct();
  res.fixation_state_m1 = fs_m1;
  res.fixation_state_m2 = fs_m2;
end

function [res, actor_resp_choice] = state_actor_response()
  send_message( task_interface.npxi_events, 'actor_response/enter' );

  chooser_win = win_m1;
  chooser_pos = @get_m1_position;

  fixator_win = win_m2;
  fixator_pos = @get_m2_position;

  chooser_choice_time = timing.actor_response_state_chooser_duration;
  state_time = timing.actor_response_state_duration;

  loc_draw_cb = wrap_draw({@draw_response, @maybe_draw_gaze_cursors},1,1);  
  chooser_rects_cb = @() rect_pad(lr_rects(get(chooser_win.Rect), [fix_circular_size, fix_circular_size]), circular_padding);

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

  actor_resp_choice = signaler_choice.ChoiceIndex;

  function draw_response()
    actor_rects = lr_rects( get(chooser_win.Rect), [fix_circular_size, fix_circular_size] );

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

function error_timeout_state(duration,errorDrawWin1, errorDrawWin2)
  % error
  static_fixation2( ...
    @time_cb, wrap_draw({@draw_error, @maybe_draw_gaze_cursors},errorDrawWin1,errorDrawWin2) ...
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
  if ( draw_m1_gaze )
    fill_oval( win_m1, [255, 0, 255], centered_rect(get_m1_position(), 50) );
    fill_oval( win_m1_copy, [255, 0, 255], centered_rect(get_m1_position(), 50) );
  end
  if ( draw_m2_gaze )
    fill_oval( win_m2, [255, 0, 255], centered_rect(get_m2_position(), 50) );
    fill_oval( win_m2_copy, [255, 0, 255], centered_rect(get_m2_position(), 50) );
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
      filp(win_m1_copy,true)
    end
    if maybeDrawWin2
      flip( win_m2, true );
      filp(win_m2_copy,true)
    end
  end
  r = @do_draw;
end

function draw_error()
%   fill_rect( win_m1, [255, 255, 0], m1_centered_rect_screen(error_square_size) );
%   fill_rect( win_m2, [255, 255, 0], m2_centered_rect_screen(error_square_size) );
  fill_rect( win_m1, [0, 0, 255], m1_centered_rect_screen(error_square_size) );
  fill_rect( win_m2, [0, 0, 255], m2_centered_rect_screen(error_square_size) );

  fill_rect( win_m1_copy, [0, 0, 255], m1_centered_rect_screen(error_square_size) );
  fill_rect( win_m2_copy, [0, 0, 255], m2_centered_rect_screen(error_square_size) );

end

function draw_fixation_crosses()

  draw_texture( win_m1, cross_im, m1_centered_rect_screen(fix_cross_size) );
  draw_texture( win_m1_copy, cross_im, m1_centered_rect_screen(fix_cross_size) );
  draw_texture( win_m2, cross_im, m2_centered_rect_screen(fix_cross_size) );
  draw_texture( win_m2_copy, cross_im, m2_centered_rect_screen(fix_cross_size) );
end


%{ 
  lifecycle
%}

function local_update()
  update( task_interface );
end

function local_shutdown()
  fprintf( '\n\n\n\n Shutting down ...' );

  task_interface.finish();
  delete( task_interface );
  close( win_m1 );
  close( win_m2 );
  close( win_m1_copy );
  close( win_m2_copy );
  
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

function rs = lr_rects(win_rect, size)

  win_center = [ mean(win_rect([1, 3])), mean(win_rect([2, 4])) ];
%   enable_remap = true;

  if enable_remap
    win_center = center_screen_m1;
  end
  
  lx = mean( [win_center(1), win_rect(1)] );
  rx = mean( [win_center(1), win_rect(3)] );
  
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