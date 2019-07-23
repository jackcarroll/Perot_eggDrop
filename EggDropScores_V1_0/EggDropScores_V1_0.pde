/**
/* EggDropScores_Vx_x
 *  Jeremy W McCarter
 *  Created: July 4, 2019
 *  Modified: July 11, 2019 by Jackson Carroll
 *  
 *  Version Tracking
 *  V1.0 - Initial Release
 *
 * NOTE: THIS IS A BELLWETHER MODIFIED VERSION OF THE EXAMPLE SKETCH: Basics/Data/CharacterStrings
 * This code is still buggy and preliminary, but is a good start.
 *
 *
 * Characters Strings. 
 *  
 * The character datatype, abbreviated as char, stores letters and 
 * symbols in the Unicode format, a coding system developed to support 
 * a variety of world languages. Characters are distinguished from other
 * symbols by putting them between single quotes ('P').<br />
 * <br />
 * A string is a sequence of characters. A string is noted by surrounding 
 * a group of letters with double quotes ("Processing"). 
 * Chars and strings are most often used with the keyboard methods, 
 * to display text to the screen, and to load images or files.<br />
 * <br />
 * The String datatype must be capitalized because it is a complex datatype.
 * A String is actually a class with its own methods, some of which are
 * featured below. 
 */

import meter.*;              // Library for meters
import processing.serial.*;  // Library for serial Tx Rx

Serial port;                 //create a port object from the Serial Class and define a buffer to recieve data
int val;

Meter m;                     // Create a new meter, call it m
char letter;
String words = "Begin...";

int scoreInterval = 20;     // Vertical spacing between scores
int scoreStartx = 650;      // Where to start scores list, x
int scoreStarty = 100;      // Where to start scores list, y
int scoresArray[] = {20, 10, 50, 40, 30, 60, 90, 80, 70, 100};  // This list is intentionally out of order
String namesArray[] = {"Apollo", "Bezerka", "Commando", "Dexphnaus", "Eagle",
                       "Fitzgarb", "Gemini", "Hercules", "Icarus", "Juno"};

void setup() {
  
// METER SETUP DEFINITIONS //  
  size(950, 360);
  textFont(createFont("SourceCodePro-Regular.ttf", 36));
  m = new Meter(this, 80, 50);
  m.setTitleFontSize(20);
  m.setTitleFontName("Arial bold");
  m.setTitle("G-Force (g)");
  m.setDisplayDigitalMeterValue(true);
  String[] scaleLabelsT = {"0", "10", "20", "30", "40", "50", "60", "70", "80"};
  m.setScaleLabels(scaleLabelsT);
  m.setScaleFontSize(18);
  m.setScaleFontName("Times New Roman bold");
  m.setScaleFontColor(color(200, 30, 70));
  m.setArcColor(color(141, 113, 178));
  m.setArcThickness(10);
  m.setMaxScaleValue(80);
  m.setNeedleThickness(3);
  m.setMinInputSignal(0);
  m.setMaxInputSignal(80);
  
// OTHER SETUP //
  port = new Serial(this, "COM5" ,9600);

}

void draw() {
  
  int capsuleAddress = (int)random(10);                       // Get random number from 0 to 9 (does not include 10)
  print("capsuleAddress = "); println(capsuleAddress);        // Print capsuleAddress in Console (below this sketch)
  String b = namesArray[capsuleAddress];                      // Get associated name from namesArray
  print("name = "); println(b);                               // Print name
  
  
  
  background(0); // Set background to black
  textSize(25);
  text("Top Scores", scoreStartx, scoreStarty - 20);          // Show text "Top Scores" at x position "scoreStartx" and y position "scoreStarty - 20"
  //print(PFont.list());
  
  // THIS IS ALL FROM THE EXAMPLE; CURRENTLY UNUSED
  //text("Click on the program, then type to add to the String", 50, 50);
  //text("Current key: " + letter, 50, 70);
  //text("The String is " + words.length() +  " characters long", 50, 90);
  
  
  textSize(15);
  scoresArray = reverse(sort(scoresArray));      // Sort scores array from high to low
  for (int a = 0; a <= 9; a++){
      //text("Score:", scoreStartx,(scoreStarty + (a * scoreInterval)));
      text(namesArray[a], scoreStartx,(scoreStarty + (a * scoreInterval)));
      text (scoresArray[a], scoreStartx + 100,(scoreStarty + (a * scoreInterval)));

  }
  

  
  
  textSize(36);
  //text(words, 50, 120, 540, 300);
  
  
    // Recieve Serial information from mega, and update the meter with it.
    if (0 < port.available()) {         // If data is available to read,
      val = port.read();                // read it and store it in val
    } 
    println(val);
    m.updateMeter(int(val));
    delay(500);
}


// THIS IS PART OF THE EXAMPLE SKETCH; CURRENTLY UNUSED
void keyTyped() {
  // The variable "key" always contains the value 
  // of the most recent key pressed.
  if ((key >= 'A' && key <= 'z') || key == ' ') {
    letter = key;
    //words = words + key;
    // Write the letter to the console
    println(key);
  }
}
