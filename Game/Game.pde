/*
Global Variables
*/
import processing.video.*;
import gab.opencv.*;
OpenCV opencv = new OpenCV(this, 800, 600);;
BlobDetection blobDetect = new BlobDetection();
HoughClass hough = new HoughClass();
QuadGraph quad = new QuadGraph();
TwoDThreeD two_d = new TwoDThreeD(800,600,0.0);
ImageProcessing imgproc = new ImageProcessing();

HScrollbar thresholdUpBar, thresholdBarminH,thresholdBarmaxH,thresholdBarminS,thresholdBarmaxS,thresholdBarminB,thresholdBarmaxB;
float thresholdUp, minH, maxH, minS, maxS, minB, maxB;

PImage img_accumulator, img_lines, img_edge;
ArrayList<PVector> hough_list, quad_list,homo_quads;
PVector angles,degree_angles;
Mover mover;
ParticleSystem ParticleSystem;
HScrollbar hs;
float dx, dy, rx, rz, depth = 400, speed = 1.0, box_size = 300, rayon = 5, cylinderBaseSize = 10, cylinderHeight = 20, last = 0, score;
boolean shiftIsPressed = false, user_won = false, was_clicked = false, particle_ON = false;
int cylinderResolution = 40;
ArrayList<PVector> clicks_shiftEnabled = new ArrayList(), clicks_shiftDisabled = new ArrayList();
ArrayList<Float> scores = new ArrayList<Float>();
PShape globe, robotnik, openCylinder = new PShape();
PVector particle_origin;  
PFont f;
String text_displayed = " ", text_score = " ", text_velocity = " ", text_last = " ";
PGraphics gameSurface, scoreboard, barChart, topView;

void settings() {
  size(500, 500, P3D);
}

void setup() {
  
  hs = new HScrollbar(200, 490, 300, 10);
  
  gameSurface = createGraphics(width, height-100, P3D);
  scoreboard = createGraphics(100, 100, P2D);
  topView = createGraphics(100, 100, P2D);
  barChart = createGraphics(300, 90, P2D);

  stroke(0);
  mover = new Mover();
  robotnik = loadShape("robotnik.obj");

  f = createFont("Arial",32,true); 
  
  //create a shpere shape with ice texture
  PImage earth = loadImage("ice.jpg");
  globe = createShape(SPHERE, rayon); 
  globe.setTexture(earth);
  globe.setStroke(false);
  
  creating_cylinder();
  imgproc = new ImageProcessing();
  String []args = {"Image processing window"};
  PApplet.runSketch(args, imgproc);
}

void draw(){
  drawGame();
  image(gameSurface, 0, 0);
  drawScoreboard();
  image(scoreboard, 100, height-100);
  drawTopView();
  image(topView, 0, height-100);
  drawBarChart();
  image(barChart, 200, height-100, 300, 100);
  hs.update(); 
  hs.display();
  
  rx = imgproc.rx;
  rz = imgproc.rz;
}

ArrayList<PVector> to_homo(ArrayList<PVector> quad_list){
  for(int i = 0; i < quad_list.size(); ++i){
    PVector quad = quad_list.get(i);
    quad.add(0,0,1.0);
  }
  return quad_list;
}

void drawBarChart() {
  barChart.beginDraw();
  barChart.background(200);
  barChart.noStroke();
  for(int i = 0; i < scores.size(); ++i) {
    if(scores.get(i) >= 0){
      barChart.fill(0, 255, 0);
      barChart.rect(hs.getPos()*i, 50, hs.getPos(), -scores.get(i)/2);
    }
    else if(scores.get(i) < 0){
      barChart.fill(255, 0, 0);
      barChart.rect(hs.getPos()*i, 50, hs.getPos(), -scores.get(i)/2);
    }
  }
  barChart.endDraw();
}

void drawTopView(){
  topView.beginDraw();
  topView.background(255);
  topView.fill(200);
  topView.scale(0.3333);
  topView.rect(0, 0, 300, 300);
  if(particle_ON) {
    for(int i = 0; i < ParticleSystem.particles.size(); i++) {
      float x = (ParticleSystem.particles.get(i).center.x + box_size - 5*cylinderBaseSize) - 100;
      float y = (ParticleSystem.particles.get(i).center.z + box_size - 5*cylinderBaseSize) - 100;
      if(i == 0) {
        topView.fill(0);
        topView.noStroke();
        topView.ellipse(x, y, 20, 20);
      }
      else {
      topView.fill(255);
      topView.noStroke();
      topView.ellipse(x, y, 20, 20);
      }
    }
  }
  
  float x = (mover.location.x + box_size - 5*cylinderBaseSize) - 100;
  float y = (mover.location.z + box_size - 5*cylinderBaseSize) - 100;
  topView.fill(100);
  topView.stroke(10);
  topView.ellipse(x, box_size-y, 15, 15);
  
  topView.endDraw();
}

