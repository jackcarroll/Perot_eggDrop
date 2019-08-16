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
    int gVal;
    int code;
    Node next;
    
    //constructor
    Node(int c, int g)
    {
      code = c;
      gVal = g;
      next = null;
    }
  }
  
  //insert a new mission/node
  public static LinkedList insert(LinkedList list, int c, int g)
  {
    //create a new node with given data
    Node new_node = new Node(c,g);
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

class Capsule 
{
  private String nameList[] = {"Apollo", "Gemini", "Mercury", "Voyager", "Enterprise",
                               "Dexphnaus", "Eagle", "Fitzgarb", "Hercules", "Icarus", 
                               "Juno", "Intrepid", "Challenger", "Kelvin", "Kestrel", 
                               "Falcon", "", "", "", "", "", "", "", "", "", "", "", "", "", ""};
  private String name;
  public int codeName;
  public LinkedList missionList = new LinkedList();
  
  Capsule(int code)                    //MAIN CONSTRUCTOR
  {
    codeName = code;
    name = nameList[codeName];
  }
  
  Capsule(String n)                    //extra constructor in case you know the name, but not the code associated with it
  {
    name = n;
    for(int i=0; i<nameList.length; i++)
    {
      if(nameList[i] == n)
        codeName = i;
    }
  }
  
  public String getName()
  {
    return name;
  }
  
  public int getCodeName()
  {
    return codeName;
  }
  
  public void newMission(Mission m)
  {
    missionList = insert(missionList, m.getCodeName(), m.getGVal());
  }
}

class Mission extends Capsule
{
  public int gVal;
  public int mass = 0;                      //second variable that is unused, but left in code as option
  
  Mission(int code, int g)                  //MAIN CONSTRUCTOR
  {
    super(code);
    gVal = g;
  }
  
  Mission(int code, int g, int m)           //constructor for if you use mass as a variable
  {
    super(code);
    gVal = g;
    mass = m;
  }
  
  public void setGVal(int g)
  {
    gVal = g;
  }
  
  public int getGVal()
  {
    return gVal;
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
