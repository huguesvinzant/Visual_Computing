class Mover {

  PVector location;
  PVector velocity;
  PVector gravityForce;
  float gravityConstant = 1;

  Mover() 
  {
    gravityForce = new PVector(0,0,0);
    location = new PVector(0,0,0);
    velocity = new PVector(0,0,0);
  }
  
  void update(float rotx, float rotz)
  {
      gravityForce.x = sin(rotz) * gravityConstant;
      gravityForce.z = sin(rotx) * gravityConstant;
      float normalForce = 1;
      float mu = 0.05;
      float frictionMagnitude = normalForce * mu;
      PVector friction = velocity.copy();
      friction.mult(-1);
      friction.normalize();
      friction.mult(frictionMagnitude);
      velocity.add(gravityForce);
      velocity.add(friction);
      location.add(velocity);
  }

  void display(float rayon)
  {
     translate(location.x,-12,-location.z);
     pushMatrix();
     rotateX(location.z/rayon); // for the rotation of the sphere
     rotateY(location.x/rayon);
     shape(globe); // instead of sphere(10);
     popMatrix();
  }

  void checkEdges(float box_edge) 
  {
    if ((location.x >= box_edge))
    {
      velocity.x = velocity.x * -1;
      location.x = box_edge;
    }
    if ((location.x <= -box_edge)) {
      velocity.x = velocity.x * -1;
      location.x = -box_edge;
    }
    if ((location.z >= box_edge)) {
      velocity.z = velocity.z * -1;
      location.z = box_edge;
    }
    if ((location.z <= -box_edge)) {
      velocity.z = velocity.z * -1;
      location.z = -box_edge;
    }
  }
  
  void ckeckCylinderCollision(ArrayList<PVector> Cylinderlocations, float radiusSphere, float radiusCylinder) {
    for(int i=0; i < Cylinderlocations.size(); i++) {
      float distance = dist(location.x, location.y, location.z, Cylinderlocations.get(i).x, 0, Cylinderlocations.get(i).y * -1);
      
      println("Distance: " + distance);
      if (distance < radiusCylinder+radiusSphere) {
        PVector n = new PVector(location.x - Cylinderlocations.get(i).x,0,location.z - Cylinderlocations.get(i).y * -1);
        velocity.sub(n.mult(2*(velocity.dot(n))));
      }
    }
  }
}
