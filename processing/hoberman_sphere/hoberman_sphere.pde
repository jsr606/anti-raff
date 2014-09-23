import controlP5.*;
import tsps.*;
TSPS tspsReceiver;
import processing.serial.*;

PFont font;

ControlP5 cp5;
Slider2D s2D;
Slider s;
Range range;

int amountOfBlobs, oldestBlob;
float blobMovement, motionMinThreshold = 100, motionMaxThreshold = 700;
int stepperDestination = 0;
float stepperAccelleraion = 500;

Serial serial;

boolean setupMotor = false;
int lastRandom = millis();
int randomDelay = 5000;

String incomingSerial;

int lastSerial = millis();
int serialFrequency = 100;

int lastPos, nextPos;
int contractDelay = 4000;
int contractSpeed = 130;

boolean calibrateMotor = true, debugMode = false;

int lastDebug = millis();
int debugFrequency = 5000;

final int CALIBRATE = 0, DEBUG = 1, SLEEP = 2, DEFAULT = -1;
int mode = CALIBRATE;

int nightTime = 1, morningTime = 6;

void setup()  {
  
  size(800, 600, OPENGL);
  smooth();

  cp5 = new ControlP5(this);
  
  cp5.setColorBackground(#7F8171);
  cp5.setColorForeground(#169B45); //Qty & rim color
  cp5.setColorActive(color(217,214,202)); //Selected items 
  
  //tracking tweaks
  cp5.addSlider("amountOfBlobs",0,20).setPosition(10,25).setSize(300,10).setAutoUpdate(true);
  cp5.addSlider("blobMovement",0,1000).setPosition(10,40).setSize(300,10).setAutoUpdate(true);
  range = cp5.addRange("motionThreshold").setPosition(10,55).setSize(300,10).setRange(0,1000).setRangeValues(50,400);
  cp5.addSlider("serialFrequency",50,3000).setPosition(10,70).setSize(300,10).setAutoUpdate(true);
  cp5.addSlider("contractDelay",1000,20000).setPosition(10,85).setSize(300,10).setAutoUpdate(true);
  cp5.addSlider("contractSpeed",1, 300).setPosition(10,100).setSize(300,10).setAutoUpdate(true);
  cp5.addToggle("calibrateMotor").setPosition(10,115).setSize(30,30).setValue(true).linebreak();
  
  // debug stuff
  cp5.addToggle("debugMode").setPosition(10,600-50).setSize(10,10).linebreak();
  cp5.addSlider("debugFrequency",1000,10000).setPosition(10,600-20).setSize(300,10);
  
  font = loadFont("VolterGoldfish-9.vlw");  
  textFont(font, 9);
  
  //all you need to do to start TSPS
  tspsReceiver= new TSPS(this, 12000);
  
  println(Serial.list());
  serial = new Serial(this, "/dev/tty.usbmodemfd131", 9600);
  serial.clear();
  
}

void draw()  {

  background(150);
  
  fill(255);
  textAlign(LEFT);
  text("ANTI // hoberman sphere",10,20);
  
  String time = nf(hour(),2)+":"+nf(minute(),2);
  text (time,800-40,20);
  
  drawTrackingData();

  float s = map(nextPos,255,0,50,height);
  stroke(255);
  noFill();
  ellipse(width/2,height/2,s,s);  
  
  if (hour() == nightTime) {
    if (mode != SLEEP) {
      println("going to sleep now");
      mode = SLEEP;
      nextPos = 255;
      serial.write(nextPos);
    }
  }
  
  if (hour() == morningTime ) {
    if (mode == SLEEP) {
      println("waking up again");
      mode = DEFAULT;
    }
  }
  
  switch(mode) {
    case CALIBRATE:
      textBox("CALIBRATION MODE");
      // just wait
      break;
    case DEBUG:
      textBox("DEBUG MODE");
      if (lastDebug + debugFrequency < millis()) {
        nextPos = int(random(255));
        serial.write(nextPos);
        lastDebug = millis();
      }
      break;
    case SLEEP:
      textBox("SLEEP MODE");
      break;
    default:
      if (blobMovement > motionMinThreshold) {
        
        // there is motion past threshold, move
        fill (255,0,0);
        noStroke();
        rect (width-15,height-15,10,10);
        
        nextPos = min (nextPos, int(map(blobMovement,motionMinThreshold,motionMaxThreshold,255,30)));
        nextPos = constrain(nextPos,0,255);
        
        println("nextPos: "+nextPos);
        
        if (lastSerial + serialFrequency < millis() ) {
          if (nextPos != lastPos) serial.write(nextPos);
          lastSerial = millis();
          lastPos = nextPos;
        }
        
      } else {
        
        // no motion, contract
        
        if (lastSerial + contractDelay < millis()) {
          println("contracting by "+contractSpeed);
          nextPos = lastPos + contractSpeed;
          nextPos = constrain(nextPos, 0, 255);
          if (nextPos != lastPos) serial.write(nextPos);
          lastPos = nextPos;
          lastSerial = millis();
        }
        
      }
    }
}

void calibrateMotor (boolean theFlag) {
  if (theFlag == true) {
    mode = CALIBRATE;
    println("enter CALIBRATE mode");
  }
  if (theFlag == false) {
    mode = DEFAULT;
    println("back to DEFAULT MODE");
  }
}

void debugMode (boolean theFlag) {
  if (theFlag == true) {
    mode = DEBUG;
    println("enter DEBUG mode");
  }
  if (theFlag == false) {
    mode = DEFAULT;
    println("back to DEFAULT MODE");
  }
}

void drawTrackingData() {
  
  // get array of people
  TSPSPerson[] people = tspsReceiver.getPeopleArray();
  
  amountOfBlobs = people.length;
  oldestBlob = 0;
  blobMovement = 0;
  
  // loop through people
  for (int i=0; i<people.length; i++){
      // draw person!
      noFill();
      stroke(255,100);
      rect(people[i].boundingRect.x*width, people[i].boundingRect.y*height, people[i].boundingRect.width*width, people[i].boundingRect.height*height);    
      
      // draw circle based on person's centroid (also from 0-1)
      fill(255,255,255);
      ellipse(people[i].centroid.x*width, people[i].centroid.y*height, 10, 10);
      
      // draw contours
      noFill();
      stroke(255,100);
      beginShape();
      for (int j=0; j<people[i].contours.size(); j++){
        PVector pt = (PVector) people[i].contours.get(j);
        if ( pt == null ){
          println(j);
        } else {
          vertex(pt.x*width, pt.y*height);
        }
      }
      endShape(CLOSE);

      // text shows more info available
      text("id: "+people[i].id+" age: "+people[i].age, people[i].boundingRect.x*width, (people[i].boundingRect.y*height + people[i].boundingRect.height*height) + 2);
      
      blobMovement += abs(dist(0,0,people[i].velocity.x,people[i].velocity.y));
      
      oldestBlob = max(oldestBlob, people[i].age);
  }; 
}

void keyPressed() {
  /*
  int ran = int(random(255));
  println("sending random value "+ran);
  serial.write(ran);
  */
}

void stepperDestination(int theDestination) {
  if (setupMotor) {
    println("new stepper destination ");
    stepperDestination = theDestination;
    println(stepperDestination);
    serial.write(stepperDestination);
  }
}

void mouseClicked() {
  //println("x: "+mouseX+" y: "+mouseY);
}

void serialEvent(Serial p) { 
  String incoming = p.readString();
  incomingSerial = incoming;
  print(incoming);
} 

void motionThreshold() {
  //println("range: "+range.getArrayValue(0)+","+range.getArrayValue(1));
  motionMinThreshold = range.getArrayValue(0);
  motionMaxThreshold = range.getArrayValue(1);
}

void textBox (String theText) {
  fill(50);
  stroke(255);
  rectMode(CENTER);
  rect(width/2,height/2,200,25);
  textAlign(CENTER);
  fill(255);
  text(theText,width/2,height/2+3);
  rectMode(CORNER);
}
