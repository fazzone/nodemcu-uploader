--[[

espWebServer.lua

a very small (~100 LOC!) footprint HTTP server for use in the nodemcu environment

set up as a lua module so you can do:

eWS = require "espWebServer"

two external function calls:

espWebServer.setAjaxCB() -- call this one with a callback function for each query string
espWebServer.start()     -- call this one to set port and buffer size and start the server

--]]

local espWebServer = {}

local fileHeader
fileHeader =
[[
HTTP/1.1 200 OK
Content-Type: text/html
Content-Length: %d
Connection: keep-alive
Keep-Alive: timeout=15
Accept-Ranges: bytes
Server: ESP8266

]]

local stringHeader
stringHeader =
[[
HTTP/1.1 200 OK
Content-Type: text/plain
Content-Length: %d

]]

local cbFunction
local bufsize
local sockDrawer={}

function espWebServer.setAjaxCB(functionName)
   -- callback function. called with argument = parsed variable (lua) table from GET's query string
   -- user should return the string that will be the content payload of the HTTP GET request
   cbFunction = functionName
   return
end

function espWebServer.start(port, bs)
   local srv=net.createServer(net.TCP)
   bufsize = bs
   srv:listen(port,function(conn) conn:on("receive", receiver) end)
   return srv
end

function sndStrCB(sock)
   sock:on("sent", nil)
   sock:close()
end

function sndFileCB(sock)
   local fp = sockDrawer[sock].filePointer
   local fn = sockDrawer[sock].fileName
   local ls = sockDrawer[sock].loadStart   
   --local ll = fp:readline()
   local ll = fp:read(bufsize)
   if ll then sock:send(ll) else
      print("File loaded, time (ms):", fn, (tmr.now()-ls)/1000.)
      fp:close()
      sock:close()
      sockDrawer[sock] = nil
   end
end

function sendFile(fn, prefix, sock)
   local fs = file.stat(fn)
   if not fs then return nil end
   local fp = file.open(fn, "r")
   if not fp then return nil end
   local pp = string.format(prefix, fs.size)
   sockDrawer[sock] = {fileName=fn, filePointer=fp, filePrefix=pp, loadStart=tmr.now()}
   sock:on("sent", sndFileCB)
   sock:send(sockDrawer[sock].filePrefix)
   return true
end

function sendOneString(str, sock)
   sock:on("sent", sndStrCB)
   sock:send(str)
end

function receiver(client,request)
   local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
   if not method then
      _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
   end
   local parsedVariables = {}
   if vars then
      for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
	 parsedVariables[k] = v
      end
   end
   if (string.find(path, "/") == 1)  and not vars then
      local filename=string.match(path, "/(.*)")
      if #filename == 0 or filename == '' then
	 filename = "index.html"
      end
      if file.exists(filename) then
	 sendFile(filename, fileHeader, client)
	 return
      else
	 sendStr="HTTP/1.1 204 No Content\r\n"
	 print("No file: "..filename)
	 sendOneString(sendStr, client)
	 return
      end
   end
   if path=="/" and vars then
      local suffix
      if cbFunction then
	 suffix = cbFunction(parsedVariables)
      end
      prefix = string.format(stringHeader, #suffix)
      sendStr = prefix..suffix
      sendOneString(sendStr, client)
   end
end
return espWebServer
