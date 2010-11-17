import processing.video.*;

int w, h;

int videoLength = 100;
boolean createVideo = false;

int frame = 1;

float min_radius = 0.5;
float max_radius = 3.0;
float min_velocity = 0.3;
float max_velocity = 1.9;

int dot_count = 100;
Dot[] dots;

MovieMaker mm;  // Declare MovieMaker object

void setup () {
  int i;
  w = 640;
  h = 480;
  int max_orbit = int(h * 0.7);
  
  size (w, h);
  background(0);
  
  // use the GPU
  smooth();
  
  dots = new Dot[dot_count];
  
  for (i=0; i<dot_count; i++)
  {
    dots[i] = new Dot().cx(w/2).cy(h/2);
    dots[i].radius(random(min_radius, max_radius));
    dots[i].orbit(random(1, max_orbit));
    dots[i].velocity(random(min_velocity, max_velocity));
  }
  
  if (createVideo) {
    mm = new MovieMaker(this, w, h, "drawing-"+year()+""+month()+""+day()+"-"+hour()+""+minute()+""+second()+".mov",
                       30, MovieMaker.VIDEO, MovieMaker.LOSSLESS);
  }
}

void draw () {
  int i;
  background(0);
  
  if (createVideo && frame > videoLength) {
    mm.finish();
    return;
  }
  for (i=0; i<dot_count; i++)
  {
    dots[i].display();
  }
  if (createVideo) {
    mm.addFrame();  // Add window's pixels to movie
  }
  frame++;
}

class Dot {
  float cx, cy;
  float angle;
  float radius;
  float orbit;
  float circ;
  float velocity;
  color col;
  float scl;
  
  Dot () {
    cx = 0;
    cy = 0;
    radius = 1;
    scl = 1;
    angle = random(360);
    orbit(100);
    velocity = 1;
    int mycol = 1 + int(random(5));
    int r = mycol == 1 || mycol == 2 || mycol == 6 ? 255 : 80;
    int g = mycol == 2 || mycol == 3 || mycol == 4 ? 255 : 80;
    int b = mycol == 4 || mycol == 5 || mycol == 6 ? 255 : 80;
    col = color (r, g, b, 120);
  }
  
  void Move () {
    angle += velocity/circ * 360;
  }
  
  Dot cx (float cx) {
    this.cx = cx;
    return this;
  }
  
  Dot cy (float cy) {
    this.cy = cy;
    return this;
  }
  
  Dot radius (float radius) {
    this.radius = radius;
    return this;
  }
  
  Dot orbit (float orbit) {
    this.orbit = orbit;
    this.circ = PI*this.orbit*2;
    return this;
  }
  
  Dot velocity (float velocity) {
    this.velocity = velocity;
    return this;
  }
  
  Dot col (color col) {
    this.col = col;
    return this;
  }
  
  Dot scl (float scl) {
    this.scl = scl;
    return this;
  }
  
  void display () {
    float x, y;
    float diameter = radius*2*scl;
    
    Move();
    x = cx + cos(angle*PI/180) * orbit * scl;
    y = cy + sin(angle*PI/180) * orbit * scl;
    
    if (x > -diameter && x < w && y > -diameter && y < h)
    {
      noStroke();
      fill(col);
      ellipse(x, y, diameter, diameter);
    }
  }
}

