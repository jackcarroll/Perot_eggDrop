/* TestStation V3.0
 *  Jackson Carroll
 *  Created: August 9th, 2019
 *  Modified: N/A
 *  
 *  V3.0 - finalize layout
 */

import mqtt.*;               // Library for MQTT communication between Test Stations and Leaderboard
import meter.*;              // Library for meters
import processing.serial.*;  // Library for serial Tx Rx
import java.util.Arrays;

Serial port;                 //create a port object from the Serial Class and define a buffer to recieve data
char HEADER = 'H';
int capName = 0;
int gVal = 0;
int oldCapName = 0;            //the old values save the data of the previous message to see
int oldGVal = 0;               //if this is the same capsule or not
boolean newData = false;
boolean firstContact = true;   //if contact has not been established
int passFail = 240;            //cutoff value for success/failure
int dataMin = 80;              //lowest value, anything below is probably error in testing
float displayGVal = dataMin;         //converted g value used for display. switched from 0-2047 scale to 0-400 scale
int missionNum[] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};    //used to keep track of most recent mission number for each capsule
boolean checkBroker = false;

Meter m;                       // Create a new meter, call it m
Mission miss;                  //a mission that is reinstated every newData
Mission currMiss;              //stores the mission value that we want to display
MQTTClient client;
PFont shentox;

//define mqtt topic names
String missionNumTopic = "capsule/missionNum";
String newMissionTopic = "capsule/newMission";
String codeTopic = "capsule/newMission/code";
String currMissionNumTopic = "capsule/newMission/missionNum";
String gValTopic = "capsule/newMission/gval";
String typeCheck = "typeCheck";

int scoreInterval = height/2;     // Vertical spacing between scores
int scoreStartx = width*12;       // Where to start scores list, x
int scoreStarty = height*2;       // Where to start scores list, y

void setup()
{
  // METER SETUP DEFINITIONS //  
  fullScreen();
  m = new Meter(this, width/6, height/7);
  m.setMeterWidth(width*2/3);
  m.setTitleFontSize(20);
  m.setTitleFontName("Arial bold");
  m.setTitle("G-Force (g)");
  m.setDisplayDigitalMeterValue(false);
  String[] scaleLabelsT = {"80", "120", "160", "200", 
                           "240", "280", "320", "360", "400"};
  m.setScaleLabels(scaleLabelsT);
  m.setScaleFontSize(18);
  m.setScaleFontName("Times New Roman bold");
  m.setScaleFontColor(color(200, 30, 70));
  m.setArcThickness(10);
  m.setMaxScaleValue(400);
  m.setNeedleThickness(3);
  m.setMinInputSignal(80);
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
  
  currMiss = new Mission();
  
  // FONT SET UP //
  shentox = createFont("Shentox-Medium.otf", 50);
  textFont(shentox);
  
  // COMMUNICATION SET-UP //
  //Serial
  try
  {
    port = new Serial(this, "COM5" ,9600);
  }
  catch(Exception e)
  {
    println("error reading COM5: " + e);
    try
    {
      port = new Serial(this, "COM4", 9600);
    }
    catch(Exception e2)
    {
      println("error reading COM4: " + e2);
    }
  }
  //MQTT
  client = new MQTTClient(this);
  client.connect("tcp://10.75.132.118:1883","Test Station"); //"tcp://[ip address]:1883" prob ethernet connection
}

void draw()
{
  //this is where the code really changes //<>//
  if(newData)
  {
    //create new mission
    missionNum[capName]++;
    displayGVal = ((float)gVal/2047)*400;     //(gVal/2047)*400 = the actual measured g Value based on 0-400g scale.
    Mission miss = new Mission(capName, missionNum[capName], displayGVal);
    
    if(miss.getGVal() > 80)
    {
      //send updated missionNum to broker
      miss.newMissionNum(missionNum);
      //send mission to leaderboard
      miss.newMission();
    }
    
    currMiss = miss;
    
    newData = false;
  }
  
  //update screen
  background(51,151,182); // Set background to blue
  fill(255,255,255);
  textSize(75);
  textAlign(CENTER);
  if(currMiss.getGVal() < dataMin)
  {
    text("Incomplete Data, Please Re-Test.", width/2, height/3.5);
  }
  else
  {
    if(currMiss.getCapName() != null)
      text(currMiss.getCapName() + " " + currMiss.getMissionNum(), width/2, height/8);     //show name of current mission being displayed
    textSize(40);
    if(currMiss.getGVal() != 401)
      displayGVal = currMiss.getGVal();
    m.updateMeter((int)displayGVal);
    fill(0,0,255);
    text(displayGVal,width/2,height/2+height/3.5);
    if(currMiss.getGVal() < passFail && currMiss.getGVal() != 0)
    {
      textSize(75);
      fill(0,255,0);
      rectMode(CENTER);
      rect(width/2,height/2+height/2.43,width/3,height/10);
      fill(255,255,255);
      text("Mission Success!",width/2,height/2+height/2.3);
    }
    else if(currMiss.getGVal()<401)    //don't display until a mission comes in
    {
      textSize(75);
      fill(255,0,0);
      rectMode(CENTER);
      rect(width/2,height/2+height/2.43,width/3,height/10);
      fill(255,255,255);
      text("Mission Failure!",width/2,height/2+height/2.3);
    }
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

//next two functions just used by mqtt
void clientConnected()
{
  println("client connected");
  client.subscribe(missionNumTopic, 2);
}

void messageReceived(String topic, byte[] payload)
{
  if(checkBroker && !newData)
  {
    //parse JSON here, set missionNum to updated vals
    JSONObject updateMissionNum = parseJSONObject(new String(payload));
    for(int i=0; i<missionNum.length; i++)
    {
      missionNum[i] = updateMissionNum.getInt(str(i)); 
    }
    println("missionNum Updated");
  
    println("Message Recieved from " + topic + " containing " + new String(payload));
  }
}
