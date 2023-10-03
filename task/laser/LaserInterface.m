classdef LaserInterface < handle
  properties (Access = private)
    port;
    comm;
    dummy;
    initialized = false;
    timers = {[], []};
    states = [0, 0];
    debug = false;
  end

  methods (Access = private, Static = true)
    function trigger_impl(obj, index, rm_timer)
      if ( ~obj.initialized )
        return
      else
        assert( ~isempty(obj.comm) && isvalid(obj.comm) );
      end

      if ( index == 0 )
        write_char = 'a';
      elseif ( index == 1 )
        write_char = 'b';
      else
        error( 'Expected index in [0, 1]' );
      end

      if ( obj.debug )
        fprintf( '\n Writing ');
      end

      write( obj.comm, write_char, 'uint8' );
      obj.states(index+1) = 1 - obj.states(index+1);

      if ( rm_timer )
        delete( obj.timers{index+1} );
        obj.timers{index+1} = [];
      end
    end
  end

  methods
    function obj = LaserInterface(port, dummy)
      validateattributes( dummy, {'logical'}, {'scalar'}, mfilename, 'dummy' );
      obj.port = port;
      obj.dummy = dummy;
    end

    function initialize(obj)
      shutdown( obj );

      if ( obj.dummy )
        return
      end

      obj.comm = serialport( obj.port, 9600 );

      r = read( obj.comm, 1, 'uint8' );
      if ( r ~= '*' )
        error( 'Expected response character ''*''; got %s', r );
      end

      obj.initialized = true;
    end

    function trigger(obj, index, for_time)
      if ( nargin < 3 )
        for_time = [];
      end

      if ( ~obj.initialized )
        return
      end

      assert( index >= 0 && index < 2, 'Expected index in [0, 1]' );
      if ( ~isempty(obj.timers{index+1}) )
        warning( 'State already high; truncating previous pulse.' );
        stop( obj.timers{index+1} );
        delete( obj.timers{index+1} );
      end

      if ( isempty(for_time) )
        if ( obj.states(index+1) )
          LaserInterface.trigger_impl( obj, index, 1 );
        else
          LaserInterface.trigger_impl( obj, index, 0 );
        end
      else
        t = timer();
        t.StartDelay = for_time;
        t.TasksToExecute = 1;
        t.TimerFcn = @(varargin) 0;
        t.StartFcn = @(varargin) LaserInterface.trigger_impl(obj, index, 0);
        t.StopFcn = @(varargin) LaserInterface.trigger_impl(obj, index, 1);
        t.start();
        obj.timers{index+1} = t;
      end
    end

    function shutdown(obj)
      if ( ~isempty(obj.comm) && isvalid(obj.comm) )
        write( obj.comm, 'r', 'uint8' );
        flush( obj.comm );
        delete( obj.comm );
        obj.comm = [];
      end

      obj.initialized = false;
    end

    function delete(obj)
      shutdown( obj );
    end
  end
end