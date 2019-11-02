import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import mqtt.*; 
import meter.*; 
import processing.serial.*; 
import java.util.Arrays; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class TestStationV3_0 extends PApplet {

/* TestStation V3.0
 *  Jackson Carroll
 *  Created: August 9th, 2019
 *  Modified: N/A
 *  
 *  V3.0 - finalize layout
 */

               // Library for MQTT communication between Test Stations and Leaderboard
              // Library for meters
  // Library for serial Tx Rx


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

public void setup()
{
  // METER SETUP DEFINITIONS //  
  
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

public void draw()
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
    text("Incomplete Data, Please Re-Test.", width/2, height/3.5f);
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
    text(displayGVal,width/2,height/2+height/3.5f);
    if(currMiss.getGVal() < passFail && currMiss.getGVal() != 0)
    {
      textSize(75);
      fill(0,255,0);
      rectMode(CENTER);
      rect(width/2,height/2+height/2.43f,width/3,height/10);
      fill(255,255,255);
      text("Mission Success!",width/2,height/2+height/2.3f);
    }
    else if(currMiss.getGVal()<401)    //don't display until a mission comes in
    {
      textSize(75);
      fill(255,0,0);
      rectMode(CENTER);
      rect(width/2,height/2+height/2.43f,width/3,height/10);
      fill(255,255,255);
      text("Mission Failure!",width/2,height/2+height/2.3f);
    }
  }
}

//code based on example from Arduino Cookbook by Micheal Margolis
public void serialEvent(Serial p)
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
public void clientConnected()
{
  println("client connected");
  client.subscribe(missionNumTopic, 2);
}

public void messageReceived(String topic, byte[] payload)
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
/* EggDropScoresV2_0 Class Definitions
 *  Jackson Carroll
 *  Created: August 9th, 2019
 *  Modified: N/A
 *  
 *  V1.0 - established superclass Capsule and subclass Mission
 */
 
//Class implementation of a singly linked list with methods built for this program's application
//node of linked list
public class Node
{
  Mission miss;
  Node next;
  
  //constructor
  Node(Mission m)
  {
    miss = m;
    next = null;
  }
}
public class Linked_List
{
  Node head;                           //head of list
  
  //append a new mission/node to the end of the list
  public Linked_List addEnd(Linked_List list, Mission m)
  {
    //create a new node with given data
    Node new_node = new Node(m);
    new_node.next = null;
    
    //if list is empty, make new_node the head
    if(list.head == null)
      list.head = new_node;
    else
    {
      //else traverse to the last node, and insert new_node after
      Node last = list.head;
      while(last.next != null)
      {
        last = last.next;
      }
      last.next = new_node;
    }
    
    return list;
  }
  
  //add a new mission/node to the front of the topScores list
  public Linked_List addTop(Linked_List list, Mission m)
  {
    Node new_node = new Node(m);
    new_node.next = null;
    
    if(list.head == null)
      list.head = new_node;
    else
    {
      //traverse the list, comparing values and placing new_node in proper rank
      Node curr = list.head, prev = list.head;
      while(curr.next != null)
      {
        if(new_node.miss.getGVal() > curr.miss.getGVal())
        {
          prev.next = new_node;
          new_node.next = curr;
        }
        prev = curr;
        curr = curr.next;
      }
    }
    return list;
  }
  
  //add a new mission/node to the front of the recentScores list
  //and remove the previous mission of that capsule
  public Linked_List addRecent(Linked_List list, Mission m)
  {
    Node new_node = new Node(m);
    new_node.next = null;
      
    if(list.head == null)
      list.head = new_node;
    else
    {
      new_node.next = list.head;
      list.head = new_node;
      
      Node iter = list.head;
      while(iter.next != null)
      {
        if(iter.miss.getCodeName() == new_node.miss.getCodeName())
          list = delete(list, iter.miss);
        iter = iter.next;
      }
    }
    
    return list;
  }
  
