/*Musical Fountains by Benjamin Seah Weile
  This artefact generates music and visualizes them in the form of a fountain. 
  The user can customize the notes being played through the use of the 
  matrix with the first column representing the Flute, second column being Violin and third column Guitar.
  The beat will play only when the first row of matrices are active.
  At the start of each bar, the chord will change to the next chord in the current progression
  Each instrument has a different octave but same key.
  Based on the user's mood and preference, the color pallete can also be changed. 
  "Current Mode" controls the current chord progression sequence based on common chord progressions.
  
  Please press an example to start
  
  Known Issue:
  The chord will sometimes not change after switching to another example during lag
  Example does not launch on start
 */
 
import controlP5.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;

Minim minim = new Minim(this);
ControlP5 cp5;

ArrayList<ParticleSystem> ps = new ArrayList<ParticleSystem>();
ArrayList<ParticleSystem> source = new ArrayList<ParticleSystem>();
ArrayList<Integer> xCoord = new ArrayList<Integer>();
ArrayList<Integer> yCoord = new ArrayList<Integer>();
PImage sprite;

int[] cyan = {0, 200, 255};
int[] white = {255, 255, 255};
int[] red = {255, 0, 0};
int[] orange = {255, 165, 0};
int[] yellow = {255, 255, 0};
int[] emerald = {80, 200, 120};
int[] indigo = {75,0,150};
int[] orchid = {186,85,211};

ArrayList<AudioPlayer> violin = new ArrayList<AudioPlayer>();
ArrayList<AudioPlayer> flute = new ArrayList<AudioPlayer>();
ArrayList<AudioPlayer> guitar = new ArrayList<AudioPlayer>();
ArrayList<AudioPlayer> beats = new ArrayList<AudioPlayer>();

int currentTime;
int timeElapsed;
int bpm = 120;
int intervalVal = 60000/bpm;

int chordNumber = 7;
int rootNote;
int thirdNote;
int fifthNote;

int currentMode = 1;
int n = 0;

int activeChords = 0;
int callNo = 0;

int[] currentChordNotes;
int[] currentChordProg = new int[3];

int[] mainEmitterIndex = {2, 7, 12, 17, 22, 27, 32, 37, 42, 47, 52, 57, 62, 67, 72, 77, 82, 87, 92, 97, 102};
ArrayList<Integer> fluteEmitters = new ArrayList<Integer>();
ArrayList<Integer> violinEmitters = new ArrayList<Integer>();
ArrayList<Integer> guitarEmitters = new ArrayList<Integer>();

int[] fluteEmVel = new int[21];
int[] violinEmVel = new int[21];
int[] guitarEmVel = new int[21];

boolean[] fluteEmVelR = new boolean[21];
boolean[] violinEmVelR = new boolean[21];
boolean[] guitarEmVelR = new boolean[21];

boolean[] fluteEmVelDir = new boolean[21];
boolean[] violinEmVelDir = new boolean[21];
boolean[] guitarEmVelDir = new boolean[21];

int fluteCap = 100;
int violinCap = 70;
int guitarCap = 90;
int chordCap = 120;

int fluteRise = 2;
int violinRise = 1;
int guitarRise = 4;
int chordRise = 8;

int fluteFall = 2;
int violinFall = 1;
int guitarFall = 5;
int chordFall = 10;

int base;
int examples = 1;
int colorScheme = 1;

//G - D - Em - C
final int[] chordProg1 = {1, 5, 6, 4};
//Em - D - C - Bm
final int[] chordProg2 = {6, 5, 4, 3};
//G - C - Am - D
final int[] chordProg3 = {1, 4, 2, 5};


void setup() {
  size(1050, 1000, P2D);

  //Start point of emitters in Y-axis 
  base = (height/3*2)+40;

  //From Particles example
  sprite = loadImage("sprite.png");

  //Instantiates ParticleSystem Objects with corresponding coordinates
  for (int i=0; i<=105; i++) {
    ps.add(new ParticleSystem(100, cyan));
    source.add(new ParticleSystem(40, white));
    xCoord.add(i*10);
    yCoord.add(base);
  }

  //Instantiates tracking variables for each Particle emitter
  for (int i=0; i<7; i++) {
    fluteEmVel[i] = 0;
    violinEmVel[i] = 0;
    guitarEmVel[i] = 0;

    fluteEmVelR[i] = false;
    violinEmVelR[i] = false;
    guitarEmVelR[i] = false;

    fluteEmVelDir[i] = false;
    violinEmVelDir[i] = false;
    guitarEmVelDir[i] = false;
  }

  for (int f=0; f<21; f+=3) {
    fluteEmitters.add(mainEmitterIndex[f]);
  }

  for (int v=1; v<21; v+=3) {
    violinEmitters.add(mainEmitterIndex[v]);
  }

  for (int g=2; g<21; g+=3) {
    guitarEmitters.add(mainEmitterIndex[g]);
  }

  //G-Major
  //In each array, 0 = G, 1 = A, 2 = B, 3 = C, 4 = D, 5 = E, 6 = F#, 7 = High G
  //Guitar: G3-G4, Violin: G4-G5, Flute: G5-G6
  for (int i = 1; i < 9; i++) {
    flute.add(minim.loadFile("data/flute/"+i+".wav"));
    guitar.add(minim.loadFile("data/guitar/"+i+".wav"));
    violin.add(minim.loadFile("data/violin/"+i+".wav"));
  }
  
  //E-Minor
  //  for (int i = 5; i < 9; i++) {
  //  flute.add(minim.loadFile("data/flute/"+i+".wav"));
  //  guitar.add(minim.loadFile("data/guitar/"+i+".wav"));
  //  violin.add(minim.loadFile("data/violin/"+i+".wav"));
  //}
  //for (int i = 1; i < 5; i++) {
  //  flute.add(minim.loadFile("data/flute/"+i+".wav"));
  //  guitar.add(minim.loadFile("data/guitar/"+i+".wav"));
  //  violin.add(minim.loadFile("data/violin/"+i+".wav"));
  //}
  

  hint(DISABLE_DEPTH_MASK);

  cp5 = new ControlP5(this);

  cp5.addMatrix("myMatrix")
    .setPosition(width/2-240, 840)
    .setSize(480, 39)
    .setGrid(8, 3)
    .setGap(1, 1)
    .setInterval(intervalVal)
    .setMode(ControlP5.MULTIPLES)
    .setColorBackground(color(120))
    .setBackground(color(40))
    .setLabelVisible(false)
    ;

  cp5.addSlider("currentMode")
    .setPosition(width/4-100, height-100)
    .setSize(200, 30)
    .setNumberOfTickMarks(3)
    .setRange(1, 3)
    .setValue(1)
    .setColorBackground(color(100, 100, 0))
    .setColorForeground(color(200, 200, 0))
    .setColorActive(color(255, 255, 0))
    ;


  //Beat to sample  
  beats.add(minim.loadFile("data/beats/120beat.wav"));

  cp5.addSlider("examples")
    .setPosition(width*3/4-100, height-100)
    .setSize(200, 30)
    .setNumberOfTickMarks(3)
    .setRange(1, 3)
    .setValue(1)
    .setColorBackground(color(100, 100, 0))
    .setColorForeground(color(200, 200, 0))
    .setColorActive(color(255, 255, 0))
    ;

  cp5.addSlider("colorScheme")
    .setPosition(width*2/4-100, height-100)
    .setSize(200, 30)
    .setNumberOfTickMarks(5)
    .setRange(1, 5)
    .setValue(1)
    .setColorBackground(color(100, 100, 0))
    .setColorForeground(color(200, 200, 0))
    .setColorActive(color(255, 255, 0))
    ;

  cp5.getController("currentMode").getCaptionLabel().align(ControlP5.CENTER, ControlP5.BOTTOM_OUTSIDE).setPaddingY(10);
  cp5.getController("examples").getCaptionLabel().align(ControlP5.CENTER, ControlP5.BOTTOM_OUTSIDE).setPaddingY(10);
  cp5.getController("colorScheme").getCaptionLabel().align(ControlP5.CENTER, ControlP5.BOTTOM_OUTSIDE).setPaddingY(10);
}

