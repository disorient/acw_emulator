/**
 * This sketch emulates the Disorient Art Car Wash Electronic Sign
 * At Burning Man 2010.  The sign is a 64' x 16' 32x8 pixel grid.
 *
 * Listens on port 58082 for UDP packets.  Packet is expected
 * to start with 1, followed by 256 bytes.  I believe the 1 
 * signifies a new frame, but this emulator just expects 257
 * bytes.
 *
 * Tested with Scott's drawer code.  Scotts stuff expects the
 * LeoPlayer to be listening at IP 192.168.1.130, so you'll
 * need to add that as an IP on the machine running the
 * emulator.
 *
 * (c)2010 Justin Day
 *
 * You may use under a CC+Attribution License.
 *
 **/
 
import hypermedia.net.*;

// constants
int Y_AXIS = 1;
int X_AXIS = 2;

// privates
UDP udp;
int[] state;
int crawl = -1;
boolean demoMode = true;
boolean nightMode = true;

void setup() {
  udp = new UDP( this, 58082 );
  udp.listen( true );

  // Sign is 64' (10 pixels per foot plus buffer)
  // By 16' (Lots more buffer)  
  size(720,480);
  
  paintBackground();
  paintSign();
  initState();
  paintBoards();
  frameRate(30);
}

void paintBackground() {
  color sky1, sky2, sky3;
  
  if (nightMode) {
    sky1 = color(0,0,0);
    sky2 = color(0,0,50);
    sky3 = color(0,0,100);
  }
  else {
    sky1 = color(0,0,0);
    sky2 = color(100,100,200);
    sky3 = color(200,200,255);
  }
  color ply1 = color(30,10,10);
  color ply2 = color(130,100,100);
  
  setGradient(0,0,720,100,sky1,sky2,Y_AXIS);
  fill(sky2); noStroke(); rect(0,100,720,80);
  setGradient(0,180,720,140,sky2,sky3,Y_AXIS);
  setGradient(0,320,720,160,ply1,ply2,Y_AXIS);
  
  if (nightMode) {
      for (int i=0; i<100; i++) {
         int x = (int)random(720);
         int y = (int)random(320);
         fill(random(100));
         rect(x,y,2,2);
      }
  }
  
}

void paintSign() {
  noFill();
  stroke(0);
  rect(40,200,640,160);
  
  fill(nightMode ? 50 : 150);
  for (int i=0; i<32; i++) {
      rect(46+i*20,200,6,160);
  }
}

void initState() {
  state = new int[256];
  for (int i=0; i<256; i++) {
     state[i] = 0;
  }
}

void paintBoards() {
  noStroke();

  int i;
  for (int y=0; y<8; y++) {
    for (int x=0; x<32; x++) {
      i = x * 8 + y;
      fill(state[i], state[i]/255.0*100, 0);
      
      rect(x*20+46,y*20+210,7,6);
    }
  }
}

void runDemo() {
  if (crawl == -1 && state[0] < 255) {
     for (int i=0; i<256; i++) {
       state[i]+=8;
     }
  }
  else {
    crawl++;
    for (int i=0; i<256; i++) {
      state[i] = (crawl == i) ? 255 : 0;
    }
    if (crawl>255)
      crawl = -1;
  }    
}

void draw () {
  if (demoMode) {
    runDemo();
  }
  
  paintBoards();
}

void receive(byte[] data, String ip, int port) {
  if (demoMode) {
    println("Started receiving data from " + ip + ".  Demo mode disabled.");
    demoMode = false;
  }
  
  if (data[0] == 1) {
    if (data.length < 257) {
        println("Packet size mismatch. Expected 257, got " + data.length);
    }
    
    for (int i=1; i<data.length; i++) {
      state[i-1] = convertByte(data[i]);
    }
  }
  else {
    println("Packet header mismatch.  Expected 1, got " + data[0]);
  }  
}

int convertByte(byte b) {
  return (b<0) ? 256+b : b;
}

void setGradient(int x, int y, float w, float h, color c1, color c2, int axis ){
  // calculate differences between color components 
  float deltaR = red(c2)-red(c1);
  float deltaG = green(c2)-green(c1);
  float deltaB = blue(c2)-blue(c1);

  // choose axis
  if(axis == Y_AXIS){
    /*nested for loops set pixels
     in a basic table structure */
    // column
    for (int i=x; i<=(x+w); i++){
      // row
      for (int j = y; j<=(y+h); j++){
        color c = color(
        (red(c1)+(j-y)*(deltaR/h)),
        (green(c1)+(j-y)*(deltaG/h)),
        (blue(c1)+(j-y)*(deltaB/h)) 
          );
        set(i, j, c);
      }
    }  
  }  
  else if(axis == X_AXIS){
    // column 
    for (int i=y; i<=(y+h); i++){
      // row
      for (int j = x; j<=(x+w); j++){
        color c = color(
        (red(c1)+(j-x)*(deltaR/h)),
        (green(c1)+(j-x)*(deltaG/h)),
        (blue(c1)+(j-x)*(deltaB/h)) 
          );
        set(j, i, c);
      }
    }  
  }
}

