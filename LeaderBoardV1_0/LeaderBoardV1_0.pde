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
MQTTClient client;

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
  client.connect("test.mosquitto.org","Test Station");
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
  text("test 1", scoreCol1, scoreHeight);
  text("test 2", scoreCol2, scoreHeight);
  text("test 1", (width/1.1)-scoreCol2, scoreHeight);
  text("test 2", (width/1.1)-scoreCol1, scoreHeight);
  //printing recentScores
  int i = 0;
  Node last = recentScores.head;
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
  client.subscribe("missionNum");
  client.subscribe("newMission");
}

void messageReceived(String topic, byte[] payload)
{
  if(topic == "missionNum")
  {
    //parse JSON here, set missionNum to updated vals
    JSONObject updateMissionNum = parseJSONObject(payload.toString());
    missionNum = updateMissionNum.getJSONArray("currMissions").getIntArray();    //efficient yet janky coding at its finest. 
  }
  else if(topic == "newMission")
  {
    JSONObject newMission = parseJSONObject(payload.toString());
    capName = newMission.getInt("code");
    gVal = newMission.getFloat("gval");
    if(newMission.getInt("missionNum") != missionNum[capName])                   //these should be equal, but just in case...
      missionNum[capName] = newMission.getInt("missionNum");
    newData = true;
  }
  else
    println("Message Recieved from " + topic + "containing " + new String(payload));
}
