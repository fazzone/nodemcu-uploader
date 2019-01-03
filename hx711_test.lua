zero = 0
calib = 10000


hx711.init(4,0)

rr = hx711.read(0)

print("raw read:", rr)


local zs = 0
for i=1, 5, 1 do
   tmr.delay(500)
   zs = zs + hx711.read(0)
end
zero = zs/5

print("scale raw zero avg:", zero)

smwt=0

while true do

   wt = (hx711.read(0) - zero)/calib
   tmr.delay(100)
   smwt = smwt + (wt-smwt)/20
   text = string.format("Weight: %4.2f Smooth Weight: %4.2f", wt, smwt)
   print(text)
end
