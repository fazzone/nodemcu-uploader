function move(t)
   t:unregister()
   --is = math.floor(math.random()*945)
   is = (movtable[iseq]-22.5)*3
   switec.moveto(0, is, step)
end

function step()
   if iseq == 0 then
      switec.reset(0)
      local movtimer=tmr.create()
      movtimer:register(1500, tmr.ALARM_SINGLE, move)
      movtimer:start()
   end

   iseq = iseq + 1

   if iseq >  #movtable then
      iseq = 1
   end

   local movtimer=tmr.create()
   movtimer:register(dlytable[iseq], tmr.ALARM_SINGLE, move)      
   movtimer:start()
   
end

print("starting - doing setup")
a = switec.setup(0,5,6,7,8,400)

iseq = 0
movtable= {22.5, 45, 90, 135, 180, 225, 270, 315, 337.5}

dlytable= {2000, 2000, 2000, 2000, 2000, 2000, 2000, 2000, 2000}



switec.moveto(0, -1000, step)
print("done with moveto -1000")



