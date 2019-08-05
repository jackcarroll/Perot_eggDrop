/* EggDrop_Vx.x
    Jeremy W McCarter
    Created: July 4, 2019
    Modified: August 4, 2019

    Version Tracking
    V1.0 - Initial Release
    V2.0 - Triggering data acquisition based on electromagnet release
    V2.1 - Cleaning up
    V2.2 - Adding findMaxParabola to fit parabola to 3 points and interpolate max value
    V2.3 - With findMaxParabola working great, I changed the library files to only
           receive values for z (ignoring x and y), which decreased acquisition time from
           3ms per sample to 1ms per sample, matching the 1000Hz sampling rate.
           This version will show that higher bandwidth data on a plot, and clean up
           the plotting/monitoring options.
    V3.0 - Adding Jackson Carroll's code for communication.
           Works using while(1) and sending random data.
    V3.1 - Incorporating sending actual data values, only when asked from Mega
    V3.2 - Adding digitalWrite(A5, LOW) to act as ground for capsuleAddress pins (A0-A4)
         - Adding NeoPixel functionality to show GREEN when attached to magnet and ready to drop, RED when not attached.
         - Cleanup and commented.
*/

// LIBRARIES //
#include "SparkFun_LIS331.h"    // Include accelerometer library
#include <Qduino.h>             // Include Qduino library
#include <Wire.h>               // Include I2C library

// DEFINE PIN NAMES //
#define magTrigger 12     // magTrigger on D12

// CREATE OBJECTS //
LIS331 xl;                // Set up LIS331 accelerometer as "xl"
qduino x;                 // Initiate Qduino library for NeoPixel support as "x" (suggested by @Qtechknow...not sure if variable name is crucial)


// INITIALIZE VARIABLES //
int capsuleAddress = 0;   // capsuleAddress defines which capsule
int16_t z;                // Initialize accelerometer z value
int points = 500;         // Total number of data points 
int dataArray[500];       // Intialize dataArray to store accelerometer data

int maxRange = 400;       // maxRange sets accelerometer range (100, 200, or 400) in g's
int beforeValueInt = 0;   // beforeValueInt is one measurement BEFORE maxValue
float beforeValueG = 0.0; // beforeValueG is beforeValueInt converted to g
int afterValueInt = 0;    // afterValueInt is one measurement AFTER maxValue
float afterValueG = 0.0;  // afterValueG is afterValueInt converted to g
int maxValue = 0;         // maxValue is the peak digital value (from 0 to 2047)
float maxInterpolated = 0;// maxInterpolated is an interpolated peak, calculated in findMaxParabola
int maxIndex = 0;         // maxIndex is the index of maxValue
float maxG = 0.0;         // maxG is maxValue converted to g

char header = '"';        // " is hex value: 0x22 chosen because highest hex val of cap name is 0x1F

// TIMING //
unsigned long timeBefore = 0;   // timeBefore is millis() before drop
unsigned long timeAfter = 0;    // timeAfter is millis() after drop
unsigned long totalTime = 0;    // totalTime is timeAfter - timeBefore

// DISPLAY OPTIONS //
boolean plotData = 0;           // Use plotData to output all of dataArray to Serial Plotter (MUST BE TETHERED TO QDUINO's USB)
boolean printData = 1;          // Use printData to print key values to Serial Monitor


// FLAGS //
boolean capsuleDetached = 0;    // capsuleDetached goes HIGH when capsule is not connected to ElectroMagnet
boolean dataArmed = 0;          // dataArmed goes HIGH when capsule is attached to ElectroMagnet, ready to collect data

void setup()
{
  Serial.begin(9600);         // Enable Serial for Serial Monitor comms
  Serial1.begin(9600);        // Enable Serial1 for UART comms
  x.setup();                  // Enable Qduino LED known as "x"

  // SET PIN MODES //
  pinMode(9, INPUT);          // Accelerometer's interrupt pin input (Currently unused as of V3.2)
  pinMode(12, INPUT_PULLUP);  // magTrigger (D12) is used to trigger data acquisition on magnetic drop
  pinMode(A0, INPUT_PULLUP);  // A0 is address0, LSB
  pinMode(A1, INPUT_PULLUP);  // A1 is address1
  pinMode(A2, INPUT_PULLUP);  // A2 is address2
  pinMode(A3, INPUT_PULLUP);  // A3 is address3
  pinMode(A4, INPUT_PULLUP);  // A4 is address4, MSB
  pinMode(A5, OUTPUT);        // A5 is pulled LOW to act as ground for capsuleAddress pins (A0-A4)


  // CONFIGURE ACCELEROMETER //
  Wire.begin();                                 // Start I2C
  xl.setI2CAddr(0x19);                          // Set accelerometer I2C address to 0x19 (default)
  xl.begin(LIS331::USE_I2C);                    // Start communication
  xl.setPowerMode(LIS331::NORMAL);              // Set PowerMode
  xl.setFullScale(LIS331::HIGH_RANGE);          // Set Range (LOW_RANGE = 100, MED_RANGE = 200, HIGH_RANGE = 400)
  xl.setODR(LIS331::DR_1000HZ);                 // Set data rate (highest is DR_1000HZ)

  digitalWrite(A5, LOW);                        // Set A5 LOW to act as ground for capsuleAddress pins (A0-A4)

} // End of setup()

