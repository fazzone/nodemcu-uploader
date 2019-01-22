--[[

medido pump

--]]

server = require "espWebServer"

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
   print("PWM set to:", pumpPWM)
   lastPWM = pumpPWM
end

local function setPumpFwd()
   gpio.write(flowDirPin, gpio.LOW)
   pumpFwd=true
   print("Fwd")
end

local function setPumpRev()
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

saveTable={}

function xhrCB(varTable)
   for k,v in pairs(varTable) do
      if saveTable[k] ~= v then   -- if there was a change
	 saveTable[k] = v
	 if k == "pumpSpeed" then -- what change was it?
	    setPumpSpeed(tonumber(v))
	 end
	 if k == "pressB" then
	    idx = tonumber(v)
	    if idx == 0     then -- "Idle" (no command)
	       --
	    elseif idx == 1 then -- "Fill"
	       setPumpFwd()
	    elseif idx == 2 then -- "Off"
	       setPumpSpeed(0)
	    elseif idx == 3 then -- "Empty"
	       setPumpRev()
	    else
	       print("idx error:", idx)
	    end
	 elseif k == "pressC" and tonumber(v) == 1 then
	    print("Clear")
	    pulseCount = 0
	    lastPulseCount=0
	    --flowRate=0
	    pumpStartTime=0
	    pumpStopTime=0
	 end
	 
      end
   end
   return string.format("%f,%f,%f,%f", node.heap(),flowCount,flowRate,runningTime)
end

local bs=512
server.setAjaxCB(xhrCB)
server.start(80, bs)
print("Starting web server on port 80, buffer size:", bs)


pwm.setup (pwmPumpPin,   1000, 0)         

gpio.mode (flowDirPin,   gpio.OUTPUT)
gpio.write(flowDirPin,   gpio.LOW)

gpio.mode (flowMeterPin, gpio.INT)
gpio.trig (flowMeterPin, "up", gpioCB)

pumpTimer=tmr.create()
tmr.register(pumpTimer, 200, tmr.ALARM_SEMI, timerCB)
tmr.start(pumpTimer)