void drawScoreboard(){
  scoreboard.beginDraw();
  scoreboard.background(0);
  
  scoreboard.fill(255);
  scoreboard.textSize(10);
  if(scores.size() == 0) {
    text_score = "Total score :"+ String.format("%.2f", (float) 0);
    scoreboard.text(text_score, 5, 20);
  }
  else {
    text_score = "Total score :"+ String.format("%.2f", scores.get(scores.size()-1));
    scoreboard.text(text_score, 5, 20);
  }
  text_velocity = "Velocity :"+ String.format("%.2f", mover.velocity.mag());
  scoreboard.text(text_velocity, 5, 40);
  
  text_last = "Last hit :"+ String.format("%.2f", last);
  scoreboard.text(text_last, 5, 60);
  
  scoreboard.endDraw();
}

void drawGame(){
  gameSurface.beginDraw();
  if (shiftIsPressed)
    updating_scene_shiftON();
  else
    updating_scene_shiftOFF();
  gameSurface.endDraw();
}

void setting_scene_and_background() {
  gameSurface.camera(width/2, height/2, depth, 250, 250, 0, 0, 1, 0);
  //gameSurface.directionalLight(50, 100, 125, 0, -1, 0); 
  //gameSurface.ambientLight(102, 102, 102);
  gameSurface.background(225);
}

/*
Drawing scene in SHIFT ON mode: top view of the board where user can click to set robotnik position
*/
void updating_scene_shiftON() {

  setting_scene_and_background();
  gameSurface.pushMatrix();
  gameSurface.translate(width/2, height/2, 0);
  gameSurface.rotateX(radians(90));
  gameSurface.rotateZ(0);
  //gameSurface.fill(200,100,0,50);
  gameSurface.noFill();
  gameSurface.box(box_size, 5, box_size);
  gameSurface.popMatrix();
  //if the user clicked on the plate, we add his click on the clicks_shiftEnabled object with x and y position, we then display the cylinder
  //if the user then click on another postion, we replace x and y 
  if(clicks_shiftEnabled.size()>0) 
    displaying_cylinder_shiftON();

  gameSurface.pushMatrix();
  //displaying the ball
  float x = (mover.location.x + box_size - 5*cylinderBaseSize);
  float y = (mover.location.z + box_size - 5*cylinderBaseSize) - 200;
  gameSurface.fill(100);
  gameSurface.stroke(10);
  gameSurface.ellipse(x, box_size-y, 20, 20);
  gameSurface.popMatrix();
  
  gameSurface.pushMatrix();
  //displaying a cylinder on the mouse position
  gameSurface.translate(mouseX, mouseY+50, 0);
  gameSurface.shape(openCylinder);
  gameSurface.popMatrix();
  //displaying rotations, speed and if the user won
  displaying_text();  
}

/*
Drawing scene in game mode (SHIFT released): the user can rotate the plate to move the ball
*/
void updating_scene_shiftOFF() {

  setting_scene_and_background();
  gameSurface.translate(width/2, height/2, 0);
  gameSurface.pushMatrix();
  gameSurface.rotateX(rx);
  gameSurface.rotateZ(rz);
  //if the user clicked on the plate in SHIFT ON mode, we draw Robotnik at the corresponding position
  if(clicks_shiftEnabled.size()>0) 
    displaying_robotnik();
  //if the user clicked on the plate in SHIFT ON mode, we start to add particles
  if(particle_ON) {
    if(frameCount % 120 == 0 && !user_won) {
      ParticleSystem.addParticle();
      if(scores.size() != 0) {
        scores.add(scores.get(scores.size()-1) - 2);
      }
    }
    for(int i=0; i < ParticleSystem.particles.size(); i++) {
      gameSurface.pushMatrix();
      gameSurface.translate(ParticleSystem.particles.get(i).center.x, ParticleSystem.particles.get(i).center.y, ParticleSystem.particles.get(i).center.z);
      gameSurface.rotateX(radians(90));
      gameSurface.shape(openCylinder);
      gameSurface.popMatrix();
    }
  }
  //creating plate and moving ball
  creating_plate();
  mover.update(rx, rz);
  mover.checkEdges(box_size/2);
  if (!user_won) {
    score = mover.ckeckCylinderCollision(clicks_shiftDisabled, rayon, cylinderBaseSize);
    if(scores.size() == 0) {
      scores.add(score);
    }
    else {
    scores.add(scores.get(scores.size()-1) + score);
    }
    if(score != 0) {
      last = score;
    }
  }
  displaying_mover();
  gameSurface.popMatrix();
  //displaying rotation and speed
  displaying_text(); 
}

