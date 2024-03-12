clc; clear;
myInstr = instrhwinfo('Bluetooth');
fs = 100;
amp = 100;
filterOrder = 4;
coFreq = 20;
b = Bitalino('btspp://98D351FD7108', fs);
b.startBackground

disp("Begin")
pause(15);
% The following shows which columns correlate to each channel.
% 1             2   3   4   5   6   7   8   9   10  11
% packetNumber  I0  I1  I2  I3  A0  A1  A2  A3  A4  A5
data = b.read;
EMG_raw = data(:,7);
delete(b)

figure;
EMG_raw = EMG_raw .* amp;
EMG_raw = highpass(EMG_raw,10,fs);
EMG_raw = lowpass(EMG_raw, 45, fs);
[b,a] = butter(filterOrder, coFreq/(fs/2));
EMG_raw = filtfilt(b,a,EMG_raw);
window_size = 50;
EMG_raw = movmean(EMG_raw, window_size);
t = linspace(0, 1, length(EMG_raw));
plot(t,EMG_raw);