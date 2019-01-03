local the_survey_url = "/forms/d/e/1FAIpQLSelOx6I1Mv7x6Xg7f7vti9Qx7y5hQHms9LdCpZhYFutPZfZOg/formResponse"
local the_entry_key = "entry.1803841049"

local threeQ =   "/forms/d/e/1FAIpQLSd_AveBb5zD6BFotkc5S84xY7JqU8HxN4hYAOoxB8HKLzEdHQ/formResponse"
local Q1="entry.1967372928"
local Q2="entry.1949919536"
local Q3="entry.58067512"

function _0_(code, data)
   print("got response ", code)
   print("shutting down")
   gpio.write(5, 1)
end

function send_via_forwarder(datapoint)
   return http.post("http://54.245.181.150:4321", nil, sjson.encode({["survey-path"] = the_survey_url, data = {[the_entry_key] = datapoint}}), _0_)
end

function send_mult_via_forwarder(data1, data2, data3)
   text= sjson.encode({["survey-path"] = threeQ, data = {[Q1] = data1, [Q2]=data2, [Q3]=data3}})
   print("sj:", text)
   return http.post("http://54.245.181.150:4321", nil, sjson.encode({["survey-path"] = threeQ, data = {[Q1] = data1, [Q2]=data2, [Q3]=data3}}), _0_)
end



function ipcallback(T)
   print("\n\tCallback: STA - GOT IP".."\n\tStation IP: "..T.IP.."\n\tSubnet mask: "..
	    T.netmask.."\n\tGateway IP: "..T.gateway)
   gpio.write(4,1)
   vv = adc.read(0)*0.945*5.59/1000
   print("voltage:", vv, " --sending to google via fwder")
   send_via_forwarder(vv)
--   tm = tmr.create()
--   tm:register(2000, tmr.ALARM_SINGLE, tmend)
--   tm:start()
end

function tmend(T)
   print("Timer ends, setting gpio high")
   gpio.mode(0, gpio.OUTPUT)
   gpio.write(0, 1)
end


print('init.lua for WiFi Station')
wifi.setmode(wifi.STATION)
print('set mode=STATION (mode='..wifi.getmode()..')')
print('MAC: ',wifi.sta.getmac())
print('chip: ',node.chipid())
print('heap: ',node.heap())
gpio.mode(4, gpio.OUTPUT)
gpio.write(5, 0)
gpio.mode(5, gpio.OUTPUT)
gpio.write(4, 0)

wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, ipcallback)


-- wifi config start
config_tbl={}
config_tbl.ssid="linksys"
config_tbl.pwd="ultra5bandit"
config_tbl.save=true
wifi.sta.config(config_tbl)
-- wifi config end
