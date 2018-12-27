chk = " checked> "
nochk=" > "
onstr="On"
offstr="Off"
chkon=false

line0='HTTP/1.0 200 OK\r\nServer: NodeMCU on ESP8266\r\nContent-Type: text/html\r\n\r\n'
line1='<meta http-equiv="refresh" content="10"/>'
line2="<h1> ESP8266 Web Server</h1>"
line3='<form action="#" method="get">'
li4='<input type="radio" name="fcn1" value="on"'
li5='<input type="radio" name="fcn1" value="off"' -- checked> Off<br>'
line6='</form>'
--'<p>Function 1 <a href=\"?btn=ON1\"><button>ON</button></a>&nbsp;<a href=\"?btn=OFF1\"><button>OFF</button></a></p>'
--   '<p>Function 2 <a href=\"?btn=ON2\"><button>ON</button></a>&nbsp;<a href=\"?btn=OFF2\"><button>OFF</button></a></p>'
line7='<p> String Disp: %d</p>'
k = 0

srv=net.createServer(net.TCP)
srv:listen(80,function(conn)
	      
	      conn:on("receive", function(client,request)
			 print("request:::", request,":::")
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
			 
			 if(_GET.fcn1 == "on")then
			    chkon = true
			    print("it's on!")
			 elseif(_GET.fcn1 == "off")then
			    chkon = false
			    print("it's off!")
			 end
			 
			 if chkon then
			    line4=li4..chk..onstr.."<br>"
			    line5=li5..nochk..offstr.."<br>"
			 else
			    line4=li4..nochk..onstr.."<br>"
			    line5=li5..chk..offstr.."<br>"
			 end
			 print("line4:", line4)
			 print("line5:", line5)
			 
			 buf = line0
			 buf = buf..line1
			 buf = buf..line2
			 buf = buf..line3
			 buf = buf..line4
			 buf = buf..line5
			 buf = buf..line6			 
			 buf = buf..string.format(line7, k)
			 k = k + 1
			 
			 print("#buf:", #buf)

			 
			 client:send(buf, function(c) print("sent complete - closing") c:close() end )
			 collectgarbage();
	      end)
end)
