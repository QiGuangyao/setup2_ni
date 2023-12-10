function roi = get_eye_roi_from_calibration_file(calib, pad_x, pad_y)

eye_l = calib.keys.key__4.coordinates;
eye_r = calib.keys.key__6.coordinates;

mid_y = mean( [eye_l(2), eye_r(2)] );
y0 = mid_y - pad_y * 0.5;
y1 = mid_y + pad_y * 0.5;

x0 = eye_l(1) - pad_x * 0.5;
x1 = eye_r(1) + pad_x * 0.5;

roi = [ x0, y0, x1, y1 ];

end