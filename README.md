# Perot_eggDrop
repo for code associated with the Perot Museum Egg/Capsule Drop Engineering Challenge in the ChallENGe Lab.

Most code is built to run within the Arduino or Processing IDE's. Written in C++ and Java respectively.

TestCapsule is test code built for an arduino uno, but simulates the actions taken by the Qduino within the capsule.

BaseStationV1_2, EggDropScoresV1_2, and EggDropScoresV3_2 are all built to work together in one system. Used during testing August 2019.

Current working code for the ChellENGe Lab test stations and leaderboard are TestStation V3.0, and Leaderboard V1.1.

System Structure:
Each capsule is treated as it's own entity that gathers data as a mission, which constitutes a unique number (i.e. Apollo 5) and the g value it measured. That data is collected by the Test station, organized into that format, and sent to the MQTT broker. It then displays the current mission, alongside with whether that mission passed or failed. The Leaderboard then retrieves the latest missions from the broker, and adds them to two lists, recentScores and topScores. recentScores, or group scores, is a collection of the most recent trial of each capsule, and the first 32 are displayed. Top Scores is a sorted list containing the missions that acheived the lowest g value. 
