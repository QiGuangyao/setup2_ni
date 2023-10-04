classdef NPXIEventsInterface < handle
  properties (Constant = true)
    URL = 'tcp://127.0.0.1:5556';
  end

  properties (Access = private)
    initialized = false;
    dummy = false;
    thread_handle = [];
  end

  methods
    function obj = NPXIEventsInterface(dummy)
      validateattributes( dummy, {'logical'}, {'scalar'}, mfilename, 'dummy' );
      obj.dummy = dummy;
    end

    function initialize(obj)
      shutdown( obj );

      if ( obj.dummy )
        return
      end

      obj.thread_handle = zeroMQwrapper( 'StartConnectThread', obj.URL );
      obj.initialized = true;
    end

    function send_message(obj, msg)
      assert( ischar(msg), 'Message must be char vector.' );

      if ( obj.dummy )
        return
      end

      if ( ~obj.initialized )
        error( 'Interface not yet initialized.' );
      end

      assert( ~isempty(obj.thread_handle) );
      zeroMQwrapper( 'Send', obj.thread_handle, msg );
    end

    function shutdown(obj)
      if ( ~isempty(obj.thread_handle) )
        zeroMQwrapper( 'CloseThread', obj.thread_handle );
        obj.thread_handle = [];
      end

      obj.initialized = false;
    end

    function delete(obj)
      shutdown( obj );
    end
  end
end