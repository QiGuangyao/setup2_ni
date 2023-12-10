function [fs_m1_solo] = static_fixation_m1_solo(...
    time_cb, draw_cb ...
  , targ_loc_cb1, pos_cb1 ...
  , loop_cb ...
  , fix_time, state_time, abort_on_break)

if ( nargin < 10 )
  abort_on_break = true;
end

entry_t = time_cb();

fs_m1_solo = FixationStateTracker( entry_t );

while ( time_cb() - entry_t < state_time && ~(fs_m1_solo.acquired) )
  loop_cb();
  
  if ( ~isempty(draw_cb) )
    draw_cb();
  end
  
  m1_xy = pos_cb1();
  
  targ_rect1 = targ_loc_cb1();
  
  t = time_cb();
  
  m1_broke = update( fs_m1_solo, m1_xy(1), m1_xy(2), t, fix_time, targ_rect1 );
  
  % 10/20/2023 GY
  if ( abort_on_break && (m1_broke) )
    break
  end


%   if ( abort_on_break && (m1_broke || m2_broke) )
%     break
%   end
end

end