/*
Displaying mover at the good position
*/
void displaying_mover() {
  gameSurface.translate(mover.location.x,-rayon -2,-mover.location.z);
  gameSurface.pushMatrix();
  gameSurface.rotateX(mover.location.z/rayon); // for the rotation of the sphere
  gameSurface.rotateY(mover.location.x/rayon);
  gameSurface.shape(globe); // instead of sphere(10);
  gameSurface.popMatrix();
}

/*
Displaying robotnik at the good position
*/
void displaying_robotnik() {

  gameSurface.pushMatrix();
  gameSurface.translate(particle_origin.x, 0, particle_origin.z);
  gameSurface.rotateX(radians(90));
  gameSurface.shape(openCylinder);
  gameSurface.popMatrix();
  gameSurface.pushMatrix();
  //Robotnik continuously look at the ball!
  float ang = atan2(mover.location.x-particle_origin.x, mover.location.z-particle_origin.z);
  gameSurface.translate(particle_origin.x, 0, particle_origin.z);
  gameSurface.rotateX(radians(180));
  gameSurface.rotateY(ang);
  gameSurface.scale(50);
  gameSurface.shape(robotnik, 0,0);
  gameSurface.popMatrix();
}

/*
Displaying the cylinder at the clicked position
*/
  void displaying_cylinder_shiftON() {
  
  gameSurface.pushMatrix();
  gameSurface.translate(clicks_shiftEnabled.get(0).x, clicks_shiftEnabled.get(0).y, 0);
  gameSurface.shape(openCylinder);
  gameSurface.popMatrix();  
}

/*
Creating a plate with tranparency to allow user to continuously see the ball
*/
void creating_plate() {

  //gameSurface.fill(200,100,0); // semi-transparent
  //gameSurface.box(box_size, 5, box_size);
  //gameSurface.hint(DISABLE_DEPTH_TEST);
  gameSurface.noFill();
  gameSurface.stroke(10);
  gameSurface.box(box_size, 5, box_size);
}

/*
Dislaying text in SHIFT ON mode and game mode, it also display a message when user won.
*/
void displaying_text() {

  gameSurface.fill(0);
  gameSurface.textFont(f);
  if(shiftIsPressed) {
    gameSurface.textSize(19);
    text_displayed = "RotationX: 90; RotationZ: 0; Speed: "+ String.format("%.2f", speed);
    gameSurface.text(text_displayed,-28,0,0);
    gameSurface.textSize(20);
    gameSurface.text("SHIFT_ON", 430, 430, 0);
  } else { 
    gameSurface.textSize(8);
    text_displayed = "RotationX: "+ String.format("%.2f", degrees(rx)) +"; RotationZ: "+ String.format("%.2f", degrees(rz)) +"; Speed: "+ String.format("%.2f", speed);
    gameSurface.text(text_displayed,-110,-100,depth-200); 
    //if user won we display a message
    if(user_won) {
      gameSurface.textSize(15);
      gameSurface.fill(0, 204, 102);
      gameSurface.text("You hit Robotnik! You won!",-90,-65,depth-200); 
      gameSurface.fill(0);
      gameSurface.textSize(7);
      gameSurface.text("Press SHIFT to choose another position for Robotnik",-90,-50,depth-200); 
      gameSurface.fill(0);
    }
  }   
}

/*
Changing color when user clicks
*/
void mousePressed() {
  gameSurface.stroke(255);
}

void mouseReleased() {
  gameSurface.stroke(0);
}

/*
Rotating plate when mouse is dragged
*/
void mouseDragged() {

  /*if(mouseOverGame()) {
    dx += mouseX - pmouseX;
    dy += mouseY - pmouseY;
    rx = map(-dy*speed, 0, height, 0, PI);
    rz = map(dx*speed, 0, width, 0, PI);
    if (rz > radians(60)) 
      rz = radians(60);
    else if (rz < radians(-60)) 
      rz = radians(-60);
    if (rx > radians(60)) 
      rx = radians(60);
    else if (rx < radians(-60)) 
      rx = radians(-60);
  }*/
}

