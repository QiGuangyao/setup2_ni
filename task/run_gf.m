function run_gf()

proj_p = fileparts( which(mfilename) );

bypass_ni = false;
bypass_video = false;
bypass_trial_data = false;
bypass_laser = false;
save_data = true;
full_screens = true;
max_num_trials = inf;

put_m1_in_center = true;
put_m2_in_center = true;
draw_m1_gaze = true;
draw_m2_gaze = true;

enable_spatial_cue = true;
enable_fix_delay = true;
enable_actor_response = true;
enable_response_feedback = true;

%{
  timing parameters
%}

initial_fixation_duration = 0.15;
initial_fixation_state_duration = 0.175;
spatial_rule_fixation_duration = 0.15;
spatial_rule_state_duration = 0.175;
iti_duration = 1;
error_duration = 1; % timeout in case of failure to fixate
feedback_duration = 1;

%{
  stimuli parameters
%}

fix_cross_size = 100; % px
error_square_size = 200;

%{
  reward parameters
%}

reward_duration_s = 0.25;

%{
  init
%}

t0 = tic();

save_ident = strrep( datestr(now), ':', '_' );

if ( save_data )
  save_p = fullfile( proj_p, 'data', save_ident );
  shared_utils.io.require_dir( save_p );
else
  save_p = '';
end

% open windows before ni
if ( full_screens )
  win_m1 = open_window( 'screen_index', 1, 'screen_rect', [] );
  win_m2 = open_window( 'screen_index', 2, 'screen_rect', [] );
else
  win_m1 = open_window( 'screen_index', 0, 'screen_rect', [0, 0, 800, 800] );
  win_m2 = open_window( 'screen_index', 0, 'screen_rect', [800, 0, 1600, 800] );
end

% start video before ni
vid_interface = AsyncVideoInterface( bypass_video, save_p, false );
initialize( vid_interface );

ni_interface = NIInterface( bypass_ni );
initialize( ni_interface, fullfile(save_p, 'ni.bin') );

gaze_tracker = ptb.Reference( NIInterface.get_empty_update_result() );

laser_interface = LaserInterface( 'COM4', bypass_laser );
initialize( laser_interface );

cross_im = ptb.Image( win_m1, imread(fullfile(proj_p, 'images/cross.jpg')) );

%{
  main trial sequence
%}

if ( bypass_trial_data )
  trial_data = [];
else
  trial_data = TaskData( save_p, 'task_data.mat', vid_interface );
end

err = [];

try

while ( ~ptb.util.is_esc_down() && ...
      (isempty(trial_data) || num_entries(trial_data) < max_num_trials) )
  drawnow;
  
  if ( isempty(trial_data) )
    trial_rec = TrialRecord();
  else
    trial_rec = push( trial_data );
  end
  
  trial_rec.fixation_with_block_rule = struct();
  trial_rec.spatial_rule = struct();

  %{
    fixation with block rule
  %}
  
  [fs_m1, fs_m2] = state_fixation_with_block_rule();  
  trial_rec.fixation_with_block_rule.fixation_state_m1 = fs_m1;
  trial_rec.fixation_with_block_rule.fixation_state_m2 = fs_m2;
  
  if ( ~fs_m1.acquired || ~fs_m2.acquired )
    % error
    error_timeout_state( error_duration );
    continue
  end

  %{
    spatial rule
  %}
  
  [fs_m1, fs_m2] = state_spatial_rule();
  trial_rec.spatial_rule.fixation_state_m1 = fs_m1;
  trial_rec.spatial_rule.fixation_state_m2 = fs_m2;

  if ( ~fs_m1.acquired || ~fs_m2.acquired )
    % error
    error_timeout_state( error_duration );
    continue
  end

  if ( 1 )  % bridge reward
    deliver_reward( 0:1, reward_duration_s );
  end

  if ( 0 )
    state_iti();
  end

  %{
    spatial cue
  %}
  
  if ( enable_spatial_cue )
    [signaler_choice, actor_fixation] = state_spatial_cue();
  end

  %{
    fixation delay
  %}
  
  if ( enable_fix_delay )
    [fs_m1, fs_m2] = state_fixation_delay();
  end
  
  %{
    response
  %}
    
  if ( enable_actor_response )
    [signaler_choice, actor_fixation] = state_actor_response();
  end
  
  %{
    feedback
  %}
  
  if ( enable_response_feedback )
    state_response_feedback();
  end
  
  b = 10;
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

