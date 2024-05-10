function calchunk()


num_chunks = 5;
min_space_between_targets = 2;
width_frac = 0.75;

[m2_left_chunk, m2_right_chunk] = choose_chunks( num_chunks, min_space_between_targets );

m2_right_chunk
m2_left_chunk

%   m1_left_chunk = (num_chunks - m2_left_chunk) + 1;
%   m1_right_chunk = (num_chunks - m2_right_chunk) + 1;


m1_left_chunk = (num_chunks - m2_right_chunk) + 1;
m1_right_chunk = (num_chunks - m2_left_chunk) + 1;

m1_left_chunk
m1_right_chunk

win_m1 = open_window( 'screen_index', 1, 'screen_rect', [] );% 4 for M1 
win_m2 = open_window( 'screen_index', 2, 'screen_rect', [] );% 1 for M2
[m2_left, m2_right] = left_right_components( get(win_m2.Rect), width_frac, m2_left_chunk, m2_right_chunk, num_chunks );
[m1_left, m1_right] = left_right_components( get(win_m1.Rect), width_frac, m1_left_chunk, m1_right_chunk, num_chunks );

m2_left,m2_right
m1_left,m1_right


close all
function [left, right] = choose_chunks(num_chunks, min_space_between_targets)
  left = randi( num_chunks - min_space_between_targets );
  right = randi( [left + min_space_between_targets, num_chunks] );
  if ( 1 )
    while ( left == 3 || right == 3 )
      [left, right] = choose_chunks( num_chunks, min_space_between_targets );
    end
  end
end

function r = recenter_on_positions(r, left, right)
  wl = diff( r{1}([1, 3]) );
  wr = diff( r{2}([1, 3]) );
  r{1}(1) = left - wl * 0.5;
  r{1}(3) = left + wl * 0.5;
  r{2}(1) = right - wr * 0.5;
  r{2}(3) = right + wr * 0.5;
end

function [left, right] = left_right_components(rect, w_frac, left_chunk, right_chunk, num_chunks)
  width = rect(3) - rect(1);
  off = width * (1 - w_frac) * 0.5;
  left = off + (left_chunk-1) / (num_chunks-1) * width * width_frac;
  right = off + (right_chunk-1) / (num_chunks-1) * width * width_frac;
end
end