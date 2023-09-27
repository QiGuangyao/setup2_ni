function validate_npxi_video_sync(vid_file1, vid_file2, npxi_data_file)

vid1 = VideoReader( vid_file1 );
vid2 = VideoReader( vid_file2 );

nf1 = vid1.NumFrames;
nf2 = vid2.NumFrames;

assert( nf1 == nf2 );

%%

dat_f = npxi_data_file;

file_info = dir( dat_f );
file_bytes = file_info.bytes;

data_type = 'int16';
bits_per_samp = 16;
bytes_per_samp = bits_per_samp / 8;

num_chans = 385;
num_frames = file_bytes / bytes_per_samp / num_chans;
assert( floor(num_frames) == num_frames );

fid = fopen( dat_f, 'r' );
try
  samps = zeros( num_frames, num_chans, data_type );
  for i = 1:num_frames
    samps(i, :) = fread( fid, num_chans, data_type );
  end
catch err
  warning( err.message );
end

fclose( fid );

samps = double( samps );

%%

sync_chan = samps(:, end);
is_pos = sync_chan > 0.99;
[isles, durs] = shared_utils.logical.find_islands( is_pos );
assert( numel(isles) == nf1 * 2 );

fprintf( '\n ok ! \n\n' );