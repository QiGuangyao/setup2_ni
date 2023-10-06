classdef FixationStateTracker < handle
  properties
    ib = false;
    acquired = false;
    entered_ts = [];
    exited_ts = [];
    acquired_ts = [];
    t0 = nan;
  end
  
  methods    
    function obj = FixationStateTracker(t0)
      obj.t0 = t0;
    end
    
    function did_break = update(obj, x, y, t, fix_time, targ_rect)
      did_break = false;
      
      if ( x >= targ_rect(1) && x <= targ_rect(3) && ...
           y >= targ_rect(2) && y <= targ_rect(4) )
         if ( ~obj.ib )
           obj.entered_ts(end+1) = t;
           obj.ib = true;
         end
         if ( ~obj.acquired && t - obj.entered_ts(end) >= fix_time )
           obj.acquired_ts(end+1) = t;
           obj.acquired = true;
         end
      else
        if ( obj.ib )
          obj.exited_ts(end+1) = t;
          obj.ib = false;
          obj.acquired = false;
          did_break = true;
        end
      end
    end
  end
end