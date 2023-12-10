classdef ParallelErrorChecker
  methods (Static = true)
    function clear_error(file_prefix)
      remove_existing_files( file_prefix );
    end

    function tf = check_log_error(file_prefix)
      msg = ParallelErrorChecker.get_error( file_prefix );
      tf = false;
      if ( ~isempty(msg) )
        warning( msg );
        tf = true;
      end
    end

    function tf = has_error(file_prefix)
      msg = ParallelErrorChecker.get_error( file_prefix );
      tf = ~isempty( msg );
    end

    function msg = get_error(file_prefix)
      msg = [];
      err_dir = save_dir( file_prefix );
      if ( ~exist(err_dir, 'dir') )
        return
      end

      if ( ~exist(err_mark_p(file_prefix), 'file') )
        return
      end

      try
        msg = fileread( err_text_p(file_prefix) );
      catch err
        warning( err.identifier ...
          , 'Failed to read file with message: %s.', err.message );
      end
    end

    function set_error(file_prefix, err_msg)
      validateattributes( file_prefix, {'char', 'string'} ...
        , {'scalartext'}, mfilename, 'file_prefix' );
      validateattributes( err_msg, {'char', 'string'} ...
        , {'scalartext'}, mfilename, 'file_prefix' );

      err_dir = save_dir( file_prefix );
      if ( ~exist(err_dir, 'dir') )
        mkdir( err_dir );
      end

      % first write error text to a file.
      try_write( err_text_p(file_prefix), err_msg );
      % mark that an error has occurred
      try_write( err_mark_p(file_prefix), '1' );
    end
  end
end

function try_write(fp, contents)

fid = fopen( fp, 'w' );
if ( fid == -1 )
  warning( 'Failed to open file: "%s".', fp );
  return
end

fwrite( fid, contents );
fclose( fid );

end

function p = err_mark_p(file_prefix)
p = fullfile( save_dir(file_prefix), 'error_mark.txt' );
end

function p = err_text_p(file_prefix)
p = fullfile( save_dir(file_prefix), 'error_text.txt' );
end

function p = save_dir(file_prefix)
p = fullfile( tempdir, file_prefix );
end

function remove_existing_files(file_prefix)

tmp_dir = save_dir( file_prefix );
if ( exist(tmp_dir, 'dir') > 0 )
  rmdir( tmp_dir, 's' );
end

end