/*
Setting zoom from arrows and setting SHIFT ON mode from SHIFT key
*/
void keyPressed() {

  float delta = 10;
  if (key == CODED) {
    if (keyCode == UP) {
      depth+=delta;
    }
    else if (keyCode == DOWN) {
      depth-=delta;
    }
    if (keyCode == SHIFT) {
      user_won = false;
      shiftIsPressed = true;
    }
  }
}

/*
Changing speed from mouse wheel
*/
void mouseWheel(MouseEvent event) {

  speed += float(event.getCount())*0.1;
  if(speed<0.1) 
    speed = 0.1;
  else if(speed > 3) 
    speed = 3;
}

/*
Setting game mode when SHIFT key is released
*/
void keyReleased() {

  if (key==CODED) {
    if (keyCode == SHIFT) {
        scores.clear();
        shiftIsPressed = false;
    }
  }
}

/*
Let user setting robotnik position
*/
void mouseClicked() {
  //verifying the user clicked on the plate
  if(shiftIsPressed && mouseX < 400 && mouseY+50 < 400 && mouseX > 100 && mouseY+50 > 100) { 
    float x = (mover.location.x + 250);
    float y = (-mover.location.z + 250);
    if(dist(mouseX, mouseY+50, x, y) > 20) {
      //clear the ArrayLists to add new position for Robotnik
      clicks_shiftDisabled.clear();
      clicks_shiftEnabled.clear();
      if(clicks_shiftDisabled.size()==0) {
        //adding position of cylinder in SHIFT ON mode and in game mode
        clicks_shiftEnabled.add( new PVector( mouseX, mouseY+50, 0 ) );
        particle_origin = new PVector( mouseX - box_size + 5*cylinderBaseSize, 0, mouseY+50 - box_size + 5*cylinderBaseSize );
        clicks_shiftDisabled.add(particle_origin);
        ParticleSystem = new ParticleSystem(particle_origin);
        particle_ON = true;
      }
    }
  }
}

boolean mouseOverGame() {
  if(mouseY <= 400) {
    return true;
  }
  else return false;
}

/*
Creating cylinder
*/
void creating_cylinder() {

  float angle;
  float[] x = new float[cylinderResolution+1];
  float[] y = new float[cylinderResolution+1];
 
  //get the x and z position on a circle for all the cylinderResolution
  for(int i=0; i < x.length; i++) {
    angle = TWO_PI / (cylinderResolution) * i;
    x[i] = sin(angle) * cylinderBaseSize;
    y[i] = cos(angle) * cylinderBaseSize;
  }
  
  openCylinder = createShape();
  
  //draw the cylinderBaseSize of the cylinder
  openCylinder.beginShape(TRIANGLE_FAN);
    openCylinder.vertex(0, 0, 0);
    for(int i=0; i < x.length; i++) {
      openCylinder.vertex(x[i], y[i], 0);
    }
  openCylinder.endShape();
 
  //draw the center of the cylinder
  openCylinder.beginShape(QUAD_STRIP); 
    for(int i=0; i < x.length; i++) {
      openCylinder.vertex(x[i], y[i], 0);
      openCylinder.vertex(x[i], y[i], cylinderHeight);
    }
  openCylinder.endShape();
 
  //draw the cylinderBaseSize of the cylinder
  openCylinder.beginShape(TRIANGLE_FAN); 
    openCylinder.vertex(0, 0, 0);
    for(int i=0; i < x.length; i++) {
      openCylinder.vertex(x[i], y[i], cylinderHeight);
    }
  openCylinder.endShape();
  
  PImage tree = loadImage("tree.jpg");
  openCylinder.setTexture(tree);
  openCylinder.setStroke(false);
}

PImage threshold_up(PImage img, float threshold){
  // create a new, initially transparent, 'result' image
  PImage result = createImage(img.width, img.height, RGB);
  for(int i = 0; i < img.width * img.height; i++) {
    if(brightness(img.pixels[i])>threshold) result.pixels[i] = img.pixels[i];
    else result.pixels[i] = 0;
  }
  return result;
}

PImage threshold_down(PImage img, float threshold){
  // create a new, initially transparent, 'result' image
  PImage result = createImage(img.width, img.height, RGB);
  for(int i = 0; i < img.width * img.height; i++) {
    if(brightness(img.pixels[i])<threshold) result.pixels[i] = img.pixels[i];
    else result.pixels[i] = 0;
  }
  return result;
}

