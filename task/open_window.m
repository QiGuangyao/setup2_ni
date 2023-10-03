function win = open_window(varargin)

defaults = struct();
defaults.screen_index = 0;
defaults.screen_rect = [0, 0, 1000, 800];
defaults.skip_sync_tests = true;
defaults.visual_debug_level = 0;

params = shared_utils.general.parsestruct( defaults, varargin );

Screen( 'Preference', 'SkipSyncTests', double(params.skip_sync_tests) );
Screen( 'Preference', 'VisualDebugLevel', double(params.visual_debug_level) );

win = ptb.Window();
win.Index = params.screen_index;
win.Rect = params.screen_rect;
win.open();

end