function swiendsleep()
   --print("in swiendsleep")
   dispSleepTimer:start()   
end

function swiendread()
   --print("in swiendread")
   readtimer:start()
end

function swiendrst() -- only call on startup
   --print("in swiendrst")
   switec.reset(0)
   swiendread()
end

function dispSleep()
   disp:clearBuffer()
   disp:sendBuffer()
   disp:setPowerSave(1)
   lock = false
   lockwt = 0
   iwt = 1
   jwt = 1
   wtboxcar={}
   lastread = 0
   noreadings = true

end

function u8g2_prepare()
  disp:setFontRefHeightExtendedText()
  disp:setDrawColor(1)
  disp:setFontPosBottom()
  disp:setFontDirection(0)
end

function init_i2c_display()
    -- SDA and SCL can be assigned freely to available GPIOs
    local sda = 2 -- now GPIO4 was: GPIO14
    local scl = 1 -- now GPIO5 was: GPIO12
    local sla = 0x3c
    --print("init .. before i2c setup")
    ii = i2c.setup(0, sda, scl, i2c.SLOW)
    print("i2c setup returns:", ii)
    disp = u8g2.ssd1306_i2c_128x64_noname(0, sla)
    print("init .. after u8g2 call, disp:", disp)
end

calib = 11010.8
zero = -17800
seq = {u8g2.DRAW_UPPER_RIGHT, u8g2.DRAW_LOWER_RIGHT, u8g2.DRAW_LOWER_LEFT,u8g2.DRAW_UPPER_LEFT}
iseq = 1
wtboxcar={}
iwt = 1
jwt = 1
wtboxlen=7
lock = false
lockwt = 0
lastread = 0
noreadings = true
tgtweight = 270

function read()
   local wt = (hx711.read(0) - zero)/calib
   tmr.delay(100)
   --print("in read, wt:", wt)

--   if wt < 10 then
--      lastread = wt
--      swiendread()
--      return
--   end

   if wt > 10 then
      print("wt, lastread, iwt", wt, lastread,iwt)
   end

   if math.abs(wt-lastread) > 1 then   
      lastread = wt
      print("wt>lastread")
      if not lock then
	 dispSleepTimer:stop()
	 disp:setPowerSave(0)
	 disp:clearBuffer()
	 disp:setFont(u8g2.font_inb24_mr)
	 local ww = disp:getStrWidth(text)
	 local hh = 30
	 ww = disp:getStrWidth('----')
	 disp:drawStr(dw/2 - ww/2, 10+hh, '----')
	 disp:sendBuffer()
      end
      swiendread()
      return
   end

   lastread = wt
   