void draw() {
  background(0);  

  for (int i=0; i<ps.size(); i++) {
    ps.get(i).update();
    ps.get(i).display();
    ps.get(i).setEmitter(xCoord.get(i), yCoord.get(i));
    source.get(i).update();
    source.get(i).display();
    source.get(i).setEmitter(xCoord.get(i), yCoord.get(i));
  }

  animate(cp5.get(Matrix.class, "myMatrix"));

  noStroke();
  fill(1, 50);
  rect(0, (height/3*2)+50, width, (height/3)-50);

  fill(255);
  textSize(16);
  text("Frame rate: " + int(frameRate), 10, 20);

  if (currentMode == 1) {
    currentChordProg = chordProg1;
  } else if (currentMode == 2) {
    currentChordProg = chordProg2;
  } else if (currentMode == 3) {
    currentChordProg = chordProg3;
  }

  currentChordNotes = calculateNotes(currentChordProg[n]);

  if (cp5.get(Matrix.class, "myMatrix").get(0, 0)==true && cp5.get(Matrix.class, "myMatrix").get(0, 1)==true 
    && cp5.get(Matrix.class, "myMatrix").get(0, 2)==true) {
    activeChords = 3;
  } else if (cp5.get(Matrix.class, "myMatrix").get(0, 0)==true && cp5.get(Matrix.class, "myMatrix").get(0, 1)==true 
    && cp5.get(Matrix.class, "myMatrix").get(0, 2)==false) {
    activeChords = 2;
  } else if (cp5.get(Matrix.class, "myMatrix").get(0, 0)==true && cp5.get(Matrix.class, "myMatrix").get(0, 1)==false 
    && cp5.get(Matrix.class, "myMatrix").get(0, 2)==true) {
    activeChords = 2;
  } else if (cp5.get(Matrix.class, "myMatrix").get(0, 0)==false && cp5.get(Matrix.class, "myMatrix").get(0, 1)==true 
    && cp5.get(Matrix.class, "myMatrix").get(0, 2)==true) {
    activeChords = 2;
  } else
    activeChords = 1;

  for (int y=0; y<yCoord.size(); y++) {
    if (yCoord.get(y)<base)
      yCoord.set(y, yCoord.get(y)+40);
  }
}


