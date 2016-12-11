--[[
XChip's NodeMCU IDE
Original Source: http://www.esp8266.com/viewtopic.php?f=19&t=1549

Petr Stehlik found the source in October 2016 and gave it a new home
at https://github.com/joysfera/nodemcu-web-ide under the GPL license.
Then updated it for new async socket send(), fixed, cleaned up,
added external editor with syntax highlighting and further improves it.

Create, Edit and run NodeMCU files using your web browser.
Examples:
http://<mcu_ip>/ will list all the files in the MCU
http://<mcu_ip>/newfile.lua    displays the file on your browser
http://<mcu_ip>/newfile.lua?edit  allows to creates or edits the specified script in your browser
http://<mcu_ip>/newfile.lua?run   it will run the specified script and will show the returned value
--]]

local AceEnabled = true -- feel free to enable or disable the shiny Ajax.org Cloud Editor

srv = net.createServer(net.TCP)
srv:listen(80, function(conn)

  local rnrn = 0
  local Status = 0
  local DataToGet = 0
  local method = ""
  local url = ""
  local vars = ""

  conn:on("receive", function(sck, payload)
    
    if Status == 0 then
        _, _, method, url, vars = string.find(payload, "([A-Z]+) /([^?]*)%??(.*) HTTP")
        -- print("Method, URL, vars: ", method, url, vars)
    end
    
    if method == "POST" then
    
        if Status == 0 then
            -- print("status", Status)
            _, _, DataToGet, payload = string.find(payload, "Content%-Length: (%d+)(.+)")
            if DataToGet then
                DataToGet = tonumber(DataToGet)
                -- print("DataToGet = "..DataToGet)
                rnrn = 1
                Status = 1                
            else
                print("bad length")
            end
        end
        
        -- find /r/n/r/n
        if Status == 1 then
            -- print("status", Status)
            local payloadlen = string.len(payload)
            local mark = "\r\n\r\n"
            local i
            for i=1, payloadlen do                
                if string.byte(mark, rnrn) == string.byte(payload, i) then
                    rnrn = rnrn + 1
                    if rnrn == 5 then
                        payload = string.sub(payload, i+1, payloadlen)
                        file.open(url, "w")
                        file.close() 
                        Status = 2
                        break
                    end
                else
                    rnrn = 1
                end
            end    
            if Status == 1 then
                return 
            end
        end       
    
        if Status == 2 then
            -- print("status", Status)
            if payload then
                DataToGet = DataToGet - string.len(payload)
                --print("DataToGet:", DataToGet, "payload len:", string.len(payload))
                file.open(url, "a+")
                file.write(payload)            
                file.close() 
            else
                sck:send("HTTP/1.1 200 OK\r\n\r\nERROR")
                Status = 0
            end

            if DataToGet == 0 then
                sck:send("HTTP/1.1 200 OK\r\n\r\nOK")
                Status = 0
            end
        end
        
        return
    end
    -- end of POST method handling
    
    DataToGet = -1
    
    if url == "favicon.ico" then
        -- print("favicon.ico handler sends 404")
        sck:send("HTTP/1.1 404 file not found")
        return
    end    

    local sen = "HTTP/1.1 200 OK\r\n\r\n"
    
    -- it wants a file in particular
    if url ~= "" and vars == "" then
        DataToGet = 0
        sck:send(sen)
        return
    end

    sen = sen .. "<html><body><h1><a href='/'>NodeMCU IDE</a></h1>"
    
    if vars == "edit" then
        if AceEnabled then
            local mode = 'ace/mode/'
            if url:match(".css") then mode = mode .. 'css'
            elseif url:match(".html") then mode = mode .. 'html'
            elseif url:match(".json") then mode = mode .. 'json'
            elseif url:match(".js") then mode = mode .. 'javascript'
            else mode = mode .. 'lua'
            end
            sen = sen .. "<style type='text/css'>#editor{width: 100%; height: 80%}</style><div id='editor'></div><script src='//rawgit.com/ajaxorg/ace-builds/master/src-min-noconflict/ace.js'></script>"
                .. "<script>var e=ace.edit('editor');e.setTheme('ace/theme/monokai');e.getSession().setMode('"..mode.."');function getSource(){return e.getValue();};function setSource(s){e.setValue(s);}</script>"
        else
            sen = sen .. "<textarea name=t cols=79 rows=17></textarea></br>"
                .. "<script>function getSource() {return document.getElementsByName('t')[0].value;};function setSource(s) {document.getElementsByName('t')[0].value = s;};</script>"
        end
        sen = sen .. "<script>function tag(c){document.getElementsByTagName('w')[0].innerHTML=c};var x=new XMLHttpRequest();x.onreadystatechange=function(){if(x.readyState==4) setSource(x.responseText);};x.open('GET',location.pathname);x.send()</script>"
            .. "<button onclick=\"tag('Saving');x.open('POST',location.pathname);x.onreadystatechange=function(){if(x.readyState==4) tag(x.responseText);};x.send(new Blob([getSource()],{type:'text/plain'}));\">Save</button> <a href='?run'>run</a> <w></w>"

    elseif vars == "run" then
        sen = sen .. "<verbatim>"

        function s_output(str) sen = sen .. str end
        node.output(s_output, 0) -- re-direct output to function s_output.

        local st, result = pcall(dofile, url)

        -- delay the output capture by 1000 milliseconds to give some time to the user routine in pcall()
        tmr.alarm(0, 1000, tmr.ALARM_SINGLE, function() 
            node.output(nil)
            if result then sen = sen .. "<br>Result of the run: " .. tostring(result) .. "<br>" end
            sen = sen .. "</verbatim></body></html>"
            sck:send(sen)
        end)

        return

    elseif vars == "delete" then
        file.remove(url)
        url = ""

    elseif vars == "restart" then
        node.restart()

    end

    local message = {}
    message[#message + 1] = sen
    sen = nil
    if url == "" then
        local l = file.list();
        for k,v in pairs(l) do  
            message[#message + 1] = "<a href='" ..k.. "?edit'>" ..k.. "</a>, size: " ..v.. " <a href='" ..k.. "?delete'>delete</a><br>"
        end
        message[#message + 1] = "<a href='#' onclick='v=prompt(\"Filename\");if (v!=null) { this.href=\"/\"+v+\"?edit\"; return true;} else return false;'>Create new</a> &nbsp; &nbsp; <a href='#' onclick='var x=new XMLHttpRequest();x.open(\"GET\",\"/?restart\");x.send();setTimeout(function(){location.href=\"/\"},5000);document.write(\"Please wait\");return false'>Restart</a>"
    end
    message[#message + 1] = "</body></html>"

    local function send_table(sk)
        if #message > 0 then
            sk:send(table.remove(message, 1))
        else
            sk:close()
            message = nil
        end
    end
    sck:on("sent", send_table)
    send_table(sck)
  end)

  conn:on("sent", function(sck)
    if DataToGet >= 0 and method == "GET" then
        if file.open(url, "r") then
            file.seek("set", DataToGet)
        local chunkSize = 512
            local line = file.read(chunkSize)
            file.close()
            if line then
                sck:send(line)
                DataToGet = DataToGet + chunkSize
                if string.len(line) == chunkSize then return end
            end
        end        
    end

    sck:close()
    sck = nil
  end)
end)

print("listening at " .. wifi.sta.getip() .. ", free: " .. node.heap())
