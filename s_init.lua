gpio.mode(3,gpio.OUTPUT)

-- create a clean reset signal for the SSD1306 display for 200 usec then
-- leave gpio 3 low. reset signal is gpio3 thru inverter...

print("init for SSD1306 OLED")
gpio.write(3,0)
gpio.write(3,1)
tmr.delay(200)
gpio.write(3,0)

if file.exists("s.lc") then
   delay=100 -- msec
   print(string.format("Launching main prog <s.lc> in %d milliseconds", delay))
   tmr.alarm(1,delay,0,function() dofile("s.lc") end)
else
   print("no file found: s.lc")
end
   
