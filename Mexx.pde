import SimpleOpenNI.*;
import codeanticode.gsvideo.*;
import processing.opengl.*;
import codeanticode.glgraphics.*;

//changes scene version
boolean male = false;

GSMovie movie;
PImage bg;

SimpleOpenNI context;
IntVector users;

//coeficient for body 3D depth increasing
float   zCoef = 4;

int[]   depthMap;
int     index;
PVector realWorldPoint;

//scale and shift scene
float xShift = 0;
float yShift = 0;
float zShift = 0;
float scaleXY = 1.4;

int     steps   = 6;  // to speed up the drawing, draw every 6th point

//hand tracking variables
boolean      handsTrackFlag = true;
PVector      handVec = new PVector();
ArrayList    handVecList = new ArrayList();
int          handVecListSize = 30;
String       lastGesture = "";

//Flower painting init
ParticleSystem psys;
ArrayList psystems;
PVector handScreenPos = new PVector();
PVector prevScreenPos = new PVector();

PVector userPosition; //current user position
HashMap COMs = new HashMap(); //user's centers of mass
int userCount = 0;
int[] userMap = null;
PVector screenPos = new PVector();

//Texture init
GLTexture bubbleTex;              // Texture used to draw each particle.
float bubbleSize;

//zilch
PVector zilchStartPoint = new PVector(583/scaleXY - xShift, 123/scaleXY - yShift, 0);
int pnum = 70; // max particle count
int zilchTimer = 0;
float minBubbleX = 10000;
float minBubbleY = 0;
int zilchDirection = 1;
ArrayList<BubbleParticle> zilchParticles = new ArrayList<BubbleParticle>();

//time vars
long millisToFade = 0;
final static int EMPTY_SCENE = 0;
final static int FADE_IN_SCENE = 1;
final static int FADE_OUT_SCENE = 2;
final static int ACTIVE_SCENE = 3;
int sceneState = EMPTY_SCENE;
int fadeTime = 3000;
int fadeMax = 255; //100% visible
int fadeMin = 64; // 64/255 visible 
int movieOpacity  = fadeMax;

void setup()
{
  size(1366, 768, GLConstants.GLGRAPHICS); 

  context = new SimpleOpenNI(this, SimpleOpenNI.RUN_MODE_MULTI_THREADED);

  users = new IntVector();

  // Load and play the video in a loop
  if (male) {
    movie = new GSMovie(this, "man-cropped-c.mov"); //load male movie
    //    bg = loadImage("man-background.001.png");
    bg = loadImage("white_background.png");
    bubbleTex = new GLTexture(this, "bubble.png");
    zilchStartPoint = new PVector(665/scaleXY - xShift, 113/scaleXY - yShift, 0);
    zilchDirection = 1;
  } 
  else {
    movie = new GSMovie(this, "wo-man-final-new-c.m4v"); //load female movie
    //    bg = loadImage("wo-man-final-new.png");
    bg = loadImage("white_background.png");
    bubbleTex = new GLTexture(this, "bubble-pink.png");
    zilchStartPoint = new PVector(265/scaleXY - xShift, 153/scaleXY - yShift, 0);
    zilchDirection = -1;
  }
  movie.loop();

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

  //Flower painting setup
  psystems = new ArrayList();
  psys = new ParticleSystem(1, new PVector(width/2, height/2, 0));
}

