# Perot_eggDrop
repo for code associated with the Perot Museum Egg/Capsule Drop Engineering Challenge in the ChallENGe Lab.

Most code is built to run within the Arduino or Processing IDE's. Written in C++ and Java respectively.

TestCapsule is test code built for an arduino uno, but simulates the actions taken by the Qduino within the capsule.

BaseStationV1_2, EggDropScoresV1_2, and EggDropScoresV3_2 are all built to work together in one system. Used during testing August 2019.


Structure of System:

# Capsule code - Qduino
  - measures accelerometer data
  - sends data alongside capsule ID through Serial
  
# Translator code - Arduino MEGA
  - recieves capsule ID and g Val data trough Serial
  - converts from bytes to int
  - sends data through Serial to Test Station
  
# Test Station code - Nuc
  - Recieves data through Serial
  - Constructs mission object to contain data
      - checking mission number against global published mission number
  - displays data, pass/fail
  - publishes data and updates global published mission number
  
# Leaderboard code - Nuc
  - Subscribes to incoming missions
  - publishes most recent mission number
  - displays list of most recent mission for each capsule
  - displays list of best performing missions
  
# capsules.pde - Nuc
  - definitions of capsule and mission objects
  - mission inherits from capsule class
  - must be paired with test station code and leaderboard code
  
MQTT System:
  test stations and leaderboard connected.
  topics:
    - posted mission for each test station
    - global list of most recent mission number for each capsule
