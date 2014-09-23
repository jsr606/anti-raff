int potVal = 0;
int pot = A0;

long pos = 0, maxPos = 0, minPos = 0;
long newDestination;
unsigned long lastPrint = millis();
unsigned long lastTick = millis();
int printDelay = 6000;
int idle = 0;
long minDelay = 33773, maxDelay = 41397;

int brakeDistance = 100;

// good speeds
// 1000 fast!
// 33773 fast
// 41397 very slow

boolean selfRunning = false, calibration = false;
float currentMotion = 0;
long motorDel;
int dir = 0;
int lastPot, potNoise = 15;
float motionIncrement = 5;

boolean debug = false;

void setup() {
  pinMode(8, OUTPUT);
  pinMode(9, OUTPUT);
  Serial.begin(9600);
  Serial.println("hello stepper world!");
}

void loop() {
  
  tick();

  if (idle > 5) {
    if (maxPos == 0 && minPos == 0) {
      if (debug) Serial.println("use pots to calibrate min and max pos");
    } else {
      if (debug) Serial.println("time to go to work");
    }
    idle = 0;
  }

  
  if (selfRunning) {
    if (newDestination > pos) {
      currentMotion += motionIncrement;
    }
    if (newDestination < pos) {
      currentMotion -= motionIncrement;
    }
    
    currentMotion = constrain(currentMotion,-1000,1000);
    
    
    float breakFactor = 1;
    float dist = abs(newDestination-pos);
    if (dist < brakeDistance) {
      //Serial.print("dist ");
      //Serial.println(dist);
      breakFactor = dist / brakeDistance;
      //Serial.print("break factor ");
      //Serial.println(breakFactor);
    }
    
    if (currentMotion < 0) {
      dir = -1;
    } else {
      dir = 1;
    }
    
    motorDel = map(abs(currentMotion)*breakFactor,0,1000,maxDelay,minDelay);
    moveStepper();
    
    if (pos == newDestination) {
      if (debug) Serial.println("i arrived");
      currentMotion = 0;
      selfRunning = false;
    }
  }
  
  potVal = 1023-analogRead(A0);
  if (potVal > (lastPot + potNoise) || potVal < (lastPot - potNoise)) {
    if (debug) Serial.print("pot moved to ");
    if (debug) Serial.println(potVal);
    lastPot = potVal;
    selfRunning = false;
    calibration = true;
  }
  
  if (calibration) {
    calibrate();
  }  
  
  if (lastPrint + printDelay < millis()) {
    if (debug) feedback();
  }
}

void calibrate() {
  dir = 0;
  
  if (potVal < 100) {
    dir = -1;
    idle = 0;
    selfRunning = false;
  } else if (potVal > 924) {
    dir = 1;
    idle = 0;
    selfRunning = false;
  }
  
  if (dir !=0) {
    motorDel = map(analogRead(A1),0,1023,minDelay,maxDelay);
    moveStepper();
    //feedback();
  }
}

void feedback() {
  Serial.print("current motion ");
  Serial.print(currentMotion);
  Serial.print("\tmotor delay: ");
  Serial.println(motorDel);
  Serial.print("current pos ");
  Serial.print(pos);
  Serial.print("\tmin: ");
  Serial.print(minPos);
  Serial.print("\tmax: ");
  Serial.print(maxPos);
  Serial.print("\tdir: ");
  Serial.print(dir);
  Serial.print("\tdest: ");
  Serial.println(newDestination);
  lastPrint = millis();
}

void moveStepper() {
  
  setDirection(dir);
  
  digitalWrite(8, HIGH);
  delayMicroseconds(motorDel);
  
  digitalWrite(8, LOW);
  delayMicroseconds(motorDel);
  
  // count steps
  if (dir == 1) pos++;
  if (dir == -1) pos--;
  
  maxPos = max(pos, maxPos);
  minPos = min(pos, minPos);
}

void setDirection(int theDirection) {
  if (theDirection == -1) {
    digitalWrite(9, HIGH);
  } else {
    digitalWrite(9, LOW); 
  }
}

void tick() {
  if (lastTick + 1000 < millis()) {
    idle++;
    lastTick = millis();
  }
}

void serialEvent() {
  while (Serial.available()) {
    int inByte = Serial.read();
    newDestination = map(inByte,0,255,minPos,maxPos);
    if (debug) Serial.print("got a new destination: ");
    if (debug) Serial.println(newDestination);
    if (debug) feedback();
    selfRunning = true;
  }
}
