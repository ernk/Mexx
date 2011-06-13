import SimpleOpenNI.*;
import codeanticode.gsvideo.*;
import processing.opengl.*;
import codeanticode.glgraphics.*;

GSMovie movie;
PImage bg;
//GLTexture tex;

SimpleOpenNI context;
float        zoomF =0.7f;
float        zCoef = 4;
float        rotX = radians(180);  // by default rotate the hole scene 180deg around the x-axis, 
// the data from openni comes upside down
float        rotY = radians(0);

float centerZ = -1000;
float xShift = 0;
float yShift = 70;
float zShift = 0;
float scaleXY = 1.2;

int     steps   = 6;  // to speed up the drawing, draw every third point

boolean      handsTrackFlag = true;
PVector      handVec = new PVector();
ArrayList    handVecList = new ArrayList();
int          handVecListSize = 30;
String       lastGesture = "";

PVector userPosition;

//Texture init
GLTexture bubbleTex;              // Texture used to draw each particle.

//Flower painting init
ParticleSystem psys;
ArrayList psystems;
PVector handScreenPos = new PVector();
PVector prevScreenPos = new PVector();

//zilch
PVector zilchStartPoint = new PVector((583 - xShift)/scaleXY, (123 - yShift)/scaleXY, 0);
int pnum = 70; // max particle count
int zilchTimer = 0;
float minBubbleX = 10000;
float minBubbleY = 0;

ArrayList<BubbleParticle> zilchParticles = new ArrayList<BubbleParticle>();

boolean male = true;

void setup()
{
  size(911, 768, GLConstants.GLGRAPHICS); 
  //  size(1280, 1080, GLConstants.GLGRAPHICS); 

  //Texture setup  
  bubbleTex = new GLTexture(this, "bubble.png");
  //  bubbleTex = new GLTexture(this, "flower64.png");  


  context = new SimpleOpenNI(this, SimpleOpenNI.RUN_MODE_MULTI_THREADED);

  // Load and play the video in a loop
  if (male)
    movie = new GSMovie(this, "man-cropped-c.mov"); //load male movie
  else
    movie = new GSMovie(this, "man-cropped-c.mov"); //load female movie
  movie.loop();

  bg = loadImage("man-background.001.png");
  // bg = loadImage("flower64.png");

  // enable mirror
  context.setMirror(true);

  // enable depthMap generation 
  context.enableDepth();

  // enable hands + gesture generation
  context.enableGesture();
  context.enableHands();

  // add focus gestures  / here i do have some problems on the mac, i only recognize raiseHand ? Maybe cpu performance ?
  context.addGesture("Wave");
  context.addGesture("Click");
  context.addGesture("RaiseHand");

  // enable skeleton generation for all joints
  context.enableUser(SimpleOpenNI.SKEL_PROFILE_ALL);

  // enable the scene, to get the floor
  context.enableScene();

  //  stroke(255, 255, 255); 
  //  perspective(95, 
  //  float(width)/float(height), 
  //  10, 150000);

  //Flower painting setup
  psystems = new ArrayList();
  psys = new ParticleSystem(1, new PVector(width/2, height/2, 0));
}

