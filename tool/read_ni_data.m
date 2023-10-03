function samps = read_ni_data(data_file)

num_samples_per_channel = 5;
num_chans = 7;
samp_size = 8;

f_info = dir( data_file );
f_bytes = f_info.bytes;

assert( mod(f_bytes, num_samples_per_channel * num_chans * samp_size) == 0 ...
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

end