function xy = convert_m2_gaze_position_to_pixels(gaze_coord_transform, xy)

[mx, my] = gaze_coord_transform.scale_coords_m2( xy(:, 1), xy(:, 2) );
xy = reshape( [mx(:), my(:)], size(xy) );

end