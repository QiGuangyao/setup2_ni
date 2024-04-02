classdef ChoiceTracker < handle
  properties
    StateTrackers;
    ChoiceIndex;
  end
  
  methods    
    function obj = ChoiceTracker(t0, n)
      obj.StateTrackers = cell( n, 1 );
      for i = 1:n
        obj.StateTrackers{i} = FixationStateTracker( t0 );
      end
    end
    
    function reset_acquired(obj)
      for i = 1:numel(obj.StateTrackers)
        reset_acquired( obj.StateTrackers{i} );
      end
    end
    
    function [did_choose, choice_index] = update(obj, x, y, t, choice_time, rects)
      did_choose = false;
      choice_index = [];
      
      assert( iscell(rects) && numel(rects) == numel(obj.StateTrackers) ...
        , 'Expected 1 rect per StateTracker.' );
      
      for i = 1:numel(obj.StateTrackers)
        update( obj.StateTrackers{i}, x, y, t, choice_time, rects{i} );
        
        if ( obj.StateTrackers{i}.acquired )
          obj.ChoiceIndex = i;
          choice_index = i;
          did_choose = true;
        end
      end
    end
  end
end