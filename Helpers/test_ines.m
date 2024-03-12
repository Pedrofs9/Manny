data = importdata('signal.txt');


data = data.data(:,6);
t = linspace(0,length(data)/100,length(data));

thenvelopewindow=50;
[signal,~] = envelope(data, thenvelopewindow, 'rms');


th1 = triangleThreshold(signal, 5);
movement1 = (signal>th1)*max(signal);
th2 = triangleThreshold(signal, 500);
movement2 = (signal>th2)*max(signal);

% figure
% subplot(2,1,1)
% plot(t,data)
% title('EMG data from OpenSignals')
% movement = (signal>th)*max(signal);
% subplot(2,1,2)
% plot(t,signal)
% hold on
% plot(t,movement)
% title('RMS of EMG Signal')
% legend('Singal RMS', 'Classification')

figure
subplot(2,1,1)
plot(t, signal)
title('Classification with 5 bins')
hold on
plot(t, movement1)
hold on
plot(t, movement1)
subplot(2,1,2)
plot(t, signal)
title('Classification with 500 bins')
hold on
plot(t, movement2)