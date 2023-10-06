classdef NIGazeTracker < handle
  properties
    latest_sample;
    gaze_coord_transform;
  end

  methods
    function obj = NIGazeTracker()
      obj.latest_sample = NIInterface.get_empty_update_result();
      obj.gaze_coord_transform = TransformNIGazeCoordinates();
    end

    function update(obj, latest_sample)
      obj.latest_sample = latest_sample;
    end

    function set_calibration_rects(obj, wins)
      set_rect_m1( obj.gaze_coord_transform, get(wins{1}.Rect) );
      set_rect_m2( obj.gaze_coord_transform, get(wins{2}.Rect) );
    end

    function xy = get_m1(obj)
      ls = obj.latest_sample;
      [x, y] = obj.gaze_coord_transform.scale_coords_m1( ls.x1, ls.y1 );
      xy = [x, y];
    end

    function xy = get_m2(obj)
      ls = obj.latest_sample;
      [x, y] = obj.gaze_coord_transform.scale_coords_m2( ls.x2, ls.y2 );
      xy = [x, y];
    end
  end
end