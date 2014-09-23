import controlP5.*;
import peasy.*;
import processing.serial.*;
import tsps.*;

TSPS tspsReceiver;

PeasyCam cam;

PImage lampImg, acrylic, spark;

int amountOfLamps = 40, debugLamp = 0;

int lampPos[] = {
  126, 266, 0, 223, 196, 0, 215, 257, 0, 191, 345, 0, 164, 394, 0, 341, 166, 0, 313, 380, 0, 296, 476, 0, 412, 75, 0, 404, 191, 0, 422, 324, 0, 482, 420, 0, 477, 133, 0, 542, 188, 0, 584, 274, 0, 677, 267, 0,
  170, 192, 1, 320, 126, 1, 333, 231, 1, 248, 354, 1, 241, 469, 1, 398, 125, 1, 402, 394, 1, 335, 527, 1, 518, 98, 1, 499, 270, 1, 615, 160, 1, 603, 352, 1, 
  143, 339, 2, 201, 424, 2, 295, 526, 2, 213, 116, 2, 292, 204, 2, 321, 313, 2, 359, 431, 2, 335, 79, 2, 411, 260, 2, 473, 187, 2, 525, 342, 2, 663, 210, 2
};

ArrayList lamps, sparks;
PFont font;

int activeLamp = -1;
float layerDistance = 20;

ControlP5 cp5;
Slider2D s2D;
Slider s;
Range range;

float sparkSpeed = 6, sparkRandomizer = 18, maxAccelleration = 50, sparkStrength = 255, sparkFadeout = 10;
int sparkFrequency = 170, lampThreshold = 100;
int lastSpark = millis();
int maxBrightness = 255;
float rotation = -0.1;
float fadeSpeed = 4.43, closeNess = 120;

boolean debugMode = false;

Serial serial;
String myPort = "/dev/tty.usbmodemfd111";

String outString = "";
int msgCount = 0, lastCount = 0;
int lastSecond = second();

int lastSerial = millis(), serialFrequency = 200;

int amountOfBlobs, oldestBlob;
float blobMovement, motionThreshold = 60;

int maxSparks = 6, maxLampsOn = 15;

int ignoreIfOlder = 300;

boolean showLayer0 = true, showLayer1 = true, showLayer2 = true;

float easterEggAge = 300, easterEggIgnore = 600;

final int DEFAULT = -1, EASTEREGG = 0, SLEEP = 1, DEBUG = 2;
int mode = DEFAULT;

int nightTime = 1, morningTime = 6;

int easterSpeed = 20, lastEaster = millis(), easterLamp = 0;