void draw()
{
  context.update();

  // 
  tint(255, 255);
  image(bg, 0, 0, 911, 768); 
  image(movie, 450, 0);

  int[]   depthMap = context.depthMap();
  int     index;
  PVector realWorldPoint;

  //translate(0, 0, centerZ);  // set the rotation center of the scene 1000 infront of the camera


  int userCount = context.getNumberOfUsers();
  int[] userMap = null;
  if (userCount > 0)
  {
    userMap = context.getUsersPixels(SimpleOpenNI.USERS_ALL);
  }


  if (zilchTimer > 0) {
    //add bubbles to zilch
    for (int i = 0; i < ceil(pnum); i++) {
      zilchParticles.add(new BubbleParticle(zilchStartPoint));
    }  
    zilchTimer -= 1;
  } 

  userPosition = new PVector();

  //image(bubbleTex, 0, 0, 20, 20);

  pushMatrix(); 
  scale(scaleXY);
  translate(0, yShift, 0); 


  for (int y=0;y < context.depthHeight();y+=steps)
  {
    for (int x=0;x < context.depthWidth();x+=steps)
    {
      index = x + y * context.depthWidth();
      if (depthMap[index] > 0)
      { 
        // get the realworld points
        realWorldPoint = context.depthMapRealWorld()[index];
        PVector screenPos = new PVector();
        context.convertRealWorldToProjective(realWorldPoint, screenPos);

        // check if there is a user
        if (userMap != null && userMap[index] != 0) { 
          //TODO: get it out from loop
          context.getCoM(userMap[index], userPosition);
          float bubbleSize = min((abs(20000/(realWorldPoint.z*zCoef + (userPosition.z - userPosition.z*zCoef)))), 80);
          tint(255, 100);
          if (screenPos.x > minBubbleX & screenPos.y < minBubbleY)
            image(bubbleTex, screenPos.x, screenPos.y, bubbleSize, bubbleSize);
        }
      }
    }
  }




  // draw the tracked hand
  if (handsTrackFlag && userCount > 0)  
  {   
    context.convertRealWorldToProjective(handVec, handScreenPos);

    int stepCount = 3;
    float sx = handScreenPos.x - prevScreenPos.x;
    float sy = handScreenPos.y - prevScreenPos.y;

    for (int step = 0; step < stepCount; step++) {
      psystems.add(new ParticleSystem(1, new PVector(handScreenPos.x + sx * step/stepCount +  random(5)-2.5, handScreenPos.y + sy * step/stepCount + random(5)-2.5)));    
    }
    prevScreenPos = handScreenPos;
  }

  for (int i = psystems.size()-1; i >= 0; i--) {
    ParticleSystem psys = (ParticleSystem) psystems.get(i);
    psys.run();

    if (psys.dead()) {
      psystems.remove(i);
    }
  }


  //render zilch
  for (int i = zilchParticles.size()-1; i >= 0; i--) {
    BubbleParticle bParticle = (BubbleParticle) zilchParticles.get(i);
    bParticle.run();
    minBubbleX = min(minBubbleX, bParticle.loc.x);
    minBubbleY = max(minBubbleY, bParticle.loc.y);

    if (bParticle.dead()) {
      zilchParticles.remove(i);
    }
  }
  popMatrix();
}

// -----------------------------------------------------------------
// hand events

void onCreateHands(int handId, PVector pos, float time)
{
  println("onCreateHands - handId: " + handId + ", pos: " + pos + ", time:" + time);
  synchronized(handVec) {
    handsTrackFlag = true;
    handVec = pos;
    handVecList.clear();
    handVecList.add(pos);
  }
}

void onUpdateHands(int handId, PVector pos, float time)
{
  //println("onUpdateHandsCb - handId: " + handId + ", pos: " + pos + ", time:" + time);

  synchronized(handVec) {
    handVec = pos;
    handVecList.add(0, pos);
    if (handVecList.size() >= handVecListSize)
    { // remove the last point 
      handVecList.remove(handVecList.size()-1);
    }
  }
}

void onDestroyHands(int handId, float time)
{
  println("onDestroyHandsCb - handId: " + handId + ", time:" + time);

  handsTrackFlag = false;
  context.addGesture(lastGesture);
}

// -----------------------------------------------------------------
// gesture events

void onRecognizeGesture(String strGesture, PVector idPosition, PVector endPosition)
{
  println("onRecognizeGesture - strGesture: " + strGesture + ", idPosition: " + idPosition + ", endPosition:" + endPosition);

  lastGesture = strGesture;
  context.removeGesture(strGesture); 
  context.startTrackingHands(endPosition);
}

void onProgressGesture(String strGesture, PVector position, float progress)
{
  //println("onProgressGesture - strGesture: " + strGesture + ", position: " + position + ", progress:" + progress);
}


// -----------------------------------------------------------------
// SimpleOpenNI user events

void onNewUser(int userId)
{
  println("onNewUser - userId: " + userId);
  zilchTimer = 11;
  minBubbleX = 10000;
  minBubbleY = 0;
}

void onLostUser(int userId)
{
  println("onLostUser - userId: " + userId);
}


// -----------------------------------------------------------------
// Keyboard events

void keyPressed()
{
  switch(key)
  {
  case ' ':
    context.setMirror(!context.mirror());
    break;
  }

  switch(keyCode)
  {
  case LEFT:
    rotY += 0.03f;
    break;
  case RIGHT:
    // zoom out
    rotY -= 0.03f;
    break;
  case UP:
    if (keyEvent.isShiftDown())
      zoomF += 0.01f;
    else
      rotX += 0.01f;
    break;
  case DOWN:
    if (keyEvent.isShiftDown())
    {
      zoomF -= 0.01f;
      if (zoomF < 0.01)
        zoomF = 0.01;
    }
    else
      rotX -= 0.1f;
    break;
  }
}

void mousePressed() {
  println("X, Y: " + mouseX + ", " + mouseY);
}

void movieEvent(GSMovie movie) {
  movie.read();
}

