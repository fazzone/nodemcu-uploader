--[[

medido pump

--]]

server = require "espWebServer"

local flowDirPin   = 3 --GPIO0
local flowMeterPin = 7 --GPIO13
local pwmPumpPin   = 8 --GPIOxx

local pulseCount=0
local flowRate=0
local lastPulseCount=0
local lastFlowTime=0
local pulsePerOz=77.6
local pressZero
local pressScale=3.75
local pressPSI
local adcDiv=5.7 -- resistive divider in front of adc   
local minPWM = 50
local maxPWM = 1023
local lastPWM = 0
local pumpPWM = 0

local pumpFwd=true

local pumpStartTime = 0
local pumpStopTime = 0
local runningTime = 0

local pulseCount = 0
local flowCount  = 0

local gotCalFact = false

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
   pressPSI = ((adcDiv*adc.read(0)/1023)-pressZero) * (pressScale)
   tmr.start(pumpTimer)
end

saveTable={}

function xhrCB(varTable)
   for k,v in pairs(varTable) do
      if saveTable[k] ~= v then   -- if there was a change
	 saveTable[k] = v
	 local kk
	 if (not gotCalFact) and (k ~= "cF" and tonumber(v) ~= 0) then
	    print("Attempt to command before calFact - rejected:", k, v)
	    kk = nil
	 else
	    kk = k
	 end
	 if kk == "pS" then -- what change was it?
	    setPumpSpeed(tonumber(v))
	 elseif kk == "pB" then
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
	 elseif kk == "pC" and tonumber(v) == 1 then
	    print("Clear")
	    pulseCount = 0
	    lastPulseCount=0
	    --flowRate=0
	    pumpStartTime=0
	    pumpStopTime=0
	 elseif kk == "cF" then
	    print("calFact passed in:", tonumber(v))
	    pulsePerOz = tonumber(v)/100
	    gotCalFact = true
	 end
      end
   end
   local ippo = math.floor(pulsePerOz * 100 + 0.5)
   return string.format("%f,%f,%f,%f,%f,%f",
			node.heap(),flowCount,flowRate,runningTime,ippo,pressPSI)
end

local ip=wifi.sta.getip()
local bs=512
server.setAjaxCB(xhrCB)
server.start(80, bs)
print("Starting web server on port 80, buffer size:", bs)
print("IP Address: ", ip)

setPumpSpeed(0)
setPumpFwd()
pwm.setup (pwmPumpPin,   1000, 0)

pressZero = adcDiv * adc.read(0) / 1023

for i=1,50,1 do
   pressZero = pressZero - (pressZero - adcDiv * adc.read(0) / 1023)/10
   print(pressZero)
end

print("pressZero:", pressZero)

gpio.mode (flowDirPin,   gpio.OUTPUT)
gpio.write(flowDirPin,   gpio.LOW)

gpio.mode (flowMeterPin, gpio.INT)
gpio.trig (flowMeterPin, "up", gpioCB)

pumpTimer=tmr.create()
tmr.register(pumpTimer, 200, tmr.ALARM_SEMI, timerCB)
tmr.start(pumpTimer)
