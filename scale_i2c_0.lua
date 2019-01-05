local the_survey_url = "/forms/d/e/1FAIpQLSelOx6I1Mv7x6Xg7f7vti9Qx7y5hQHms9LdCpZhYFutPZfZOg/formResponse"
local the_entry_key = "entry.1803841049"

local threeQ =   "/forms/d/e/1FAIpQLSd_AveBb5zD6BFotkc5S84xY7JqU8HxN4hYAOoxB8HKLzEdHQ/formResponse"
local Q1="entry.1967372928"
local Q2="entry.1949919536"
local Q3="entry.58067512"

local fourQ="/forms/d/e/1FAIpQLSduu7su_pDsTa4RqXMZDtnP4VpZeAPSCL67Z_Cnm32YV4D6vw/formResponse"
local fourQ1="entry.712941540"
local fourQ2="entry.484786416"
local fourQ3="entry.1737268520"
local fourQ4="entry.805234295"

local function send_via_forwarder(datapoint)
   local function _0_(code, data)
      return print("via: got response ", code)
   end
   return http.post("http://54.245.181.150:4321", nil, sjson.encode({["survey-path"] = the_survey_url, data = {[the_entry_key] = datapoint}}), _0_)
end

local function send_mult_via_forwarder(data1, data2, data3)
   local function _0_(code, data)
      return print("mult: got response ", code)
   end
   text= sjson.encode({["survey-path"] = threeQ, data = {[Q1] = data1, [Q2]=data2, [Q3]=data3}})
   --print("sj:", text)
   return http.post("http://54.245.181.150:4321", nil, text, _0_)
   --sjson.encode({["survey-path"] = threeQ, data = {[Q1] = data1, [Q2]=data2, [Q3]=data3}}), _0_)
end

local function send_four_via_forwarder(data1, data2, data3, data4)
   local function _0_(code, data)
      return print("four: got response ", code)
   end
   text= sjson.encode({["survey-path"] = fourQ, data = {[fourQ1] = data1, [fourQ2]=data2, [fourQ3]=data3, [fourQ4]=data4}})
   --print("sj:", text)
   return http.post("http://54.245.181.150:4321", nil, text, _0_)
   --sjson.encode({["survey-path"] = fourQ, data = {[fourQ1] = data1, [fourQ2]=data2, [fourQ3]=data3, [fourQ4]=data4}}), _0_)
end

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
   --print("dispsleep")
   switec.moveto(0, 0)
   disp:clearBuffer()
   disp:sendBuffer()
   disp:setPowerSave(1)
   lock = false
   sent_to_google=false
   lockwt = 0
   iwt = 1
   jwt = 1
   wtboxcar={}
   lastread = 0
   noreadings = true
   gpio.mode(3, gpio.OUTPUT)
   gpio.write(3,1) -- power off
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
    --print("i2c setup returns:", ii)
    disp = u8g2.ssd1306_i2c_128x64_noname(0, sla)
    --print("init .. after u8g2 call, disp:", disp)
end

calib = 10957.0
zero = 0
seq = {u8g2.DRAW_UPPER_RIGHT, u8g2.DRAW_LOWER_RIGHT, u8g2.DRAW_LOWER_LEFT,u8g2.DRAW_UPPER_LEFT}
iseq = 1
wtboxcar={}
iwt = 1
jwt = 1
wtboxlen=7
lock = false
sent_to_google=false
lockwt = 0
lastread = 0
noreadings = true
tgtweight = 270

function read()
   rr = hx711.read(0)
   
   wt = (rr - zero)/calib
   --tmr.delay(100)
   --print("in read, wt, lastread, rr:", wt, lastread, rr)

