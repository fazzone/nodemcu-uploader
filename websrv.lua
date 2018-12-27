line0='HTTP/1.0 200 OK\r\nServer: NodeMCU on ESP8266\r\nContent-Type: text/html\r\n\r\n'
line1='<meta http-equiv="refresh" content="2"/>'
line2="<h1> ESP8266 Web Server</h1>"
line3=
'<p>Function 1 <a href=\"?btn=ON1\"><button>ON</button></a>&nbsp;<a href=\"?btn=OFF1\"><button>OFF</button></a></p>'
line4=
   '<p>Function 2 <a href=\"?btn=ON2\"><button>ON</button></a>&nbsp;<a href=\"?btn=OFF2\"><button>OFF</button></a></p>'
line5='<p> String Disp: %d</p>'
k = 0

lastbtn=""
btnstate={Button1="OFF", Button2="OFF"}


srv=net.createServer(net.TCP)
srv:listen(80,function(conn)
	      
	      conn:on("receive", function(client,request)
			 -- print("request:::", request,":::")
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

			 buf = line0
			 buf = buf..line1
			 buf = buf..line2
			 buf = buf..line3
			 buf = buf..line4
			 buf = buf..string.format(line5, k)
			 k = k + 1
			 
			 print("#buf:", #buf)
			 print("Button1 state", btnstate.Button1)
			 print("Button2 state", btnstate.Button2)			 
			 
			 if(_GET.btn == "ON1" and lastbtn ~= "ON1" )then
			    print("Function 1 ON")
			    btnstate.Button1 = "ON"
			 elseif(_GET.btn == "OFF1" and lastbtn ~= "OFF1")then
			    print("Function 1 OFF")
			    btnstate.Button1 = "OFF"
			 elseif(_GET.btn == "ON2" and lastbtn ~= "ON2")then
			    print("Function 2 ON")
			    btnstate.Button2 = "ON"
			 elseif(_GET.btn == "OFF2" and lastbtn ~= "OFF2")then
			    print("Function 2 OFF")
			    btnstate.Button2 = "OFF"
			    k = 0
			 end

			 lastbtn = _GET.btn
			 
			 client:send(buf, function(c) print("sent complete - closing") c:close() end )
			 collectgarbage();
	      end)
end)
