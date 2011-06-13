// A simple Particle class

class Particle {
  PVector loc;
  PVector vel;
  PVector acc;
  float rad;
  float timer;
  int angle;
  PGraphics pg;


  // One constructor
  Particle(PVector a, PVector v, PVector l, float r_) {
    acc = a.get();
    vel = v.get();
    loc = l.get();
    rad = r_;
    timer = 100.0;
  }

  // Another constructor (the one we are using here)
  Particle(PVector l) {
    acc = new PVector(0, 0, 0);
    vel = new PVector(random(-0.2, 0.2)/scaleXY, random(-0.2, 0.2)/scaleXY, 0);
    loc = l.get();
    rad = 10;
    //r = 10.0;
    timer = 20.0;
  }


  void run() {
    update();
    render();
  }

  // Method to update location
  void update() {
    vel.add(acc);
    loc.add(vel);
    timer -= 1.0;
  }

  // Method to display
  void render() {
    noStroke();
    if (male)
      fill(112 , 12 , 175, 100);
    else
      fill(250 , 120 , 12, 100);
      
    angle += 10;
    float val = 2*cos(radians(angle)) * 6.0/scaleXY;
    for (int a = 0; a < 360; a += 75) {
      float xoff = cos(radians(a)) * val/scaleXY;
      float yoff = sin(radians(a)) * val/scaleXY;
      ellipse(loc.x + xoff, loc.y + yoff, val, val);
    }
    fill(255);
    ellipse(loc.x, loc.y, 4/scaleXY, 4/scaleXY);
  }

  // Is the particle still useful?
  boolean dead() {
    if (timer <= 0.0) {
      return true;
    } 
    else {
      return false;
    }
  }
}

class BubbleParticle extends Particle {
  float bSize = 6/scaleXY;

  BubbleParticle(PVector l) {
    super(l);
    acc.x = random(0.6, 1.2)/scaleXY;
    acc.y = random(0.3, 0.8)/scaleXY;
    vel.x = random(-30, -20)/scaleXY;
    vel.y = random(-4, 2)/scaleXY;
    timer = 35;
  }
  void render() {
    tint(255, 64);
    image(bubbleTex, loc.x, loc.y, bSize, bSize);
  }
  
  // Method to update location
  void update() {
    if (vel.x * (vel.x + acc.x) <= 0 )  
      acc.x = -vel.x/3.5;  
    vel.add(acc);
    loc.add(vel);
    timer -= 1.0;
  }  
}

