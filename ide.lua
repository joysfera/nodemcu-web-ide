--[[
XChip's NodeMCU IDE
Original Source: http://www.esp8266.com/viewtopic.php?f=19&t=1549

Updated for new async socket send(), fixed, cleaned up
and improved by Petr Stehlik

Create, Edit and run NodeMCU files using your webbrowser.
Examples:
http://<mcu_ip>/ will list all the files in the MCU
http://<mcu_ip>/newfile.lua    displays the file on your browser
http://<mcu_ip>/newfile.lua?edit  allows to creates or edits the specified script in your browser
http://<mcu_ip>/newfile.lua?run   it will run the specified script and will show the returned value
--]]

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
        sen = sen .. "<script>function tag(c){document.getElementsByTagName('w')[0].innerHTML=c};\n"
                  .. "var x=new XMLHttpRequest()\nx.onreadystatechange=function(){if(x.readyState==4) document.getElementsByName('t')[0].value = x.responseText; };\nx.open('GET',location.pathname)\nx.send()</script>"
                  .. "<textarea name=t cols=79 rows=17></textarea></br>"
                  .. "<button onclick=\"tag('Saving');x.open('POST',location.pathname);\nx.onreadystatechange=function(){if(x.readyState==4) tag(x.responseText);};\nx.send(new Blob([document.getElementsByName('t')[0].value],{type:'text/plain'}));\">Save</button> <a href='?run'>run</a> <w></w>"

    elseif vars == "run" then
        sen = sen .. "<verbatim>"

        function s_output(str) sen = sen .. str end
        node.output(s_output, 0) -- re-direct output to function s_output.

        local st, result = pcall(dofile, url)

        node.output(nil)

        if result then sen = sen .. "<br>Result of the run: " .. tostring(result) end
        sen = sen .. "</verbatim>"

    elseif vars == "delete" then
        file.remove(url)
        url = ""

    elseif vars == "restart" then
        node.restart()

    end

    if url == "" then
        local l = file.list();
        for k,v in pairs(l) do  
            sen = sen .. "<a href='" ..k.. "?edit'>" ..k.. "</a>, size: " ..v.. " <a href='" ..k.. "?delete'>delete</a><br>"
        end
        sen = sen .. "<a href='#' onclick='v=prompt(\"Filename\");if (v!=null) { this.href=\"/\"+v+\"?edit\"; return true;} else return false;'>Create new</a> &nbsp; &nbsp; <a href='#' onclick='var x=new XMLHttpRequest();x.open(\"GET\",\"/?restart\");x.send();setTimeout(function(){location.href=\"/\"},5000);document.write(\"Please wait\");return false'>Restart</a>"
    end

    sck:send(sen .. "</body></html>")

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
