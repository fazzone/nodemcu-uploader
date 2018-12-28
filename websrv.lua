function receiver(client,request)

   encode[1] = encode[1] + 1
   encode[2] = encode[2] + 5
   
   local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
   print("method, path,vars:", method, path, vars)

   if(method == nil)then
      _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
      print("method nil: method, path:", method, path)
   end

   local _GET = {}

   if (vars ~= nil)then
      for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
	 _GET[k] = v
	 print("k, v:", k, v)
      end
   end

   local function send(localSocket)
      ll = ff:readline()
      line = line + 1
      if ll then
	 if string.find(ll, "%%d") then
	    --print("enc line", line, ll)
	    lc = ll
	    ll = string.format(lc, encode[encidx])
	    encidx = encidx+1
	    --print("sending", ll)	    
	 end
	 --print("sending", ll)
	 localSocket:send(ll)
      else
	 print('done sending, closing')
	 localSocket:close()
      end
   end

   ff:seek("set", 0)
   line = 0
   encidx = 1
   
   client:on("sent", send)
   send(client)
   
   collectgarbage();
end


srv=net.createServer(net.TCP)

ff = file.open("test.html", "r")
print("ff for test.html is:", ff)
line = 0

encode={}
encidx = 1
encode[1]=0
encode[2]=0

srv:listen(80,function(conn)
	      conn:on("receive", receiver)	      
end)


--HTTP/1.0 200 OK\r\nServer: NodeMCU on ESP8266\r\nContent-Type: text/html\r\n\r\n'