void myMatrix(int theX, int theY) {

  //The first note in the bar is the full triad chord
  if (theX == 0 && theY == 0) {
    for (AudioPlayer e : flute)
      e.rewind();
    chord(currentChordProg[n], flute);
    currentChordNotes = calculateNotes(currentChordProg[n]);
    for (int i=0; i<7; i++) {
      fluteEmVelDir[i] = true;
      fluteEmVelR[i] = false;
    }
    if (flute.get(currentChordNotes[0]).isPlaying() && flute.get(currentChordNotes[1]).isPlaying()
      && flute.get(currentChordNotes[2]).isPlaying()) {
      chordRewind(currentChordProg[n], flute);
    }
  }
  if (theX == 0 && theY == 1) {
    for (AudioPlayer e : violin)
      e.rewind();
    chord(currentChordProg[n], violin);
    currentChordNotes = calculateNotes(currentChordProg[n]);
    for (int i=0; i<7; i++) {
      violinEmVelDir[i] = true;
      violinEmVelR[i] = false;
    }
    if (violin.get(currentChordNotes[0]).isPlaying() && violin.get(currentChordNotes[1]).isPlaying()
      && violin.get(currentChordNotes[2]).isPlaying()) {
      chordRewind(chordNumber, violin);
    }
  }
  if (theX == 0 && theY == 2) {
    for (AudioPlayer e : guitar)
      e.rewind();
    chord(currentChordProg[n], guitar);
    currentChordNotes = calculateNotes(currentChordProg[n]);
    for (int i=0; i<7; i++) {
      guitarEmVelDir[i] = true;
      guitarEmVelR[i] = false;
    }
    if (guitar.get(currentChordNotes[0]).isPlaying() && guitar.get(currentChordNotes[1]).isPlaying()
      && guitar.get(currentChordNotes[2]).isPlaying()) {
      chordRewind(chordNumber, guitar);
    }
  }

  if (theX == 0) {
    //Play beat on first bar
    beats.get(0).play();
    if (beats.get(0).isPlaying()) {
      beats.get(0).rewind();
    }
    callNo++;
    if (callNo == activeChords) {
      n++;
      if (n>3) {
        n=0;    
        currentChordNotes = calculateNotes(currentChordProg[n]);
      }
      callNo = 0;
    }
  }

  //Individual Instruments and Notes in Key of G in the current chord
  if (theX % 4 == 1 && theY == 0) {
    if (theX == 1) {
      fluteEmVelDir[0] = true;
      fluteEmVelR[0] = false;
    } else {
      fluteEmVelDir[4] = true;
      fluteEmVelR[4] = false;
    }
    flute.get(currentChordNotes[0]).play();
    if (flute.get(currentChordNotes[0]).isPlaying()) {
      flute.get(currentChordNotes[0]).rewind();
    }
  }
  if (theX % 4 == 2 && theY == 0) {
    if (theX == 2) {
      fluteEmVelDir[1] = true;
      fluteEmVelR[1] = false;
    } else {
      fluteEmVelDir[5] = true;
      fluteEmVelR[5] = false;
    }
    flute.get(currentChordNotes[1]).play();
    if (flute.get(currentChordNotes[1]).isPlaying()) {
      flute.get(currentChordNotes[1]).rewind();
    }
  }
  if (theX % 4 == 3 && theY == 0) {
    if (theX == 3) {
      fluteEmVelDir[2] = true;
      fluteEmVelR[2] = false;
    } else {
      fluteEmVelDir[6] = true;
      fluteEmVelR[6] = false;
    }
    flute.get(currentChordNotes[2]).play();
    if (flute.get(currentChordNotes[2]).isPlaying()) {
      flute.get(currentChordNotes[2]).rewind();
    }
  }
  if (theX == 4 && theY == 0) {
    fluteEmVelDir[3] = true;
    fluteEmVelR[3] = false;
    int rF = int(random(0, 8));
    flute.get(rF).play();
    if (flute.get(rF).isPlaying()) {
      flute.get(rF).rewind();
    }
  }
  if (theX % 4 == 1 && theY == 1) {
    if (theX == 1) {
      violinEmVelDir[0] = true;
      violinEmVelR[0] = false;
    } else {
      violinEmVelDir[4] = true;
      violinEmVelR[4] = false;
    }
    violin.get(currentChordNotes[1]).play();
    if (violin.get(currentChordNotes[1]).isPlaying()) {
      violin.get(currentChordNotes[1]).rewind();
    }
  }
  if (theX % 4 == 2 && theY == 1) {
    if (theX == 2) {
      violinEmVelDir[1] = true;
      violinEmVelR[1] = false;
    } else {
      violinEmVelDir[5] = true;
      violinEmVelR[5] = false;
    }
    violin.get(currentChordNotes[2]).play();
    if (violin.get(currentChordNotes[2]).isPlaying()) {
      violin.get(currentChordNotes[2]).rewind();
    }
  }
  if (theX % 4 == 3 && theY == 1) {
    if (theX == 3) {
      violinEmVelDir[2] = true;
      violinEmVelR[2] = false;
    } else {
      violinEmVelDir[6] = true;
      violinEmVelR[6] = false;
    }
    violin.get(currentChordNotes[0]).play();
    if (violin.get(currentChordNotes[0]).isPlaying()) {
      violin.get(currentChordNotes[0]).rewind();
    }
  }
  if (theX == 4 && theY == 1) {
    violinEmVelDir[3] = true;
    violinEmVelR[3] = false;
    int rV = int(random(0, 8));
    violin.get(rV).play();
    if (violin.get(rV).isPlaying()) {
      violin.get(rV).rewind();
    }
  }
  if (theX % 4 == 1 && theY == 2) {
    if (theX == 1) {
      guitarEmVelDir[0] = true;
      guitarEmVelR[0] = false;
    } else {
      guitarEmVelDir[4] = true;
      guitarEmVelR[4] = false;
    }
    guitar.get(currentChordNotes[2]).play();
    if (guitar.get(currentChordNotes[2]).isPlaying()) {
      guitar.get(currentChordNotes[2]).rewind();
    }
  }
  if (theX % 4 == 2 && theY == 2) {
    if (theX == 2) {
      guitarEmVelDir[1] = true;
      guitarEmVelR[1] = false;
    } else {
      guitarEmVelDir[5] = true;
      guitarEmVelR[5] = false;
    }
    guitar.get(currentChordNotes[0]).play();
    if (guitar.get(currentChordNotes[0]).isPlaying()) {
      guitar.get(currentChordNotes[0]).rewind();
    }
  }
  if (theX % 4 == 3 && theY == 2) {
    if (theX == 3) {
      guitarEmVelDir[2] = true;
      guitarEmVelR[2] = false;
    } else {
      guitarEmVelDir[6] = true;
      guitarEmVelR[6] = false;
    }
    guitar.get(currentChordNotes[1]).play();
    if (guitar.get(currentChordNotes[1]).isPlaying()) {
      guitar.get(currentChordNotes[1]).rewind();
    }
  }
  if (theX == 4 && theY == 2) {
    guitarEmVelDir[3] = true;
    guitarEmVelR[3] = false;
    int rG = int(random(0, 8));
    guitar.get(rG).play();
    if (guitar.get(rG).isPlaying()) {
      guitar.get(rG).rewind();
    }
  }
}

//Plays a triad chord in the Key 
void chord(int root, ArrayList<AudioPlayer> instrument) {
  instrument.get(root-1).play();

  if (root < 7)
    instrument.get(root+1).play();
  else
    instrument.get(root-6).play();

  if (root < 5)
    instrument.get(root+3).play();
  else
    instrument.get(root-4).play();
}

void chordRewind(int root, ArrayList<AudioPlayer> instrument) {
  instrument.get(root-1).rewind();

  if (root < 7)
    instrument.get(root+1).rewind();
  else
    instrument.get(root-6).rewind();

  if (root < 5)
    instrument.get(root+3).rewind();
  else
    instrument.get(root-4).rewind();
}

int[] calculateNotes(int chord) {
  int[] chordNotes = new int[4];
  chordNotes[0] = chord-1;

  if (chord < 7)
    chordNotes[1] = chord+1;
  else
    chordNotes[1] = chord-6;

  if (chord < 5)
    chordNotes[2] = chord+3;
  else
    chordNotes[2] = chord-4;

  if (chord < 3)
    chordNotes[3] = chord+5;
  else
    chordNotes[3] = chord-2;

  return chordNotes;
}

