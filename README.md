# nodemcu-web-ide
Simple Web IDE running on NodeMCU Lua

Originaly written by XChip in February 2015 and published in
http://www.esp8266.com/viewtopic.php?f=19&t=1549

Picked up by Petr Stehlík in October 2016, updated for recent NodeMCU based on SDK 1.5.x, fixed async socket:send issues, cleaned up and started improving.

https://github.com/joysfera/nodemcu-web-ide

### Usage
1. set up your NodeMCU Lua device to automatically connect to your WiFi
2. upload the _ide.lua_ to your device
3. run it with `dofile("ide.lua")`
4. launch your web browser and open the IP address of your device
