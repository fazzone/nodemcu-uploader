--'<p>Function 1 <a href=\"?btn=ON1\"><button>ON</button></a>&nbsp;<a href=\"?btn=OFF1\"><button>OFF</button></a></p>'
--   '<p>Function 2 <a href=\"?btn=ON2\"><button>ON</button></a>&nbsp;<a href=\"?btn=OFF2\"><button>OFF</button></a></p>'
--      '<input type="radio" name="fcn1" value="on"> On<br>'
--    '<input type="radio" name="fcn1" value="off" checked> Off<br>' 
--response[#response+1]=
--   
k=0
delta=10

function receiver(client,request)

   local response = {'HTTP/1.0 200 OK\r\nServer: NodeMCU on ESP8266\r\nContent-Type: text/html\r\n\r\n'}
   response[#response+1]=
      "<h1> ESP8266 Web Server</h1>"
   response[#response+1]=   
      '<meta http-equiv="refresh" content="10"/>'
   response[#response+1]=
      '<form action="" method="get"> '
--   response[#response+1]=
--   '<label for="name">Enter your name: </label>'
--   response[#response+1]=   
--      '<input type="text" name="name" id="name">'
   response[#response+1]=
      '<button type="submit" class="btn btn-danger btn-lg" name="One" value="Empty"> Empty</button>'
   response[#response+1]=
      '<button type="submit" class="btn btn-primary btn-lg" name="Two" value="Off"> Off</button>'
   response[#response+1]=
      '<button type="submit" class="btn btn-success btn-lg btn-block" name="Three" value="Fill"> Fill</button>'    response[#response+1]=
      '</form>'
   response[#response+1]=
      string.format('<p> Counter: %d</p>', k)
   response[#response+1]=
   '<label for="fuel">Fuel Level:</label>'
   response[#response+1]=
      string.format('<meter id="fuel" name="fuel" min="0" max="100" value="%d">', k)
   response[#response+1]=
      '</meter>'


   local function send(localSocket)
      if #response > 0 then
	 --print("sending", #response)
	 localSocket:send(table.remove(response,1))
      else
	 print('done sending, closing')
	 localSocket:close()
	 response=nil
      end
   end
   
   print("request:::", request,":::")
   local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
   print("method, path,vars:", method, path, vars)
   if(method == nil)then
      _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
      print("method nil: method, path:", method, path)
   end
   local _GET = {}
   local vv
   if (vars ~= nil)then
      for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
	 _GET[k] = v
	 print("k, v:", k, v)
	 vv = v
      end
   end

   print("vv=", vv)
   
   if vv == "Fill" then delta=10
   elseif vv == "Empty" then delta=-10
   elseif vv == "Off" then delta = 0
   end
   
   
   k=k+delta
   if k > 100 then k = 0 end
   if k < 0 then k = 0 end

   client:on("sent", send)
   send(client)
   
   collectgarbage();
end


srv=net.createServer(net.TCP)

srv:listen(80,function(conn)
	      conn:on("receive", receiver)	      
end)
