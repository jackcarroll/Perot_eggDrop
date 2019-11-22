/* TestCapsule
 * Jackson Carroll
 * Created: July 17, 2019
 * Modified: July 23, 2019
 * 
 * V1.1 - Now sends data as bytes using Serial.write()
 */

int randCap;
int randGVal;

char header = '"';                     //hex value: 0x22  chosen because highest hex val of
                                       //cap name is 0x1F
void setup() 
{
  Serial.begin(9600);
  randomSeed(analogRead(7));           //set to an unused pin to help randomize data
  establishContact();
}

void loop()                            //sends a random capsule with random g value every second
{
  if(Serial.available() > 0)           //wait for call from test station before responding
  {
    //generate random data
    randCap = random(32);
    randGVal = random(2048);

    //send header
    Serial.print(header);

    //send capsule name
    Serial.write(lowByte(randCap));    //only least significant byte contains data of cap name

    //send g value
    Serial.write(highByte(randGVal));  //send most significant byte
    Serial.write(lowByte(randGVal));   //send least significant byte
    
    delay(1000);
  }
  
}

void establishContact()                //this code waits to hear from test station before sending data.
{                                      //my code calls it during setup, in the capsule it should
  while(Serial.available() <= 0)       //be called once data has been recieved
  {
    Serial.print('\n');
    delay(300);
  }
}
