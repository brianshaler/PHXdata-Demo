import processing.video.*;

int w, h;

int cx, cy;
int videoLength = 1000;
boolean createVideo = false;
boolean showHistogram = false;

int current_pose = 0;
float current_x;
float current_y;
float current_zoom;

int frame = 1;

float min_radius = 0.1;
float max_radius = 1.2;
float min_velocity = 0.3;
float max_velocity = 1.9;

int cluster_count = 1;
Cluster[] clusters;
int dot_count = 100000;
Dot[] dots;
Pose[] poses;
int[] points;
int buckets = 1000;

MovieMaker mm;  // Declare MovieMaker object

void setup () {
  int i;
  w = 1440;
  h = 900;
  int max_orbit = int(h * 0.7);
  int range = 1000;
  float total_points = 50000;
  float mid = max_orbit * .3;
  float index;
  float j;
  float f;
  
  size (w, h);
  background(0);
  smooth();
  
  clusters = new Cluster[1];
  dots = new Dot[dot_count];
  points = new int[range];
  
  poses = new Pose[6];
  poses[0] = new Pose(1, 25, w/4-100, h/4+100);
  poses[1] = new Pose(200, 25, w/4+100, h/4-100);
  poses[2] = new Pose(500, 5, w/3, h/3);
  poses[3] = new Pose(600, 1.5, w/2, h/2);
  poses[4] = new Pose(1000, 10, w*.7, h*.6);
  poses[5] = new Pose(9999, 1, w*.7, h*.6);
  
  clusters[0] = new Cluster(dot_count).x(w/2).y(h/2).startx(w/2).starty(h/2);
  
  for (i=0; i<buckets; i++)
  {
    points[i] = 0;
  }
  for (i=0; i<total_points; i++)
  {
    j = i/total_points * range;
    index = distribute(j, mid, range);
    points[int(index/range * buckets)]++;
  }
  for (i=0; i<dot_count; i++)
  {
    dots[i] = new Dot(clusters[0]);
    dots[i].radius(random(min_radius*1000, max_radius*1000)/1000);
    dots[i].orbit(distribute(random(1650, max_orbit*1000)/1000, mid, max_orbit));
    dots[i].velocity(random(min_velocity*1000, max_velocity*1000)/1000);//*(random(2)-1));
  }
  
  Date d = new Date();
  long current = d.getTime()/1000;
  String nm = str(current);
  
  if (createVideo) {
    mm = new MovieMaker(this, w, h, "drawing-"+year()+""+month()+""+day()+"-"+hour()+""+minute()+""+second()+".mov",
                       30, MovieMaker.VIDEO, MovieMaker.LOSSLESS);
  }
}

float distribute (float p, float mid, float range) {
  float X;
  float z;
  float asymptote;
  float result;
  
  if (p<mid)
  {
    X = p+1.5;
    asymptote = ((-X*.29-mid/X*.9) + mid*.3)*2;
    asymptote = asymptote > 0 ? asymptote : 0;
    return p + asymptote;
  } else
  {
    X = -(p-mid)-10;
    asymptote = ((-X*.64-(range-mid)/X*6) + (range-mid)*.45935)*.91;
    asymptote = asymptote > 0 ? asymptote : 0;
    result = mid + X + asymptote;
    if (result > range-1) { result = range-1; }
    if (result < 0) { result = 0; }
    return result;
    //return mid + (p-mid)/(2-1*((p+50)-mid)/(range+50-mid));
  }
}

void draw () {
  int i;
  background(0);
  
  if (frame >= poses[current_pose+1].frame)
  {
    current_pose += 1;
  }
  
  float f = float(frame-poses[current_pose].frame) / float(poses[current_pose+1].frame-poses[current_pose].frame);
  current_zoom = tween(poses[current_pose].zoom, poses[current_pose+1].zoom, f);
  current_x = tween(poses[current_pose].x, poses[current_pose+1].x, f);
  current_y = tween(poses[current_pose].y, poses[current_pose+1].y, f);
  println("("+frame+"): "+current_x+", "+current_y+" @"+current_zoom+"x");
  
  if (createVideo && frame > videoLength) {
    mm.finish();
    return;
  }
  for (i=0; i<cluster_count; i++)
  {
    clusters[i].display();
  }
  if (showHistogram)
  {
    for (i=0; i<buckets; i++)
    {
      stroke(255);
      strokeWeight(1);
      line(i, 0, i, points[i]*2);
    }
  }
  if (createVideo) {
    mm.addFrame();  // Add window's pixels to movie
  }
  frame++;
}

float tween (float v1, float v2, float f) {
  //println(f+" of "+v1+" / "+v2);
  return v1 + (v2-v1) * (sin(f*PI-HALF_PI)+1)/2;
}

class Cluster {
  float x, y;
  float startx, starty;
  float scl = 1;
  int dot_count;
  int dots_added = 0;
  Dot[] dots;
  
  Cluster (int dot_count) {
    this.dot_count = dot_count;
    dots = new Dot[dot_count];
  }
  
  void addDot (Dot dot) {
    dots[dots_added] = dot;
    dots_added++;
  }
  
  void display () {
    int i;
    
    x = w/2 - (current_x - startx)*current_zoom;
    y = h/2 - (current_y - starty)*current_zoom;
    scl = current_zoom;
    for (i=0; i<dot_count; i++)
    {
      dots[i].scl = scl;
      dots[i].Move();
      dots[i].display();
    }
  }
  
  Cluster x (float x) {
    this.x = x;
    return this;
  }
  
  Cluster y (float y) {
    this.y = y;
    return this;
  }
  
  Cluster startx (float startx) {
    this.startx = startx;
    return this;
  }
  
  Cluster starty (float starty) {
    this.starty = starty;
    return this;
  }
}

class Dot {
  Cluster cluster;
  float cx, cy;
  float angle;
  float radius;
  float orbit;
  float circ;
  float velocity;
  color col;
  float scl;
  
  Dot (Cluster _cluster) {
    cluster = _cluster;
    cluster.addDot(this);
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
    
    x = cluster.x + cos(angle*PI/180) * orbit * scl;
    y = cluster.y + sin(angle*PI/180) * orbit * scl;
    
    if (x > -diameter && x < w && y > -diameter && y < h)
    {
      noStroke();
      fill(col);
      ellipse(x, y, diameter, diameter);
    }
  }
}

class Pose {
  int frame;
  float zoom;
  float x, y;
  Pose (int _frame, float _zoom, float _x, float _y) {
    frame = _frame;
    zoom = _zoom;
    x = _x;
    y = _y;
  }
}

