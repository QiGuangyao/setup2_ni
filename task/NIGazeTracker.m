classdef NIGazeTracker < handle
  properties
    latest_sample;
  end

  methods
    function obj = NIGazeTracker()
      obj.latest_sample = NIInterface.get_empty_update_result();
    end

    function update(obj, latest_sample)
      obj.latest_sample = latest_sample;
    end

    function xy = get_m2(obj)
      ls = obj.latest_sample;
      [x, y] = TransformNIGazeCoordinates.scale_coords_m2( ls.x2, ls.y2 );
      xy = [x, y];
    end

    function xy = get_m1(obj)
      ls = obj.latest_sample;
      [x, y] = TransformNIGazeCoordinates.scale_coords_m1( ls.x1, ls.y1 );
      xy = [x, y];
    end
  end
end