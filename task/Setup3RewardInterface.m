classdef Setup3RewardInterface < handle
  properties (Constant = true)
    PORT = 'COM5';
  end

  properties
    dummy = false;
    comm = [];
    initialized = false;
  end

  methods
    function obj = Setup3RewardInterface(dummy)
      if ( nargin < 1 )
        dummy = false;
      end

      validateattributes( dummy, {'logical'}, {'scalar'}, mfilename, 'dummy' );
      obj.dummy = dummy;
    end

    function update(obj)
      if ( obj.initialized )
        update( obj.comm );
      end
    end

    function flush_sync(obj, dur_s, channels)
      if ( nargin < 3 )
        channels = 0:1;
      end
      
      if ( nargin < 2 )
        dur_s = 15;
      end

      trigger( obj, channels, dur_s );

      t0 = tic;
      while ( toc(t0) < dur_s + 1 )
        update( obj );
      end
    end

    function trigger(obj, channels, durations_s)
      if ( ~obj.initialized )
        return
      end

      for i = 1:numel(channels)
        dur = durations_s(mod(i-1, numel(durations_s)) + 1) * 1e3;
        switch ( channels(i) )
          case 0
            chan = 'A';
          case 1
            chan = 'B';
          otherwise
            error( 'Expected channel index 0 or 1; got %d', channels(i) );
        end

        reward( obj.comm, chan, dur );
      end
    end

    function initialize(obj)
      if ( obj.dummy )
        return
      end

      obj.comm = serial_comm.SerialManagerPaired( ...
        obj.PORT, struct(), {'A', 'B'}, 'slave' );
      start( obj.comm );
      obj.initialized = true;
    end

    function shutdown(obj)
      if ( obj.initialized )
        close( obj.comm );
        obj.initialized = false;
      end
    end

    function delete(obj)
      shutdown( obj );
    end
  end
end