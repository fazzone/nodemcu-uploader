function print_socket(str)
   srv = net.createConnection(net.TCP, 0)
   srv:on("receive", function(sck, c) print("c:",c) end)
   -- Wait for connection before sending.
   srv:on("connection", function(sck, c)
	     --print("in connection, about to send")
	     --print("sck, c:", sck, c)
	     sck:send(str)
	     sck:close()
   end)
   srv:connect(10138, "10.0.0.48")
end

-- usage: print_socket("Hi there!")
-- python(2) listener code below --

--[[
from __future__ import print_function
import socket
import time

host="10.0.0.48"
port=10138
print("host, port:", host, port)

serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
serversocket.bind((host,port))
serversocket.listen(5) 
while True:
	connection, address = serversocket.accept()
	#print("conn, addr:", connection, address)
	buf = connection.recv(64)
	if len(buf) > 0:
		print(buf) 
	connection.close()
--]]