void setup()  {
  
  size(800, 600, OPENGL);
  smooth();

  println(Serial.list());
  serial = new Serial(this, myPort, 9600);
  serial.bufferUntil(10); 
  serial.clear();

  cam = new PeasyCam(this, 400,300,0,600);
  cam.setMinimumDistance(50);
  cam.setMaximumDistance(1500);
  
  cp5 = new ControlP5(this);
  
  cp5.setColorBackground(#7F8171);
  cp5.setColorForeground(color(204,204,0)); //Qty & rim color
  cp5.setColorActive(color(217,214,202)); //Selected items 
  
  
  cp5.addSlider("layerDistance",0,200).setValue(40).setSize(150,10).linebreak();
  cp5.addSlider("maxBrightness",0,255).setSize(150,10).linebreak();
  cp5.addSlider("fadeSpeed",0,10).setSize(150,10).linebreak();
  cp5.addSlider("sparkSpeed",0,100).setSize(150,10).linebreak();
  cp5.addSlider("sparkRandomizer",0,150).setSize(150,10).linebreak();
  cp5.addSlider("sparkFrequency",0,1500).setSize(150,10).linebreak();
  cp5.addSlider("maxAccelleration",0,150).setSize(150,10).linebreak();
  cp5.addSlider("sparkStrength",0,500).setSize(150,10).linebreak();
  cp5.addSlider("sparkFadeout",0,100).setSize(150,10).linebreak();
  cp5.addSlider("closeNess",0,500).setSize(150,10).linebreak();
  cp5.addSlider("maxSparks",0,20).setSize(150,10).linebreak();
  cp5.addSlider("maxLampsOn",0,40).setSize(150,10).linebreak();
  cp5.addSlider("lampThreshold",0,255).setSize(150,10).linebreak();
  s2D = cp5.addSlider2D("gravity").setPosition(10,275).setSize(100,100).setMinX(-150).setMinY(-150).setMaxX(150).setMaxY(150).setArrayValue(new float[] {150, 150});
  
  //debug mode
  cp5.addToggle("debugMode").setPosition(10,600-45).setSize(10,10).linebreak();
  cp5.addSlider("debugLamp",0,39).setPosition(10,600-20).setSize(150,10).setAutoUpdate(true).linebreak();

  //tracking tweaks
  cp5.addSlider("oldestBlob",0,1000).setPosition(10,600-160).setSize(300,10).setAutoUpdate(true);
  range = cp5.addRange("easterEgg").setPosition(10,600-145).setSize(300,10).setRange(0,1000).setRangeValues(easterEggAge,easterEggIgnore);
  //cp5.addSlider("ignoreIfOlder",0,1000).setPosition(10,600-145).setSize(300,10);
  cp5.addSlider("blobMovement",0,1000).setPosition(10,600-130).setSize(300,10).setAutoUpdate(true);
  cp5.addSlider("motionThreshold",0,1000).setPosition(10,600-115).setSize(300,10);
  cp5.addSlider("serialFrequency",25,3000).setPosition(10,600-100).setSize(300,10).setAutoUpdate(true);
  
  
  cp5.setAutoDraw(false);
  
  font = loadFont("VolterGoldfish-9.vlw");  
  textFont(font, 9);
  
  lamps = new ArrayList();

  for (int i = 0; i < amountOfLamps; i++) {
    lamps.add(new Lamp(lampPos[i*3],lampPos[i*3+1],lampPos[i*3+2],i));
  }
  
  sparks = new ArrayList();
  
  // closest possible lamp distance
  float nearest = 1000;
  for (int i = 0; i < amountOfLamps; i++) {
    for (int j = 0; j < amountOfLamps; j++) {
      if (i!=j) {
        float d = distanceBetweenLamps (i, j);
        nearest = min(nearest, d);
      }
    }
  }
  println("nearest lamp distance "+nearest);
  
  lampImg = loadImage("lamp.png");
  acrylic = loadImage("acrylic.png");
  spark = loadImage("spark.png");
  
  //start TSPS
  tspsReceiver= new TSPS(this, 12000);
  
}

void draw()  {
  pushMatrix();
  background(150);
  
  translate(width,0);
  rotateY(radians(180-25));
  
  switch(mode) {
    case DEBUG:
      textBox("DEBUG MODE");
      for (int i = 0; i < amountOfLamps; i++) {
        Lamp thisLamp = (Lamp) lamps.get(i);
        if (debugLamp == i) {
          thisLamp.brightness = 255;
        } else {
          thisLamp.brightness = 0;
        } 
      }
      break;
    case SLEEP:
      textBox("SLEEP MODE");
      // do nothing
      break;
    case EASTEREGG:
      textBox("EASTER EGG TIME");
      // insert running lights
      if (lastEaster + easterSpeed < millis() ) {
        easterLamp ++;
        easterLamp = easterLamp % amountOfLamps;
        println("easterlamp "+easterLamp);
        lastEaster = millis();
        
        for (int i = 0; i<amountOfLamps; i++) {
          Lamp thisLamp = (Lamp) lamps.get(i);
          if (i == easterLamp) {
            thisLamp.brightness = 255;
          } else {
            thisLamp.brightness = 0;
          }
        }
        
      }

      
      break;
    default:
      // update sparks
      for (int i = 0; i<sparks.size(); i++) {
        Spark thisSpark = (Spark) sparks.get(i);
        thisSpark.update();
        // check for dead sparks
        if (thisSpark.strength < 0) {
          sparks.remove(i);
        }  
      }
  }
  
  // draw lamps
  for (int i = 0; i < amountOfLamps; i++) {
    
    Lamp thisLamp = (Lamp) lamps.get(i);
    
    if (thisLamp.layer == 0 && showLayer0) {
      thisLamp.update();
    }
    if (thisLamp.layer == 1 && showLayer1) {
      thisLamp.update();
    }
    if (thisLamp.layer == 2 && showLayer2) {
      thisLamp.update();
    }    
  }
  
  drawAcrylic();
  drawTrackingData();
  
  if (lastSerial + serialFrequency < millis() ) {
    sendSerial();
    lastSerial = millis();
  }
  
  popMatrix();
  gui();
    
  if (hour() == nightTime) {
    if (mode != SLEEP) {
      println("going to sleep now");
      mode = SLEEP;
    }
  }
  
  if (hour() == morningTime ) {
    if (mode == SLEEP) {
      println("waking up again");
      mode = DEFAULT;
    }
  }
  
}

void sendSerial() {
  //print("sending to serial port: ");
  //send start msg
  
  int lampOnCount = 0;
  
  serial.write(2);
  for (int i = 0; i<40; i++) {
    Lamp thisLamp = (Lamp) lamps.get(i);
    if (thisLamp.brightness > lampThreshold) {
      
      // crude hack to have a hard max on lamps on
      if (lampOnCount < maxLampsOn) {
        serial.write(1);
      } else {
        serial.write(0);
      }
      lampOnCount++;
      
      //print("1");
    } else {
      serial.write(0);
      //print("0");
    }
    //outString = outString + j;
  }
  //println();
  serial.write(10);
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
      
      if (people[i].age < easterEggIgnore) {    
        oldestBlob = max(oldestBlob, people[i].age);
      }
      
      if (oldestBlob > easterEggAge) {
        // only go from default to easter egg
        if (mode == DEFAULT) {
          mode = EASTEREGG;
        }
      } else {
        // only go from easter egg back to default
        if (mode == EASTEREGG) {
          mode = DEFAULT;
        }
      }
      
      
  };
  
  if (blobMovement > motionThreshold) {
    if (sparks.size() < maxSparks) {
      if (lastSpark + sparkFrequency < millis()) {
        int r = int(random(amountOfLamps));
        sparks.add(new Spark(r));
        lastSpark = millis();
      }
    }
  
  }
  
}

