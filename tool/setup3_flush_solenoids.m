interface = Setup3RewardInterface();
initialize( interface );

channels = 0:1;
channels = 0;
dur_s = 30;
flush_sync( interface, dur_s, channels );

delete( interface );