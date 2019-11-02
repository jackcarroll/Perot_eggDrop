import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import mqtt.*; 
import java.util.Arrays; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class LeaderBoardV1_1 extends PApplet {

/* LeaderBoardV1_1
 *  Jackson Carroll
 *  Created: Sept 20th, 2019
 *  Modified: N/A
 *  
 *  V1.1 - finalize layout
 */

               // Library for MQTT communication between Test Stations and Leaderboard


int capName = 0;
float gVal = 0;         //g value used for display. switched from 0-2047 scale to 0-400 scale
int missionNum[] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};    //used to keep track of most recent mission number for each capsule
boolean newData = false;
boolean checkBroker = false;

Mission miss;
Mission dummyMiss = new Mission();
MQTTClient client;
PFont shentox;

//define mqtt topic names
String missionNumTopic = "capsule/missionNum";
String newMissionTopic = "capsule/newMission";
String codeTopic = "capsule/newMission/code";
String currMissionNumTopic = "capsule/newMission/missionNum";
String gValTopic = "capsule/newMission/gval";
String typeCheck = "typeCheck";

Linked_List recentScores;
Linked_List topScores;

int scoreInterval = height/2;     // Vertical spacing between scores
int scoreHeight = height*2;
int scoreCol1 = width*(3/2);
int scoreCol2 = width*5;

public void setup()
{
  
  
  recentScores = new Linked_List();
  recentScores.addTop(recentScores,dummyMiss);
  topScores = new Linked_List();
  topScores.addTop(topScores,dummyMiss);
  
  // FONT SET UP //
  shentox = createFont("Shentox-Medium.otf", 50);
  textFont(shentox);
  
  // COMMUNICATION SET-UP //
  //MQTT
  client = new MQTTClient(this);
  client.connect("tcp://10.75.132.118:1883","Test Station");
}

public void draw()
{ 
  if(newData)
  {
    Mission miss = new Mission(capName, missionNum[capName], gVal);
    println(miss.getCapName() + miss.getMissionNum());
    recentScores = recentScores.addRecent(recentScores, miss);
    topScores = topScores.addTop(topScores, miss);
    newData = false;
  }
  
  //update screen
  background(51,151,182); // Set background to black
  fill(255,255,255);
  textSize(55);
  text("Group Scores", width/7, height/8);
  text("Top Scores", width-(width/3), height/8);
  textSize(29);
  //text("test 1", scoreCol1, scoreHeight);
  //text("test 2", scoreCol2, scoreHeight);
  //text("test 1", (width/1.1)-scoreCol2, scoreHeight);
  //text("test 2", (width/1.1)-scoreCol1, scoreHeight);
  //printing recentScores
  int i = 1;
  Node last = recentScores.head;
  while(last.next != null && i<=16)    //first row of recentScores
  {
    text(i+". "+last.miss.getCapName()+" "+last.miss.getMissionNum()+" - "+nf(last.miss.getGVal(),0,3), scoreCol1, scoreHeight+(i*scoreInterval));
    i++;
    last = last.next;
  }
  while(last.next != null && i<=32)    //second row of recentScores
  {
    text(i+". "+last.miss.getCapName()+" "+last.miss.getMissionNum()+" - "+nf(last.miss.getGVal(),0,3), scoreCol2, scoreHeight+((i-16)*scoreInterval));
    i++;
    last = last.next;
  }
  //printing topScores
  i = 1;
  last = topScores.head;
  while(last.next != null && i<=16)    //first row of topScores
  {
    text(i+". "+last.miss.getCapName()+" "+last.miss.getMissionNum()+" - "+nf(last.miss.getGVal(),0,3), (width/1.25f)-scoreCol2, scoreHeight+(i*scoreInterval));
    i++;
    last = last.next;
  }
  while(last.next != null && i<=32)    //second row of topScores
  {
    text(i+". "+last.miss.getCapName()+" "+last.miss.getMissionNum()+" - "+nf(last.miss.getGVal(),0,3), (width/1.25f)-scoreCol1, scoreHeight+((i-16)*scoreInterval));
    i++;
    last = last.next;
  }
  
  //clear group scores
  if(mousePressed == true)
  {
    if(mouseX < width/2 && mouseY < height/2)
    {
      recentScores.head = new Node(dummyMiss);
      recentScores.head.next = null;
    }
  }
}

//next two functions just used by mqtt
public void clientConnected()
{
  println("client connected");
  client.subscribe(missionNumTopic, 2);
  client.subscribe(newMissionTopic, 2);
}

public void messageReceived(String topic, byte[] payload)
{
  try
  {
    //parse payload into json
    JSONObject message = parseJSONObject(new String(payload));
    if(message.getInt(typeCheck) == 0)
    {
      capName = message.getInt(codeTopic);
      gVal = message.getFloat(gValTopic);
      if(message.getInt(currMissionNumTopic) != missionNum[capName])                   //these should be equal, but just in case...
        missionNum[capName] = message.getInt(currMissionNumTopic);
      newData = true;
      println("newMission Updated");
    }
    else if(message.getInt(typeCheck) == 1)
    {
      for(int i=0; i<missionNum.length; i++)
      {
        missionNum[i] = message.getInt(str(i)); 
      }
      println("missionNum Updated");
    }
    else
      println("Message Recieved from " + topic + " containing " + new String(payload));
  }
  catch (Exception e)
  {
    e.printStackTrace();
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
  
  //add a new mission/node ordered into the topScores list
  public Linked_List addTop(Linked_List list, Mission m)
  {
    Node new_node = new Node(m);
    new_node.next = null;
    Node curr;
    
    if(list.head == null || head.miss.getGVal() >= new_node.miss.getGVal())
    {
      new_node.next = list.head;
      list.head = new_node;
    }
    else
    {
      curr = list.head;
      while(curr.next != null && curr.next.miss.getGVal() < new_node.miss.getGVal())
        curr = curr.next;
      new_node.next = curr.next;
      curr.next = new_node;
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
      
      Node iter = list.head.next;
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
  
  //print out the list
  public void printList(Linked_List list)
  {
    Node curr = list.head;
    
    while(curr != null)
    {
      println(curr.miss.getCapName() + curr.miss.getMissionNum());
      curr = curr.next;
    }
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
    missionNumJSON.setInt(typeCheck,1);        //1 if missionNum, 0 if newMission
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
    String[] appletArgs = new String[] { "--present", "--window-color=#666666", "--stop-color=#cccccc", "LeaderBoardV1_1" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
