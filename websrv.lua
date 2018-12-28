--[[

websrv.lua - a stupid-simple web server for the ESP8266 wifi subsystem

creates a server and listens on port 80

assumes a file websrv.html exists in the ESP flash file system. This file contains
the html and any required CSS/style elements for displaying a (very) simple website
on a remote browser. could work in sta or ap mode, envisioned more for ap mode using
a phone as a GUI conected to the 8266's AP for an iot project

the main idea is that the file websrv.html is stored in the flash file system, and thus the 
bulk of html data is kept out of RAM. the send() function reads the html file line-by-line
and uses the asynch style of completion functions to ensure that each line is sent to the server 
in order. If any line has a %d in it, it will be processed specially .. with the nth element
of the encode[] table inserted by doing a string encode. yes this is dirt simple and limited to one
encode per line, etc. It can be extended if needed. Or maybe the rest of the world has a simple
way do to this and I am just an idiot :-) done this way the websrv.lua and websrv.html must be kept
closely in synch regarding the content. concerns are not separated. but the footprint is small!

this advantage of doing it this way is that only one line at a time comes into RAM. the file is 
only opened once, and the file pointer is reset on each interaction. this is intended for VERY 
simple GUIs, e.g. on a phone browser with a few lines of info display and some buttons to control 
an iot device

--]]

function receiver(client,request)

   -- encode[n] is the variable to replace the nth instance of %d which is
   -- assumed to be only once per line
   -- for testing just create two of them that increment
   
   encode[1] = encode[1] + 1
   encode[2] = encode[2] + 5

   -- parse the response using lua patterns. I didn't think of this I stole it...
   
   local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
   print("method, path,vars:", method, path, vars)

   if not method then
      _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
      print("method nil: method, path:", method, path)
   end

   local parsedvar = {}

   if (vars ~= nil)then
      for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
	 parsedvar[k] = v
	 print("k, v:", k, v)
      end
   end

   -- at this point you have the info from the input controls (e.g. buttons) in parsedvar[]
   -- and can take whatever actions you wish based on them...

   -- this is the function that calls itself back to make sure all the lines of html are
   -- sent one at a time and in order
   
   local function send(localSocket)
      ll = ff:readline()
      line = line + 1
      if ll then
	 if string.find(ll, "%%d") then
	    lc = ll
	    ll = string.format(lc, encode[encidx])
	    encidx = encidx+1
	 end
	 localSocket:send(ll)
      else
	 localSocket:close()
      end
   end

   -- arrive here when entire response is about to be sent to server
   -- reset file pointer to html file, line counter and variable indexer
   
   ff:seek("set", 0)
   line = 0
   encidx = 1
   
   client:on("sent", send) -- prime the pump .. create a "catcher" for first line sent 
   send(client)
   
   collectgarbage();
end


srv=net.createServer(net.TCP)

ff = file.open("websrv.html", "r")
print("ff for websrv.html is:", ff)
line = 0

encode={}
encidx = 1
encode[1]=0
encode[2]=0

srv:listen(80,function(conn)
	      conn:on("receive", receiver)	      
end)


--HTTP/1.0 200 OK\r\nServer: NodeMCU on ESP8266\r\nContent-Type: text/html\r\n\r\n'