void draw()
{
  try {
    context.update();

    //backgroung image
    tint(255, 255);
    image(bg, 0, 0, width, height); 

    //movie
    movieOpacity = calcMovieOpacity();
    tint(255, movieOpacity);
    if (male) {
      image(movie, 510, 0);
    } 
    else {
      image(movie, 56, 0);
    } 

    //get depth map from kinect
    depthMap = context.depthMap();

    //calculate user's centers of mass
    userCount = context.getNumberOfUsers();
    userMap = null;
    if (userCount > 0)
    {
      userMap = context.getUsersPixels(SimpleOpenNI.USERS_ALL);

      //calculate centers of mass of users    
      context.getUsers(users);
      for (int i = 0; i < users.size(); i++) {
        PVector uPosition = new PVector();
        try {
          context.getCoM(users.get(i), uPosition);
          COMs.put(users.get(i), uPosition);
        }
        catch (Exception e) {
          e.printStackTrace();
          return;
        }
      }
    }

    pushMatrix(); 
    scale(scaleXY);
    translate(xShift, yShift, zShift); 


    if (zilchTimer > 0) {
      //add bubbles to zilch
      for (int i = 0; i < ceil(pnum); i++) {
        zilchParticles.add(new BubbleParticle(zilchStartPoint));
      }  
      zilchTimer -= 1;
    } 

    try {
      for (int y=0;y < context.depthHeight();y+=steps)
      {
        for (int x=0;x < context.depthWidth();x+=steps)
        {
          index = x + y * context.depthWidth();
          if (depthMap[index] > 0)
          { 
            // get the realworld points
            realWorldPoint = context.depthMapRealWorld()[index];         
            context.convertRealWorldToProjective(realWorldPoint, screenPos);

            // check if there is a user
            if (userMap != null && userMap[index] != 0) { 
              userPosition = (PVector)COMs.get(userMap[index]);
              bubbleSize = min((abs(20000/(realWorldPoint.z*zCoef + (userPosition.z - userPosition.z*zCoef)))), 80);
              tint(255, 100);
              if (screenPos.x > minBubbleX & screenPos.y < minBubbleY)
                image(bubbleTex, screenPos.x, screenPos.y, bubbleSize, bubbleSize);
            }
          }
        }
      }
    }
    catch(Exception e) {
      e.printStackTrace();
      return;
    }


    // draw the tracked hand
    if (handsTrackFlag && userCount > 0)  
    {   
      context.convertRealWorldToProjective(handVec, handScreenPos);

      if (prevScreenPos.x == 0 & prevScreenPos.y == 0) prevScreenPos = handScreenPos.get();
      float sx = handScreenPos.x - prevScreenPos.x;
      float sy = handScreenPos.y - prevScreenPos.y;
      int stepCount = ceil(sqrt(sq(sx) + sq(sy)) / 15);  

      for (int step = 0; step < stepCount; step++) {
        psystems.add(new ParticleSystem(1, new PVector(handScreenPos.x - sx * step/stepCount, handScreenPos.y - sy * step/stepCount )));
      }
      prevScreenPos = handScreenPos.get();
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
    if (minBubbleY > 600) minBubbleX = 0;
    popMatrix();
  }
  catch (Exception e) {
    e.printStackTrace();
    return;
  }
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
  prevScreenPos.x = 0;
  prevScreenPos.y = 0;
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
  //  movieOpacity = 64;

  //pause movie and fade in flacon, make zilch
  if (sceneState == EMPTY_SCENE) {
    zilchTimer = 11;
    minBubbleX = 10000;
    minBubbleY = 0;
    movie.pause();
    millisToFade = millis() + fadeTime;
    sceneState = FADE_IN_SCENE;
  }
  else if (sceneState == FADE_OUT_SCENE) {
    sceneState = FADE_IN_SCENE;
  }
}

void onLostUser(int userId)
{
  println("onLostUser - userId: " + userId);
  userCount = context.getNumberOfUsers();
  if (userCount == 0)
  {
    //loop movie and fade out flacon
    if (sceneState == ACTIVE_SCENE) {
      millisToFade = millis() + fadeTime;
      sceneState = FADE_OUT_SCENE;
    }
    else if (sceneState == FADE_IN_SCENE) {
      sceneState = FADE_OUT_SCENE;
    }    
    movie.loop();
  }
}


void mousePressed() {
  println("X, Y: " + mouseX + ", " + mouseY);
}

void movieEvent(GSMovie movie) {
  movie.read();
}

int calcMovieOpacity() {
  long mDiff;
  switch(sceneState) {
  case EMPTY_SCENE: 
    movieOpacity = fadeMax; 
    break;
  case ACTIVE_SCENE: 
    movieOpacity = fadeMin; 
    break;
  case FADE_IN_SCENE: 
    mDiff = millisToFade - millis();
    if ( mDiff > 0) {
      movieOpacity = fadeMin + ceil((fadeMax-fadeMin)*mDiff/fadeTime);
    }
    else {
      sceneState = ACTIVE_SCENE;
      movieOpacity = fadeMin;
    }
    break;
  case FADE_OUT_SCENE: 
    mDiff = millisToFade - millis();
    if ( mDiff > 0) {
      movieOpacity = fadeMax - ceil((fadeMax-fadeMin)*mDiff/fadeTime);
    }
    else {
      sceneState = EMPTY_SCENE;
      movieOpacity = fadeMax;
    }
    break;
  }
  return movieOpacity;
}

