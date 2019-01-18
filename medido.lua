function startUp()
   dispTimer=tmr.create()
   tmr.register(dispTimer, 10, tmr.ALARM_SEMI, timerCB)
   tmr.start(dispTimer)
end

dw=128
dh=64


function cdisp(font, text, x, y)
   local ww, xd
   --disp:setFont(font)
   ww=0--disp:getStrWidth(text)
   if x == 0 then xd = dw/2 - ww/2 else xd = x end
   --disp:drawStr(xd, y, text)
end

function init_i2c_display()

   local rst  =0 -- GPIO16
   local sda = 5 -- GPIO14
   local scl = 6 -- GPIO12
   local sla = 0x3c
   
   gpio.mode(rst, gpio.OUTPUT)    -- do clean reset of disp driver
   gpio.write(rst, 1)
   gpio.write(rst, 0)
   tmr.delay(200)
   gpio.write(rst, 1)
   
   --i2c.setup(0, sda, scl, i2c.SLOW)
   --disp = u8g2.ssd1306_i2c_128x64_noname(0, sla)
   
   --disp:setFontRefHeightExtendedText()
   --disp:setDrawColor(1)
   --disp:setFontPosTop()
   --disp:setFontDirection(0)
end

function pumpGoFwd()
   gpio.write(flowDirPin, gpio.LOW)
   pumpFwd=true
   --print("fwd")
end

function pumpGoRev()
   gpio.write(flowDirPin, gpio.HIGH)
   pumpFwd=false
   --print("rev")
end

pwmPumpPin = 8
flowDirPin =   3 --GPIO0
minPWM = 50
lastPWM = 0
pumpStartTime = 0
pumpStopTime = 0
pump_pwm = 0

function rotaryCB(type, pos, time)
   deltaT=math.abs(math.abs(time)-math.abs(lastTime))/1000000
   mins=time/(60*1000000)
   --print(string.format("type:%2d pos:%4d time:%12d deltaT:%3.3f mins:%3.2f", type, pos, time, deltaT, mins))
   if type == rotary.TURN then
      rotaryPos=pos
      local mult = 0.25
      local deltaR = math.abs(rotaryPos - lastPos)
      mult = mult * math.max(math.min(deltaR, 6), 1)
      pumpSpeed = pumpSpeed + mult*(rotaryPos - lastPos)
      if pumpSpeed < -100 then
	 pumpSpeed = -100
      end
      if pumpSpeed > 100  then
	 pumpSpeed = 100
      end
      if pumpSpeed >= 0 then
	 pumpGoFwd()
      else
	 pumpGoRev()
      end
      lastPos = pos
   end

   if type == rotary.DBLCLICK then
      saveCount = pulseCount 
   end

   if type == rotary.LONGPRESS then
      pulseCount = 0
      lastPulseCount=0
      flowRate=0
      pumpStartTime=0
      pumpStopTime=0
   end

   if type == rotary.PRESS then
      pumpSpeed = 0
   end
   pump_pwm = math.floor(math.abs(pumpSpeed*1023/100))
   if pump_pwm < minPWM then pump_pwm = 0 end
   --print("pwm:", pump_pwm)
   pwm.setduty(pwmPumpPin, pump_pwm)

   if lastPWM == 0 and pump_pwm > 0 then -- just turned on .. note start time
      pumpStartTime = tmr.time()
   end
   if lastPWM > 0 and pump_pwm == 0 then -- just turned off .. note stop time
      pumpStopTime = tmr.time()
   end
   
      
   lastTime = time
   lastPWM = pump_pwm
end

flowMeterPin = 7 --GPIO13

function gpioCB(lev, pul, cnt)
   if pumpFwd then
      pulseCount=pulseCount + cnt
   else
      pulseCount=pulseCount - cnt
   end
   
   gpio.trig(flowMeterPin, "up")
end

function timerCB()
   --print("timerCB")
   local now = tmr.now()
   local deltaT = math.abs(math.abs(now) - math.abs(lastFlowTime)) / (1000000. * 60.) -- mins
   lastFlowTime = now
   local deltaF = (pulseCount - lastPulseCount) / pulsePerOz
   lastPulseCount = pulseCount
   flowRate = flowRate - (flowRate - (deltaF / deltaT))/4
   --if flowRate < 0 then flowRate = 0 end -- handle correctly in rotary button callback
   local io=2
   --disp:clearBuffer()

   if pump_pwm > 0 then
      runningTime = math.abs(math.abs(tmr.time()) - math.abs(pumpStartTime))
   else
      runningTime = math.abs(math.abs(pumpStopTime) - math.abs(pumpStartTime))
   end
   local rt = math.min(runningTime)
   --cdisp(u8g2.font_profont17_mr, string.format("Vol %.1f oz",   pulseCount/pulsePerOz), 1,  0+io)
   if runningTime <= 59 then
      --cdisp(u8g2.font_profont17_mr, string.format("Tim %2d sec",  math.floor(rt)), 1, 15+io)
   else
      local min = math.floor(rt/60)
      local sec = math.floor(rt-60*min)
      --cdisp(u8g2.font_profont17_mr, string.format("Tim %2d:%02d min",  min, sec), 1, 15+io)
   end

   tickTock = tmr.time()
   if tickTock%6 < 3 and pump_pwm > minPWM then
      --cdisp(u8g2.font_profont17_mr, string.format("Flw %.1f oz/m", flowRate), 1, 30+io)
   else
      --cdisp(u8g2.font_profont17_mr, string.format("P   %.1f psi", 1.2),       1, 30+io)
   end
   
   --cdisp(u8g2.font_6x10_tf, "Empty", 20, 53)
   --cdisp(u8g2.font_6x10_tf, "Fill",  85, 53)

   --disp:drawFrame(1, 52, 127, 12)
   --local j = math.floor(63*minPWM/1023)
   ----disp:drawFrame(64-j, 52, 2*j, 12)
   local k = math.floor( (pumpSpeed/100)*63)
   if pumpSpeed >= 0 then
      --disp:drawBox(64, 52, k, 12)
   else
      --disp:drawBox(64+k, 52, -k, 12)      
   end
   --disp:drawVLine(64,52,12)
   --disp:sendBuffer()
   tmr.start(dispTimer)
end



lastTime=0
rotaryPos=0

lastPos=0
pulseCount=0
lastPulseCount=0
flowTime=0
lastFlowTime=0
saveCount=0
pulsePerOz=77.6
pumpSpeed = 0
flowRate=0
pumpFwd=true

--rotary.setup(0,2,1,4, 1000, 500) -- GPIO4,GPIO5,GPIO2

--rotary.on(0, rotary.ALL, rotaryCB)

pwm.setup(pwmPumpPin, 1000, 0) -- GPIO15, 1Khz, 0% duty cycle

gpio.mode(flowDirPin, gpio.OUTPUT)
gpio.write(flowDirPin, gpio.LOW)

gpio.mode(flowMeterPin, gpio.INT)

pulseCount=0

gpio.trig(flowMeterPin, "up", gpioCB)

--init_i2c_display() -- uses (5,6) GPIO14,GPIO12 

--disp:clearBuffer()

io=2
--cdisp(u8g2.font_profont22_mr, "MedidoPump", 0, 0+io)
--cdisp(u8g2.font_profont17_mr, "Version 1.0", 0, 25+io)
--disp:sendBuffer()

splashTimer=tmr.create()
tmr.register(splashTimer, 4000, tmr.ALARM_SINGLE, startUp)
tmr.start(splashTimer)