--   if wt > 10 and noreadings then -- skip first reading
--      noreadings = false
--      swiendread()
--   end
      
   local roundwt = (math.floor(wt*10) + 0.5)/10
   if math.abs(roundwt) < 0.2 then roundwt = 0.0 end

   if wt > 10 then

      wtboxcar[iwt] = wt

      local sum = 0
      jj = iwt -- math.min(iwt, wtboxlen)
      for i=1, jj, 1 do
	 sum = sum + wtboxcar[i]
      end
      local avg = sum / jj
      
      local sumsq = 0
      for i=1, jj, 1 do
	 sumsq = sumsq + (avg - wtboxcar[i])^2
      end
      stddev = math.sqrt(sumsq/jj)
      
      --print("wt, avg, stddev", wt, avg, stddev)

      jwt = jwt + 1

      if (jwt >= wtboxlen) and (stddev < 0.15)  and (not lock) then
	 lock = true
	 lockwt = (math.floor(wt*10) + 0.5) / 10
      end

      if iwt >= wtboxlen then
	 iwt = 1
      else
	 iwt = iwt + 1
      end
      
      dispSleepTimer:stop()
      disp:setPowerSave(0)
      disp:clearBuffer()

      local text

      disp:setFont(u8g2.font_6x10_tf)
      text = string.format("%d", jwt)
      disp:drawStr(115, 45, text)
      
      if lock then
	 text = string.format("%3.1f", lockwt)
	 disp:drawDisc(120, 10, 2)
      else

	 text = string.format("%3.1f", avg)
	 disp:drawDisc(120, 10, 2, seq[iseq])
	 if iseq == #seq then
	    iseq = 1
	 else
	    iseq = iseq + 1
	 end
      end
      
      disp:setFont(u8g2.font_inb24_mr)
      local ww = disp:getStrWidth(text)
      local hh = 30
      ww = disp:getStrWidth(text)
      disp:drawStr(dw/2 - ww/2, 10+hh, text)
      --print(text)

      disp:setFont(u8g2.font_inb16_mr)

      if lock then
	 text = "GTFO"
      else
	 text = string.format("(%.1f)", tgtweight)
      end
      --print(text)
      ww = disp:getStrWidth(text)
      disp:drawStr(dw/2 - ww/2, 30+hh, text)
      text = string.format("T: %.1f", tgtweight)
      disp:sendBuffer()
      
      if lock then swiwt = lockwt else swiwt = avg end
      local movdeg = 180 + 150 * (swiwt - tgtweight) / 10
      if movdeg < 30 then movdeg = 30 end
      if movdeg > 330 then movdeg = 330 end
      is = math.floor((movdeg - 22.5) * 3 + 0.5)
      if jwt > 2 then
	 switec.moveto(0, is, swiendread)
      else
	 switec.moveto(0, 0, swiendread)
      end
      
   else
      is = 0
      if lock then
	 print("lock true, done")
	 if tgtweight ~= lockwt then print("Set T:", lockwt) end
	 tgtweight = lockwt 
	 
	 --local movdeg = 180 + 150 * (lockwt - tgtweight) / 10
	 --if movdeg < 30 then movdeg = 30 end
	 --if movdeg > 330 then movdeg = 330 end
	 --is = math.floor((movdeg - 22.5) * 3 + 0.5)
	 switec.moveto(0, 0, swiendread)
      else
	 switec.moveto(0, 0, swiendread)
      end

      dispSleepTimer:start()
   end

end


init_i2c_display()
u8g2_prepare()

dh = 64
dw = 128

--print("Display Height:", dh)
--print("Display Width:", dw)

hx711.init(4,0)

local zs = 0
for i=1, 5, 1 do
   tmr.delay(500)
   zs = zs + hx711.read(0)
end
zero = zs/5

print("scale raw zero:", zero)

disp:setPowerSave(0)
disp:clearBuffer()

disp:setFont(u8g2.font_6x10_tf)
text = string.format("Hazel Scale V%.1f", 1.0)
ww = disp:getStrWidth(text)
disp:drawStr(dw/2 - ww/2, 20, text)

disp:setFont(u8g2.font_6x10_tf)
text = string.format("Raw Zero: %d", zero)
ww = disp:getStrWidth(text)
disp:drawStr(dw/2 - ww/2, 30, text)

text = string.format("Cal Factor: %5.2f", calib)
ww = disp:getStrWidth(text)
disp:drawStr(dw/2 - ww/2, 40, text)

text = string.format("Tgt Weight: %5.2f", tgtweight)
ww = disp:getStrWidth(text)
disp:drawStr(dw/2 - ww/2, 50, text)

ipa = wifi.sta.getip()
text = string.format("IP address: " .. ipa)
ww = disp:getStrWidth(text)
disp:drawStr(dw/2 - ww/2, 60, text)

disp:sendBuffer()

readtimer=tmr.create()
readtimer:register(1000, tmr.ALARM_SEMI, read)

dispSleepTimer=tmr.create()
dispSleepTimer:register(5000, tmr.ALARM_SEMI, dispSleep)

-- setup motor control: channel 0, pins 5,6,7,8 and 200 deg/sec

switec.setup(0,5,6,7,8,200)-- position specified in 1/3s of degree so it goes from 0 to 945 (315 degrees full scale * 3)

switec.moveto(0, -1000, swiendrst) -- force against CCW stop before reset (done in swiendrst())


