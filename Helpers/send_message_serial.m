% Define the serial port
serialportlist("available")
port = serialport("COM6", 9600);

% Open the serial port
configureTerminator(port, "LF");
flush(port);
fopen(port);
fscanf(port)
% Send the message "up" to the serial port
message = "U"; 
write(port, message, "char");
pause(5)
write(port, "S", "char");
pause(5)
% Close the serial port
fclose(port);
clear port