--   if wt < 10 then
--      lastread = wt
--      swiendread()
--      return
--   end

   --if wt > 10 then
   --   print("wt, lastread, iwt", wt, lastread,iwt)
   --end

   if math.abs(wt-lastread) > 1 then   
      lastread = wt
      --print("|wt-lastread| > 1")
      if not lock then
	 dispSleepTimer:stop()
	 disp:setPowerSave(0)
	 disp:clearBuffer()
	 disp:setFont(u8g2.font_inb24_mr)
	 local ww = disp:getStrWidth(text)
	 local hh = 30
	 ww = disp:getStrWidth('----')
	 disp:drawStr(dw/2 - ww/2, 10+hh, '----')
	 --print("----")
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
      --print(text)
      disp:sendBuffer()
      
      if lock then swiwt = lockwt else swiwt = avg end
      local movdeg = 180 + 120 * (swiwt - tgtweight) / 3
      if movdeg < 30 then movdeg = 30 end
      if movdeg > 330 then movdeg = 330 end
      is = math.floor((movdeg - 22.5) * 3 + 0.5)
      if jwt > 2 then
	 switec.moveto(0, is, swiendread)
      else
	 switec.moveto(0, 0, swiendread)
      end
      
   else -- wt <= 10
      --print("In ELSE, lock:", lock)
      is = 0
      if lock then
	 print("lock true, done")
	 --if tgtweight ~= lockwt then print("Set T:", lockwt) end
	 print("Set T:", lockwt)
	 tgtweight = lockwt
	 if not sent_to_google then -- make sure only done once
	    --send_via_forwarder(lockwt)
	    --send_mult_via_forwarder(lockwt, zero, calib)
	    vbatt = adc.read(0)
	    --print("send four", lockwt, zero, calib, vbatt)
	    send_four_via_forwarder(lockwt, zero, calib, vbatt)
	    sent_to_google=true
	    -- persist lockwt as new tgtweight
	    if file.open("target.dat", "w+") then
	       file.writeline(string.format("%f", lockwt))
	       file.close()
	       --print("closed file target.dat")
	    else
	       print("could not open target.dat")
	    end

	 end
	 
	 --local movdeg = 180 + 150 * (lockwt - tgtweight) / 10
	 --if movdeg < 30 then movdeg = 30 end
	 --if movdeg > 330 then movdeg = 330 end
	 --is = math.floor((movdeg - 22.5) * 3 + 0.5)
	 switec.moveto(0, 0, swiendread)
      else -- if not lock...
	 switec.moveto(0, 0, swiendread)
      end

      dispSleepTimer:start()
   end

end

vbatt1 = adc.read(0)

gpio.mode(3, gpio.OUTPUT)
gpio.write(3,0) -- power on

if file.exists("target.dat") then
   --print("target.dat exists, reading")
   if file.open("target.dat", "r") then
      rl = file.readline()
      --print("read:", rl)
      tgtweight = tonumber(rl)
      --print("tgtweight:", tgtweight)
      file.close()
   else
      print("could not open target.dat for reading")
   end
else
   print("no target.dat, seeding with 270")
   tgtweight = 270.0
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

--print("scale raw zero:", zero)

disp:setPowerSave(0)
disp:clearBuffer()

disp:setFont(u8g2.font_6x10_tf)
text = string.format("Delta Scale V%.1f", 1.0)
ww = disp:getStrWidth(text)
disp:drawStr(dw/2 - ww/2, 20, text)
--print(text)

disp:setFont(u8g2.font_6x10_tf)
text = "--> Step On Now <--"
ww = disp:getStrWidth(text)
disp:drawStr(dw/2 - ww/2, 30, text)
--print(text)

text = string.format("Prev Weight: %5.2f", tgtweight)
ww = disp:getStrWidth(text)
disp:drawStr(dw/2 - ww/2, 40, text)
--print(text)

ipa = wifi.sta.getip()
text = string.format("IP address: " .. ipa)
ww = disp:getStrWidth(text)
disp:drawStr(dw/2 - ww/2, 50, text)
--print(text)

hh = node.heap()
text = string.format("Heap: " .. hh)
ww = disp:getStrWidth(text)
disp:drawStr(dw/2 - ww/2, 60, text)

disp:sendBuffer()

vbatt2 = adc.read(0)
send_mult_via_forwarder(0, vbatt1, vbatt2)   

readtimer=tmr.create()
readtimer:register(1000, tmr.ALARM_SEMI, read)

dispSleepTimer=tmr.create()
dispSleepTimer:register(10000, tmr.ALARM_SEMI, dispSleep)

-- setup motor control: channel 0, pins 5,6,7,8 and 200 deg/sec

switec.setup(0,5,6,7,8,200)-- position specified in 1/3s of degree so it goes from 0 to 945 (315 degrees full scale * 3)

switec.moveto(0, -1000, swiendrst) -- force against CCW stop before reset (done in swiendrst())

--switec.reset(0)
--swiendread()



