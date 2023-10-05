classdef MatlabTimeSync < handle
  properties
    clock_t0;
    clock_t1;
  end

  methods
    function obj = MatlabTimeSync(clock_t0)
      obj.clock_t0 = clock_t0;
      obj.clock_t1 = nan( size(clock_t0) );
    end

    function finish(obj, clock_t1)
      obj.clock_t1 = clock_t1;
    end

    function s = get_saveable_data(obj)
      s = struct();
      prop_names = { 'clock_t0', 'clock_t1' };
      for i = 1:numel(prop_names)
        s.(prop_names{i}) = obj.(prop_names{i});
      end
    end
  end
end