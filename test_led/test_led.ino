// Define the LED pin
int ledPin1 = 3;
int ledPin2 = 6;
int ledPin3 = 11;
char KeyVal[3];
// Setup function runs once when Arduino is powered on or reset
int M0 = 0, M1 = 0, M2 = 0;
void setup() {
  // Initialize serial communication at a baud rate of 9600
  Serial.begin(9600);
  Serial.println("Ligado");
  // Set LED pin as an output
  pinMode(ledPin1, OUTPUT);
  pinMode(ledPin2, OUTPUT);
  pinMode(ledPin3, OUTPUT);

  analogWrite(ledPin1, 0);
  analogWrite(ledPin2, 0);
  analogWrite(ledPin3, 0);
}

void ReadKey() {
    int i = 0;
    while (Serial.available()) {
      char receivedChar = Serial.read();
      if (receivedChar == '#') {
        //Serial.flush();
        break;
      }
      else if (receivedChar == ';' || receivedChar == '\n') {
        continue;
      }
      else {
        KeyVal[i] = receivedChar;
        i++;
      }
      Serial.println(KeyVal);
    }
}


// Loop function runs repeatedly as long as Arduino is on
void loop() {
 ReadKey();
 
 //PRIMEIRO 
  if (KeyVal[0] == 'U') {
    if (M0 < 250){
      M0 += 1;
    }
  } 
  else if (KeyVal[0] == 'S') {
    if (M0 > 10){
      M0 -= 1;
    }
  } 
  analogWrite(ledPin1, M0);
  
  if (KeyVal[1] == 'U') {
    if (M1 < 250){
      M1 += 1;
    }
  } 
  else if (KeyVal[1] == 'S') {
    if (M1 > 10){
      M1 -= 1;
    }
  } 
  analogWrite(ledPin2, M1);

  if (KeyVal[2] == 'U') {
    if (M2 < 250){
      M2 += 1;
    }
  } 
  else if (KeyVal[2] == 'S') {
    if (M2 > 10){
      M2 -= 1;
    }
  } 
  analogWrite(ledPin3, M2);
  
  delay(30);
}