void examples(int val) {
  switch(val) {
  case 1:
    cp5.get("currentMode").setValue(1);
    cp5.get("colorScheme").setValue(1);
    cp5.get(Matrix.class, "myMatrix").clear();
    cp5.get(Matrix.class, "myMatrix").set(3, 0, true);
    cp5.get(Matrix.class, "myMatrix").set(0, 1, true);
    cp5.get(Matrix.class, "myMatrix").set(4, 1, true);
    cp5.get(Matrix.class, "myMatrix").set(0, 2, true);
    cp5.get(Matrix.class, "myMatrix").set(1, 2, true);
    cp5.get(Matrix.class, "myMatrix").set(2, 2, true);
    cp5.get(Matrix.class, "myMatrix").set(3, 2, true);
    cp5.get(Matrix.class, "myMatrix").set(4, 2, true);
    cp5.get(Matrix.class, "myMatrix").set(5, 2, true);
    cp5.get(Matrix.class, "myMatrix").set(6, 2, true);
    cp5.get(Matrix.class, "myMatrix").set(7, 2, true);
    break;
  case 2:
    cp5.get("currentMode").setValue(2);
    cp5.get("colorScheme").setValue(4);
    cp5.get(Matrix.class, "myMatrix").clear();
    cp5.get(Matrix.class, "myMatrix").set(1, 0, true);
    cp5.get(Matrix.class, "myMatrix").set(0, 1, true);
    cp5.get(Matrix.class, "myMatrix").set(1, 2, true);
    cp5.get(Matrix.class, "myMatrix").set(2, 2, true);
    cp5.get(Matrix.class, "myMatrix").set(4, 2, true);
    cp5.get(Matrix.class, "myMatrix").set(5, 2, true);
    cp5.get(Matrix.class, "myMatrix").set(7, 2, true);
    break;
  case 3:
    cp5.get("currentMode").setValue(3);
    cp5.get("colorScheme").setValue(3);
    cp5.get(Matrix.class, "myMatrix").clear();
    cp5.get(Matrix.class, "myMatrix").set(0, 0, true);
    cp5.get(Matrix.class, "myMatrix").set(1, 1, true);
    cp5.get(Matrix.class, "myMatrix").set(4, 1, true);
    cp5.get(Matrix.class, "myMatrix").set(0, 2, true);
    cp5.get(Matrix.class, "myMatrix").set(3, 2, true);
    cp5.get(Matrix.class, "myMatrix").set(7, 2, true);
    break;
  }
}

void colorScheme(int val) {
  switch(val) {
  case 1:
    ps = new ArrayList<ParticleSystem>();
    source = new ArrayList<ParticleSystem>();
    for (int i=0; i<=105; i++) {
      ps.add(new ParticleSystem(100, cyan));
      source.add(new ParticleSystem(40, white));
    }
    break;
  case 2:
    ps = new ArrayList<ParticleSystem>();
    source = new ArrayList<ParticleSystem>();
    for (int i=0; i<=105; i++) {
      ps.add(new ParticleSystem(100, red));
      source.add(new ParticleSystem(40, orange));
    }
    break;
  case 3:
    ps = new ArrayList<ParticleSystem>();
    source = new ArrayList<ParticleSystem>();
    for (int i=0; i<=105; i++) {
      ps.add(new ParticleSystem(100, yellow));
      source.add(new ParticleSystem(40, orange));
    }
    break;
  case 4:
    ps = new ArrayList<ParticleSystem>();
    source = new ArrayList<ParticleSystem>();
    for (int i=0; i<=105; i++) {
      ps.add(new ParticleSystem(100, emerald));
      source.add(new ParticleSystem(40, cyan));
    }
    break;
  case 5:
    ps = new ArrayList<ParticleSystem>();
    source = new ArrayList<ParticleSystem>();
    for (int i=0; i<=105; i++) {
      ps.add(new ParticleSystem(100, indigo));
      source.add(new ParticleSystem(40, orchid));
    }
    break;
  }
}

