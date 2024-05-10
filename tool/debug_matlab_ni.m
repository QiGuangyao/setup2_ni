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

%%

dst_p = 'C:\Users\chang\source\setup2_ni\data\test2.dat';

interface = NIInterface();
initialize( interface, dst_p );

t0 = tic;
pulse_t0 = tic;
while ( toc(t0) < 60 && ~ptb.util.is_esc_down )
  res = tick( interface );

  if ( 1 )
    fprintf("%0.4f, %0.4f, %0.4f | %0.4f, %0.4f, %0.4f\n", ...
      res.pupil1, res.x1, res.y1, res.pupil2, res.x2, res.y2 );
  end

  if ( 1 && toc(pulse_t0) > 2 )
    reward_t0 = tic;
    for i = 1:2
      reward_trigger( interface, i-1, 0.5 );
    end
    reward_elapsed = toc( reward_t0 );
    pulse_t0 = tic;
    fprintf( 'Reward took %0.3f(s)\n', reward_elapsed );
  end
end

delete( interface );