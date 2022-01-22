local pixelcode_noise = love.filesystem.read( "noise.glsl" )
local frag_files = {}
for k,v in ipairs( love.filesystem.getDirectoryItems( "" ) ) do
   if string.find( v, ".frag" ) then
      table.insert( frag_files, v )
   end
end

local vertexcode = [[
#pragma language glsl3
vec4 position( mat4 transform_projection, vec4 vertex_position )
{
   return transform_projection * vertex_position;
}
]]

local global_dt, img, shader, shader_type

local function set_shader( num )
   local w, h = love.graphics.getDimensions()
   shader_type = frag_files[num+1]
   shader = love.graphics.newShader( pixelcode_noise .. love.filesystem.read(shader_type), vertexcode)
   global_dt = 0
   if shader:hasUniform("u_resolution") then
      shader:send( "u_resolution", {w, h} )
   end
end

function love.load()
   local w = 800
   local h = 450
   local prog_name = "Naev Overlay Demo"
   love.window.setTitle( prog_name )
   love.filesystem.setIdentity( prog_name );
   love.window.setMode( w, h, {resizable = true} )
   --love.window.setMode( 0, 0, {fullscreen = true} )
   -- Set up the shader
   set_shader( 0 )
   -- We need an image for the shader to work so we create a 1x1 px white image.
   local idata = love.image.newImageData( 1, 1 )
   idata:setPixel( 0, 0, 1, 1, 1, 1 )
   img      = love.graphics.newImage( idata )
   -- Set the font
   love.graphics.setNewFont( 24 )
end

function love.keypressed(key)
   local num = tonumber(key)
   if num~=nil then
      set_shader( num )
   elseif key=="q" or key=="escape" then
      love.event.quit()
   elseif key=="s" then
      local scr_name = ( "Screenshot_" .. os.time() .. ".png" )
      love.graphics.captureScreenshot( scr_name )
      print( "Captured screenshot " .. scr_name )
   end
end

function love.draw ()
   local lg = love.graphics

   local w, h = love.graphics.getDimensions()
   lg.setColor( 0, 0, 1, 1 )
   lg.setShader(shader)
   lg.draw( img, 0, 0, 0, w, h )
   lg.setShader()
   if global_dt < 1 then
      lg.setColor( 1, 1, 1, 1-global_dt )
      lg.printf( shader_type, 0, h/2-12, w, "center" )
   end
end

function love.update( dt )
   global_dt = (global_dt or 0) + dt
   if shader:hasUniform("u_time") then
      shader:send( "u_time", global_dt )
   end
end
