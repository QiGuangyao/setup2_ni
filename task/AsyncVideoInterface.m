classdef AsyncVideoInterface < handle
  properties (Constant = true)
    FRAME_RATE = 45;
    INITIAL_TIMEOUT = 30;
  end

  properties (SetAccess = private)
    initialized = false;
    dummy = false;
    video_writer_output_p = '';
    serial = false;
  end

  properties (Access = private)
    par_future = [];
    serial_result = [];
    cached_result = [];
  end

  methods
    function obj = AsyncVideoInterface(dummy, dst_p, serial)
      validateattributes( dummy, {'logical'}, {'scalar'}, mfilename, 'dummy' );
      validateattributes( dst_p, {'char'}, {'scalartext'}, mfilename, 'dst_p' );
      validateattributes( serial, {'logical'}, {'scalar'}, mfilename, 'serial' );
      obj.dummy = dummy;
      obj.video_writer_output_p = dst_p;
      obj.serial = serial;
    end

    function initialize(obj)
      shutdown( obj );

      if ( obj.dummy )
        return
      end

      cb = @() do_capture(...
        obj.FRAME_RATE, obj.video_writer_output_p, obj.INITIAL_TIMEOUT);

      if ( obj.serial )
        obj.serial_result = cb();
      else
        obj.par_future = parfeval( cb, 1 );
      end

      obj.initialized = true;
    end

    function res = get_saveable_data(obj)
      wait( obj );
      res = obj.cached_result;
    end

    function res = wait(obj)
      res = [];

      if ( ~obj.initialized )
        return
      end

      if ( ~isempty(obj.serial_result) )
        % serial
        assert( isempty(obj.par_future) );
        res = obj.serial_result;
        obj.serial_result = [];
      else
        % parallel
        assert( ~isempty(obj.par_future) );
        wait( obj.par_future );

        if ( ~isempty(obj.par_future.Error) )
          warning( obj.par_future.Error.message );
        end

        try
          res = fetchOutputs( obj.par_future );
        catch err
          warning( err.message );
        end
        delete( obj.par_future );
        obj.par_future = [];
      end

      if ( ~isempty(res) )
        obj.cached_result = res;
      end
    end
    
    function shutdown(obj)
      obj.serial_result = [];

      if ( ~isempty(obj.par_future) )
        delete( obj.par_future );
      end

      obj.initialized = false;
    end

    function delete(obj)
      shutdown( obj );
    end
  end
end

function res = do_capture(frame_rate, dst_p, init_timeout)

res = [];
success = true;

% When this amount of time has elapsed with no new frames available, 
% capture will be stopped.
ACQ_TIMEOUT = 5;

[vi1, vw1, vs1] = make_components( 1, frame_rate, dst_p );
[vi2, vw2, vs2] = make_components( 2, frame_rate, dst_p );

start( vi1 );
start( vi2 );

t0 = tic();
last_t = nan;
while ( ~vi1.FramesAvailable || ~vi2.FramesAvailable )
  if ( isnan(last_t) || toc(t0) - last_t > 0.25 )
    fprintf( '\n Waiting for frames' );
    last_t = toc( t0 );
  end
  if ( toc(t0) > init_timeout )
    fprintf( 'Failed to start capturing frames within %0.3f s\n', init_timeout );
    success = false;
    break
  end
end

if ( success )
  fprintf( '\n Began' );
  
  t = tic;
  while ( true )
    drawnow;
  
    if ( vi1.FramesAvailable || vi2.FramesAvailable )
      t = tic;
    elseif ( toc(t) > ACQ_TIMEOUT )
      fprintf( '\n No frames received within %0.3f s; stopping acquisition.' ...
        , ACQ_TIMEOUT );
      break
    end
  end
end
  
stop( vi1 );
stop( vi2 );

delete( vi1 );
delete( vi2 );

if ( ~isempty(vw1) )
  release( vw1 ); 
end
if ( ~isempty(vw2) )
  release( vw2 );
end

if ( success )
  res = struct();
  res.vs1 = vs1;
  res.vs2 = vs2;
end

imaqreset;

end

function [vi1, vid_writer1, vid_sync1] = make_components(index, frame_rate, vid_p)

vi1 = videoinput( 'gentl', index );
triggerconfig( vi1, 'hardware', 'DeviceSpecific' );
% set_exposure_time_from_fps( vi1, frame_rate, 1e3 );

% video writer
vid_fname = sprintf( 'video_%d.mp4', index );

if ( isempty(vid_p) )
  vid_writer1 = [];
else
  vid_writer1 = vision.VideoFileWriter( fullfile(vid_p, vid_fname) );
  set( vid_writer1, 'FrameRate', frame_rate );
  set( vid_writer1, 'FileFormat', 'MPEG4' );
end

% vid sync
vid_sync1 = make_vid_sync();

% vi config
vi1.FramesAcquiredFcn = ...
  @(src, obj) save_images(vid_writer1, vid_fname, vid_sync1, src, obj);
vi1.FramesAcquiredFcnCount = 1;
vi1.Timeout = 30;
vi1.TriggerRepeat = inf;

end

function s = make_vid_sync()

s = ptb.Reference( struct );
s.Value.vid_time = [];
s.Value.frame_num = [];
s.Value.vid_fname = strings( 0 );

end

function save_images(vid_writer, vid_name, vid_sync, src, cb_data)   

imgs = getdata( src, src.FramesAvailable );
fprintf( '\n Writing images into %s; size: %d %d' ...
  , vid_name, size(imgs, 1), size(imgs, 2) );

if ( ~isempty(vid_writer) )
  try
    for i = 1:size(imgs, 4)
      step( vid_writer, imgs(:, :, :, i) );
    end
  catch err
    warning( err.message );
  end
end

vid_sync.Value.vid_time(end+1, :) = cb_data.Data.AbsTime;
vid_sync.Value.frame_num(end+1, 1) = cb_data.Data.FrameNumber;
vid_sync.Value.vid_fname(end+1, 1) = string( vid_name );

end

function set_exposure_time_from_fps(vid1, fps, pad_us)

src = getselectedsource( vid1 );
desired_exposure_time_us = (1 / fps) * 1e6 - pad_us;
set( src, 'ExposureTime', desired_exposure_time_us );

end
