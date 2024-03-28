import socket
import serial
import json
import numpy as np
import matplotlib.pyplot as plt
from time import time, sleep
from scipy.signal import hilbert

# CONNECTION TO OPENSIGNALS TCP/IP PROTOCOL
ip_address = 'localhost'  # IP address of the computer running OpenSignals
port_number = 5555  # Port number configured in OpenSignals
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((ip_address, port_number))
s.sendall(b'start')  # Signals OpenSignals that Python is ready to receive data
print("connection done")

# CONNECTION TO ROBOT ARM
port = serial.Serial('/dev/ttyACM0', 9600)  # Change to the correct COM Port
port.reset_input_buffer()

# ACQUISITION PARAMETERS AND VARIABLES
samp_freq = 100
buffer_size = 1024
used_channels = []

first_json = True
k = 0
cont = True
points = 0
current_state = 0
with_th = False

json_data = ''
emg_data = np.zeros((3, 2))
time = np.zeros(2)
th = []

# PLOTS CONFIGURATION
plotTitle = 'EMG Signal'
xLabel = 'Time (s)'
yLabel = 'Voltage (mV)'
legend1 = 'Channel 1'
legend2 = 'Channel 2'
legend3 = 'Channel 3'

fig, axs = plt.subplots(3)
channel1plot, = axs[0].plot(time, emg_data[0, :], '-b')
axs[0].set_title(plotTitle)
axs[0].legend([legend1])
axs[0].set_ylim([-2, 2])
axs[0].set_xlabel(xLabel)
axs[0].set_ylabel(yLabel)

channel2plot, = axs[1].plot(time, emg_data[1, :], '-r')
axs[1].legend([legend2])
axs[1].set_ylim([-2, 2])
axs[1].set_xlabel(xLabel)
axs[1].set_ylabel(yLabel)

channel3plot, = axs[2].plot(time, emg_data[2, :], '-g')
axs[2].legend([legend3])
axs[2].set_ylim([-2, 2])
axs[2].set_xlabel(xLabel)
axs[2].set_ylabel(yLabel)

plt.show(block=False)

# MAIN LOOP
sleep(1)
start_time = time()
oldStrToSend = ""
while cont:
    chunk = s.recv(buffer_size)
    new_char = chunk.decode('utf-8')
    json_data += new_char

    if '}}' in json_data and not first_json:
        substrings = json_data.split('}}')

        for t in range(len(substrings) - 1):
            json_str = substrings[t]
            json_str += '}}'

            json_file = json.loads(json_str)

            current_size = len(emg_data[0, :])
            channel = 1

            for i in range(len(available_devices)):
                for k in range(used_channels[i] - 1, -1, -1):
                    new_data = json_file['returnData'][available_devices[i]][:, -k]
                    emg_data[channel - 1, current_size:current_size + len(new_data)] = new_data
                    channel += 1

        json_data = substrings[-1]

        if plt.fignum_exists(1):
            time = np.linspace(0, time() - start_time, len(emg_data[0, :]))
            channel1plot.set_xdata(time)
            channel1plot.set_ydata(emg_data[0, :])
            channel2plot.set_xdata(time)
            channel2plot.set_ydata(emg_data[1, :])
            channel3plot.set_xdata(time)
            channel3plot.set_ydata(emg_data[2, :])
            plt.draw()
            plt.pause(0.01)

# Define a function to calculate the root mean square of a signal
def rms(x):
    return np.sqrt(np.mean(x**2))

# Define a function to calculate the threshold using the triangle method
def triangle_threshold(signal, num_bins):
    hist, bin_edges = np.histogram(signal, bins=num_bins)
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2
    max_idx = np.argmax(hist)
    max_value = bin_centers[max_idx]
    hist[:max_idx] = 0
    min_idx = np.argmin(hist)
    min_value = bin_centers[min_idx]
    return (max_value + min_value) / 2

# Define a function to calculate the envelope of a signal
def calculate_envelope(signal):
    analytic_signal = hilbert(signal)
    envelope = np.abs(analytic_signal)
    return envelope

# MAIN LOOP
sleep(1)
start_time = time()
oldStrToSend = ""
while cont:
    chunk = s.recv(buffer_size)
    new_char = chunk.decode('utf-8')
    json_data += new_char

    if '}}}' in json_data:
        print("first json")
        substrings = json_data.split('}}}')
        json_str = substrings[0]
        json_str += '}}}'
        json_data = substrings[1]

        json_file = json.loads(json_str)
        available_devices = list(json_file['returnData'].keys())

        for i in range(len(available_devices)):
            num_channels = len(json_file['returnData'][available_devices[i]]['channels'])
            used_channels.append(num_channels)

        emg_data = np.zeros((sum(used_channels), 2))
        rms_signal = np.zeros((sum(used_channels), 2))
        first_json = False
        print(used_channels)
        start_time = time()

    new_k = len(emg_data[0, :]) // 50
    if new_k > k and with_th:
        k = new_k
        strToSend = ""
        for ch in range(emg_data.shape[0]):
            x = emg_data[ch, -50:]
            value = rms(x)
            if value > th[ch]:
                strToSend += "U;"
                current_state = 1
            else:
                strToSend += "S;"
                current_state = 0

        strToSend += "#"
        if strToSend != oldStrToSend:
            port.write(strToSend.encode())
            print(strToSend)
            oldStrToSend = strToSend

    if len(emg_data[0, :]) > 30 * 100:
        for ch in range(emg_data.shape[0]):
            thenvelopewindow = 50
            signal = calculate_envelope(emg_data[ch, :])
            new_th = triangle_threshold(signal, 24)
            if not with_th:
                th.append(new_th)
            elif new_th > 0.7 * th[ch] and with_th:
                th[ch] = new_th

        with_th = True
        emg_data = emg_data[:, -15 * 100:]
        new_k = 0

    if not plt.fignum_exists(1):
        cont = False
    print(plt.fignum_exists(3))
    sleep(0.01)

# END PROGRAM
port.close()
s.close()