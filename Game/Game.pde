float dx, dy, rx, rz;
boolean first = true;

void settings() {
  size(500, 500, P3D);
}

void setup() {
  stroke(0);
}

void draw() {
  camera(); 
  directionalLight(50, 100, 125, 0, -1, 0); 
  ambientLight(102, 102, 102);
  background(200);
  translate(width/2, height/2, 0);
  rotateX(rx);
  rotateZ(rz);
  box(100, 5, 100);
}

void mousePressed() {
  stroke(255);
}

void mouseReleased() {
  stroke(0);
}

void mouseDragged() {
  dx += mouseX - pmouseX;
  dy += mouseY - pmouseY;
  rx = map(-dy, 0, height, 0, PI/3);
  rz = map(dx, 0, width, 0, PI/3);
}