PImage thresholdHSB(PImage img, float minH, float maxH, float minS, float maxS, float minB, float maxB){
  // create a new, initially transparent, 'result' image
  PImage result = createImage(img.width, img.height, RGB);
  for(int i = 0; i < img.width * img.height; i++) {
    if(brightness(img.pixels[i])>=minB & brightness(img.pixels[i])<=maxB & hue(img.pixels[i])>=minH & hue(img.pixels[i])<=maxH & saturation(img.pixels[i])>=minS & saturation(img.pixels[i])<=maxS){
      result.pixels[i] = color(255,255,255);
    }
    else{
      result.pixels[i] = color(0,0,0);
    }
  }
  return result;
}

boolean imagesEqual(PImage img1, PImage img2){
  if(img1.width != img2.width || img1.height != img2.height) return false;
  for(int i = 0; i < img1.width*img1.height ; i++)
    //assuming that all the three channels have the same value
    if(red(img1.pixels[i]) != red(img2.pixels[i])) return false;
    return true;
}

PImage convolute(PImage img) {

float[][] kernel = { { 9, 12, 9 },
{ 12, 15, 12 },
{ 9, 12, 9 }};
float normFactor = 99.f;

// create a greyscale image (type: ALPHA) for output
PImage result = createImage(img.width, img.height, ALPHA);

int N = kernel[0].length;
int pad = (N-1)/2;
// kernel size N = 3

// for each (x,y) pixel in the image:
// - multiply intensities for pixels in the range
// (x - N/2, y - N/2) to (x + N/2, y + N/2) by the
// corresponding weights in the kernel matrix
// - sum all these intensities and divide it by normFactor
// - set result.pixels[y * img.width + x] to this value

// create a new greyscale image of size img + padding.
PImage img_padded = createImage(img.width+(2*pad), img.height+(2*pad), ALPHA);

// Center the img into img_padded --> get img with a zero padding around borders.
img_padded.set(pad,pad,img);


////Convolution
for(int i=0;i< result.width;i++){
  for(int j=0;j< result.height;j++){
    color c = 0;
    for(int n=-pad;n<=pad;n++){
      for(int m=-pad;m<=pad;m++){
        result.loadPixels();
        c += brightness(img_padded.pixels[(i + pad - n) + (j + pad - m)*img_padded.width])*kernel[n + pad][m + pad];

      }
    }
        c /= normFactor;
        result.pixels[j * result.width + i] =  color(c);
        result.updatePixels();

  }
}

return result;
}

PImage scharr(PImage img) {
float normFactor = 1.f;
float[][] vKernel = {
{ 3, 0, -3 },
{ 10, 0, -10 },
{ 3, 0, -3 } };

float[][] hKernel = {
{ 3, 10, 3 },
{ 0, 0, 0 },
{ -3, -10, -3 } };

int N = hKernel[0].length;
int pad = (N-1)/2;

PImage result = createImage(img.width, img.height, ALPHA);
// clear the image
for (int i = 0; i < img.width * img.height; i++) {
result.pixels[i] = color(0);
}
float max=0;
float[] buffer = new float[img.width * img.height];
// *************************************
// Implement here the double convolution
// *************************************
// create a new greyscale image of size img + padding.
PImage img_padded = createImage(img.width+(2*pad), img.height+(2*pad), ALPHA);

// Center the img into img_padded --> get img with a zero padding around borders.
img_padded.set(pad,pad,img);

for(int i=0;i< result.width;i++){
  for(int j=0;j< result.height;j++){
    color sum_h = 0;
    color sum_v = 0;
    for(int n=-pad;n<=pad;n++){
      for(int m=-pad;m<=pad;m++){
        result.loadPixels();
        sum_h += brightness(img_padded.pixels[(i + pad - n) + (j + pad - m)*img_padded.width])*hKernel[n + pad][m + pad];
        sum_v += brightness(img_padded.pixels[(i + pad - n) + (j + pad - m)*img_padded.width])*vKernel[n + pad][m + pad];

      }
    }
        sum_h /= normFactor;
        sum_v /= normFactor;
        float sum=sqrt(pow(sum_h, 2) + pow(sum_v, 2));
        buffer[i + img.width*j] = sum;
        if(sum > max){
          max = sum;
        }

  }
}

for (int y = 1; y < img.height - 1; y++) { // Skip top and bottom edges
for (int x = 1; x < img.width - 1; x++) { // Skip left and right
int val=(int) ((buffer[y * img.width + x] / max)*255);
result.pixels[y * img.width + x]=color(val);
}
}
return result;
}