void loop()
{

  //*//*/* LAUNCH SEQUENCE /*//*/*//

  // CHECK ELECTROMAGNET //
  capsuleDetached = digitalRead(magTrigger);            // capsuleDetached = 0 means attached and ready to drop; 1 means magnet detached


  // IF CAPSULE IS ON MAGNET //
  if (!capsuleDetached) {                               // If capsule is on ElectroMagnet
    x.setRGB("green");                                  // Set NeoPixel to GREEN while on ElectroMagnet; must be lowercase
    dataArmed = 1;                                      // dataArmed means get ready to take data on next drop
    delay(50);                                          // delay 50ms to avoid bouncing or jostling
  }

  // WAIT UNTIL DROP //
  while (!capsuleDetached) {                            // Wait here until ElectroMagnet is released
    capsuleDetached = digitalRead(magTrigger);          // Has it dropped yet?
    delay(10);
  }

  //// CAPSULE HAS DROPPED!!! /////
  if (dataArmed) {
    x.setRGB("red");                                     // Set NeoPixel to RED while dropping; must be lowercase
    delay(400);                                          // IMPORTANT!  delay(400) to delay data collection for first 400ms of drop.
                                                         // With points = 500 @ 1kHz, data is only collected for 0.5s.  A 6-foot drop
                                                         // takes approximately 0.9 seconds, so without this 400ms delay, the data collection
                                                         // would be completed before impact actually happens.
   
    // TAKE DATA //
    timeBefore = millis();                              // Take timeBefore reading
    for (int a = 0; a < points; a++) {                  // Do this 'points' times
      xl.readAxes(z);                                   // Read data in z dimension from accelerometer
      dataArray[a] = z;                                 // Put z data into array
    }
    timeAfter = millis();                               // Take timeAfter reading
    totalTime = timeAfter - timeBefore;                 // Calculate total acquisition time


    // FIND MAX VALUE //
    maxValue = 0;                             // Reset maxValue to find maxValue
    for (int b = 0; b < points; b++) {        // Do this 'points' times
      if (dataArray[b] > maxValue) {          // If current point is greater than maxValue,
        maxIndex = b;                         // Update maxIndex
        maxValue = dataArray[b];              // Update maxValue
      }   
    }
    beforeValueInt = dataArray[maxIndex - 1]; // Get value before max
    afterValueInt = dataArray[maxIndex + 1];  // Get value after max


  }   // End of data acquisition


  // PERFORM CALCULATIONS //
  maxG = (maxValue / 2047.0) * maxRange;                // Calculate maxG from maxValue
  beforeValueG = (beforeValueInt / 2047.0) * maxRange;  // Calculate beforeValueG
  afterValueG = (afterValueInt / 2047.0) * maxRange;    // Calculate afterValueG
  maxInterpolated = findMaxParabola(beforeValueInt, maxValue, afterValueInt, maxRange);     // Calculate maxInterpolated based on fit parabola of 3 points


  // PRINT DATA TO SERIAL MONITOR //
  if (printData && dataArmed) {
    Serial.print("beforeG = "); Serial.println(beforeValueG);
    Serial.print("maxG = "); Serial.println(maxG);
    Serial.print("maxInterpolated = "); Serial.println(maxInterpolated);
    Serial.print("afterG = "); Serial.println(afterValueG);
    Serial.print("maxValue = "); Serial.println(maxValue);
    Serial.print("maxIndex = "); Serial.println(maxIndex);
    Serial.print("Total Acquisition Time: "); Serial.print(totalTime); Serial.println("ms");
    Serial.println();

  }

  // OUTPUT DATA TO SERIAL PLOTTER //
  if (plotData && dataArmed) {
    for (int c = maxIndex - 20; c < maxIndex + 20; c++) {
      float data  = (dataArray[c] / 2047.0) * maxRange;
      Serial.println(data);
    }
  }


  // OUTPUT DATA TO UART FOR CONNECTION TO MEGA & PROCESSING //
  if (Serial1.available() > 0) {       // wait for call from test station before responding
    establishContact();
    capsuleAddress = getAddress();            // Get capsuleAddress

    Serial1.print(header);                    // Send header
    Serial1.write(lowByte(capsuleAddress));   // Only least significant byte contains data of capsuleAddress

    //send g value
    Serial1.write(highByte(maxValue));  //send most significant byte
    Serial1.write(lowByte(maxValue));   //send least significant byte

    delay(1000);

  }


  dataArmed = 0;    // Reset dataArmed flag

} // END OF LOOP


float findMaxParabola(int beforeValue, int maxValue, int afterValue, int maxRange) {
  float result, a, c, x0, y0, x1, y1, x2, y2, x3, y3;
  x0 = 0;
  y0 = 0;
  x1 = 0;
  y1 = beforeValue;
  x2 = 1;
  y2 = maxValue;
  x3 = 2;
  y3 = afterValue;

  c  = ((y1 - y2) / (y2 - y3));
  x0 = (((sq(x1) + sq(x2) + c * (sq(x2) - sq(x3))))  /  (2.0 * ( -x1 + x2 + (c * x2) - (c * x3) )));
  a  = ((y1 - y2)  /  (sq(x1 - x0) - sq(x2 - x0) ));
  y0 = (y1 - (a * sq(x1 - x0)));

  result  = (y0 / 2047.0) * maxRange;
  return result;    // The max of the parabola
}

int getAddress() {
  int capsuleAddress = (digitalRead(A0) * 1) + (digitalRead(A1) * 2) + (digitalRead(A2) * 4) + (digitalRead(A3) * 8) + (digitalRead(A4) * 16);
  return capsuleAddress;
}

void establishContact()                // This code waits to hear from test station before sending data.
{ 
  while (Serial1.available() <= 0)      
  {
    Serial1.write('\n');
    delay(300);
  }
}
