<<<<<<< Updated upstream
warning('off', 'all');

myInstr = instrhwinfo('Bluetooth');
fs = 100;
amp = 1;
filterOrder = 6;
coFreq = 20;
wn = 45/(fs/2);
b = Bitalino('btspp://98D351FD7108', fs);
b.startBackground

serialportlist("available")
%port = serialport("COM10", 9600);
%configureTerminator(port, "LF");
%flush(port);
%fopen(port);
%fscanf(port)
%data = data.data(:,6);
%t = 1:length(data);
acquired_data = [];
x = [];
rms_live = [];
th = 0.04;
led_mode = [];

time_limit = 30;
time = 0;
delay = 1;
disp("Begin")
tic
while time <= time_limit
    data = b.read;
    EMG_raw = data(:,7);
    EMG_raw = EMG_raw .* amp;
    EMG_raw = abs(EMG_raw);
    EMG_raw = highpass(EMG_raw,5,fs);
    EMG_raw = lowpass(EMG_raw, 45, fs);
    %[bb,a] = butter(filterOrder, wn, 'low');
    %EMG_raw = filtfilt(bb,a,EMG_raw);
    window_size = 50;
    EMG_raw = movmean(EMG_raw, window_size);

    x(end+1:end+length(EMG_raw)) = EMG_raw;
    value = rms(x);
    rms_live(end+1) = value;
    new_th = triangleThreshold(rms_live, 24);
    if new_th > th
        fprintf('New threshold selected: %d\n', new_th);
        th = new_th;
    end
    if value>th
        fprintf('Above threshold value found: %d\n', value);
        led_mode(end+1) = 1;
        %write(port, "U", "char");         
    else 
        %write(port, "S", "char");
        led_mode(end+1) = 0;
    end
    pause(delay);
    time = toc;
    fprintf('Time: %f\n', time);
end

b.stopBackground;
delete(b)
%fclose(port);
%clear port

thenvelopewindow=50;
[rms_signal,maxChunkTime] = envelope(x, thenvelopewindow, 'rms');

th = triangleThreshold(rms_signal, 24);
action = (rms_signal>th).*max(rms_signal);
led_mode = led_mode.*max(rms_signal);
t = linspace(0, time, length(x));
t_1 = 1:length(rms_signal);

figure
plot(t,x,t,rms_signal)

=======

myInstr = instrhwinfo('Bluetooth');
fs = 100;
amp = 1;
filterOrder = 6;
coFreq = 20;
wn = 45/(fs/2);
b = Bitalino('btspp://98D351FD7108', fs);
b.startBackground

serialportlist("available")
%port = serialport("COM10", 9600);
%configureTerminator(port, "LF");
%flush(port);
%fopen(port);
%fscanf(port)
%data = data.data(:,6);
%t = 1:length(data);
acquired_data = [];
x = [];
rms_live = [];
th = 0.04;
led_mode = [];

time_limit = 30;
time = 0;
delay = 1;
disp("Begin")
tic
while time <= time_limit
    data = b.read;
    EMG_raw = data(:,7);
    EMG_raw = EMG_raw .* amp;
    EMG_raw = abs(EMG_raw);
    EMG_raw = highpass(EMG_raw,5,fs);
    EMG_raw = lowpass(EMG_raw, 45, fs);
    %[bb,a] = butter(filterOrder, wn, 'low');
    %EMG_raw = filtfilt(bb,a,EMG_raw);
    window_size = 50;
    EMG_raw = movmean(EMG_raw, window_size);

    x(end+1:end+length(EMG_raw)) = EMG_raw;
    value = rms(x);
    rms_live(end+1) = value;
    new_th = triangleThreshold(rms_live, 24);
    if new_th > th
        fprintf('New threshold selected: %d\n', new_th);
        th = new_th;
    end
    if value>th
        fprintf('Above threshold value found: %d\n', value);
        led_mode(end+1) = 1;
        %write(port, "U", "char");         
    else 
        %write(port, "S", "char");
        led_mode(end+1) = 0;
    end
    pause(delay);
    time = toc;
    fprintf('Time: %f\n', time);
end

b.stopBackground;
delete(b)
%fclose(port);
%clear port

thenvelopewindow=50;
[rms_signal,maxChunkTime] = envelope(x, thenvelopewindow, 'rms');

th = triangleThreshold(rms_signal, 24);
action = (rms_signal>th).*max(rms_signal);
led_mode = led_mode.*max(rms_signal);
t = linspace(0, time, length(x));
t_1 = 1:length(rms_signal);

figure
plot(t,x,t,rms_signal)

>>>>>>> Stashed changes
t_1 = linspace(0, time, length(rms_live));
figure
plot(t_1,rms_live)