function [chooser_choice1, chooser_choice2] = state_choice2(...
    time_cb, loop_cb, draw_cb ...
  , chooser1_pos_cb, chooser2_pos_cb ...
  , chooser1_rects_cb, chooser2_rects_cb ...
  , chooser1_enable, chooser2_enable ...
  , chooser1_choice_time, chooser2_choice_time, state_time ...
  , varargin ...
)

defaults = struct();
defaults.on_chooser_choice1 = @() 1;
defaults.on_chooser_choice2 = @() 1;

params = shared_utils.general.parsestruct( defaults, varargin );
called_choice1_cb = false;
called_choice2_cb = false;

entry_t = time_cb();

chooser_choice1 = ChoiceTracker( entry_t, 2 );
chooser_choice2 = ChoiceTracker( entry_t, 2 );

while ( time_cb() - entry_t < state_time )
  loop_cb();

  elapsed_t = time_cb() - entry_t;
  
  if ( ~isempty(draw_cb) )
    draw_cb( elapsed_t, chooser_choice1, chooser_choice2 );
  end
  
  chooser1_xy = chooser1_pos_cb();
  chooser2_xy = chooser2_pos_cb();
  
  chooser1_rects = chooser1_rects_cb();
  chooser2_rects = chooser2_rects_cb();
  
  t = time_cb();
  
  chooser_chose1 = false;
  chooser_chose2 = false;

  if ( chooser1_enable(elapsed_t) )
    chooser_chose1 = update( ...
        chooser_choice1, chooser1_xy(1), chooser1_xy(2), t ...
      , chooser1_choice_time, chooser1_rects );
  end

  if ( ~called_choice1_cb && chooser_chose1 )
    params.on_chooser_choice1();
    called_choice1_cb = true;
  end
  
  if ( chooser2_enable(elapsed_t) )
    chooser_chose2 = update( ...
        chooser_choice2, chooser2_xy(1), chooser2_xy(2), t ...
      , chooser2_choice_time, chooser2_rects );
  end

  if ( ~called_choice2_cb && chooser_chose2 )
    params.on_chooser_choice2();
    called_choice2_cb = true;
  end
end

end