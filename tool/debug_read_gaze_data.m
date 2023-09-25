data_file = 'C:\Users\setup2\source\setup2_ni\data\test.dat';

num_samples_per_channel = 5;
num_chans = 6;
samp_size = 8;

f_info = dir( data_file );
f_bytes = f_info.bytes;

assert( num_samples_per_channel * num_chans * samp_size ...
  , 'Expected file size to be divisible by samples, channels and buffer size.' );

num_frames = f_bytes / (num_chans * samp_size);

fid = fopen( data_file, 'r' );
try
  samps = zeros( num_frames, num_chans );
  for i = 1:num_frames
    samps(i, :) = fread( fid, num_chans, 'double' );
  end
catch err
  warning( err.message );
end

fclose( fid );

%

figure(1); clf;
subplot( 1, 2, 1 );
plot( samps(:, 2) );  % x1
hold on;
plot( samps(:, 3) );  % x2
ylim( [-5, 5] );
subplot( 1, 2, 2 );
plot( samps(:, 4) );  % y1
hold on;
plot( samps(:, 5) );  % y2
ylim( [-5, 5] );