public class Spark {

  public float xPos, yPos, zPos, xDir, yDir, zDir;
  public float strength, age;
  public int id;
  
  public Spark (int theID) {
    // random spark generator
    id = theID;
    Lamp thisLamp = (Lamp) lamps.get(id);
    xPos = thisLamp.xPos;
    yPos = thisLamp.yPos;
    zPos = thisLamp.zPos;
    strength = sparkStrength;
    xDir = random(-sparkRandomizer,sparkRandomizer)+s2D.arrayValue()[0];
    yDir = random(-sparkRandomizer,sparkRandomizer)+s2D.arrayValue()[1];
    zDir = random(-sparkRandomizer,sparkRandomizer);
    thisLamp.brightness = strength;
    age = 0;
  }
  
  public void update() {
    
    pushMatrix();
    translate(xPos, yPos, zPos);
    stroke(0);
    strokeWeight(1);
    noFill();
    box(5);
    line(0,0,0,xDir,yDir,zDir);
    translate(xDir,yDir,zDir);
    box(3);
    popMatrix();
    age ++;
    if (age>sparkSpeed) {
      strength = strength - sparkFadeout;
      nextMove();
    }
  }
  
  public void nextMove() {
    age = 0;
    for (int i = 0; i<amountOfLamps; i++) {
      if (i != id) {
        Lamp thatLamp = (Lamp) lamps.get(i);
        float d = dist (xPos+xDir, yPos+yDir, zPos+zDir, thatLamp.xPos, thatLamp.yPos, thatLamp.zPos);
        
        if (d<random(closeNess/2,closeNess)) {
          id = i;
          Lamp thisLamp = (Lamp) lamps.get(i);
          // update position
          xPos = thisLamp.xPos;
          yPos = thisLamp.yPos;
          zPos = thisLamp.zPos;
          // update direction
          xDir = xDir + random(-sparkRandomizer,sparkRandomizer)+s2D.arrayValue()[0];
          yDir = yDir + random(-sparkRandomizer,sparkRandomizer)+s2D.arrayValue()[1];
          zDir = zDir + random(-sparkRandomizer,sparkRandomizer);
          
          xDir = constrain(xDir, -maxAccelleration, maxAccelleration);
          yDir = constrain(yDir, -maxAccelleration, maxAccelleration);
          zDir = constrain(zDir, -maxAccelleration, maxAccelleration);
          
          //update lights
          thisLamp.brightness = strength;
          break;
        }
      }
    }
  }
}

