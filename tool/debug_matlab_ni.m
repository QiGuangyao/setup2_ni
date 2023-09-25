dst_p = 'C:\Users\setup2\source\setup2_ni\data\test2.dat';

ni_mex( uint32(0), dst_p );

t0 = tic;
while ( toc(t0) < 20 )
  res = ni_mex( uint32(1) );
  fprintf("%0.4f, %0.4f, %0.4f | %0.4f, %0.4f, %0.4f\n", ...
    res.pupil1, res.x1, res.y1, res.pupil2, res.x2, res.y2 );
end

ni_mex( uint32(3) );