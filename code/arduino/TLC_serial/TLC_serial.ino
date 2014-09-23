#include "Tlc5940.h"
int brightness = 0;

int bulbBrightness[40];
int currentBulb = -1;
boolean incoming = false;

int lightLevel[40];
int index = 0;

void setup()
{
  Tlc.init();
  Serial.begin(9600);
  Serial.println("hello world!");
  Serial.print("connected to TLCS: ");
  Serial.println(NUM_TLCS);
  blackout();
}

void loop()
{
  delay(50);
  //blackout();
  Tlc.update();  
}

void blackout() {
  for (int i = 0; i<40; i++) {
    setLamp(i,0);
  }
  Tlc.update();
}

void setLamp(int theLamp, int theBrightness) {
  int brightness = map(theBrightness, 0, 255, 4095, 0);
  Tlc.set(theLamp,brightness);
}

void serialEvent() {
  
  while (Serial.available()) {
      int inByte = Serial.read();
      if (inByte == 2) {
        // start of transmission
        index = 0;
      }
      if (inByte == 0) {
        //Serial.print(char(48));
        //Serial.print('0');
        lightLevel[index] = 0;
        setLamp(index,0);
        index++;
      }
      if (inByte == 1) {
        //Serial.print(char(49));
        //Serial.print('1');
        lightLevel[index] = 1;
        setLamp(index,255);
        index++;
      }
  }
}



