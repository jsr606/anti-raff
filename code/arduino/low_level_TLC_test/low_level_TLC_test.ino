#include "Tlc5940.h"

void setup()
{
  Tlc.init();
  Serial.begin(9600);
}

void loop()
{
  Tlc.clear();  
  
  for (int i=0; i<48; i++) {
    for (int j=0; j<48; j++) {
      if (i == j) {
        Tlc.set(j,0);
      } else {
        Tlc.set(j,4095);
      }
    }
  }
  Tlc.update();
  delay(100);
}
