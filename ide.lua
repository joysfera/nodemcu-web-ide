--[[
XChip's NodeMCU IDE

Create, Edit and run NodeMCU files using your webbrowser.
Examples:
http://<mcu_ip>/ will list all the files in the MCU
http://<mcu_ip>/newfile.lua    displays the file on your browser
http://<mcu_ip>/newfile.lua?edit  allows to creates or edits the specified script in your browser
http://<mcu_ip>/newfile.lua?run   it will run the specified script and will show the returned value

]]--

srv=net.createServer(net.TCP) 
srv:listen(80,function(conn) 

   local rnrn=0
   local Status = 0
   local DataToGet = 0
   local method=""
   local url=""
   local vars=""

  conn:on("receive",function(conn,payload) 
    
    if Status==0 then
        _, _, method, url, vars = string.find(payload, "([A-Z]+) /([^?]*)%??(.*) HTTP")
        print(method, url, vars)                          
    end
    
    if method=="POST" then
    
        if Status==0 then
            --print("status", Status)
            _,_,DataToGet, payload = string.find(payload, "Content%-Length: (%d+)(.+)")
            if DataToGet~=nil then
                DataToGet = tonumber(DataToGet)
                --print(DataToGet)
                rnrn=1
                Status = 1                
            else
                print("bad length")
            end
        end
        
        -- find /r/n/r/n
        if Status==1 then
            --print("status", Status)
            local payloadlen = string.len(payload)
            local mark = "\r\n\r\n"
            local i
            for i=1, payloadlen do                
                if string.byte(mark, rnrn) == string.byte(payload, i) then
                    rnrn=rnrn+1
                    if rnrn==5 then 
                        payload = string.sub(payload, i+1,payloadlen)
                        file.open(url, "w")
                        file.close() 
                        Status=2
                        break
                    end
                else
                    rnrn=1
                end
            end    
            if Status==1 then 
                return 
            end
        end       
    
        if Status==2 then
            --print("status", Status)
            if payload~=nil then
                DataToGet=DataToGet-string.len(payload)
                --print("DataToGet:", DataToGet, "payload len:", string.len(payload))
                file.open(url, "a+")
                file.write(payload)            
                file.close() 
            else
                conn:send("HTTP/1.1 200 OK\r\n\r\nERROR")
                Status=0
            end

            if DataToGet==0 then                
                conn:send("HTTP/1.1 200 OK\r\n\r\nOK")     
                Status=0
            end            
        end
        
        return
    end    
    
    DataToGet = -1
    
    if url == "favicon.ico" then
        conn:send("HTTP/1.1 404 file not found")
        return
    end    

    conn:send("HTTP/1.1 200 OK\r\n\r\n")
    
    -- it wants a file in particular
    if url~="" and vars=="" then
        DataToGet = 0
        return
    end    

    conn:send("<html><body><h1>NodeMCU IDE</h1>")
    
    if vars=="edit" then
        conn:send("<script>function tag(c){document.getElementsByTagName('w')[0].innerHTML=c};\n")
        conn:send("var x=new XMLHttpRequest()\nx.onreadystatechange=function(){if(x.readyState==4) document.getElementsByName('t')[0].value = x.responseText; };\nx.open('GET',location.pathname,true)\nx.send()</script>")
        conn:send("<a href='/'>Back to file list</a><br><br><textarea name=t cols=79 rows=17></textarea></br>")   
        conn:send("<button onclick=\"tag('Saving');x.open('POST',location.pathname,true);\nx.onreadystatechange=function(){if(x.readyState==4) tag(x.responseText);};\nx.send(new Blob([document.getElementsByName('t')[0].value],{type:'text/plain'}));\">Save</button><a href='?run'>run</a><w></w>")
    end    

    if vars=="run" then        
        conn:send("<verbatim>")                
        local st, result=pcall(dofile, url)
        conn:send(tostring(result))   
        conn:send("</verbatim>")  
    end
  
    if url=="" then
        local l = file.list();
        for k,v in pairs(l) do  
            conn:send("<a href='"..k.."?edit'>"..k.."</a>, size:"..v.."<br>")
        end        
    end
    
    conn:send("</body></html>")
        
  end)
  conn:on("sent",function(conn) 
    if DataToGet>=0 and method=="GET" then
        if file.open(url, "r") then            
            file.seek("set", DataToGet)
            local line=file.read(512)
            file.close()
            if line then
                conn:send(line)
                DataToGet = DataToGet + 512    
            
                if (string.len(line)==512) then
                    return
                end
            end
        end        
    end
    
    conn:close() 
  end)
end)
print("listening, free:", node.heap())