function [fs_m1, fs_m2] = state_fixation_with_block_rule()
  loc_draw_cb = wrap_draw(...
    {@draw_fixation_crosses, @maybe_draw_gaze_cursors});
  [fs_m1, fs_m2] = static_fixation2( ...
    @time_cb, loc_draw_cb ...
    , @() m1_centered_rect(fix_cross_size), @get_m1_position ...
    , @() m2_centered_rect(fix_cross_size), @get_m2_position ...
    , @local_update ...
    , initial_fixation_duration, initial_fixation_state_duration );
end

function [fs_m1, fs_m2] = state_spatial_rule()
  loc_draw_cb = wrap_draw({@draw_spatial_rule, @maybe_draw_gaze_cursors});
  [fs_m1, fs_m2] = static_fixation2( ...
    @time_cb, loc_draw_cb ...
  , @() m1_centered_rect(fix_cross_size), @get_m1_position ...
  , @() m2_centered_rect(fix_cross_size), @get_m2_position ...
  , @local_update, spatial_rule_fixation_duration, spatial_rule_state_duration );

  function draw_spatial_rule()
    frame_m1_rect( [255, 0, 0], get(win_m1.Rect) );
    draw_texture( win_m1, cross_im, m1_centered_rect(fix_cross_size) );
    draw_texture( win_m2, cross_im, m2_centered_rect(fix_cross_size) );
  end
end

function [signaler_choice, actor_fixation] = state_spatial_cue()
  loc_draw_cb = wrap_draw({@draw_spatial_cues, @maybe_draw_gaze_cursors});
  chooser_rects_cb = @() lr_rects(get(win_m1.Rect), [100, 100]);
  fixator_rects_cb = @() m2_centered_rect([100, 100]);

  state_time = 0.6;
  trigger( laser_interface, 0 );
%   trigger( laser_interface, 1 );

  [signaler_choice, actor_fixation] = state_choice(...
      @time_cb, @local_update, loc_draw_cb ...
    , @get_m1_position, @get_m2_position ...
    , chooser_rects_cb, fixator_rects_cb ...
    , state_time, state_time, state_time ...
  );

  trigger( laser_interface, 0 );
%   trigger( laser_interface, 1 );

  function draw_spatial_cues()
    signaler_rects = lr_rects( get(win_m1.Rect), [100, 100] );

    fill_m1_oval( [255, 255, 255], signaler_rects{1} );
    fill_m1_rect( [255, 255, 255], signaler_rects{2} );
  end
end

function [fs_m1, fs_m2] = state_fixation_delay()
  loc_draw_cb = []; % TODO
  [fs_m1, fs_m2] = static_fixation2( ...
    @time_cb, loc_draw_cb ...
    , @() centered_rect(win_m1.Center, [100, 100]), @get_m1_position ...
    , @() centered_rect(win_m2.Center, [100, 100]), @get_m2_position ...
    , @local_update, 0.15, 0.15 );
end

function [signaler_choice, actor_fixation] = state_actor_response()
  loc_draw_cb = wrap_draw({@draw_response, @maybe_draw_gaze_cursors});  
  chooser_rects_cb = @() lr_rects(get(win_m2.Rect), [100, 100]);
  fixator_rects_cb = @() m1_centered_rect([100, 100]);
  [signaler_choice, actor_fixation] = state_choice(...
      @time_cb, @local_update, loc_draw_cb ...
    , @get_m2_position, @get_m1_position ...
    , chooser_rects_cb, fixator_rects_cb ...
    , 0.6, 0.6, 0.6 ...
  );

  function draw_response()
    actor_rects = lr_rects( get(win_m2.Rect), [100, 100] );

    fill_m2_rect( [255, 255, 255], actor_rects{1} );
    fill_m2_rect( [255, 255, 255], actor_rects{2} );
  end
end

function state_response_feedback()
  static_fixation2( ...
    @time_cb, wrap_draw({}) ...
  , @() m1_centered_rect(fix_cross_size), @get_m1_position ...
  , @() m2_centered_rect(fix_cross_size), @get_m2_position ...
  , @local_update, feedback_duration, feedback_duration );
end

function state_iti()
  static_fixation2( ...
    @time_cb, wrap_draw({}) ...
  , @() m1_centered_rect(fix_cross_size), @get_m1_position ...
  , @() m2_centered_rect(fix_cross_size), @get_m2_position ...
  , @local_update, iti_duration, iti_duration );
end

function error_timeout_state(duration)
  % error
  static_fixation2( ...
    @time_cb, wrap_draw({@draw_error}) ...
  , @invalid_rect, @get_m1_position ...
  , @invalid_rect, @get_m2_position ...
  , @local_update, duration, duration );
end

%{
  utilities
%}

function deliver_reward(chans, duration_s)
  reward_trigger( ni_interface, chans, duration_s );
end

