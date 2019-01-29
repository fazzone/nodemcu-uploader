--[[

espWebServer.lua

a very small footprint HTTP server for use in the nodemcu environment

set up as a lua module so you can do:

eWS = require "espWebServer"

two external function calls:

espWebServer.setAjaxCB() -- call this one with a callback function for each query string
espWebServer.start()     -- call this one to set port and buffer size and start the server

restrictions: 

only implements one route: "/" for index.html and other source(s) and ajax with query strings
only intended for GET requests

oddness: sometimes loads files twice??

--]]

local espWebServer = {}

local fileHeader
fileHeader = {
   http="HTTP/1.1 ",
   type="Content-type: ",
   length="Content-length: ",
   alive="Keep-Alive: Timeout=",
   server="Server: ",
}

local mimeType
mimeType = {
   html = "text/html",
   css  = "text/css",
   js   = "text/javascript",
   ico  = "image/x-icon",
   mp3  = "audio/mpeg",
}

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

local isk=0

function sndFileCB(sock)
   local fp = sockDrawer[sock].filePointer
   local ll = fp:read(bufsize)
   if ll then sock:send(ll) else
      local fn = sockDrawer[sock].fileName
      local ls = sockDrawer[sock].loadStart   
      print("File loaded, time (ms):", fn, (tmr.now()-ls)/1000.)
      print("closing", fp)
      fp:close()
      sock:close()
      sockDrawer[sock] = nil
      isk = isk - 1
      print("isk:", isk)
   end
end

function buildHttpHeader(size, mime)
   local crlf = "\r\n"
   local ch = fileHeader.http.."200 OK"
   local cl = string.format(fileHeader.length.."%d", size)
   local ct = fileHeader.type..mime
   local ck = fileHeader.alive.."15"
   local cs = fileHeader.server.."ESP8266"
   return ch..crlf..ct..crlf..cl..crlf..ck..crlf..cs..crlf..crlf
end


function sendFile(fn, mimetype, sock)
   local fs = file.stat(fn)
   if not fs then return nil end
   local fp = file.open(fn, "r")
   if not fp then return nil end
   print("opening", fp)
   local pp = buildHttpHeader(fs.size, mimetype)
   --print("http header:", pp)
   sockDrawer[sock] = {fileName=fn, filePointer=fp, filePrefix=pp, loadStart=tmr.now()}
   isk = isk + 1
   print("isk:", isk)
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
   --
   --print("client", client)
   --print("path", path)
   --print("vars", vars)
   --print("request",request)
   --print("method", method)
   
   local parsedVariables = {}
   if vars then
      for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
	 parsedVariables[k] = v
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
      return
   end

   --local fileName = string.match(path, "[^/]+$")
   local fileType = string.match(path, "[^.]+$")
   local filePath = string.match(path, "/(.*)")

   if filePath == '' then
      filePath = "index.html"
   end
   
   local mime = mimeType[fileType]

   if not mime then
      mime = "text/html"
      if path ~= '/' then
	 print("No mime type for filetype ", fileType)
      end
   end
   --print("filePath:", filePath)
   --print("mime:", mime)
   
   if file.exists(filePath) then
      sendFile(filePath, mime, client)
      return
   else
      sendStr="HTTP/1.1 204 No Content\r\n\r\n"
      print("No file: "..filePath)
      sendOneString(sendStr, client)
      return      
   end
end

return espWebServer
