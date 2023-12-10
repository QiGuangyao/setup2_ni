%{

10/6/23


Eye calibration and face calibration:
-------------

from: "C:\Users\setup2\source\fv\script"s

general:
  1. eye calibration
    run fv_manual_eyelink_calibrate_m1.m
    run fv_manual_eyelink_calibrate_m2.m
  2. face calibration
    mornitor go down
    run fv_run_face_calibration_m1
    run fv_run_face_calibration_m2

in detail:
  1. activate eyelink 1 connection
  2. m1 eye calibration
  3. activate eyelink 2 connection
  4. m2 eye calibration
  5. mornitor go down
  6. activate eyelink 1 connection
  7. m1 face calibration
  8. activate eyelink 2 connection
  9. m2 face calibration



C:\Users\setup2\source\calibration\script
  run_calibration.m

after face calibration files
'C:\Users\setup2\source\gaze_following\data\face_calibration'


Running the task:
--------------

(0). If the task computer is on and the NeuroPixels PCIe chassis is off, shut
  down the task computer. When the task computer is fully powered off, 
  turn on the NeuroPixels PCIe chassis. Then turn on the task computer.

  Similarly, at the end of the recording session, shut down the computer
  before turning off the NeuroPixels PCIe chassis.

1. If not already open, open the Open-ephys GUI. Take note of the command
  window that appears -- it should indicate that one or more headstages are
  found on ports (1-4). This is important since it won't be possible to
  start recording if zero headstages are detected.

2. Open SpinView and verify that two cameras are detected. For each camera,
  click on the camera and then click on the GPIO tab towards the bottom of
  the GUI. Verify that the "Trigger Selector" is set to "FrameStart", that 
  "Trigger Mode" is "On", and that "Trigger Source" is "Line 3".

3. Close the SpinView GUI -- this is necessary, since otherwise MATLAB
  won't be able to read from the cameras.

4. If not already open, open MATLAB. The task script is called `run_gf.m`.
  In this script, you can change timing, stimulus, and other task-condition
  parameters. The main interface class is called `TaskInterface`; you can
  edit this class file (i.e., `TaskInterface.m`) to bypass hardware for
  debugging purposes.

5. When ready to begin a run, click the play button in the Open-Ephys GUI
  and then the record button. *It is essential that recording begins in the
  Open-Ephys GUI before the task starts*. 

6. Run the task by clicking the play button in MATLAB with the `run_gf.m`
  script open.

Stopping the task:
--------------

1. Hold the escape key until the MATLAB command window prints "Shutting
  down ...". It will take up to a minute for the task to finish shutting
  down, and it will indicate when it is done. *It is critical that the task
  is stopped before the Open-Ephys GUI recording*.

2. Once the task is stopped, you can stop recording on the Open-Ephys GUI.

A note on data:
--------------

Each run of the task data will be saved in a new folder under the directory
(C:\Users\setup2\source\setup2_ni\task\data). In this folder, there will be
the NI-Daq data (ni.bin), the task data (task_data.mat) and the two videos
(video_1.mp4 and video_2.mp4)

The neuro-pixel data are saved a bit differently -- each time you open the
GUI, a new recording session folder will be created. Subsequently, every
start/stop recording will generate an "experiment" directory inside this
folder. So, for example, if you open the GUI and start/stop recording 3
times, you will have one session folder, within which are 3 experiment
folders (experiment 1, 2, 3). 

The current root neuro pixel data directory is 
(C:\Users\setup2\Documents\Open Ephys\data\test)

A note on synchronization: 
--------------

In order to synchronize data from the NI-Daq card (gaze data) with the
task, either the videos must be enabled + recording, or the Open-Ephys
GUI must be enabled + recording, or both. I.e., if the videos are not 
recorded and the open-ephys GUI is not recording, then it is not currently 
possible to synchronize the NI-Daq data with the task.

Note that you can and should validate that the NI data, videos, and neuro
pixel data were properly synchronized via the NI-Daq's synchronization
pulse for a given run. You can run the script `run_validate_video_sync` to
load the latest sessions' worth of data and verify that the correct number
of synchronization pulses (and video frames) were recorded from each 
hardware source.

%}