import SimpleOpenNI.*;
import codeanticode.gsvideo.*;
import processing.opengl.*;
import codeanticode.glgraphics.*;

GSMovie movie;
//GLTexture tex;
PImage bg;

SimpleOpenNI context;
float        zoomF =0.7f;
float zCoef = 3;
float        rotX = radians(180);  // by default rotate the hole scene 180deg around the x-axis, 
// the data from openni comes upside down
float        rotY = radians(0);
color[]      userColors = { 
  color(0, 0, 255), color(0, 0, 255), color(0, 0, 255), color(0, 0, 255), color(255, 0, 255), color(0, 255, 255)
};
color[]      userCoMColors = { 
  color(255, 100, 100), color(100, 255, 100), color(100, 100, 255), color(255, 255, 100), color(255, 100, 255), color(100, 255, 255)
};

float centerZ = -1000;

boolean      handsTrackFlag = false;
PVector      handVec = new PVector();
ArrayList    handVecList = new ArrayList();
int          handVecListSize = 30;
String       lastGesture = "";

PVector userPosition;

void setup()
{
  size(911, 768, P3D); 
  //  size(1280, 1080, GLConstants.GLGRAPHICS); 
  context = new SimpleOpenNI(this, SimpleOpenNI.RUN_MODE_MULTI_THREADED);

  // Load and play the video in a loop
  //movie = new GSMovie(this, "man.m4v");
  //movie.loop();
  
  bg = loadImage("man-background.001.png");

  // tex = new GLTexture(this);

  // disable mirror
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

  stroke(255, 255, 255);
  //smooth();  
  perspective(95, 
  float(width)/float(height), 
  10, 150000);
}

void draw()
{
//  stroke(0);
//  fill(0, eraser_opacity);
  tint(255,64);
  beginShape();
  texture(bg);
    vertex(0, 0, 500);
    vertex(911, 0, 500);
    vertex(911, 768, 500);
    vertex(0, 768, 500);
  endShape();  
  tint(255,255);
  // update the cam
  context.update();
 // background(0);
  //  background(movie);

  //rotY += 0.03f;
  // set the scene pos
  translate(width/2, height/2, 0);
  rotateX(rotX);
  rotateY(rotY);
  scale(zoomF);


  int[]   depthMap = context.depthMap();
  int     steps   = 3;  // to speed up the drawing, draw every third point
  int     index;
  PVector realWorldPoint;

  translate(0, 0, centerZ);  // set the rotation center of the scene 1000 infront of the camera


  int userCount = context.getNumberOfUsers();
  int[] userMap = null;
  if (userCount > 0)
  {
    userMap = context.getUsersPixels(SimpleOpenNI.USERS_ALL);
  }

  userPosition = new PVector();
  for (int y=0;y < context.depthHeight();y+=steps)
  {
    for (int x=0;x < context.depthWidth();x+=steps)
    {
      index = x + y * context.depthWidth();
      if (depthMap[index] > 0)
      { 
        // get the realworld points
        realWorldPoint = context.depthMapRealWorld()[index];

        // check if there is a user
        if (userMap != null && userMap[index] != 0)          
        {  // calc the user color
          int colorIndex = userMap[index] % userColors.length;
          stroke(userColors[colorIndex]);
          strokeWeight(2);
          context.getCoM(colorIndex, userPosition);
          //println(pos.z);
          //centerZ = pos.z - pos.z*2;
          point(realWorldPoint.x, realWorldPoint.y, realWorldPoint.z*zCoef + (userPosition.z - userPosition.z*zCoef) );
        }
        //        else
        //          // default color
        //          stroke(100); 
        //        point(realWorldPoint.x, realWorldPoint.y, realWorldPoint.z);
      }
    }
  } 

  // draw the tracked hand
  if (handsTrackFlag)  
  {
    pushStyle();
    stroke(255, 0, 0, 200);
    float z;
    noFill();
    Iterator itr = handVecList.iterator(); 

    beginShape();
    while ( itr.hasNext () ) 
    { 
      PVector p = (PVector) itr.next();
      z = p.z ;
      if (userPosition != null && userPosition.z != 0 ) z = z*zCoef + (userPosition.z - userPosition.z*zCoef);
      vertex(p.x, p.y, z);
    }
    endShape();   

    stroke(255, 0, 0);
    strokeWeight(4);
    z = handVec.z ;
    if (userPosition != null && userPosition.z != 0 ) z = z*zCoef + (userPosition.z - userPosition.z*zCoef);
    point(handVec.x, handVec.y, z);
    popStyle();
  }
}

// -----------------------------------------------------------------
// hand events

void onCreateHands(int handId, PVector pos, float time)
{
  println("onCreateHands - handId: " + handId + ", pos: " + pos + ", time:" + time);

  handsTrackFlag = true;
  handVec = pos;


  handVecList.clear();
  handVecList.add(pos);
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

void movieEvent(GSMovie movie) {
  movie.read();
}

