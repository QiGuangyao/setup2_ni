function [m1_p, m2_p] = get_latest_fv_far_plane_calibration_file_names()

fv_conf = fv.config.load();
sesh_dir = fullfile( fv_conf.PATHS.data, dsp3.datedir );
m1_dir = fullfile( sesh_dir, 'face_calibration_m1' );
m2_dir = fullfile( sesh_dir, 'face_calibration_m2' );

m1_p = get_latest_far_plane_calibration_filename( dsp3.datedir, m1_dir );
m2_p = get_latest_far_plane_calibration_filename( dsp3.datedir, m2_dir );

end

function latest_file_p = get_latest_far_plane_calibration_filename(sesh_dir, in_p)

if ( exist(in_p, 'dir') == 0 )
  latest_file_p = '';
else
  mats = shared_utils.io.findmat( in_p );
  mat_names = shared_utils.io.filenames( mats );
  mat_nums = cellfun( ...
    @(x) strrep(x, sprintf('%s-far_plane_calibration', sesh_dir), ''), mat_names, 'un', 0 );
  mat_nums = str2double( mat_nums );
  [~, latest_num] = max( mat_nums );
  latest_file_p = fullfile( in_p, sprintf('%s.mat', mat_names{latest_num}) );
end

end