function r = time_cb()
  r = toc( t0 );
end

function m1_xy = get_m1_position()
  if ( put_m1_in_center )
    m1_xy = win_m1.Center;
  else
    [x, y] = TransformNIGazeCoordinates.scale_coords_m1( ...
      gaze_tracker.Value.x1, gaze_tracker.Value.y1 );
    m1_xy = [x, y];
  end
end

function m2_xy = get_m2_position()
  if ( put_m2_in_center )
    m2_xy = win_m2.Center;
  else
    [x, y] = TransformNIGazeCoordinates.scale_coords_m2( ...
      gaze_tracker.Value.x2, gaze_tracker.Value.y2 );
    m2_xy = [x, y];
  end
end

function r = m1_centered_rect(size)
  r = centered_rect( win_m1.Center, size );
%   r([2, 4]) = r([2, 4]) + 20; % shift target up by 20 px
end

function r = m2_centered_rect(size)
  r = centered_rect( win_m2.Center, size );
end

function draw_texture(win, im, rect)
  Screen( 'DrawTexture', win.WindowHandle, im.TextureHandle, [], rect );
end

function fill_m1_rect(varargin)  
  Screen( 'FillRect', win_m1.WindowHandle, varargin{:} );
end

function fill_m1_oval(varargin)  
  Screen( 'FillOval', win_m1.WindowHandle, varargin{:} );
end

function fill_m2_oval(varargin)  
  Screen( 'FillOval', win_m2.WindowHandle, varargin{:} );
end

function frame_m1_rect(varargin)  
  Screen( 'FrameRect', win_m1.WindowHandle, varargin{:} );
end

function fill_m2_rect(varargin)
  Screen( 'FillRect', win_m2.WindowHandle, varargin{:} );
end

function maybe_draw_gaze_cursors()
  if ( draw_m1_gaze )
    fill_m1_oval( [255, 0, 255], centered_rect(get_m1_position(), 100) );
  end
  if ( draw_m2_gaze )
    fill_m2_oval( [255, 0, 255], centered_rect(get_m2_position(), 100) );
  end
end

function r = wrap_draw(fs)
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
    flip( win_m1, true );
    flip( win_m2, true );
  end
  r = @do_draw;
end

function draw_error()
  fill_m1_rect( [255, 255, 0], m1_centered_rect(error_square_size) );
  fill_m2_rect( [255, 255, 0], m2_centered_rect(error_square_size) );
end

function draw_fixation_crosses()
  draw_texture( win_m1, cross_im, m1_centered_rect(fix_cross_size) );
  draw_texture( win_m2, cross_im, m2_centered_rect(fix_cross_size) );
end

%{ 
  lifecycle
%}

function local_update()
  res = tick( ni_interface );
  gaze_tracker.Value = res;
end

function local_shutdown()
  fprintf( '\n\n\n\n Shutting down ...' );

  delete( ni_interface );
  delete( trial_data );
  delete( vid_interface );
  delete( laser_interface );
  close( win_m1 );
  close( win_m2 );
  
  fprintf( ' Done.' );
end

end

function [chooser_choice, fixator_fixation] = state_choice(...
    time_cb, loop_cb, draw_cb ...
  , chooser_pos_cb, fixator_pos_cb ...
  , chooser_rects_cb, fixator_rect_cb ...
  , chooser_choice_time, fixator_fix_time, state_time ...
)

entry_t = time_cb();

chooser_choice = ChoiceTracker( entry_t, 2 );
fixator_fixation = FixationStateTracker( entry_t );

while ( time_cb() - entry_t < state_time )
  loop_cb();
  
  if ( ~isempty(draw_cb) )
    draw_cb();
  end
  
  chooser_xy = chooser_pos_cb();
  fixator_xy = fixator_pos_cb();
  
  chooser_rects = chooser_rects_cb();
  fixator_rect = fixator_rect_cb();
  
  t = time_cb();
  
  [chooser_chose, choice_index] = update( ...
      chooser_choice, chooser_xy(1), chooser_xy(2), t ...
    , chooser_choice_time, chooser_rects );
  
  fixator_broke = update( ...
    fixator_fixation, fixator_xy(1), fixator_xy(2), t ...
    , fixator_fix_time, fixator_rect );
end

end

function rs = lr_rects(win_rect, size)

win_center = [ mean(win_rect([1, 3])), mean(win_rect([2, 4])) ];
lx = mean( [win_center(1), win_rect(1)] );
rx = mean( [win_center(1), win_rect(3)] );

rs = { ...
    centered_rect([lx, win_center(2)], size) ...
  , centered_rect([rx, win_center(2)], size) ...
};

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