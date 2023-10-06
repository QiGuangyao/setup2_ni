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