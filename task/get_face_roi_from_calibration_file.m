function roi = get_face_roi_from_calibration_file(calib, pad_x, pad_y)

tl = calib.keys.key__7.coordinates;
tr = calib.keys.key__9.coordinates;
bl = calib.keys.key__1.coordinates;
br = calib.keys.key__3.coordinates;

x0 = mean( [tl(1), bl(1)] );
x1 = mean( [tr(1), br(1)] );
y0 = mean( [tl(2), tr(2)] );
y1 = mean( [bl(2), br(2)] );

if ( x0 > x1 )
  t = x0;
  x0 = x1;
  x1 = t;
end

if ( y0 > y1 )
  t = y0;
  y0 = y1;
  y1 = t;
end

roi = [ x0 - pad_x * 0.5, y0 - pad_y * 0.5, x1 + pad_x * 0.5, y1 + pad_y * 0.5 ];

end