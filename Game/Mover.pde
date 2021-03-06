// A simple Mover class
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
  
  // Method to update location according to the velocity
  void update(float rotx, float rotz)
  {
      gravityForce.x = sin(rotz) * gravityConstant;
      gravityForce.z = sin(rotx) * gravityConstant;
      float normalForce = 1;
      float mu = 0.2;
      float frictionMagnitude = normalForce * mu;
      PVector friction = velocity.copy();
      friction.mult(-1);
      friction.normalize();
      friction.mult(frictionMagnitude);
      velocity.add(gravityForce);
      velocity.add(friction);
      location.add(velocity);
  }

  // Method for collision with box edges
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
  
  // Method for collision with cylinders
  float ckeckCylinderCollision(ArrayList<PVector> Cylinderlocations, float radiusSphere, float radiusCylinder) {
    for(int i=0; i < Cylinderlocations.size(); i++) {
      float distance = dist(location.x, 0, location.z, Cylinderlocations.get(i).x, 0, Cylinderlocations.get(i).z * -1);
      if (distance <= radiusCylinder+radiusSphere) {
        if(i==0){
          user_won = true;
          particle_ON = false;
          return 0;
        }
        PVector n = new PVector(location.x - Cylinderlocations.get(i).x, 0, location.z - Cylinderlocations.get(i).z * -1).normalize();
        float score = velocity.mag();
        velocity.sub(n.mult(2*velocity.dot(n)));
        clicks_shiftDisabled.remove(i);
        ParticleSystem.particles.remove(i);
        return score;
      }
    }
    return 0;
  }
}
