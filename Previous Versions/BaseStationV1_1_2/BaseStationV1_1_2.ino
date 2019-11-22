/* BaseStationV1.1.2
 *  Jackson Carroll
 *  Created: July 22, 2019
 *  Modified: July 23, 2019
 *  
 *  V1.1.2 - worked at the byte level instead of the value level
 */

//vars for parsing data
boolean newData = false;
byte header = 0x22;                  //ASCII value: "
byte temp;
int capsuleName = 0;
int gVal = 0;

boolean RepeaterMode = 1;            // Set to 1 if you want to receive data on Serial3 and send it out on Serial
                                     // Set to 0 to disable
                                     // NOTE: Do not use RepeaterMode and TestMode simultaneously!

boolean TestMode = 0;                // Set to 1 to simply send data through Serial (USB)
                                     // Set to 0 to disable                          
                                     // NOTE: Do not use RepeaterMode and TestMode simultaneously!

void setup() 
{
  Serial.begin(9600);                // open Serial port (USB), set data rate to 9600 bps
  Serial3.begin(9600);               // open Serial3 port, set data rate to 9600 bps
}

void loop() 
{
if (RepeaterMode){                   // If RepeaterMode is enabled (1)
  recvPackage();
  if(newData)
    sendData();
}


if (TestMode){                       // If TestMode is enabled (1)
  delay(2000);
  for (int a = 0; a <= 99; a++){     // Do this 100 times
    Serial.write(a);                 // Print a on Serial port (USB)
    delay(1000);                     // delay 1000ms (1s)
  }
}
}

//reads and parses the data on the serial port
void recvPackage()
{
  Serial3.print('A');
  if(Serial3.available()>= 4)        //if there are 4 bytes available on the serial port
  {
    Serial3.readBytes(&temp,1);
    if(temp == header)               //look for start of message
    {
      //reading capsule name
      Serial3.readBytes(&temp,1);
      if(temp <= 0x1F)               //0x1F = 31 in decimal, used for error checking
        capsuleName = temp;
      else
        Serial.println("error reading capsule name");

      //reading g value
      Serial3.readBytes(&temp,1);
      if(temp <= 0x07)               //2047 in hex is 0x07FF, this looks at just the MSB
      {
        gVal = temp*256;
        Serial3.readBytes(&temp,1);  //recieving the LSB
        gVal = gVal + temp;
      }
      else
        Serial.println("error reading g value");

      newData = true;                //ready to send data to processing
    }
    else
      Serial.println("Waiting for header");
  }
}

//send data through the Serial (USB) port to the computer
void sendData()
{
  Serial.print("Capsule Number: |");
  Serial.println(capsuleName);
  Serial.print("G Value: |");
  Serial.println(gVal);
  Serial.println(" ");
  newData = false;
}
