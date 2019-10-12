/* EggDropScoresV2_0 Class Definitions
 *  Jackson Carroll
 *  Created: August 9th, 2019
 *  Modified: N/A
 *  
 *  V1.0 - established superclass Capsule and subclass Mission
 */
 
//Class implementation of a singly linked list
public class LinkedList
{
  Node head;                           //head of list
  
  //node of linked list
  class Node
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
  
  //insert a new mission/node
  public LinkedList insert(LinkedList list, Mission m)
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
  
  //return the most recent mission (tail of linked list)
  public Node recentMission(LinkedList list)
  {
    Node last = list.head;
    while(last.next != null)           //traverse linked list
    {
      last = last.next;
    }
    return last;
  }
}

public class Capsule 
{
  private String nameList[] = {"Apollo", "Mercury", "Gemini", "Enterprise", "Voyager", "Discovery", 
                               "Atlantis", "Endeavour", "Artemis", "Orion", "Pioneer", "Ranger",
                               "Mariner", "Spirit", "Pathfinder", "Phoenix", "Curiosity", "Viking",
                               "Cassini", "Galileo", "Juno", "Magellan", "Infinity", "Falcon", 
                               "Serenity", "Reliant", "Defiant", "Kelvin", "Intrepid", "Eagle",
                               "Odyssey", "Kestrel", "Saturn", "Hercules"};
  private String name;
  public int codeName;
  public int missionNum = 0;
  private JSONObject missionNumJSON;
  
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
    missionNumJSON.setJSONArray("currMissions", new JSONArray(new IntList(currMissions)));    //couple of inline casts to get the array into a format JSON can read
    client.publish("missionNum", missionNumJSON.toString());
  }
}

public class Mission extends Capsule
{
  public float gVal = 401;                    //401 is larger than the largest possible score (real g-value), init-ed for potential comparison purposes
  public int mass = 0;                        //second variable that is unused, but left in code as option
  private JSONObject missionJSON;
  
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
    missionJSON.setInt("code", this.getCodeName());
    missionJSON.setInt("missionNum", this.getMissionNum());
    missionJSON.setFloat("gval",this.getGVal());
    client.publish("newMission", missionJSON.toString());
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
