% *HANDYBOT* 
%
%     Developers: Carolina Albuquerque, David Machado, José Almeida
%     Medical Bionics and Robotics Course, FEUP 2023
%
%     This code allows to control the SUNFOUNDER Robot Arm using muscular
%     activity from the user.
%     The robot is to be connected via serial port, while the EMG data is
%     obtained from OpenSignals via TCP/IP port. At least one Bitalino
%     board should be connected to OpenSignals in order to run this program

clear all; clc; close all;
warning('off', 'all');

%% CONNECTION TO OPENSIGNALS TCP/IP PROTOCOL

ip_address = 'localhost'; % IP address of the computer running OpenSignals
port_number = 5555; % Port number configured in OpenSignals
s = tcpclient(ip_address, port_number);
num_bytes = 9999;
fopen(s);
write(s, 'start'); % Signals OpenSignals that MatLab is ready to recieve data
disp("connection done")

%% CONNECTION TO ROBOT ARM

serialportlist("available")
port = serialport("/dev/ttyACM0", 9600); % Change to the correct COM Port
configureTerminator(port, "LF");
flush(port);
fopen(port);
fscanf(port);

%% ACQUISITON PARAMETERS AND VARIABLES

samp_freq = 100;
buffer_size = 1024;
used_channels = [];

first_json = true;
k=0;
cont = true;
points = 0;
current_state = 0;
with_th = false;

json_data = '';
emg_data = [0 0;0 0;0 0];
time = [0 0];
th = [];

%% PLOTS CONFIGURATION

plotTitle = 'EMG Signal';
xLabel = 'Time (s)';
yLabel = 'Voltage (mV)';
legend1 = 'Channel 1';
legend2 = 'Channel 2';
legend3 = 'Channel 3';

figure(1)
subplot(3,1,1);
channel1plot = plot(time, emg_data(1,:), '-b');
title(plotTitle, 'FontSize', 10);
legend(legend1);
ylim([-2 2]);
xlabel(xLabel, 'FontSize',10);
ylabel(yLabel, 'FontSize', 10);

subplot(3,1,2);
channel2plot = plot(time, emg_data(2,:), '-r');
legend(legend2);
ylim([-2 2]);
xlabel(xLabel, 'FontSize',10);
ylabel(yLabel, 'FontSize', 10);

subplot(3,1,3);
channel3plot = plot(time, emg_data(3,:), '-g');
legend(legend3);
ylim([-2 2]);
xlabel(xLabel, 'FontSize',10);
ylabel(yLabel, 'FontSize', 10);



%% MAIN LOOP

pause(1)
tic
oldStrToSend = "";
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
        end
    end

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
        tic
    end
    
    new_k = floor(length(emg_data(1,:))/50);
    if new_k > k && with_th
        k = new_k;
        strToSend = "";
        for ch=1:size(emg_data,1) 
            x = emg_data(ch, end-50:end);
            value = rms(x);
            if value>th(ch)
                 strToSend = strToSend + "U;";
                 current_state = 1;
            else
                 strToSend = strToSend + "S;";
                 current_state = 0;
            end
        end

        strToSend = strToSend+"#";
        if strToSend ~= oldStrToSend
            write(port, strToSend, "string");
            disp(strToSend)
            oldStrToSend = strToSend;
        end
    end

    if length(emg_data(1,:))>30*100
            for ch=1:size(emg_data,1)
                thenvelopewindow=50;
                [signal,~] = envelope(emg_data(ch,:), thenvelopewindow, 'rms');
                new_th = triangleThreshold(signal, 24);
                if ~with_th
                    th(ch) = new_th;
                elseif new_th > 0.7*th(ch) && with_th
                    th(ch) = new_th;
                end

            end
            with_th = true;
            emg_data = emg_data(:,end-15*100:end);
            new_k = 0;
    end

    if ~ishandle(channel1plot)
        cont = false;
    end
    disp(ishandle(channel3plot))
    pause(0.01)
end

%% END PROGRAM

clear port
clear s