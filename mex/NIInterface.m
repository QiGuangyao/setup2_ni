%{

see also ni_mex.cpp

%}

classdef NIInterface < handle
  properties
    dummy = false;
    initialized = false;
  end

  methods
    function obj = NIInterface()
    end

    function initialize(obj, dst_file_p)
      validateattributes( ...
        dst_file_p, {'char'}, {'scalartext'}, mfilename, 'dst_file_p' );

      shutdown( obj );

      if ( obj.dummy )
        return
      end

      NIInterface.start( dst_file_p );
      obj.initialized = true;
    end

    function shutdown(obj)
      if ( obj.initialized )
        NIInterface.stop();
      end

      obj.initialized = false;
    end

    function res = tick(obj)
      if ( ~obj.initialized )
        res = empty_update_result();
      else
        res = NIInterface.update();
      end
    end

    function reward_trigger(obj, chan, dur_s)
      if ( ~obj.initialized )
        return
      end

      NIInterface.trigger_reward( chan, dur_s );
    end

    function delete(obj)
      shutdown( obj );
    end
  end

  methods (Static = true)
    function start(dst_p)
      ni_mex( uint32(0), dst_p );
    end

    function trigger_reward(channel, dur_s)
      ni_mex( uint32(2), channel, dur_s );
    end

    function res = update()
      res = ni_mex( uint32(1) );
    end

    function stop()
      ni_mex( uint32(3) );
    end
  end
end

function res = empty_update_result()

res = struct();
res.pupil1 = 0;
res.x1 = 0;
res.y1 = 0;
res.pupil2 = 0;
res.x2 = 0;
res.y2 = 0;

end
%{

dst_p = 'C:\Users\setup2\source\setup2_ni\data\test2.dat';

ni_mex( uint32(0), dst_p );

t0 = tic;
pulse_t0 = tic;
while ( toc(t0) < 5 )
  res = ni_mex( uint32(1) );

  if ( 0 )
    fprintf("%0.4f, %0.4f, %0.4f | %0.4f, %0.4f, %0.4f\n", ...
      res.pupil1, res.x1, res.y1, res.pupil2, res.x2, res.y2 );
  end

  if ( 1 && toc(pulse_t0) > 2 )
    reward_t0 = tic;
    for i = 1:2
      ni_mex( uint32(2), i-1, 0.5 );
    end
    reward_elapsed = toc( reward_t0 );
    pulse_t0 = tic;
    fprintf( 'Reward took %0.3f(s)\n', reward_elapsed );
  end
end

ni_mex( uint32(3) );

%}