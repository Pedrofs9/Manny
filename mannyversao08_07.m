%% MANYYMAOZINHAS

% Muscles
% Ch1 -> EPB 
% Ch2 -> ED
% Ch3 -> FDP
% Ch4 -> FPL

% Positions
% Rock, Paper, Scissor

%% CONNECTION TO OPENSIGNALS TCP/IP PROTOCOL
clc; clear all; close all;

ip_address = 'localhost'; % IP address of the computer running OpenSignals
port_number = 5555; % Port number configured in OpenSignals
s = tcpclient(ip_address, port_number);
num_bytes = 9999;
fopen(s);
write(s, 'start'); % Signals OpenSignals that MatLab is ready to recieve data
disp("connection done")

%% CONNECTION TO ROBOT ARM

% serialportlist("available")
% port = serialport("COM3", 9600); % Change to the correct COM Port
% configureTerminator(port, "LF");
% flush(port);
% fopen(port);
% fscanf(port);

%% ACQUISITON PARAMETERS AND VARIABLES

samp_freq = 100;
buffer_size = 1024;
used_channels = [];

first_json = true;
k=0;
cont = true;
points = 0;
current_state = 0;
with_th = 0;

json_data = '';
emg_data = [0 0;0 0;0 0; 0 0];
time = [0 0];
th = [];

%%
figure(2)
figTitle = "Activated Muscles";
textPos = [0.2 0 0.9 0.1]; 
textString = 'Please follow the guidelines';
textAnnotation = annotation('textbox',...
                           'Position', textPos,...
                           'String', textString,...
                           'FontSize', 14,...
                           'EdgeColor', 'none');  % Remove textbox border


subplot(2,2,1)
title("Muscle 1")
m1 = rectangle('Position', [0 0 2 2],'Curvature', [0 0], 'FaceColor', "white");
axis square
axis off

subplot(2,2,2)
title("Muscle 2")
m2 = rectangle('Position', [0 0 2 2],'Curvature', [0 0], 'FaceColor', "white");
axis square
axis off

subplot(2,2,3)
title("Muscle 3")
m3 = rectangle('Position', [0 0 2 2],'Curvature', [0 0], 'FaceColor', "white");
axis square
axis off

subplot(2,2,4)
title("Muscle 4")
m4 = rectangle('Position', [0 0 2 2],'Curvature', [0 0], 'FaceColor', "white");
axis square
axis off

mscl = [m1, m2, m3, m4];
%% PLOTS CONFIGURATION

plotTitle = 'EMG Signal';
xLabel = 'Time (s)';
yLabel = 'Voltage (mV)';
legend1 = 'Channel 1';
legend2 = 'Channel 2';
legend3 = 'Channel 3';
legend4 = 'Channel 4';

figure(3)
subplot(4,1,1);
channel1plot = plot(time, emg_data(1,:), '-b');
title(plotTitle, 'FontSize', 10);
legend(legend1);
ylim([-2 2]);
xlabel(xLabel, 'FontSize',10);
ylabel(yLabel, 'FontSize', 10);

subplot(4,1,2);
channel2plot = plot(time, emg_data(2,:), '-r');
legend(legend2);
ylim([-2 2]);
xlabel(xLabel, 'FontSize',10);
ylabel(yLabel, 'FontSize', 10);

subplot(4,1,3);
channel3plot = plot(time, emg_data(3,:), '-g');
legend(legend3);
ylim([-2 2]);
xlabel(xLabel, 'FontSize',10);
ylabel(yLabel, 'FontSize', 10);

subplot(4,1,4);
channel4plot = plot(time, emg_data(4,:), '-g');
legend(legend4);
ylim([-2 2]);
xlabel(xLabel, 'FontSize',10);
ylabel(yLabel, 'FontSize', 10);

%% RECEIVE FIRST JSON

oldStrToSend = "";
while first_json 
    chunk = read(s, buffer_size, 'uint8');
    new_char = char(chunk);
    json_data = append(json_data,new_char);

    % this is the first json
    if contains(json_data, '}}}')
        disp("first json")
        substrings = split(json_data, '}}}');
        json_str = substrings(1);
        json_str = append(json_str{1},'}}}');
        json_data = substrings(2);
        json_data = json_data{1};
        
        json_file = jsondecode(json_str);
        available_devices = fieldnames(json_file.returnData);
        
        for i=1:length(available_devices)
            num_channels = length(json_file.returnData.(available_devices{i}).channels);
            used_channels(i) = num_channels;
        end

        emg_data = zeros(sum(used_channels), 2);
        rms_signal = zeros(sum(used_channels), 2);
        first_json = false;
        disp(used_channels)
    end
end

n_channels = sum(used_channels);

%% LOOP FOR SETTING THE THRESHOLDS

