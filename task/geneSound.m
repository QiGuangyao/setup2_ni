clear;
clc;
% sca;

InitializePsychSound;

% Open Psych-Audio port
smapleFreq = 48000;
pahandle = PsychPortAudio('Open', [], 1, 1, smapleFreq, 2);

% Set the volume
PsychPortAudio('Volume', pahandle, 2);

% Make a beep which we will play back to the user
dura = 1;%secs
frequency = 500;%Hz %1250 for low/ 2500 for high
[myBeep, samplingRate] = MakeBeep(frequency, dura, smapleFreq);
PsychPortAudio('FillBuffer', pahandle, [myBeep; myBeep]);

% Show audio playback
PsychPortAudio('Start', pahandle, 1, 0, 1);
a1 = GetSecs;
[startTime, endPositionSecs, xruns, estStopTime] = PsychPortAudio('Stop', pahandle, 1, 1);
a2 = GetSecs;
a2-a1
% Close the audio device
PsychPortAudio('Close', pahandle);

% save sound data
filename = ['lowSound',num2str(frequency),'hz','.wav'];
audiowrite(filename, myBeep, smapleFreq)
% audiowrite('NameOfWavFile.wav', myBeep, smapleFreq);
