gpio.mode(3,gpio.OUTPUT)
gpio.write(3,0)

if file.exists("s.lua") then
   delay=100 -- msec
   print(string.format("Launching main prog <s.lua> in %d milliseconds", delay))
   tmr.alarm(1,delay,0,function() dofile("s.lua") end)
else
   print("no file found: s.lua")
end
   
