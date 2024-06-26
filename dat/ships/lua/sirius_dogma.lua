local flow = require "ships.lua.lib.flow"
require "ships.lua.sirius"

function update( p, _dt )
   local f = flow.get( p, mem )
   local mod = math.max( (f-250)*0.04, 0 )
   p:shippropSet{
      fwd_damage = mod,
      tur_damage = mod,
      launch_damage = mod,
   }
end
