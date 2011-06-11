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
    vel = new PVector(random(-0.2, 0.2), random(-0.2, 0.2), 0);
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
    //    float r = dist (0,height,mouseX,mouseY);
    //    float g = dist (width,height,mouseX,mouseY);
    //    float b = dist (0,0,mouseX,mouseY);
    fill(250, 150, 200, 100);
    //    ellipse(loc.x,loc.y,rad,rad);//random(100));
    // image(pg, 0, 0, width, height); 


    angle += 10;
    float val = 2*cos(radians(angle)) * 6.0;
    for (int a = 0; a < 360; a += 75) {
      float xoff = cos(radians(a)) * val;
      float yoff = sin(radians(a)) * val;
      ellipse(loc.x + xoff, loc.y + yoff, val, val);
    }
    fill(255);
    ellipse(loc.x, loc.y, 4, 4);
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
  int bSize = 6;

  BubbleParticle(PVector l) {
    super(l);
    acc.x = random(0.6, 1.2);
    acc.y = random(0.2, 0.6);
    vel.x = random(-30, -20);
    vel.y = random(-4, 2);
    timer = 30;
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

