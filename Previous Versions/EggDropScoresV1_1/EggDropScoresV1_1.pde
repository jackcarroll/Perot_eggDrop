/* EggDropScores_V1_1
 *  Jackson Carroll
 *  Created: July 23, 2019
 *  Modified: N/A
 *  
 *  V1.1 - adding code for recieving data from test station Mega & more robust leaderboard
 *
 * NOTE: THIS ORIGINALLY WAS A BELLWETHER MODIFIED VERSION OF THE EXAMPLE SKETCH: Basics/Data/CharacterStrings
 */

import meter.*;              // Library for meters
import processing.serial.*;  // Library for serial Tx Rx

Serial port;                 //create a port object from the Serial Class and define a buffer to recieve data
char HEADER = 'H';
int capName = 0;
int gVal = 0;
int oldCapName = 0;          //the old values save the data of the previous message to see
int oldGVal = 0;             //if this is the same capsule or not
boolean newData = false;
boolean firstContact = true;   //if contact has not been established

Meter m;                     // Create a new meter, call it m
char letter;
String words = "Begin...";

int scoreInterval = height/2;     // Vertical spacing between scores
int scoreStartx = width*14;      // Where to start scores list, x
int scoreStarty = height*2;      // Where to start scores list, y
String namesArray[] = {"Apollo", "Gemini", "Mercury", "Bezerka", "Commando",
                       "Dexphnaus", "Eagle", "Fitzgarb", "Hercules", "Icarus", 
                       "Juno", "Voyager", "Challenger", "Enterprise", "Kestrel", 
                       "Falcon", "", "", "", "", "", "", "", "", "", "", "", "", "", ""};
int missionNum[] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};              //increases every time it sees new data from each respective capsule
int scoreVal[] = {2200,2200,2200,2200,2200,2200,2200,2200,2200,2200,2200,2200,2200,2200,2200,2200,2200,2200,2200,2200};    //saves the top score of each capsule
int topMission[] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};          //saves the top scoring mission number of each capsule

void setup() 
{
// METER SETUP DEFINITIONS //  
  fullScreen();
  m = new Meter(this, width/16, height/4);
  m.setMeterWidth(width/2);
  m.setTitleFontSize(20);
  m.setTitleFontName("Arial bold");
  m.setTitle("G-Force (g)");
  m.setDisplayDigitalMeterValue(true);
  String[] scaleLabelsT = {"0", "200", "400", "600", "800", "1000", 
                           "1200", "1400", "1600", "1800", "2000", "2200"};
  m.setScaleLabels(scaleLabelsT);
  m.setScaleFontSize(18);
  m.setScaleFontName("Times New Roman bold");
  m.setScaleFontColor(color(200, 30, 70));
  m.setArcColor(color(141, 113, 178));
  m.setArcThickness(10);
  m.setMaxScaleValue(2200);
  m.setNeedleThickness(3);
  m.setMinInputSignal(0);
  m.setMaxInputSignal(2200);
  
// OTHER SETUP //
  port = new Serial(this, "COM5" ,9600);
}

void draw() 
{
  background(0); // Set background to black
  textSize(55);
  text("Top Scores", scoreStartx, scoreStarty - 20);          // Show text "Top Scores" at x position "scoreStartx" and y position "scoreStarty - 20"
  text(namesArray[capName] + " " + missionNum[capName], width/4, height/6);     //show name of current mission being displayed 
  textSize(35);
  for (int a=0; a<3; a++)    //update this loop to the number of capsules being used.
  {
    if(scoreVal[a] < 2200)   //if there is a top score, display it
    {
      text(namesArray[a] + " " + topMission[a], scoreStartx,(scoreStarty + (a * scoreInterval)+height/16));
      text (scoreVal[a], scoreStartx + width/8,(scoreStarty + (a * scoreInterval)+height/16));
    }
  }
  
  if(newData)    //if we have recieved new data, update mission number, meter, and score
  {
     missionNum[capName]++;
     if(gVal < scoreVal[capName])    //if this mission should be the new top score
     {
       scoreVal[capName] = gVal;
       topMission[capName] = missionNum[capName];
     }
     
     //save data values to compare to new messages
     oldCapName = capName;
     oldGVal = gVal;
     
     newData = false;
  }
  m.updateMeter(gVal);
}

//code based on example from Arduino Cookbook by Micheal Margolis
void serialEvent(Serial p)
{
  String message = port.readStringUntil('\n'); // read serial data
  if(message != null)
  {
    message = trim(message);
    if(firstContact)      //establishes contact with mega, saying its ready for data
    {
      port.write('A');
      port.clear();
      firstContact = false;
    }
    else
    {
      String [] data  = message.split(","); // Split the comma-separated message
      if(data[0].charAt(0) == HEADER)       // check for header character in the first field
      {
        capName = Integer.parseInt(data[1]);
        gVal = Integer.parseInt(data[2]);
      }
    }
  }
  if(capName != oldCapName || gVal != oldGVal)               //if it is not a repeat message
    newData = true;
}
