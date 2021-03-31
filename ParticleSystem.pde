//Adapted from "Particles by Daniel Shiffman".

class ParticleSystem {
  ArrayList<Particle> particles;
  int[] rgb;

  PShape particleShape;

  ParticleSystem(int n, int[] rgb) {
    particles = new ArrayList<Particle>();
    particleShape = createShape(PShape.GROUP);
    this.rgb = rgb;
    for (int i = 0; i < n; i++) {
      Particle p = new Particle(rgb);
      particles.add(p);
      particleShape.addChild(p.getShape());
    }
  }

  void update() {
    for (Particle p : particles) {
      p.update();
    }
  }

  void setEmitter(float x, float y) {
    for (Particle p : particles) {
      if (p.isDead()) {
        p.rebirth(x, y);
      }
    }
  }

  void display() {

    shape(particleShape);
  }
}
