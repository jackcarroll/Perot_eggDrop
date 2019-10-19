/* LeaderBoardV1_0
 *  Jackson Carroll
 *  Created: Sept 20th, 2019
 *  Modified: N/A
 *  
 *  V1.0 - fully integrate mqtt and leaderboard
 */

import mqtt.*;               // Library for MQTT communication between Test Stations and Leaderboard
import java.util.Arrays;

int capName = 0;
float gVal = 0;         //g value used for display. switched from 0-2047 scale to 0-400 scale
int missionNum[] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};    //used to keep track of most recent mission number for each capsule
boolean newData = false;

Mission miss;
Mission dummyMiss = new Mission();
MQTTClient client;

//define mqtt topic names
String missionNumTopic = "capsule/missionNum";
String newMissionTopic = "capsule/newMission";
String codeTopic = "capsule/newMission/code";
String currMissionNumTopic = "capsule/newMission/missionNum";
String gValTopic = "capsule/newMission/gval";

Linked_List recentScores;
Linked_List topScores;

int scoreInterval = height/2;     // Vertical spacing between scores
int scoreHeight = height*3;
int scoreCol1 = width*(3/2);
int scoreCol2 = width*5;

void setup()
{
  fullScreen();
  
  recentScores = new Linked_List();
  topScores = new Linked_List();
  
  // COMMUNICATION SET-UP //
  //MQTT
  client = new MQTTClient(this);
  client.connect("mqtt://try:try@broker.shiftr.io","Test Station");
}

void draw()
{ 
  if(newData)
  {
    Mission miss = new Mission(capName, missionNum[capName], gVal);
    recentScores = recentScores.addRecent(recentScores, miss);
    topScores = topScores.addTop(topScores, miss);
    newData = false;
  }
  
  //update screen
  background(0); // Set background to black
  fill(255,255,255);
  textSize(55);
  text("Group Scores", width/7, height/6);
  text("Top Scores", width-(width/3), height/6);
  textSize(30);
  //text("test 1", scoreCol1, scoreHeight);
  //text("test 2", scoreCol2, scoreHeight);
  //text("test 1", (width/1.1)-scoreCol2, scoreHeight);
  //text("test 2", (width/1.1)-scoreCol1, scoreHeight);
  //printing recentScores
  int i = 0;
  Node last;
  if(recentScores.head == null)
    last = new Node(dummyMiss);
  else
    last = recentScores.head;
  while(last.next != null && i<16)    //first row of recentScores
  {
    text(last.miss.getCapName()+" "+last.miss.getMissionNum()+" - "+last.miss.getGVal(), scoreCol1, scoreHeight+(i*scoreInterval));
    i++;
    last = last.next;
  }
  i=0;
  while(last.next != null && i<16)    //second row of recentScores
  {
    text(last.miss.getCapName()+" "+last.miss.getMissionNum()+" - "+last.miss.getGVal(), scoreCol2, scoreHeight+(i*scoreInterval));
    i++;
    last = last.next;
  }
  //printing topScores
  i = 0;
  if(topScores.head == null)
    last = new Node(dummyMiss);
  else
    last = topScores.head;
  while(last.next != null && i<16)    //first row of topScores
  {
    text(last.miss.getCapName()+" "+last.miss.getMissionNum()+" - "+last.miss.getGVal(), (width/1.1)-scoreCol2, scoreHeight+(i*scoreInterval));
    i++;
    last = last.next;
  }
  i=0;
  while(last.next != null && i<32)    //second row of topScores
  {
    text(last.miss.getCapName()+" "+last.miss.getMissionNum()+" - "+last.miss.getGVal(), (width/1.1)-scoreCol1, scoreHeight+(i*scoreInterval));
    i++;
    last = last.next;
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
  //parse payload into json
  JSONObject message = parseJSONObject(new String(payload));
  if(message.isNull(codeTopic))
  {
    capName = message.getInt(codeTopic);
    gVal = message.getFloat(gValTopic);
    if(message.getInt(currMissionNumTopic) != missionNum[capName])                   //these should be equal, but just in case...
      missionNum[capName] = message.getInt(currMissionNumTopic);
    newData = true;
    println("newMission Updated");
  }
  else
  {
    for(int i=0; i<missionNum.length; i++)
    {
      missionNum[i] = message.getInt(str(i)); 
    }
    println("missionNum Updated");
  }
  
  
  
  
  if(topic == missionNumTopic)
  {
    //parse JSON here, set missionNum to updated vals
    JSONObject updateMissionNum = parseJSONObject(payload.toString());
    missionNum = updateMissionNum.getJSONArray("currMissions").getIntArray();    //efficient yet janky coding at its finest. 
    println("missionNum Updated");
  }
  else if(topic == newMissionTopic)
  {
    JSONObject newMission = parseJSONObject(payload.toString());
    capName = newMission.getInt(codeTopic);
    gVal = newMission.getFloat(gValTopic);
    if(newMission.getInt(currMissionNumTopic) != missionNum[capName])                   //these should be equal, but just in case...
      missionNum[capName] = newMission.getInt(currMissionNumTopic);
    newData = true;
    println("newMission Updated");
  }
  else
    println("Message Recieved from " + topic + " containing " + new String(payload));
}
