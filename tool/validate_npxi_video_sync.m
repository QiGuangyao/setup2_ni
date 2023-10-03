function validate_npxi_video_sync(vid_file1, vid_file2, ni_file, npxi_data_file)

vid1 = VideoReader( vid_file1 );
vid2 = VideoReader( vid_file2 );

nf1 = vid1.NumFrames;
nf2 = vid2.NumFrames;

assert( nf1 == nf2 );

%%  npxi

npxi_samps = read_npxi_samples( npxi_data_file );
sync_chan = npxi_samps(:, end);
is_pos = sync_chan > 0.99;
[npxi_isles, npxi_durs] = shared_utils.logical.find_islands( is_pos );
assert( numel(npxi_isles) == nf1 * 2 || numel(npxi_isles) == nf1 * 2 - 1 ...
  , ['Mismatch between # neuropix sync pulses and video frames: ' ...
  , '%d sync pulses; %d frames'], numel(npxi_isles), nf1 * 2 ...
);

fprintf( '\n npxi: ok (%d) \n\n', numel(npxi_isles) );

%%  ni

ni_samps = read_ni_data( ni_file );
ni_above_thresh = ni_samps(:, 7) > 4.7;
[ni_isles, ~] = shared_utils.logical.find_islands( ni_above_thresh );
assert( numel(ni_isles) == nf1 * 2 || numel(ni_isles) == nf1 * 2 - 1 ...
  , ['Mismatch between # ni sync pulses and video frames: ' ...
  , '%d sync pulses; %d frames'], numel(ni_isles), nf1 * 2 ...
);

fprintf( '\n ni: ok (%d) \n\n', numel(ni_isles) );

end