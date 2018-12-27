line1="<h1> ESP8266 Web Server</h1>"
line2=
'<p>Function 1 <a href=\"?btn=ON1\"><button>ON</button></a>&nbsp;<a href=\"?btn=OFF1\"><button>OFF</button></a></p>'
line3=
'<p>Function 2 <a href=\"?btn=ON2\"><button>ON</button></a>&nbsp;<a href=\"?btn=OFF2\"><button>OFF</button></a></p>'

srv=net.createServer(net.TCP)
srv:listen(80,function(conn)
	      
	      conn:on("receive", function(client,request)
			 -- print("request:::", request,":::")
			 local buf = "";
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

			 buf = buf..line1
			 buf = buf..line2
			 buf = buf..line3

			 if(_GET.btn == "ON1")then
			    print("Function 1 ON")
			 elseif(_GET.btn == "OFF1")then
			    print("Function 1 OFF")
			 elseif(_GET.btn == "ON2")then
			    print("Function 2 ON")
			 elseif(_GET.btn == "OFF2")then
			    print("Function 2 OFF")
			 end
			 client:send(buf, function(c) print("sent complete - closing") c:close() end )
			 collectgarbage();
	      end)
end)
