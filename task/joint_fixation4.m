function [fs_m1, fs_m2, achieved_required_overlap,achieved_required_interval] = joint_fixation4(...
    time_cb, draw_cb ...
  , targ_loc_cb1, pos_cb1 ...
  , targ_loc_cb2, pos_cb2, loop_cb ...
  , fix_time_m1,fix_time_m2, state_time, abort_on_break ...
  , varargin)

if ( nargin < 10 || isempty(abort_on_break) )
  abort_on_break = true;
end

defaults = struct();
defaults.m1_first_acq_callback = [];
defaults.m2_first_acq_callback = [];
defaults.m1_every_acq_callback = [];
defaults.m2_every_acq_callback = [];
defaults.allow_non_overlapping_acq = true;
defaults.overlap_duration_to_exit = nan;

params = shared_utils.general.parsestruct( defaults, varargin );
overlap_dur = params.overlap_duration_to_exit;

entry_t = time_cb();
achieved_required_overlap = false;
achieved_required_interval = false;
fs_m1 = FixationStateTracker( entry_t ...
  , 'first_acquire_callback', params.m1_first_acq_callback ...
  , 'every_acquire_callback', params.m1_every_acq_callback ...
);
fs_m2 = FixationStateTracker( entry_t ...
  , 'first_acquire_callback', params.m2_first_acq_callback ...
  , 'every_acquire_callback', params.m2_every_acq_callback ...
);



% fs_m1_m2 = FixationStateTracker( entry_t ...
%   , 'first_acquire_callback', params.m1_m2_first_acq_callback ...
%   , 'every_acquire_callback', params.m1_m2_every_acq_callback ...
% );


while ( time_cb() - entry_t < state_time && ~(fs_m1.ever_acquired && fs_m2.ever_acquired) )
  loop_cb();
  
  if ( ~isempty(draw_cb) )
    draw_cb();
  end
  
  m1_xy = pos_cb1();
  m2_xy = pos_cb2();
  
  targ_rect1 = targ_loc_cb1();
  targ_rect2 = targ_loc_cb2();
  
  t = time_cb();
  
  [m1_broke, m1_info] = update( fs_m1, m1_xy(1), m1_xy(2), t, fix_time_m1, targ_rect1 );
  [m2_broke, m2_info] = update( fs_m2, m2_xy(1), m2_xy(2), t, fix_time_m2, targ_rect2 );

  if ( ~isnan(m1_info.ib_entry_t) && ~isnan(m2_info.ib_entry_t) )
    % overlap duration test
    latest_t = max( m1_info.ib_entry_t, m2_info.ib_entry_t );
    if ( ~isnan(overlap_dur) && t - latest_t >= overlap_dur )
      achieved_required_overlap = true;
      break
    end
  end

  if ( ~isnan(m1_info.ib_entry_t) && ~isnan(m2_info.ib_entry_t) )
    % overlap duration test
    latest_t = max( m1_info.ib_entry_t, m2_info.ib_entry_t );
    if ( ~isnan(overlap_dur) && t - latest_t >= overlap_dur )
      achieved_required_interval = true;
      break
    end
  end



  
  % 10/20/2023 GY
  if ( abort_on_break && (m1_broke && m2_broke) )
    break
  end

  if ( params.allow_non_overlapping_acq )
    % allows non-overlapping successful acquisitions 
    if ( fs_m1.ever_acquired && fs_m2.ever_acquired )
      break
    end
  end


%   if ( abort_on_break && (m1_broke || m2_broke) )
%     break
%   end
end

end