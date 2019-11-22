/* EggDropScoresV2_0
 *  Jackson Carroll
 *  Created: August 9th, 2019
 *  Modified: N/A
 *  
 *  V2.0 - restructure code as an Object Oriented Program
 */

import mqtt.*;               // Library for MQTT communication between Test Stations and Leaderboard
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
int missionNum[] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};    //used just for non-mqtt case

Meter m;                       // Create a new meter, call it m
Mission miss;
MQTTClient client;

int scoreInterval = height/2;     // Vertical spacing between scores
int scoreStartx = width*14;       // Where to start scores list, x
int scoreStarty = height*2;       // Where to start scores list, y

void setup()
{
  // METER SETUP DEFINITIONS //  
  fullScreen();
  m = new Meter(this, width/16, height/4);
  m.setMeterWidth(width/2);
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
  
  
  // COMMUNICATION SET-UP //
  //Serial
  port = new Serial(this, "COM4" ,9600);
  //MQTT
  client = new MQTTClient(this);
  client.connect("test.mosquitto.org","Test Station");
}

void draw()
{
  //this is where the code really changes
  if(newData)
  {
    //create new mission
    missionNum[capName]++;                    //just used for non-mqtt case
    displayGVal = ((float)gVal/2047)*400;     //(gVal/2047)*400 = the actual measured g Value based on 0-400g scale.
    Mission miss = new Mission(capName, missionNum[capName], displayGVal);    //constructor used for non-mqtt case
    //Mission miss = new Mission(capname, displayGVal);          //constructor used for mqtt case
    
    //send mission to leaderboard
    //mqtt.publish(miss);
    
    newData = false;
  }
  
  //update screen
  background(0); // Set background to black
  fill(255,255,255);
  textSize(55);
  text(miss.getCapName() + " " + missionNum[capName], width/4, height/6);     //show name of current mission being displayed
  textSize(35);
  m.updateMeter((int)miss.getGVal());
  fill(0,0,255);
  text(displayGVal,width/3.5,height/2+height/3.8);
  if(miss.getGVal() < passFail && miss.getGVal() != 0)
  {
    textSize(55);
    fill(0,255,0);
    text("Mission Success!",width/4.7,height/2+height/3);
  }
  else if(miss.getGVal()<401)    //don't display until a mission comes in
  {
    textSize(55);
    fill(255,0,0);
    text("Mission Failure!",width/4.7,height/2+height/3);
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
  client.subscribe("missionNum");
}

void messageReceived(String topic, byte[] payload)
{
  if(topic == "missionNum")
  {
    //parse JSON here, set missionNum to updated val
  }
  else
    println("Message Recieved from " + topic + "containing " + new String(payload));
}
