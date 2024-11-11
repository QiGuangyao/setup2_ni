data_file = 'D:\tempData\data\20-Jun-2024 15_51_45\ni.bin';

samps = read_ni_data( data_file );

%

figure(1); clf;
subplot( 1, 3, 1 );
plot( samps(:, 2) );  % x1
hold on;
plot( samps(:, 3) );  % x2
title( 'm1' );
ylim( [-5, 5] );
subplot( 1, 3, 2 );
plot( samps(:, 4) );  % y1
hold on;
plot( samps(:, 5) );  % y2
title( 'm2' );
ylim( [-5, 5] );
% sync
subplot( 1, 3, 3 );
plot( samps(:, 7) );
title( 'sync' );
ylim( [-5, 5] );