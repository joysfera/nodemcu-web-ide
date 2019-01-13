# nodemcu-web-ide
Simple Web IDE running on NodeMCU Lua

Originaly written by XChip in February 2015 and published in
http://www.esp8266.com/viewtopic.php?f=19&t=1549

Picked up by Petr Stehlík in October 2016, updated for recent NodeMCU based on SDK 1.5.x, fixed async `socket:send()` issues, cleaned up and started improving.

https://github.com/joysfera/nodemcu-web-ide

### Usage
1. set up WiFi connection using `wifi.sta.config({ssid='YourWiFiName',pwd='YourWiFiPassword')`
2. upload&compile the _ide.lua_ to your device using [nodemcu-uploader](https://github.com/kmpm/nodemcu-uploader): ```nodemcu-uploader.py -c ide.lua```
3. using a terminal program run the uploaded file with the `dofile("ide.lc")` command
4. launch your web browser and open the IP address of your device
