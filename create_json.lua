local threeQ="/forms/d/e/1FAIpQLSd_AveBb5zD6BFotkc5S84xY7JqU8HxN4hYAOoxB8HKLzEdHQ/formResponse"
local Q1="entry.1967372928"
local Q2="entry.1949919536"
local Q3="entry.58067512"

local fourQ= "/forms/d/e/1FAIpQLSduu7su_pDsTa4RqXMZDtnP4VpZeAPSCL67Z_Cnm32YV4D6vw/formResponse"
local fourQ1="entry.712941540"
local fourQ2="entry.484786416"
local fourQ3="entry.1737268520"
local fourQ4="entry.805234295"


goog_tbl={}
goog_tbl.AWSfwd="http://54.245.181.150:4321"
goog_tbl.fR3=threeQ
goog_tbl.fR3Q1=Q1
goog_tbl.fR3Q2=Q2
goog_tbl.fR3Q3=Q3
goog_tbl.fR4=fourQ
goog_tbl.fR4Q1=fourQ1
goog_tbl.fR4Q2=fourQ2
goog_tbl.fR4Q3=fourQ3
goog_tbl.fR4Q4=fourQ4
file.open("delta_goog.jsn", "w+")
tj=sjson.encode(goog_tbl)
print("tj:", tj)
file.write(tj)
file.close()

config_tbl={}
config_tbl.ssid="linksys"
config_tbl.pwd="ultra5bandit"
config_tbl.save=true


file.open("delta_wifi.jsn", "w+")
tj=sjson.encode(config_tbl)
print("tj:", tj)
file.write(tj)
file.close()



file.open("delta_target.jsn", "w+")
t={270, 170, calib=10957}
tj = sjson.encode(t)
print("tj:", tj)
file.write(tj)
file.close()



