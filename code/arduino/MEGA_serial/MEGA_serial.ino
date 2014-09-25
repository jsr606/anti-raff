// MEGA serial

int index = 0;

int outPin [] = { 2, 3, 4, 5, 6, 7, 8, 9,10,11,
                 22,23,24,25,26,27,28,29,30,31,
                 32,33,34,35,35,36,37,38,39,40,
                 41,42,43,44,45,46,47,48,49,50};

void setup()
{
  for (int i = 0; i<40; i++) {
    pinMode(outPin[i],OUTPUT);
  }
  
  Serial.begin(9600);
  Serial.println("hello world!");
  
  blackout();
}

void loop()
{
  delay(50);
}

void blackout() {
  for (int i = 0; i<40; i++) {
    digitalWrite(outPin[i],HIGH);
  }
}

void serialEvent() {
  while (Serial.available()) {
    int inByte = Serial.read();
    if (inByte == 2) {
      // start of transmission
      index = 0;
    }
    if (inByte == 0) {
      digitalWrite(outPin[index],HIGH);
      index++;
    }
    if (inByte == 1) {
      digitalWrite(outPin[index],LOW);
      index++;
    }
  }
}

