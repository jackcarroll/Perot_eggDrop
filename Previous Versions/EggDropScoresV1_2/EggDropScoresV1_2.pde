
/* EggDropScoresV1_2
 *  Jackson Carroll
 *  Created: July 23, 2019
 *  Modified: N/A
 *  
 *  V1.2 - sorting top scores, converting g values, adding success/failure and group scores
 */

import meter.*;              // Library for meters
import processing.serial.*;  // Library for serial Tx Rx
import java.util.Arrays;

Serial port;                 //create a port object from the Serial Class and define a buffer to recieve data
char HEADER = 'H';
int capName = 0;
int gVal = 0;
float displayGVal = 0;         //converted g value used for display. switched from 0-2047 scale to 0-400 scale, then lowered to 0-200 scale for readability
int oldCapName = 0;            //the old values save the data of the previous message to see
int oldGVal = 0;               //if this is the same capsule or not
boolean newData = false;
boolean firstContact = true;   //if contact has not been established
int passFail = 240;            //cutoff value for success/failure

Meter m;                       // Create a new meter, call it m

int scoreInterval = height/2;     // Vertical spacing between scores
int scoreStartx = width*14;       // Where to start scores list, x
int scoreStarty = height*2;       // Where to start scores list, y

String namesArray[] = {"Apollo", "Mercury", "Gemini", "Enterprise", "Voyager", "Discovery", 
                       "Atlantis", "Endeavour", "Artemis", "Orion", "Pioneer", "Ranger",
                       "Mariner", "Spirit", "Pathfinder", "Phoenix", "Curiosity", "Viking",
                       "Cassini", "Galileo", "Juno", "Magellan", "Infinity", "Falcon", 
                       "Serenity", "Reliant", "Defiant", "Kelvin", "Intrepid", "Eagle",
                       "Odyssey", "Kestrel", "Saturn", "Hercules"};
int missionNum[] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};                                            //increases every time it sees new data from each respective capsule
float scoreVal[] = {401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401};    //saves the top score of each capsule (init-ed to max value+1)
int topMission[] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};                                            //saves the top scoring mission number of each capsule
float recentScore[] = {401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401,401};

void setup() 
{
// METER SETUP DEFINITIONS //  
  fullScreen();
  m = new Meter(this, width/16, height/4);
  m.setMeterWidth(width/3);
  m.setTitleFontSize(20);
  m.setTitleFontName("Arial bold");
  m.setTitle("G-Force (g)");
  m.setDisplayDigitalMeterValue(false);
  String[] scaleLabelsT = {"0", "40", "80", "120", "160", "200", 
                           "240", "280", "320", "360", "400"};
  m.setScaleLabels(scaleLabelsT);
  m.setScaleFontSize(18);
  m.setScaleFontName("Times New Roman bold");
  m.setScaleFontColor(color(200, 30, 70));
  m.setArcThickness(10);
  m.setMaxScaleValue(400);
  m.setNeedleThickness(3);
  m.setMinInputSignal(0);
  m.setMaxInputSignal(400);
  m.setLowSensorWarningActive(true);
  m.setHighSensorWarningActive(true);
  m.setLowSensorWarningValue(passFail-40);
  m.setHighSensorWarningValue(passFail);
  m.setLowSensorWarningArcColor(color(0,255,0));
  m.setHighSensorWarningArcColor(color(255,0,0));
  m.setMidSensorWarningArcColor(color(255,255,0));
  m.setSensorWarningLowText("");
  m.setSensorWarningHighText("");
  
  
// OTHER SETUP //
  port = new Serial(this, "COM5" ,9600);
}

void draw() 
{
  if(newData)    //if we have recieved new data, update mission number, meter, and score
  {     
     missionNum[capName]++;
     displayGVal = ((float)gVal/2047)*400;     //(gVal/2047)*400 = the actual measured g Value based on 0-400g scale.
     recentScore[capName] = displayGVal;
     if(displayGVal < scoreVal[capName])       //if this mission should be the new top score
     {
       scoreVal[capName] = displayGVal;
       topMission[capName] = missionNum[capName];
     }
     
     newData = false;
  }
  
  background(0); // Set background to black
  fill(255,255,255);
  textSize(55);
  text("Top Scores", scoreStartx+width/20, scoreStarty - 20);          // Show text "Top Scores" at x position "scoreStartx" and y position "scoreStarty - 20"
  text("Group Scores",scoreStartx-width/4,scoreStarty-20);
  if(scoreVal[capName] != 401)    //don't display until a mission comes in
    text(namesArray[capName] + " " + missionNum[capName], width/6.1, height/6);     //show name of current mission being displayed 
  textSize(30);
  for (int a=0; a<31; a++)    //update this loop to the number of capsules being used.
  {
    if(scoreVal[a] != 401)   //if there is a top score, display it
    {
      text(namesArray[a] + " " + topMission[a], scoreStartx+width/20,(scoreStarty + (a * scoreInterval)+height/16));
      text (scoreVal[a], scoreStartx+width/20 + width/8,(scoreStarty + (a * scoreInterval)+height/16));
      text(namesArray[a] + " " + missionNum[a], scoreStartx-width/4,(scoreStarty + (a * scoreInterval)+height/16));
      text (recentScore[a], scoreStartx-width/4 + width/8,(scoreStarty + (a * scoreInterval)+height/16));
    }
  }
  m.updateMeter((int)displayGVal);
  fill(0,0,255);
  text(displayGVal,width/5,height/2 + height/10.5);
  if(displayGVal < passFail && displayGVal != 0)
  {
    textSize(55);
    fill(0,255,0);
    text("Mission Success!",width/7.5,height/2+height/6);
  }
  else if(scoreVal[capName]<401)    //don't display until a mission comes in
  {
    textSize(55);
    fill(255,0,0);
    text("Mission Failure!",width/7.5,height/2+height/6);
  }
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
  {
    newData = true;
    
    //save data values to compare to new messages
    oldCapName = capName;
    oldGVal = gVal;
  }
}
