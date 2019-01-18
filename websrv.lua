--[[


medido pump



--]]

flowDirPin   = 3 --GPIO0
flowMeterPin = 7 --GPIO13
pwmPumpPin   = 8 --GPIOxx

pulseCount=0
flowRate=0
lastPulseCount=0
lastFlowTime=0
pulsePerOz=77.6

minPWM = 50
maxPWM = 1023
lastPWM = 0
pumpPWM = 0

pumpFwd=true

pumpStartTime = 0
pumpStopTime = 0
runningTime = 0

pulseCount = 0
flowCount  = 0

function gpioCB(lev, pul, cnt)
   if pumpFwd then
      pulseCount=pulseCount + cnt
   else
      pulseCount=pulseCount - cnt
   end
   gpio.trig(flowMeterPin, "up")
end

local function setPumpSpeed(ps)
   pumpPWM = math.floor(ps*maxPWM/100)
   if pumpPWM < minPWM then pumpPWM = 0 end
   if pumpPWM > 1023 then pumpPWM = maxPWM end
   pwm.setduty(pwmPumpPin, pumpPWM)
   if lastPWM == 0 and pumpPWM > 0 then -- just turned on .. note startime
      print("pump start")
      pumpStartTime = tmr.now()
   end
   if lastPWM > 0 and pumpPWM == 0 then -- just turned off .. note stop time
      print("pump stop")
      pumpStopTime = tmr.now()
   end
   print("pwm set to:", pumpPWM)
   lastPWM = pumpPWM
end

function setPumpFwd()
   gpio.write(flowDirPin, gpio.LOW)
   pumpFwd=true
   print("Fwd")
end

function setPumpRev()
   gpio.write(flowDirPin, gpio.HIGH)
   pumpFwd=false
   print("Rev")
end

function timerCB()
   local now = tmr.now()
   local deltaT = math.abs(math.abs(now) - math.abs(lastFlowTime)) / (1000000. * 60.) -- mins
   lastFlowTime = now
   flowCount = pulseCount / pulsePerOz
   local deltaF = (pulseCount - lastPulseCount) / pulsePerOz
   lastPulseCount = pulseCount
   flowRate = flowRate - (flowRate - (deltaF / deltaT))/4
   if pumpPWM > 0 then
      runningTime = math.abs(math.abs(tmr.now()) - math.abs(pumpStartTime)) / 1000000. -- secs
   else
      runningTime = math.abs(math.abs(pumpStopTime) - math.abs(pumpStartTime)) / 1000000.
   end
   tmr.start(pumpTimer)
end

pwm.setup (pwmPumpPin,   1000, 0)         

gpio.mode (flowDirPin,   gpio.OUTPUT)
gpio.write(flowDirPin,   gpio.LOW)

gpio.mode (flowMeterPin, gpio.INT)
gpio.trig (flowMeterPin, "up", gpioCB)

pumpTimer=tmr.create()
tmr.register(pumpTimer, 200, tmr.ALARM_SEMI, timerCB)
tmr.start(pumpTimer)


----------------------------------------------------------------------------------------------------

local sendStr
local fileStr
local sendFile = false
local activeSend = false
local ff
local lastSpeed = 0

local function sendCB(localSocket)
   if sendStr then -- string was sent, this is the callback
      sendStr = nil
      if not sendFile then
	 localSocket:close()
	 localSocket:on("sent", nil)
	 activeSend = false
	 --print("string sent:", sendStr)
      end
   end
   if sendFile then
      local ll = ff:readline()
      if ll then
	 localSocket:send(ll)
	 --print(ll)
      else
	 --print("ll null -- EOF")
	 localSocket:close()
	 localSocket:on("sent", nil)
	 sendFile=false
	 activeSend=false
	 --print("html file sent")
      end	 
   end
end

local function send(localSocket)
   if activeSend then
      print("?Already sending?")
   end
   localSocket:on("sent", sendCB)
   activeSend = true
   if sendStr then
      localSocket:send(sendStr)
   elseif sendFile then
      --print("in sendFile")
      ff:seek("set", 0)
      --print("sending:", fileStr)
      localSocket:send(fileStr)
   end
end

function receiver(client,request)
      
   --parse the response using lua patterns. I didn't think of this I stole it...
   --print("************************")
   --print("receiver: request:", request)
   
   local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
   --print("method, path,vars:", method, path, vars)

   if not method then
      _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
      --print("method nil: method, path:", method, path)
   end

   local parsedvar = {}

   if (vars ~= nil)then
      for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
	 parsedvar[k] = v
	 --print("k, v:", k, v)
      end
   end

   if path == "/" and not vars then
      print("sending html")
      sendFile = true
      send(client)
   elseif path == "/favicon.ico" then
      sendStr="HTTP/1.1 204 No Content"
      send(client)
   elseif path=="/" and vars then
   
      for k,v in pairs(parsedvar) do
	 --print("parsedvar loop: k,v=", k,v)
	 if k =="pumpSpeed" then
	    --print("pumpSpeed=", v)
	    ps = tonumber(v)
	    if ps ~= lastSpeed then
	       setPumpSpeed(ps)
	       lastSpeed = ps
	    end
	 elseif k == "pressB" then
	    --print("Button:", parsedvar[k])
	    pb = tonumber(v)
	    if pb == 1 then
	       setPumpFwd()
	    elseif pb == 2 then
	       setPumpSpeed(0)
	       lastSpeed = ps
	    elseif pb == 3 then
	       setPumpRev()
	    end
	 end
      end

      -- package up responses here
      
      s0=node.heap()
      s1=flowCount
      s2=flowRate
      s3=runningTime

      
      suffix=
	 string.format("%f,%f,%f,%f", s0,s1,s2,s3)
      prefix=
	 string.format("HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: %d\r\n\r\n", #suffix)
      sendStr=prefix..suffix
      send(client)
   end
   
   
end

srv=net.createServer(net.TCP)
   
ff = file.open("websrv.html", "r")

local contentLength=0
while true do
   local line = ff:readline()
   if not line then break end
   contentLength = contentLength + #line
end


fileStr=string.format(
	 "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: %d\r\n\r\n\r\n",
	 contentLength)

print("Starting receiver on port 80")

srv:listen(80,function(conn) conn:on("receive", receiver) end)


-------------------------------------------------------------------------------------------------