  //delete an element of the list based on what mission it stores
  public Linked_List delete(Linked_List list, Mission m)
  {
    Node curr = list.head, prev = null;
    
    if(curr != null && curr.miss == m)
    {
      list.head = curr.next;
      return list;
    }
    
    while(curr != null && curr.miss != m)
    {
      prev = curr;
      curr = curr.next;
    }
    
    if(curr != null)
      prev.next = curr.next;
    
    return list;
  }
}

public class Capsule 
{
  private String nameList[] = {"Apollo", "Mercury", "Gemini", "Enterprise", "Voyager", "Discovery", 
                               "Atlantis", "Endeavour", "Artemis", "Orion", "Pioneer", "Ranger",
                               "Mariner", "Spirit", "Pathfinder", "Phoenix", "Curiosity", "Viking",
                               "Cassini", "Galileo", "Juno", "Magellan", "Infinity", "Falcon", 
                               "Serenity", "Reliant", "Defiant", "Kelvin", "Intrepid", "Eagle",
                               "Odyssey", "Kestrel", "Saturn", "Hercules", "Webb", "Hubble", "Surveyor",
                               "Genesis", "Icarus", "Kirk"};
  private String name;
  public int codeName;
  public int missionNum = 0;
  private JSONObject missionNumJSON = new JSONObject();
  
  Capsule(int code)                           //constructor if you don't need to track mission num
  {
    codeName = code;
    name = nameList[codeName];
  }
  
  Capsule(int code, int mission)              //MAIN CONSTRUCTOR
  {
    codeName = code;
    name = nameList[codeName];
    missionNum = mission;
    
  }
  
  Capsule(String n)                           //extra constructor in case you know the name, but not the code associated with it
  {
    name = n;
    for(int i=0; i<nameList.length; i++)
    {
      if(nameList[i] == n)
        codeName = i;
    }
  }
  
  public String getCapName()
  {
    return name;
  }
  
  public int getCodeName()
  {
    return codeName;
  }
  
  public void setMissionNum(int mission)
  {
    missionNum = mission;
  }
  
  public int getMissionNum()
  {
    return missionNum;
  }
  
  public void newMissionNum(int[] currMissions)
  {
    boolean retained = true;
    for(int i=0; i<currMissions.length; i++)
    {
      String JSONKey = str(i);
      missionNumJSON.setInt(JSONKey,currMissions[i]);
    }
    missionNumJSON.setInt(typeCheck,1);       //1 if missionNum, 0 if newMission
    client.publish(missionNumTopic, missionNumJSON.toString(), 2, retained);
    checkBroker = true;
  }
}

public class Mission extends Capsule
{
  public float gVal;                    //401 is larger than the largest possible score (real g-value), init-ed for potential comparison purposes
  public int mass = 0;                        //second variable that is unused, but left in code as option
  private JSONObject missionJSON = new JSONObject();
  
  Mission(int code, float g)                  //MAIN CONSTRUCTOR
  {
    super(code);
    gVal = g;
  }
  
  Mission(int code, int mission, float g)     //constructor for non-mqtt case
  {
    super(code,mission);
    gVal = g;
  }
  
  Mission(int code, float g, int m)           //constructor for if you use mass as a variable
  {
    super(code);
    gVal = g;
    mass = m;
  }
  
  Mission()                                   //empty constructor for init case
  {
    super(null);
    gVal = 401;
  }
  
  public void setGVal(float g)
  {
    gVal = g;
  }
  
  public float getGVal()
  {
    return gVal;
  }
  
  public void newMission()
  {
    boolean retained = true;
    missionJSON.setInt(codeTopic, this.getCodeName());
    missionJSON.setInt(currMissionNumTopic, this.getMissionNum());
    missionJSON.setFloat(gValTopic,this.getGVal());
    missionJSON.setInt(typeCheck,0);        //1 if missionNum, 0 if newMission
    client.publish(newMissionTopic, missionJSON.toString(), 2, retained);
    println("newMission " + retained);
  }
  
  public void setMass(int m)                //only use if mass included in experiment
  {
    mass = m;
  }
  
  public int getMass()                      //only use if mass included in experiment
  {
    return mass;
  }
}
  public void settings() {  fullScreen(); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "--present", "--window-color=#666666", "--stop-color=#cccccc", "TestStationV3_0" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
