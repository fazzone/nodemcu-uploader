print('init.lua for wifi in access point mode')
wifi.setmode(wifi.SOFTAP)
print('set mode=STATION (mode='..wifi.getmode()..')')
print('MAC: ',wifi.sta.getmac())
print('chip: ',node.chipid())
print('heap: ',node.heap())
wifi.eventmon.register(wifi.eventmon.STA_GOT_IP,
		       function(T)
			  print("\n\tCallback: STA - GOT IP".."\n\tStation IP: "..T.IP.."\n\tSubnet mask: "..
				   T.netmask.."\n\tGateway IP: "..T.gateway)
end)


wifi.eventmon.register(wifi.eventmon.AP_STACONNECTED, function(T)
			  print("\n\tAP - STATION CONNECTED".."\n\tMAC: "..T.MAC.."\n\tAID: "..T.AID)
end)

wifi.eventmon.register(wifi.eventmon.AP_STADISCONNECTED, function(T)
			  print("\n\tAP - STATION DISCONNECTED".."\n\tMAC: "..T.MAC.."\n\tAID: "..T.AID)
end)

 -- wifi config start
config_tbl={}
config_tbl.ssid="esp8266"
config_tbl.pwd="12345678"
config_tbl.save=false
config_tbl.auth=wifi.WPA_WPA2_PSK
print("config return:", wifi.ap.config(config_tbl))
-- wifi config end
