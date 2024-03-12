clear all
clc
close all
ip_address = 'localhost'; % replace with the IP address of the computer running OpenSignals
port_number = 5555; % replace with the port number configured in OpenSignals
s = tcpclient(ip_address, port_number); % create a TCP/IP object
num_bytes = 8;
set(s, 'InputBufferSize', num_bytes); % set the input buffer size to match the expected data size
fopen(s); % open the connection
<<<<<<< Updated upstream

tic
cont = true;
while cont
    data = fread(s,2,'float');
    plot(data);
    drawnow
    pause(3);
    if toc > 20
        cont = false;
    end
end
=======
write(s, 'start');
cont = true;
v = [];
buffer_size = 1024;
json_data = '';
first_json = true;


% CONFIGURAÇÃO DOS GRÁFICOS

plotTitle = 'EMG Signal';
xLabel = 'Time (s)';
yLabel = 'Voltage (mV)';

emg_data = [0 0];
time = [0 0];
figure
plotGraph1 = plot(time, emg_data, '-b');
hold on;
title(plotTitle, 'FontSize', 10);
xlabel(xLabel, 'FontSize',10);
ylabel(yLabel, 'FontSize', 10);
drawnow

th = 0.1;
tic
count = 1;
while cont && (ishandle(plotGraph1))
    chunk = read(s, buffer_size, 'uint8');
    new_char = char(chunk);
    json_data = append(json_data,new_char);
    if contains(json_data, '}}') && ~first_json

        substrings = split(json_data, '}}');
        for t=1:length(substrings)-1
            json_str = substrings(t);
            json_str = append(json_str{1},'}}');
            json_file = jsondecode(json_str);
            new_data = json_file.returnData.x98_D3_51_FD_71_08(:,7);
            emg_data(end+1:end+length(new_data)) = new_data;
        end
        json_data = substrings(end);
        json_data = json_data{1};

        time = linspace(0,toc,length(emg_data));
        set(plotGraph1, 'XData', time, 'Ydata', emg_data);
        drawnow
    end
    if contains(json_data, '}}}')
        substrings = split(json_data, '}}}');
        json_str = substrings(1);
        json_str = append(json_str{1},'}}}');
        json_data = substrings(2);
        json_data = json_data{1};

        json_file = jsondecode(json_str);
        disp(json_file)
        first_json = false;
    end
end

>>>>>>> Stashed changes
