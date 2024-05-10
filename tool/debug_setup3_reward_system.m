comm = serial_comm.SerialManagerPaired( 'COM5', struct(), {'A', 'B'}, 'slave' );

%%

comm.start()

%%

comm.reward( 'A', 500 );

%%

comm.close();