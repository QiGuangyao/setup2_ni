function ni_t = transform_ni_clock_to_matlab_clock(...
  ni_sync_channel, vid_ts, clock_t0, extrapolate)

FS = 1e3; % ni sample rate

validateattributes( ni_sync_channel, {'double'}, {'vector'}, mfilename, 'ni_sync_channel' );
validateattributes( vid_ts, {'datetime'}, {}, mfilename, 'vid_ts' );
validateattributes( clock_t0, {'datetime'}, {}, mfilename, 'clock_t0' );

if ( nargin < 4 )
  extrapolate = false;
end

is_pos = ni_sync_channel > 0.99;
[npxi_isles, npxi_durs] = shared_utils.logical.find_islands( is_pos );

sync_ts = npxi_isles(1:2:end);
sync_ts = sync_ts(1:size(vid_ts, 1));

% clock_t0 is the canonical t0 for task events
vid_t_offset = vid_ts - clock_t0;
sec_offset = seconds( vid_t_offset );

ni_t = nan( numel(ni_sync_channel), 1 );
for i = 1:numel(sync_ts)-1
  i0 = sync_ts(i);
  i1 = sync_ts(i + 1);
  sync_t0 = sec_offset(i);
  sync_t1 = sec_offset(i + 1);
  num_points = i1 - i0 + 1;
  sync_t = linspace( sync_t0, sync_t1, num_points );
  ni_t(i0:i1) = sync_t;
end

if ( extrapolate )
  % assign (approximate) timestamps to periods of the NI data that precede
  % (pre) the first synch pulse and follow (post) the last. these 
  % timestamps assume a constant sample rate of `FS`.
  num_pre = sync_ts(1);
  extrap_pre = sec_offset(1) - (0:num_pre-1)/FS;
  ni_t(1:sync_ts(1)) = fliplr( extrap_pre );  
  
  num_post = numel( ni_sync_channel ) - sync_ts(end) + 1;
  extrap_post = sec_offset(end) + (0:num_post-1)/FS;
  ni_t(sync_ts(end):end) = extrap_post;
end

end