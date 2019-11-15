/* LeaderBoardV1_1
 *  Jackson Carroll
 *  Created: Sept 20th, 2019
 *  Modified: N/A
 *  
 *  V1.1 - finalize layout
 */

import mqtt.*;               // Library for MQTT communication between Test Stations and Leaderboard
import java.util.Arrays;

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

void setup()
{
  fullScreen();
  
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
  client.connect("mqtt://try:try@broker.shiftr.io","Test Station");  //tcp://10.75.132.118:1883
}

void draw()
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
  textSize(55);
  fill(255,217,73);
  rectMode(CENTER);
  rect(width/4.4,height/9,width/2.3,height/11);
  fill(255,255,255);
  textAlign(CENTER);
  text("Group Scores / Puntajes Grupales", width/4.5, height/8);
  fill(255,217,73);
  rectMode(CENTER);
  rect(width-width/3.8, height/9,width/2.5,height/11);
  fill(255,255,255);
  text("Top Scores / Puntajes más Altos", width-(width/3.76), height/8);
  textSize(29);
  textAlign(LEFT);
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
    text(i+". "+last.miss.getCapName()+" "+last.miss.getMissionNum()+" - "+nf(last.miss.getGVal(),0,3), (width/1.25)-scoreCol2, scoreHeight+(i*scoreInterval));
    i++;
    last = last.next;
  }
  while(last.next != null && i<=32)    //second row of topScores
  {
    text(i+". "+last.miss.getCapName()+" "+last.miss.getMissionNum()+" - "+nf(last.miss.getGVal(),0,3), (width/1.25)-scoreCol1, scoreHeight+((i-16)*scoreInterval));
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
    else if(mouseX > width/2 && mouseY < height/2)
    {
      topScores.head = new Node(dummyMiss);
      topScores.head.next = null;
    }
  }
}

//next two functions just used by mqtt
void clientConnected()
{
  println("client connected");
  client.subscribe(missionNumTopic, 2);
  client.subscribe(newMissionTopic, 2);
}

void messageReceived(String topic, byte[] payload)
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
