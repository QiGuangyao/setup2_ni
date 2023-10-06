classdef TaskInterface < handle
  properties
    t0;
    data_p = '';

    put_m1_gaze_in_center = true;
    put_m2_gaze_in_center = true;

    bypass_video = true;
    bypass_ni = true;
    bypass_npxi_events = false;
    bypass_laser = false;
    bypass_reward = false;

    laser_port = 'COM4';

    matlab_time;
    video_interface;
    ni_interface;
    gaze_tracker;
    npxi_events;
    laser_interface;
    task_data;
  end

  methods
    function obj = TaskInterface(t0, save_p)
      obj.t0 = t0;
      obj.data_p = save_p;
    end

    function m1_xy = get_m1_position(obj, win_m1)
      if ( obj.put_m1_gaze_in_center )
        m1_xy = win_m1.Center;
      else
        m1_xy = get_m1( obj.gaze_tracker );
      end
    end

    function m1_xy = get_m2_position(obj, win_m2)
      if ( obj.put_m2_gaze_in_center )
        m1_xy = win_m2.Center;
      else
        m1_xy = get_m2( obj.gaze_tracker );
      end
    end

    function deliver_reward(obj, chans, duration_s)
      if ( ~obj.bypass_reward )
        reward_trigger( obj.ni_interface, chans, duration_s );
      end
    end

    function r = elapsed_time(obj)
      r = seconds( datetime() - obj.t0 );
    end

    function initialize(obj)
      obj.matlab_time = MatlabTimeSync( obj.t0 );

      % video
      %
      %
      obj.video_interface = AsyncVideoInterface( obj.bypass_video, obj.data_p );
      initialize( obj.video_interface );
      
      % ni
      %
      %
      obj.ni_interface = NIInterface( obj.bypass_ni );
      initialize( obj.ni_interface, fullfile(obj.data_p, 'ni.bin') );
      ni_meta_info = get_meta_info( obj.ni_interface );

      % gaze tracker
      %
      %
      obj.gaze_tracker = NIGazeTracker();

      % neuro pixel events
      %
      %
      obj.npxi_events = NPXIEventsInterface( obj.bypass_npxi_events );
      initialize( obj.npxi_events );

      % laser
      %
      % 
      obj.laser_interface = LaserInterface( obj.laser_port, obj.bypass_laser );
      initialize( obj.laser_interface );

      % wait for pulse train to begin.
      wait_for_sync_pulse_train_to_likely_begin( obj.ni_interface );
    end

    function update(obj)
      res = tick( obj.ni_interface );
      update( obj.gaze_tracker, res );
    end

    function finish(obj)
      obj.matlab_time.finish( datetime() );
    end

    function shutdown(obj)
      delete( obj.ni_interface );
      % @NOTE: Task data should be deleted after NI shuts down, but before
      % video interface is deleted (bc the video data may be needed
      % as part of the task data shutdown procedure).
      delete( obj.task_data );
      delete( obj.video_interface );
      delete( obj.laser_interface );
      delete( obj.npxi_events );
    end

    function delete(obj)
      shutdown( obj );
    end
  end
end