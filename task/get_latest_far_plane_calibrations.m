function [m1_calib, m2_calib] = get_latest_far_plane_calibrations(varargin)

try
  [m1_calib_p, m2_calib_p] = get_latest_fv_far_plane_calibration_file_names( varargin{:} );        
catch err
  warning( err.message );
  m1_calib_p = '';
  m2_calib_p = '';
end

if ( ~isempty(m1_calib_p) )
  m1_calib = load( m1_calib_p );
else
  warning( 'Missing m1 calibration file.' );
  m1_calib = [];
end

if ( ~isempty(m2_calib_p) )
  m2_calib = load( m2_calib_p );
else
  warning( 'Missing m2 calibration file.' );
  m2_calib = [];
end

end