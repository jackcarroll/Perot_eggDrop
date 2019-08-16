/* EggDropScoresV2_0
 *  Jackson Carroll
 *  Created: August 9th, 2019
 *  Modified: N/A
 *  
 *  V2.0 - restructure code as an Object Oriented Program
 */

Capsule apollo;
 
 void setup()
 {
   apollo = new Capsule(0);
 }
 
 void draw()
 {
   println(apollo.getName());
   println(apollo.getCodeName());
 }