% Rock, Paper, Scissor
th = zeros(n_channels, 3); %Nchannels x NPositions
signal_view = zeros(n_channels,3,1);
peaks_view = zeros(n_channels,3,1);
for pos=1:3
    disp("Try Position")
    setting_thr = true;
    current_size = 0;
    emg_data = zeros(n_channels, 2);
    while setting_thr
        chunk = read(s, buffer_size, 'uint8');
        new_char = char(chunk);
        json_data = append(json_data,new_char);

        if contains(json_data, '}}') && ~first_json
            substrings = split(json_data, '}}');
    
            for t=1:length(substrings)-1
                json_str = substrings(t);
                json_str = append(json_str{1},'}}');
    
                json_file = jsondecode(json_str);
                
                current_size = length(emg_data(1,:));
                channel = 1;
    
                for i = 1:length(available_devices)
                    for k = used_channels(i)-1:-1:0
                        new_data = json_file.returnData.(available_devices{i})(:, end-k);
                        emg_data(channel, current_size+1:current_size+length(new_data)) = new_data;
                        channel = channel + 1;
                    end 
                end
            end

            if current_size > 15*samp_freq
                for channel = 1:n_channels
                    thenvelopewindow=50;
                    [signal,~] = envelope(emg_data(channel,:), thenvelopewindow, 'rms');
                    %signal_view(channel,pos,1:length(signal)) = signal;
                    [peak_values,loc] = findpeaks(signal,'MinPeakDistance',1*samp_freq);
                    %peaks_view(channel,pos,1:length(peak_values)) = loc;
                    % num_peaks = length(loc);
                    if length(peak_values) > 0
                    %     peak_values = zeros(1, num_peaks);
                    %     for l = 1:num_peaks
                    %         peak_start = max(1, loc(l) - samp_freq);
                    %         peak_end = min(length(signal), loc(l) + samp_freq);
                    %         chk_signal = signal(peak_start:peak_end);
                    %         peak_values(l) = max(chk_signal);
                    %     end
                        sorted_peaks = sort(peak_values);
                        if sorted_peaks(end-1)>0
                            th_tmp = sorted_peaks(end-1);
                        else
                            th_tmp = sorted_peaks(end);
                        end
                        thr(channel,pos) = th_tmp;
                    else
                        thr(channel,pos) = -100;
                    end
                    
                end
                setting_thr = false;
                emg_data = emg_data(:,end);
            end

            json_data = substrings(end);
            json_data = json_data{1};
        end
    end
end

% Set the thresholds

th_epb = 0.75*thr(1,2);
th_ed = 0.85*min(thr(2,2:3));
th_fdp = 0.85*thr(3,1);
th_epl = 0.75*min(thr(4,1),thr(4,3));

th = [th_epb, th_ed, th_fdp, th_epl];

%% MAIN LOOP

emg_data = zeros(n_channels, 2);
rms_signal = zeros(n_channels, 2);
tic
while cont
    chunk = read(s, buffer_size, 'uint8');
    new_char = char(chunk);
    json_data = append(json_data,new_char);

    if contains(json_data, '}}') && ~first_json
        substrings = split(json_data, '}}');

        for t=1:length(substrings)-1
            json_str = substrings(t);
            json_str = append(json_str{1},'}}');

            json_file = jsondecode(json_str);
            
            current_size = length(emg_data(1,:));
            channel = 1;

            for i = 1:length(available_devices)
                for k = used_channels(i)-1:-1:0
                    new_data = json_file.returnData.(available_devices{i})(:, end-k);
                    emg_data(channel, current_size+1:current_size+length(new_data)) = new_data;
                    channel = channel + 1;
                end 
            end
        end
        json_data = substrings(end);
        json_data = json_data{1};
        
        if ishandle(channel1plot)
            time = linspace(0,toc,length(emg_data(1,:)));
            set(channel1plot, 'XData', time, 'Ydata', emg_data(1,:));
            set(channel2plot, 'XData', time, 'Ydata', emg_data(2,:));
            set(channel3plot, 'XData', time, 'Ydata', emg_data(3,:));
            set(channel4plot, 'XData', time, 'Ydata', emg_data(4,:));
        end
    end
    
    new_k = floor(length(emg_data(1,:))/50);
    if new_k > k
        k = new_k;
        strToSend = "";
        for ch=1:size(emg_data,1) 
            x = emg_data(ch, end-50:end);
            value = rms(x);
            if value>th(ch)
                 strToSend = strToSend + "U;";
                 set(mscl(ch), 'FaceColor', "green");
            else
                 strToSend = strToSend + "S;";
                 set(mscl(ch), 'FaceColor', "red");
            end
        end

        strToSend = strToSend+"#";
        if strToSend ~= oldStrToSend
            %write(port, strToSend, "string");
            %disp(strToSend)
            oldStrToSend = strToSend;
            % if strToSend == "S;S;U;U;#"
            %     disp("Pedra")
            % elseif strToSend == "U;U;S;S;#"
            %     disp("Papel")
            % elseif strToSend == "S;U;S;U;#"
            %     disp("Tesoura")
            % end
            disp(strToSend)
        end
    end

    % if length(emg_data(1,:))>45*samp_freq && with_th<3
    %     with_th = with_th +1;
    %     for ch=1:size(emg_data,1)
    %         thenvelopewindow=50;
    %         [signal,~] = envelope(emg_data(ch,:), thenvelopewindow, 'rms');
    %         new_th = 0.8*triangleThreshold(signal, 24);
    %         if ~with_th
    %             th(with_th,ch) = new_th;
    %         %elseif new_th > 0.7*th(ch) && with_th
    %         %    th(ch) = new_th;
    %         end
    %     end
    %     emg_data = emg_data(:,end);
    %     disp("Th: " + th(end,:))
    %     disp("moviment " + with_th + " was set")
    % end

    if ~ishandle(channel1plot)
        cont = false;
    end
    pause(0.01)
end

%% END PROGRAM

clear port
clear s