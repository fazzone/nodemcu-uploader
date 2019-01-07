--[[

Write the json config file for the delta scale

Upload to ESP8266 and run there

Companion utility for delta_scale.lua

--]]


local threeQ="/forms/d/e/1FAIpQLSd_AveBb5zD6BFotkc5S84xY7JqU8HxN4hYAOoxB8HKLzEdHQ/formResponse"
local Q1="entry.1967372928"
local Q2="entry.1949919536"
local Q3="entry.58067512"

local fourQ_U1= "/forms/d/e/1FAIpQLSduu7su_pDsTa4RqXMZDtnP4VpZeAPSCL67Z_Cnm32YV4D6vw/formResponse"
local fourQ_U1_Q1="entry.712941540"
local fourQ_U1_Q2="entry.484786416"
local fourQ_U1_Q3="entry.1737268520"
local fourQ_U1_Q4="entry.805234295"

local fourQ_U2="/forms/d/e/1FAIpQLSdcuT0A_xyqr3g8q5FiYnVeavU8cv1DNsRY89X5Ed2N4I4zmA/formResponse"
local fourQ_U2_Q1="entry.1203978065"
local fourQ_U2_Q2="entry.78249897"
local fourQ_U2_Q3="entry.475586023"
local fourQ_U2_Q4="entry.1816098028"

config_tbl={}

config_tbl.AWSfwd="http://54.245.181.150:4321"

config_tbl.fR3=threeQ
config_tbl.fR3Q1=Q1
config_tbl.fR3Q2=Q2
config_tbl.fR3Q3=Q3

config_tbl.fR4_U1=fourQ_U1
config_tbl.fR4_U1_Q1=fourQ_U1_Q1
config_tbl.fR4_U1_Q2=fourQ_U1_Q2
config_tbl.fR4_U1_Q3=fourQ_U1_Q3
config_tbl.fR4_U1_Q4=fourQ_U1_Q4

config_tbl.fR4_U2=fourQ_U2
config_tbl.fR4_U2_Q1=fourQ_U2_Q1
config_tbl.fR4_U2_Q2=fourQ_U2_Q2
config_tbl.fR4_U2_Q3=fourQ_U2_Q3
config_tbl.fR4_U2_Q4=fourQ_U2_Q4

config_tbl.ssid="linksys"
config_tbl.pwd="ultra5bandit"
config_tbl.save=true

config_tbl.calib = 10957

print("opening delta_config.jsn")
file.open("delta_config.jsn", "w+")
tj=sjson.encode(config_tbl)
print("tj:", tj)
file.write(tj)
file.close()

------------------------------------

target_tbl={0,0}

print("opening delta_target.jsn")
file.open("delta_target.jsn", "w+")
tj=sjson.encode(target_tbl)
print("tj:", tj)
file.write(tj)
file.close()