void animate(Matrix cp5) {

  //Flute Chord
  if (cp5.get(0, 0)) {
    for (int i=0; i<7; i++) {
      if (fluteEmVelDir[i]&&!fluteEmVelR[i]) {
        fluteEmVel[i]+=fluteRise;
        if (fluteEmVel[i]>=fluteCap)
          fluteEmVelDir[i]=false;
      }
      if (!fluteEmVelDir[i]&&!fluteEmVelR[i]) {
        fluteEmVel[i]-=chordFall;
        if (yCoord.get(fluteEmitters.get(i))<=base) {
          fluteEmVelR[i]=true;
          fluteEmVel[i]=0;
        }
      }
      yCoord.set(fluteEmitters.get(i), yCoord.get(fluteEmitters.get(i))-fluteEmVel[i]);
      yCoord.set(fluteEmitters.get(i)-2, int(lerp(yCoord.get(fluteEmitters.get(i)), base, 0.7)));
      yCoord.set(fluteEmitters.get(i)-1, int(lerp(yCoord.get(fluteEmitters.get(i)), base, 0.3)));
      yCoord.set(fluteEmitters.get(i)+1, int(lerp(yCoord.get(fluteEmitters.get(i)), base, 0.1)));
      yCoord.set(fluteEmitters.get(i)+2, int(lerp(yCoord.get(fluteEmitters.get(i)), base, 0.5)));
    }
  }

  //Flute Cells  
  if (cp5.get(1, 0)) {
    if (fluteEmVelDir[0]&&!fluteEmVelR[0]) {
      fluteEmVel[0]+=fluteRise;
      if (fluteEmVel[0]>=fluteCap)
        fluteEmVelDir[0]=false;
    }
    if (!fluteEmVelDir[0]&&!fluteEmVelR[0]) {
      fluteEmVel[0]-=fluteFall;
      if (yCoord.get(fluteEmitters.get(0))<=base) {
        fluteEmVelR[0]=true;
        fluteEmVel[0]=0;
      }
    }
    yCoord.set(fluteEmitters.get(0), yCoord.get(fluteEmitters.get(0))-fluteEmVel[0]);
    yCoord.set(fluteEmitters.get(0)-2, int(lerp(yCoord.get(fluteEmitters.get(0)), base, 0.7)));
    yCoord.set(fluteEmitters.get(0)-1, int(lerp(yCoord.get(fluteEmitters.get(0)), base, 0.3)));
    yCoord.set(fluteEmitters.get(0)+1, int(lerp(yCoord.get(fluteEmitters.get(0)), base, 0.1)));
    yCoord.set(fluteEmitters.get(0)+2, int(lerp(yCoord.get(fluteEmitters.get(0)), base, 0.5)));
  }
  if (cp5.get(2, 0)) { 
    if (fluteEmVelDir[1]&&!fluteEmVelR[1]) {
      fluteEmVel[1]+=fluteRise;
      if (fluteEmVel[1]>=fluteCap)
        fluteEmVelDir[1]=false;
    }
    if (!fluteEmVelDir[1]&&!fluteEmVelR[1]) {
      fluteEmVel[1]-=fluteFall;
      if (yCoord.get(fluteEmitters.get(1))<=base) {
        fluteEmVelR[1]=true;
        fluteEmVel[1]=0;
      }
    }
    yCoord.set(fluteEmitters.get(1), yCoord.get(fluteEmitters.get(1))-fluteEmVel[1]);
    yCoord.set(fluteEmitters.get(1)-2, int(lerp(yCoord.get(fluteEmitters.get(1)), base, 0.7)));
    yCoord.set(fluteEmitters.get(1)-1, int(lerp(yCoord.get(fluteEmitters.get(1)), base, 0.3)));
    yCoord.set(fluteEmitters.get(1)+1, int(lerp(yCoord.get(fluteEmitters.get(1)), base, 0.1)));
    yCoord.set(fluteEmitters.get(1)+2, int(lerp(yCoord.get(fluteEmitters.get(1)), base, 0.5)));
  }
  if (cp5.get(3, 0)) {
    if (fluteEmVelDir[2]&&!fluteEmVelR[2]) {
      fluteEmVel[2]+=fluteRise;
      if (fluteEmVel[2]>=fluteCap)
        fluteEmVelDir[2]=false;
    }
    if (!fluteEmVelDir[2]&&!fluteEmVelR[2]) {
      fluteEmVel[2]-=fluteFall;
      if (yCoord.get(fluteEmitters.get(2))<=base) {
        fluteEmVelR[2]=true;
        fluteEmVel[2]=0;
      }
    }
    yCoord.set(fluteEmitters.get(2), yCoord.get(fluteEmitters.get(2))-fluteEmVel[2]);
    yCoord.set(fluteEmitters.get(2)-2, int(lerp(yCoord.get(fluteEmitters.get(2)), base, 0.7)));
    yCoord.set(fluteEmitters.get(2)-1, int(lerp(yCoord.get(fluteEmitters.get(2)), base, 0.3)));
    yCoord.set(fluteEmitters.get(2)+1, int(lerp(yCoord.get(fluteEmitters.get(2)), base, 0.1)));
    yCoord.set(fluteEmitters.get(2)+2, int(lerp(yCoord.get(fluteEmitters.get(2)), base, 0.5)));
  }
  if (cp5.get(4, 0)) {
    if (fluteEmVelDir[3]&&!fluteEmVelR[3]) {
      fluteEmVel[3]+=fluteRise;
      if (fluteEmVel[3]>=fluteCap)
        fluteEmVelDir[3]=false;
    }
    if (!fluteEmVelDir[3]&&!fluteEmVelR[3]) {
      fluteEmVel[3]-=fluteFall;
      if (yCoord.get(fluteEmitters.get(3))<=base) {
        fluteEmVelR[3]=true;
        fluteEmVel[3]=0;
      }
    }
    yCoord.set(fluteEmitters.get(3), yCoord.get(fluteEmitters.get(3))-fluteEmVel[3]);
    yCoord.set(fluteEmitters.get(3)-2, int(lerp(yCoord.get(fluteEmitters.get(3)), base, 0.7)));
    yCoord.set(fluteEmitters.get(3)-1, int(lerp(yCoord.get(fluteEmitters.get(3)), base, 0.3)));
    yCoord.set(fluteEmitters.get(3)+1, int(lerp(yCoord.get(fluteEmitters.get(3)), base, 0.1)));
    yCoord.set(fluteEmitters.get(3)+2, int(lerp(yCoord.get(fluteEmitters.get(3)), base, 0.5)));
  }
  if (cp5.get(5, 0)) {
    if (fluteEmVelDir[4]&&!fluteEmVelR[4]) {
      fluteEmVel[4]+=fluteRise;
      if (fluteEmVel[4]>=fluteCap)
        fluteEmVelDir[4]=false;
    }
    if (!fluteEmVelDir[4]&&!fluteEmVelR[4]) {
      fluteEmVel[4]-=fluteFall;
      if (yCoord.get(fluteEmitters.get(4))<=base) {
        fluteEmVelR[4]=true;
        fluteEmVel[4]=0;
      }
    }
    yCoord.set(fluteEmitters.get(4), yCoord.get(fluteEmitters.get(4))-fluteEmVel[4]);
    yCoord.set(fluteEmitters.get(4)-2, int(lerp(yCoord.get(fluteEmitters.get(4)), base, 0.7)));
    yCoord.set(fluteEmitters.get(4)-1, int(lerp(yCoord.get(fluteEmitters.get(4)), base, 0.3)));
    yCoord.set(fluteEmitters.get(4)+1, int(lerp(yCoord.get(fluteEmitters.get(4)), base, 0.1)));
    yCoord.set(fluteEmitters.get(4)+2, int(lerp(yCoord.get(fluteEmitters.get(4)), base, 0.5)));
  }

  if (cp5.get(6, 0)) {
    if (fluteEmVelDir[5]&&!fluteEmVelR[5]) {
      fluteEmVel[5]+=fluteRise;
      if (fluteEmVel[5]>=fluteCap)
        fluteEmVelDir[5]=false;
    }
    if (!fluteEmVelDir[5]&&!fluteEmVelR[5]) {
      fluteEmVel[5]-=fluteFall;
      if (yCoord.get(fluteEmitters.get(5))<=base) {
        fluteEmVelR[5]=true;
        fluteEmVel[5]=0;
      }
    }
    yCoord.set(fluteEmitters.get(5), yCoord.get(fluteEmitters.get(5))-fluteEmVel[5]);
    yCoord.set(fluteEmitters.get(5)-2, int(lerp(yCoord.get(fluteEmitters.get(5)), base, 0.7)));
    yCoord.set(fluteEmitters.get(5)-1, int(lerp(yCoord.get(fluteEmitters.get(5)), base, 0.3)));
    yCoord.set(fluteEmitters.get(5)+1, int(lerp(yCoord.get(fluteEmitters.get(5)), base, 0.1)));
    yCoord.set(fluteEmitters.get(5)+2, int(lerp(yCoord.get(fluteEmitters.get(5)), base, 0.5)));
  }


  if (cp5.get(7, 0)) {
    if (fluteEmVelDir[6]&&!fluteEmVelR[6]) {
      fluteEmVel[6]+=fluteRise;
      if (fluteEmVel[6]>=fluteCap)
        fluteEmVelDir[6]=false;
    }
    if (!fluteEmVelDir[6]&&!fluteEmVelR[6]) {
      fluteEmVel[6]-=fluteFall;
      if (yCoord.get(fluteEmitters.get(6))<=base) {
        fluteEmVelR[6]=true;
        fluteEmVel[6]=0;
      }
    }
    yCoord.set(fluteEmitters.get(6), yCoord.get(fluteEmitters.get(6))-fluteEmVel[6]);
    yCoord.set(fluteEmitters.get(6)-2, int(lerp(yCoord.get(fluteEmitters.get(6)), base, 0.7)));
    yCoord.set(fluteEmitters.get(6)-1, int(lerp(yCoord.get(fluteEmitters.get(6)), base, 0.3)));
    yCoord.set(fluteEmitters.get(6)+1, int(lerp(yCoord.get(fluteEmitters.get(6)), base, 0.1)));
    yCoord.set(fluteEmitters.get(6)+2, int(lerp(yCoord.get(fluteEmitters.get(6)), base, 0.5)));
  }

  //violin chord
  if (cp5.get(0, 1)) {
    for (int i=0; i<7; i++) {
      if (violinEmVelDir[i]&&!violinEmVelR[i]) {
        violinEmVel[i]+=chordRise;
        if (violinEmVel[i]>=chordCap)
          violinEmVelDir[i]=false;
      }
      if (!violinEmVelDir[i]&&!violinEmVelR[i]) {
        violinEmVel[i]-=chordFall;
        if (yCoord.get(violinEmitters.get(i))<=base) {
          violinEmVelR[i]=true;
          violinEmVel[i]=0;
        }
      }
      yCoord.set(violinEmitters.get(i), yCoord.get(violinEmitters.get(i))-violinEmVel[i]);
      yCoord.set(violinEmitters.get(i)-2, int(lerp(yCoord.get(violinEmitters.get(i)), base, 0.7)));
      yCoord.set(violinEmitters.get(i)-1, int(lerp(yCoord.get(violinEmitters.get(i)), base, 0.3)));
      yCoord.set(violinEmitters.get(i)+1, int(lerp(yCoord.get(violinEmitters.get(i)), base, 0.1)));
      yCoord.set(violinEmitters.get(i)+2, int(lerp(yCoord.get(violinEmitters.get(i)), base, 0.5)));
    }
  }

  if (cp5.get(1, 1)) {
    if (violinEmVelDir[0]&&!violinEmVelR[0]) {
      violinEmVel[0]+=violinRise;
      if (violinEmVel[0]>=violinCap)
        violinEmVelDir[0]=false;
    }
    if (!violinEmVelDir[0]&&!violinEmVelR[0]) {
      violinEmVel[0]--;
      if (yCoord.get(violinEmitters.get(0))<=base) {
        violinEmVelR[0]=true;
        violinEmVel[0]=0;
      }
    }
    yCoord.set(violinEmitters.get(0), yCoord.get(violinEmitters.get(0))-violinEmVel[0]);
    yCoord.set(violinEmitters.get(0)-2, int(lerp(yCoord.get(violinEmitters.get(0)), base, 0.8)));
    yCoord.set(violinEmitters.get(0)-1, int(lerp(yCoord.get(violinEmitters.get(0)), base, 0.2)));
    yCoord.set(violinEmitters.get(0)+1, int(lerp(yCoord.get(violinEmitters.get(0)), base, 0.4)));
    yCoord.set(violinEmitters.get(0)+2, int(lerp(yCoord.get(violinEmitters.get(0)), base, 0.6)));
  }
  if (cp5.get(2, 1)) { 
    if (violinEmVelDir[1]&&!violinEmVelR[1]) {
      violinEmVel[1]+=violinRise;
      if (violinEmVel[1]>=violinCap)
        violinEmVelDir[1]=false;
    }
    if (!violinEmVelDir[1]&&!violinEmVelR[1]) {
      violinEmVel[1]--;
      if (yCoord.get(violinEmitters.get(1))<=base) {
        violinEmVelR[1]=true;
        violinEmVel[1]=0;
      }
    }
    yCoord.set(violinEmitters.get(1), yCoord.get(violinEmitters.get(1))-violinEmVel[1]);
    yCoord.set(violinEmitters.get(1)-2, int(lerp(yCoord.get(violinEmitters.get(1)), base, 0.8)));
    yCoord.set(violinEmitters.get(1)-1, int(lerp(yCoord.get(violinEmitters.get(1)), base, 0.2)));
    yCoord.set(violinEmitters.get(1)+1, int(lerp(yCoord.get(violinEmitters.get(1)), base, 0.4)));
    yCoord.set(violinEmitters.get(1)+2, int(lerp(yCoord.get(violinEmitters.get(1)), base, 0.6)));
  }
  if (cp5.get(3, 1)) {
    if (violinEmVelDir[2]&&!violinEmVelR[2]) {
      violinEmVel[2]+=violinRise;
      if (violinEmVel[2]>=violinCap)
        violinEmVelDir[2]=false;
    }
    if (!violinEmVelDir[2]&&!violinEmVelR[2]) {
      violinEmVel[2]--;
      if (yCoord.get(violinEmitters.get(2))<=base) {
        violinEmVelR[2]=true;
        violinEmVel[2]=0;
      }
    }
    yCoord.set(violinEmitters.get(2), yCoord.get(violinEmitters.get(2))-violinEmVel[2]);
    yCoord.set(violinEmitters.get(2)-2, int(lerp(yCoord.get(violinEmitters.get(2)), base, 0.8)));
    yCoord.set(violinEmitters.get(2)-1, int(lerp(yCoord.get(violinEmitters.get(2)), base, 0.2)));
    yCoord.set(violinEmitters.get(2)+1, int(lerp(yCoord.get(violinEmitters.get(2)), base, 0.4)));
    yCoord.set(violinEmitters.get(2)+2, int(lerp(yCoord.get(violinEmitters.get(2)), base, 0.6)));
  }
  if (cp5.get(4, 1)) {
    if (violinEmVelDir[3]&&!violinEmVelR[3]) {
      violinEmVel[3]+=violinRise;
      if (violinEmVel[3]>=violinCap)
        violinEmVelDir[3]=false;
    }
    if (!violinEmVelDir[3]&&!violinEmVelR[3]) {
      violinEmVel[3]--;
      if (yCoord.get(violinEmitters.get(3))<=base) {
        violinEmVelR[3]=true;
        violinEmVel[3]=0;
      }
    }
    yCoord.set(violinEmitters.get(3), yCoord.get(violinEmitters.get(3))-violinEmVel[3]);
    yCoord.set(violinEmitters.get(3)-2, int(lerp(yCoord.get(violinEmitters.get(3)), base, 0.8)));
    yCoord.set(violinEmitters.get(3)-1, int(lerp(yCoord.get(violinEmitters.get(3)), base, 0.2)));
    yCoord.set(violinEmitters.get(3)+1, int(lerp(yCoord.get(violinEmitters.get(3)), base, 0.4)));
    yCoord.set(violinEmitters.get(3)+2, int(lerp(yCoord.get(violinEmitters.get(3)), base, 0.6)));
  }
  if (cp5.get(5, 1)) {
    if (violinEmVelDir[4]&&!violinEmVelR[4]) {
      violinEmVel[4]+=violinRise;
      if (violinEmVel[4]>=violinCap)
        violinEmVelDir[4]=false;
    }
    if (!violinEmVelDir[4]&&!violinEmVelR[4]) {
      violinEmVel[4]--;
      if (yCoord.get(violinEmitters.get(4))<=base) {
        violinEmVelR[4]=true;
        violinEmVel[4]=0;
      }
    }
    yCoord.set(violinEmitters.get(4), yCoord.get(violinEmitters.get(4))-violinEmVel[4]);
    yCoord.set(violinEmitters.get(4)-2, int(lerp(yCoord.get(violinEmitters.get(4)), base, 0.8)));
    yCoord.set(violinEmitters.get(4)-1, int(lerp(yCoord.get(violinEmitters.get(4)), base, 0.2)));
    yCoord.set(violinEmitters.get(4)+1, int(lerp(yCoord.get(violinEmitters.get(4)), base, 0.4)));
    yCoord.set(violinEmitters.get(4)+2, int(lerp(yCoord.get(violinEmitters.get(4)), base, 0.6)));
  }

  if (cp5.get(6, 1)) {
    if (violinEmVelDir[5]&&!violinEmVelR[5]) {
      violinEmVel[5]+=violinRise;
      if (violinEmVel[5]>=violinCap)
        violinEmVelDir[5]=false;
    }
    if (!violinEmVelDir[5]&&!violinEmVelR[5]) {
      violinEmVel[5]--;
      if (yCoord.get(violinEmitters.get(5))<=base) {
        violinEmVelR[5]=true;
        violinEmVel[5]=0;
      }
    }
    yCoord.set(violinEmitters.get(5), yCoord.get(violinEmitters.get(5))-violinEmVel[5]);
    yCoord.set(violinEmitters.get(5)-2, int(lerp(yCoord.get(violinEmitters.get(5)), base, 0.8)));
    yCoord.set(violinEmitters.get(5)-1, int(lerp(yCoord.get(violinEmitters.get(5)), base, 0.2)));
    yCoord.set(violinEmitters.get(5)+1, int(lerp(yCoord.get(violinEmitters.get(5)), base, 0.4)));
    yCoord.set(violinEmitters.get(5)+2, int(lerp(yCoord.get(violinEmitters.get(5)), base, 0.6)));
  }


  if (cp5.get(7, 1)) {
    if (violinEmVelDir[6]&&!violinEmVelR[6]) {
      violinEmVel[6]+=violinRise;
      if (violinEmVel[6]>=violinCap)
        violinEmVelDir[6]=false;
    }
    if (!violinEmVelDir[6]&&!violinEmVelR[6]) {
      violinEmVel[6]--;
      if (yCoord.get(violinEmitters.get(6))<=base) {
        violinEmVelR[6]=true;
        violinEmVel[6]=0;
      }
    }
    yCoord.set(violinEmitters.get(6), yCoord.get(violinEmitters.get(6))-violinEmVel[6]);
    yCoord.set(violinEmitters.get(6)-2, int(lerp(yCoord.get(violinEmitters.get(6)), base, 0.8)));
    yCoord.set(violinEmitters.get(6)-1, int(lerp(yCoord.get(violinEmitters.get(6)), base, 0.2)));
    yCoord.set(violinEmitters.get(6)+1, int(lerp(yCoord.get(violinEmitters.get(6)), base, 0.4)));
    yCoord.set(violinEmitters.get(6)+2, int(lerp(yCoord.get(violinEmitters.get(6)), base, 0.6)));
  }

  if (cp5.get(0, 2)) {
    for (int i=0; i<7; i++) {
      if (guitarEmVelDir[i]&&!guitarEmVelR[i]) {
        guitarEmVel[i]+=chordRise;
        if (guitarEmVel[i]>=chordCap)
          guitarEmVelDir[i]=false;
      }
      if (!guitarEmVelDir[i]&&!guitarEmVelR[i]) {
        guitarEmVel[i]-=chordFall;
        if (yCoord.get(guitarEmitters.get(i))<=base) {
          guitarEmVelR[i]=true;
          guitarEmVel[i]=0;
        }
      }
      yCoord.set(guitarEmitters.get(i), yCoord.get(guitarEmitters.get(i))-guitarEmVel[i]);
      yCoord.set(guitarEmitters.get(i)-2, int(lerp(yCoord.get(guitarEmitters.get(i)), base, 0.7)));
      yCoord.set(guitarEmitters.get(i)-1, int(lerp(yCoord.get(guitarEmitters.get(i)), base, 0.3)));
      yCoord.set(guitarEmitters.get(i)+1, int(lerp(yCoord.get(guitarEmitters.get(i)), base, 0.1)));
      yCoord.set(guitarEmitters.get(i)+2, int(lerp(yCoord.get(guitarEmitters.get(i)), base, 0.5)));
    }
  }


  if (cp5.get(1, 2)) {
    if (guitarEmVelDir[0]&&!guitarEmVelR[0]) {
      guitarEmVel[0]+=guitarRise;
      if (guitarEmVel[0]>=guitarCap)
        guitarEmVelDir[0]=false;
    }
    if (!guitarEmVelDir[0]&&!guitarEmVelR[0]) {
      guitarEmVel[0]-=guitarFall;
      if (yCoord.get(guitarEmitters.get(0))<=base) {
        guitarEmVelR[0]=true;
        guitarEmVel[0]=0;
      }
    }
    yCoord.set(guitarEmitters.get(0), yCoord.get(guitarEmitters.get(0))-guitarEmVel[0]);
    yCoord.set(guitarEmitters.get(0)-2, int(lerp(yCoord.get(guitarEmitters.get(0)), base, 0.8)));
    yCoord.set(guitarEmitters.get(0)-1, int(lerp(yCoord.get(guitarEmitters.get(0)), base, 0.2)));
    yCoord.set(guitarEmitters.get(0)+1, int(lerp(yCoord.get(guitarEmitters.get(0)), base, 0.4)));
    yCoord.set(guitarEmitters.get(0)+2, int(lerp(yCoord.get(guitarEmitters.get(0)), base, 0.6)));
  }
  if (cp5.get(2, 2)) { 
    if (guitarEmVelDir[1]&&!guitarEmVelR[1]) {
      guitarEmVel[1]+=guitarRise;
      if (guitarEmVel[1]>=guitarCap)
        guitarEmVelDir[1]=false;
    }
    if (!guitarEmVelDir[1]&&!guitarEmVelR[1]) {
      guitarEmVel[1]-=guitarFall;
      if (yCoord.get(guitarEmitters.get(1))<=base) {
        guitarEmVelR[1]=true;
        guitarEmVel[1]=0;
      }
    }
    yCoord.set(guitarEmitters.get(1), yCoord.get(guitarEmitters.get(1))-guitarEmVel[1]);
    yCoord.set(guitarEmitters.get(1)-2, int(lerp(yCoord.get(guitarEmitters.get(1)), base, 0.8)));
    yCoord.set(guitarEmitters.get(1)-1, int(lerp(yCoord.get(guitarEmitters.get(1)), base, 0.2)));
    yCoord.set(guitarEmitters.get(1)+1, int(lerp(yCoord.get(guitarEmitters.get(1)), base, 0.4)));
    yCoord.set(guitarEmitters.get(1)+2, int(lerp(yCoord.get(guitarEmitters.get(1)), base, 0.6)));
  }
  if (cp5.get(3, 2)) {
    if (guitarEmVelDir[2]&&!guitarEmVelR[2]) {
      guitarEmVel[2]+=guitarRise;
      if (guitarEmVel[2]>=guitarCap)
        guitarEmVelDir[2]=false;
    }
    if (!guitarEmVelDir[2]&&!guitarEmVelR[2]) {
      guitarEmVel[2]-=guitarFall;
      if (yCoord.get(guitarEmitters.get(2))<=base) {
        guitarEmVelR[2]=true;
        guitarEmVel[2]=0;
      }
    }
    yCoord.set(guitarEmitters.get(2), yCoord.get(guitarEmitters.get(2))-guitarEmVel[2]);
    yCoord.set(guitarEmitters.get(2)-2, int(lerp(yCoord.get(guitarEmitters.get(2)), base, 0.8)));
    yCoord.set(guitarEmitters.get(2)-1, int(lerp(yCoord.get(guitarEmitters.get(2)), base, 0.2)));
    yCoord.set(guitarEmitters.get(2)+1, int(lerp(yCoord.get(guitarEmitters.get(2)), base, 0.4)));
    yCoord.set(guitarEmitters.get(2)+2, int(lerp(yCoord.get(guitarEmitters.get(2)), base, 0.6)));
  }
  if (cp5.get(4, 2)) {
    if (guitarEmVelDir[3]&&!guitarEmVelR[3]) {
      guitarEmVel[3]+=guitarRise;
      if (guitarEmVel[3]>=guitarCap)
        guitarEmVelDir[3]=false;
    }
    if (!guitarEmVelDir[3]&&!guitarEmVelR[3]) {
      guitarEmVel[3]-=guitarFall;
      if (yCoord.get(guitarEmitters.get(3))<=base) {
        guitarEmVelR[3]=true;
        guitarEmVel[3]=0;
      }
    }
    yCoord.set(guitarEmitters.get(3), yCoord.get(guitarEmitters.get(3))-guitarEmVel[3]);
    yCoord.set(guitarEmitters.get(3)-2, int(lerp(yCoord.get(guitarEmitters.get(3)), base, 0.8)));
    yCoord.set(guitarEmitters.get(3)-1, int(lerp(yCoord.get(guitarEmitters.get(3)), base, 0.2)));
    yCoord.set(guitarEmitters.get(3)+1, int(lerp(yCoord.get(guitarEmitters.get(3)), base, 0.4)));
    yCoord.set(guitarEmitters.get(3)+2, int(lerp(yCoord.get(guitarEmitters.get(3)), base, 0.6)));
  }
  if (cp5.get(5, 2)) {
    if (guitarEmVelDir[4]&&!guitarEmVelR[4]) {
      guitarEmVel[4]+=guitarRise;
      if (guitarEmVel[4]>=guitarCap)
        guitarEmVelDir[4]=false;
    }
    if (!guitarEmVelDir[4]&&!guitarEmVelR[4]) {
      guitarEmVel[4]-=guitarFall;
      if (yCoord.get(guitarEmitters.get(4))<=base) {
        guitarEmVelR[4]=true;
        guitarEmVel[4]=0;
      }
    }
    yCoord.set(guitarEmitters.get(4), yCoord.get(guitarEmitters.get(4))-guitarEmVel[4]);
    yCoord.set(guitarEmitters.get(4)-2, int(lerp(yCoord.get(guitarEmitters.get(4)), base, 0.8)));
    yCoord.set(guitarEmitters.get(4)-1, int(lerp(yCoord.get(guitarEmitters.get(4)), base, 0.2)));
    yCoord.set(guitarEmitters.get(4)+1, int(lerp(yCoord.get(guitarEmitters.get(4)), base, 0.4)));
    yCoord.set(guitarEmitters.get(4)+2, int(lerp(yCoord.get(guitarEmitters.get(4)), base, 0.6)));
  }

  if (cp5.get(6, 2)) {
    if (guitarEmVelDir[5]&&!guitarEmVelR[5]) {
      guitarEmVel[5]+=guitarRise;
      if (guitarEmVel[5]>=guitarCap)
        guitarEmVelDir[5]=false;
    }
    if (!guitarEmVelDir[5]&&!guitarEmVelR[5]) {
      guitarEmVel[5]-=guitarFall;
      if (yCoord.get(guitarEmitters.get(5))<=base) {
        guitarEmVelR[5]=true;
        guitarEmVel[5]=0;
      }
    }
    yCoord.set(guitarEmitters.get(5), yCoord.get(guitarEmitters.get(5))-guitarEmVel[5]);
    yCoord.set(guitarEmitters.get(5)-2, int(lerp(yCoord.get(guitarEmitters.get(5)), base, 0.8)));
    yCoord.set(guitarEmitters.get(5)-1, int(lerp(yCoord.get(guitarEmitters.get(5)), base, 0.2)));
    yCoord.set(guitarEmitters.get(5)+1, int(lerp(yCoord.get(guitarEmitters.get(5)), base, 0.4)));
    yCoord.set(guitarEmitters.get(5)+2, int(lerp(yCoord.get(guitarEmitters.get(5)), base, 0.6)));
  }


  if (cp5.get(7, 2)) {
    if (guitarEmVelDir[6]&&!guitarEmVelR[6]) {
      guitarEmVel[6]+=guitarRise;
      if (guitarEmVel[6]>=guitarCap)
        guitarEmVelDir[6]=false;
    }
    if (!guitarEmVelDir[6]&&!guitarEmVelR[6]) {
      guitarEmVel[6]-=guitarFall;
      if (yCoord.get(guitarEmitters.get(6))<=base) {
        guitarEmVelR[6]=true;
        guitarEmVel[6]=0;
      }
    }
    yCoord.set(guitarEmitters.get(6), yCoord.get(guitarEmitters.get(6))-guitarEmVel[6]);
    yCoord.set(guitarEmitters.get(6)-2, int(lerp(yCoord.get(guitarEmitters.get(6)), base, 0.8)));
    yCoord.set(guitarEmitters.get(6)-1, int(lerp(yCoord.get(guitarEmitters.get(6)), base, 0.2)));
    yCoord.set(guitarEmitters.get(6)+1, int(lerp(yCoord.get(guitarEmitters.get(6)), base, 0.4)));
    yCoord.set(guitarEmitters.get(6)+2, int(lerp(yCoord.get(guitarEmitters.get(6)), base, 0.6)));
  }
}