void findNearestLamps (int theID) {
  for (int i = 0; i<amountOfLamps; i++) {
    
    float d = distanceBetweenLamps(i, theID);
    Lamp thisLamp = (Lamp) lamps.get(i);
    thisLamp.brightness = map(d,55,200,255,0);
    
  }
}

public class Lamp {

    public float xPos, yPos, zPos, layer, brightness = 0;
    public int ID;
    public int [] neighbours;
    public color col = #000000;
    
    public Lamp (float theX, float theY, int theLayer, int theID) {
      xPos = theX;
      yPos = theY;
      zPos = theLayer * layerDistance;
      layer = theLayer;
      ID = theID;
    }
    
    public void update() {
      
      if (activeLamp == ID) {
        fill(255,0,0);
      } else {
        fill(brightness);
      }
      
      // to emphasize layer difference
      float sizing = map(layer, 0, 2, 10, 5);
      
      pushMatrix();
      translate(xPos, yPos,zPos);
      stroke(0);
      fill(brightness);
      box(sizing);
      popMatrix();
      
      if (brightness > 0) {
        brightness = brightness - fadeSpeed;
        brightness = constrain(brightness,0,maxBrightness);
      }
      
    }  

}

float distanceBetweenLamps (int ID1, int ID2) {
  Lamp thisLamp = (Lamp) lamps.get(ID1);
  Lamp thatLamp = (Lamp) lamps.get(ID2);
  float d = dist (thisLamp.xPos, thisLamp.yPos, thisLamp.zPos, thatLamp.xPos, thatLamp.yPos, thatLamp.zPos);
  return d;
}

void layerDistance(int theDistance) {
  layerDistance = theDistance;
  for (int i = 0; i<amountOfLamps; i++) {
    Lamp thisLamp = (Lamp) lamps.get(i);
    thisLamp.zPos = thisLamp.layer * layerDistance;
  }
}

void keyPressed() {
  if (key == '-') {
    rotation = rotation - 0.01;
  }
  if (key == '+') {
    rotation = rotation + 0.01;
  }
  if (key == ' ') {
    int r = int(random(amountOfLamps));
    sparks.add(new Spark(r));
  }
  if (keyCode == RIGHT) {
    debugLamp ++;
    debugLamp = constrain(debugLamp,0,amountOfLamps);
  }
  if (keyCode == LEFT) {
    debugLamp--;
    debugLamp = constrain(debugLamp,0,amountOfLamps);
  }
  if (key == '1') {
    showLayer0 = !showLayer0;
  }
  if (key == '2') {
    showLayer1 = !showLayer1;
  }
  if (key == '3') {
    showLayer2 = !showLayer2;
  }
}

void gui() {
  hint(DISABLE_DEPTH_TEST);
  cam.beginHUD();
  fill(255);
  text("ANTI // brain sculpture",10,20);
  String time = nf(hour(),2)+":"+nf(minute(),2);
  text (time,800-40,20);
  cp5.draw();
  cam.endHUD();
  hint(ENABLE_DEPTH_TEST);
}


void mouseClicked() {
  println("grav "+s2D.arrayValue()[0]);
  println("x: "+mouseX+" y: "+mouseY);
}

void drawAcrylic() {
  pushMatrix();
  line(0,0,800,0);
  line(800,0,800,600);
  line(800,600,0,600);
  line(0,600,0,0);
  translate(0,0,layerDistance);
  line(0,0,800,0);
  line(800,0,800,600);
  line(800,600,0,600);
  line(0,600,0,0);
  translate(0,0,layerDistance);
  line(0,0,800,0);
  line(800,0,800,600);
  line(800,600,0,600);
  line(0,600,0,0);
  popMatrix();
}


void easterEgg() {
  //println("range: "+range.getArrayValue(0)+","+range.getArrayValue(1));
  easterEggAge = range.getArrayValue(0);
  easterEggIgnore = range.getArrayValue(1);
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

void debugMode(boolean theFlag) {
  if (theFlag == true) mode = DEBUG;
  if (theFlag == false) mode = DEFAULT;
}
