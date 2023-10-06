function [fs_m1, fs_m2] = static_fixation2(...
    time_cb, draw_cb ...
  , targ_loc_cb1, pos_cb1 ...
  , targ_loc_cb2, pos_cb2, loop_cb ...
  , fix_time, state_time, abort_on_break)

if ( nargin < 10 )
  abort_on_break = true;
end

entry_t = time_cb();

fs_m1 = FixationStateTracker( entry_t );
fs_m2 = FixationStateTracker( entry_t );

while ( time_cb() - entry_t < state_time && ~(fs_m1.acquired && fs_m2.acquired) )
  loop_cb();
  
  if ( ~isempty(draw_cb) )
    draw_cb();
  end
  
  m1_xy = pos_cb1();
  m2_xy = pos_cb2();
  
  targ_rect1 = targ_loc_cb1();
  targ_rect2 = targ_loc_cb2();
  
  t = time_cb();
  
  m1_broke = update( fs_m1, m1_xy(1), m1_xy(2), t, fix_time, targ_rect1 );
  m2_broke = update( fs_m2, m2_xy(1), m2_xy(2), t, fix_time, targ_rect2 );
  
  if ( abort_on_break && (m1_broke || m2_broke) )
    break
  end
end

end