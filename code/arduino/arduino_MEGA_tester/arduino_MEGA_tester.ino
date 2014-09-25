// arduino MEGA testerarduino MEGA tester

int outPin [] = { 2, 3, 4, 5, 6, 7, 8, 9,10,11,
                 22,23,24,25,26,27,28,29,30,31,
                 32,33,34,35,35,36,37,38,39,40,
                 41,42,43,44,45,46,47,48,49,50};
                 
void setup(){
  for (int i = 0; i<40; i++) {
    pinMode(outPin[i],OUTPUT);
  }
}

void loop() {
  
  // run through all lamps, night rider effect
  
  for (int i = 0; i<40; i++) {
    for (int j = 0; j<40; j++) {
      
      // turn on 1 of 40 lamps
      if (i == j) {
        digitalWrite(outPin[j],LOW);
      } else {
        digitalWrite(outPin[j],HIGH);
      }
  
    }
    
    delay(300);
  }
}
