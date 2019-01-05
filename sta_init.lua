function ipcallback(T)
   print("\n\tCallback: STA - GOT IP".."\n\tStation IP: "..T.IP.."\n\tSubnet mask: "..
	    T.netmask.."\n\tGateway IP: "..T.gateway)
   --print("about to dofile('s.lua')")
   --dofile("s.lua")
end

print('init.lua for WiFi Station')
wifi.setmode(wifi.STATION)
print('set mode=STATION (mode='..wifi.getmode()..')')
print('MAC: ',wifi.sta.getmac())
print('chip: ',node.chipid())
print('heap: ',node.heap())

wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, ipcallback)

-- wifi config start
config_tbl={}
config_tbl.ssid="linksys"
config_tbl.pwd="ultra5bandit"
config_tbl.save=true
wifi.sta.config(config_tbl)
-- wifi config end
