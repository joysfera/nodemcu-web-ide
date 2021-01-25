# nodemcu-web-ide
Simple Web IDE running on NodeMCU Lua.
This sketch is compatiable with NodeMCU 3.0.

Originaly written by XChip in February 2015 and published in
http://www.esp8266.com/viewtopic.php?f=19&t=1549

Picked up by Petr Stehlík in October 2016, updated for recent NodeMCU based on SDK 1.5.x, fixed async `socket:send()` issues, cleaned up and started improving.

https://github.com/joysfera/nodemcu-web-ide

### Usage
1. upload&compile the _ide.lua_ to your device using [nodemcu-uploader](https://github.com/kmpm/nodemcu-uploader): ```nodemcu-uploader.py -c ide.lua```
2. use a terminal program (Putty, picocom) to connect to your NodeMCU device via the serial (USB) port
3. set up WiFi connection using `wifi.sta.config({ssid='YourWiFiName',pwd='YourWiFiPassword'})`
4. run the uploaded file with the `dofile("ide.lc")` command
5. launch your web browser and open the IP address of your device
