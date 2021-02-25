--[[
-- Love2d Graphics for Naev!
--]]
local class = require 'class'
local love = require 'love'
local object = require 'love.object'
local filesystem = require 'love.filesystem'
local love_math = require 'love.math'

local graphics = {
   _bgcol = naev.colour.new( 0, 0, 0, 1 ),
   _fgcol = naev.colour.new( 1, 1, 1, 1 ),
   _wraph = "clamp",
   _wrapv = "clamp",
   _wrapd = "clamp",
}

-- Helper functions
local function _mode(m)
   if     m=="fill" then return false
   elseif m=="line" then return true
   else   error( string.format(_("Unknown fill mode '%s'"), mode ) )
   end
end
local function _H( x, y, r, sx, sy )
   -- TODO don't do this for every drawing...
   local H
   if graphics._canvas then
      -- Rendering to canvas
      local cw = graphics._canvas.t.w
      local ch = graphics._canvas.t.h
      H = naev.transform.ortho( 0, cw, 0, ch, -1, 1 )
          :scale( love.s, love.s )
   else
      -- Rendering to screen
      H = graphics._O
   end
   H = H * graphics._T[1].T
   if r == 0 then
      H = H:translate(x,y)
           :scale( sx, -sy )
           :translate(0,-1)
   else
      local hw = sx/2
      local hh = sy/2
      H = H:translate(x+hw,y+hh)
           :rotate2d(r)
           :translate(-hw,-hh)
           :scale( sx, -sy )
           :translate(0,-1)
   end
   return H
end
local function _gcol( c )
   local r, g, b = c:rgb()
   local a = c:alpha()
   return r, g, b, a
end
local function _scol( r, g, b, a )
   if type(r)=="table" then
      a = r[4]
      b = r[3]
      g = r[2]
      r = r[1]
   end
   return naev.colour.new( r, g, b, a or 1 )
end


--[[
-- Drawable class
--]]
graphics.Drawable = class.inheritsFrom( object.Object )
graphics.Drawable._type = "Drawable"
function graphics.Drawable.draw() love._unimplemented() end


--[[
-- Image class
--]]
graphics.Image = class.inheritsFrom( graphics.Drawable )
graphics.Image._type = "Image"
function graphics.newImage( filename )
   local ttex
   if type(filename)=='string' then
      ttex = naev.tex.open( filesystem.newFile( filename ) )
   elseif type(filename)=='table' and filename.type then
      local ot = filename:type()
      if ot=='ImageData' then
         ttex = naev.tex.open( filename.d, filename.w, filename.h )
      end
   end
   if ttex ~= nil then
      local t = graphics.Image.new()
      t.tex = ttex
      t.w, t.h = ttex:dim()
      -- Set defaults
      t:setFilter( graphics._minfilter, graphics._magfilter )
      t:setWrap( graphics._wraph, graphics._wrapv, graphics._wrapd )
      return t
   end
   error(_('wrong parameter type'))
end
function graphics.Image:setFilter( min, mag, anisotropy )
   mag = mag or min
   anisotropy = anisotropy or 1
   self.tex:setFilter( min, mag, anisotropy )
   self.min = min
   self.mag = mag
   self.anisotropy = anisotropy
end
function graphics.Image:getFilter() return self.min, self.mag, self.anisotropy end
function graphics.Image:setWrap( horiz, vert, depth )
   vert = vert or horiz
   depth = depth or horiz
   self.tex:setWrap( horiz, vert, depth )
   self.wraph = horiz
   self.wrapv = vert
   self.wrapd = depth
end
function graphics.Image:getWrap() return self.wraph, self.wrapv, self.wrapd end
function graphics.Image:getDimensions() return self.w, self.h end
function graphics.Image:getWidth() return self.w end
function graphics.Image:getHeight() return self.h end
function graphics.Image:draw( ... )
   local arg = {...}
   local w,h = self.tex:dim()
   local x,y,r,sx,sy,tx,ty,tw,th
   if type(arg[1])=='number' then
      -- x, y, r, sx, sy
      x = arg[1]
      y = arg[2]
      r = arg[3] or 0
      sx = arg[4] or 1
      sy = arg[5] or sx
   else
      -- quad, x, y, r, sx, sy
      local q = arg[1]
      x = arg[2]
      y = arg[3]
      r = arg[4] or 0
      sx = arg[5] or 1
      sy = arg[6] or sx
      tx = q.x
      ty = q.y
      tw = q.w
      th = q.h
      love._unimplemented()
   end
   -- TODO be less horribly inefficient
   local shader = graphics._shader or graphics._shader_default
   shader = shader.shader
   local s3, s4
   if graphics._canvas == nil then
      s3 = -1.0
      s4 = love.h
   else
      s3 = 1.0
      s4 = 0.0
   end
   shader:sendRaw( "love_ScreenSize", {love.w, love.h, s3, s4} )

   -- Get transformation and run
   local H = _H( x, y, r, w*sx, h*sy )
   naev.gfx.renderTexH( self.tex, shader, H, graphics._fgcol );
end


--[[
-- Quad class
--]]
graphics.Quad = class.inheritsFrom( graphics.Drawable )
graphics.Quad._type = "Quad"
function graphics.newQuad( x, y, width, height, sw, sh )
   local q = graphics.Drawable.new()
   if type(sw)~="number" then
      local t = sw
      sw = t.w
      sh = t.h
   end
   q.x = x/sw
   q.y = y/sh
   q.w = width/sw
   q.h = height/sh
   q.quad = true
   return q
end


--[[
-- Transformation class
--]]
function graphics.origin()
   local nw, nh = naev.gfx.dim()
   local nx = -love.x
   local ny = love.h+love.y-nh
   graphics._O = naev.transform.ortho( nx, nx+nw, ny+nh, ny, -1, 1 )
   graphics._T = { love_math.newTransform() }
end
function graphics.push()
   local t = graphics._T[1]
   table.insert( graphics._T, 1, t:clone() )
end
function graphics.pop()
   table.remove( graphics._T, 1 )
   if graphics._T[1] == nil then
      graphics._T[1] = love.math.newTransform()
   end
end
function graphics.translate( dx, dy ) graphics._T[1]:translate( dx, dy ) end
function graphics.scale( sx, sy ) graphics._T[1]:scale( sx, sy ) end
function graphics.rotate( angle ) graphics._T[1]:rotate( angle ) end


--[[
-- SpriteBatch class
--]]
graphics.SpriteBatch = class.inheritsFrom( graphics.Drawable )
graphics.SpriteBatch._type = "SpriteBatch"
function graphics.newSpriteBatch( image, maxsprites, usage  )
   love._unimplemented()
   local batch = graphics.SpriteBatch.new()
   batch.image = image
   batch:clear()
   return batch
end
function graphics.SpriteBatch:clear()
   love._unimplemented()
end
function graphics.SpriteBatch:setColor()
   love._unimplemented()
end
function graphics.SpriteBatch:add( ... )
   local arg = {...}
   love._unimplemented()
end
function graphics.SpriteBatch:draw()
   love._unimplemented()
end


--[[
-- Global functions
--]]
function graphics.getDimensions() return love.w, love.h end
function graphics.getWidth()  return love.w end
function graphics.getHeight() return love.h end
function graphics.getBackgroundColor() return _gcol( graphics._bgcol ) end
function graphics.setBackgroundColor( red, green, blue, alpha )
   graphics._bgcol = _scol( red, green, blue, alpha )
end
function graphics.getColor() return _gcol( graphics._fgcol ) end
function graphics.setColor( red, green, blue, alpha )
   graphics._fgcol = _scol( red, green, blue, alpha )
end
function graphics.setDefaultFilter( min, mag, anisotropy )
   graphics._minfilter = min
   graphics._magfilter = mag
   graphics._anisotropy = 1
end
function graphics.getDefaultFilter()
   return graphics._minfilter, graphics._magfilter, graphics._anisotropy
end


--[[
-- Rendering primitives and drawing
--]]
function graphics.clear( ... )
   local arg = {...}
   local col
   if #arg==0 then
      col = graphics._bgcol
   elseif type(arg[1])=="number" then
      local r = arg[1]
      local g = arg[2]
      local b = arg[3]
      local a = arg[4] or 1
      col = _scol( r, g, b, a )
   elseif type(arg[1])=="table" then
      local r = arg[1][1]
      local g = arg[1][1]
      local b = arg[1][1]
      local a = arg[1][1] or 1
      col = _scol( r, g, b, a )
   end
   if graphics._canvas == nil then
      -- Minor optimization: just render when there is non-transparent color
      if col:alpha()>0 then
         naev.gfx.renderRect( love.x, love.y, love.w, love.h, col )
      end
   else
      graphics._canvas.canvas:clear( col )
   end
end
function graphics.draw( drawable, ... )
   drawable:draw( ... )
end
function graphics.rectangle( mode, x, y, width, height )
   local H = _H( x, y, 0, width, height )
   naev.gfx.renderRectH( H, graphics._fgcol, _mode(mode) )
end
function graphics.circle( mode, x, y, radius )
   local H = _H( x, y, 0, radius, radius )
   naev.gfx.renderCircleH( H, graphics._fgcol, _mode(mode) )
end
function graphics.print( text, ... )
   local arg = {...}
   local t = type(arg[1])
   -- We have to specify limit so we just put a ridiculously large value
   local w = 1e6
   local align = "left"
   if t=="number" then
      local x = arg[1]
      local y = arg[2]
      graphics.printf( text, x, y, w, align )
   else
      local font = arg[1]
      local x = arg[2]
      local y = arg[3]
      graphics.printf( text, font, x, y, w, align )
   end
end
function graphics.printf( text, ... )
   local arg = {...}
   local x, y, limit, align, font, col

   if type(arg[1])=="number" then
      -- love.graphics.printf( text, x, y, limit, align )
      font = graphics._font
      x = arg[1]
      y = arg[2]
      limit = arg[3]
      align = arg[4]
   else
      -- love.graphics.printf( text, font, x, y, limit, align )
      font = arg[1]
      x = arg[2]
      y = arg[3]
      limit = arg[4]
      align = arg[5]
   end
   align = align or "left"
   col = graphics._fgcol

   local H = _H( x, y+font.height, 0, 1, 1 )
   local sx = graphics._T[1].T:get()[1][1] -- X scaling
   local wrapped, maxw = naev.gfx.printfWrap( font.font, text, limit/sx )

   local atype
   if align=="left" then
      atype = 1
   elseif align=="center" then
      atype = 2
   elseif align=="right" then
      atype = 3
   end
   naev.gfx.printRestoreClear()
   for k,v in ipairs(wrapped) do
      local tx
      if atype==1 then
         tx = 0
      elseif atype==2 then
         tx = (limit-v[2])/2
      elseif atype==3 then
         tx = (limit-v[2])
      end
      naev.gfx.printRestoreLast()

      HH = H:translate( sx*tx, 0 )
      naev.gfx.printH( HH, font.font, v[1], col )
      H = H:translate( 0, -font.lineheight );
   end
end


--[[
-- Font stuff
--]]
graphics.Font = class.inheritsFrom( object.Object )
graphics.Font._type = "Font"
function graphics.newFont( ... )
   local arg = {...}
   local filename, size
   if type(arg[1])=="string" then
      -- newFont( filename, size )
      filename = filesystem.newFile( arg[1] ):getFilename() -- Trick to set path
      size = arg[2] or 12
   else
      -- newFont( size )
      filename = nil
      size = arg[1] or 12
   end

   local f = graphics.Font.new()
   f.font = naev.font.new( filename, size )
   f.filename = filename
   f.height= f.font:height()
   f.lineheight = f.height*1.5 -- Naev default
   f:setFilter( graphics._minfilter, graphics._magfilter )
   return f
end
function graphics.Font:setFallbacks( ... )
   local arg = {...}
   for k,v in ipairs(arg) do
      local filename = v.filename
      if not self.font:addFallback( filename ) then
         error(_("failed to set fallback font"))
      end
   end
end
function graphics.Font:getWrap( text, wraplimit )
   local wrapped, maxw = naev.gfx.printfWrap( self.font, text, wraplimit )
   local wrappedtext = {}
   for k,v in ipairs(wrapped) do
      wrappedtext[k] = v[1]
   end
   return maxw, wrappedtext
end
function graphics.Font:getHeight() return self.height end
function graphics.Font:getWidth( text ) return self.font:width( text ) end
function graphics.Font:getLineHeight() return self.lineheight end
function graphics.Font:setLineHeight( height ) self.lineheight = height end
function graphics.Font:getFilter() return self.min, self.mag, self.anisotropy end
function graphics.Font:setFilter( min, mag, anisotropy )
   mag = mag or min
   anisotropy = anisotropy or 1
   self.font:setFilter( min, mag, anisotropy )
   self.min = min
   self.mag = mag
   self.anisotropy = anisotropy
end
function graphics.setFont( fnt ) graphics._font = fnt end
function graphics.getFont() return graphics._font end
function graphics.setNewFont( file, size )
   local font = graphics.newFont( file, size )
   graphics.setFont( font )
   return font
end


--[[
-- Shader class
--]]
graphics.Shader = class.inheritsFrom( object.Object )
graphics.Shader._type = "Shader"
function graphics.newShader( pixelcode, vertexcode )
   local prepend = [[
#version 140
// Syntax sugar
#define Image           sampler2D
#define ArrayImage      sampler2DArray
#define VolumeImage     sampler3D
#define Texel           texture
#define love_PixelColor color_out
#define love_Position   gl_Position
#define love_PixelCoord (vec2(gl_FragCoord.x, (gl_FragCoord.y * love_ScreenSize.z) + love_ScreenSize.w))

// Uniforms shared by pixel and vertex shaders
uniform mat4 ViewSpaceFromLocal;
uniform mat4 ClipSpaceFromView;
uniform mat4 ClipSpaceFromLocal;
uniform mat3 ViewNormalFromLocal;
uniform vec4 love_ScreenSize;
uniform vec4 ConstantColor;

// Compatibility
#define TransformMatrix             ViewSpaceFromLocal
#define ProjectionMatrix            ClipSpaceFromView
#define TransformProjectionMatrix   ClipSpaceFromLocal
#define NormalMatrix                ViewNormalFromLocal
]]
   local frag = [[
#define PIXEL
uniform sampler2D MainTex;

in vec4 VaryingTexCoord;
in vec4 VaryingColor;
out vec4 color_out;

vec4 effect( vec4 vcolor, Image tex, vec2 texcoord, vec2 pixcoord );

void main(void) {
   love_PixelColor = effect( VaryingColor, MainTex, VaryingTexCoord.st, love_PixelCoord );
}
]]
   local vert = [[
#define VERTEX
in vec4 VertexPosition;
in vec4 VertexTexCoord;
in vec4 VertexColor;

out vec4 VaryingTexCoord;
out vec4 VaryingColor;

vec4 position( mat4 clipSpaceFromLocal, vec4 localPosition );

void main(void) {
    VaryingTexCoord  = VertexTexCoord;
    VaryingTexCoord.y= 1.0 - VaryingTexCoord.y;
    VaryingColor     = ConstantColor;
    love_Position    = position( ClipSpaceFromLocal, VertexPosition );
}
]]
   local s = graphics.Shader.new()
   vertexcode = vertexcode or pixelcode
   s.shader = naev.shader.new(
         prepend..frag..pixelcode,
         prepend..vert..vertexcode )
   return s
end
function graphics.setShader( shader )
   graphics._shader = shader
end
function graphics.Shader:send( name, ... )
   self.shader:send( name, ... )
end
function graphics.Shader:hasUniform( name )
   return self.shader:hasUniform( name )
end


--[[
-- Canvas class
--]]
graphics.Canvas = class.inheritsFrom( object.Drawable )
graphics.Canvas._type = "Canvas"
function graphics.newCanvas( width, height, settings )
   local c = graphics.Canvas.new()
   if not width then
      local nw, nh, ns = naev.gfx.dim()
      width = nw
      height= nh
   end
   c.canvas = naev.canvas.new( width, height )
   -- Set texture
   local t = graphics.Image.new()
   t.tex = c.canvas:getTex()
   t.w, t.h = t.tex:dim()
   t:setFilter( graphics._minfilter, graphics._magfilter )
   t:setWrap( graphics._wraph, graphics._wrapv, graphics._wrapd )
   c.t = t
   return c
end
function graphics.setCanvas( canvas )
   if canvas==nil then
      naev.canvas.set()
   else
      naev.canvas.set( canvas.canvas )
   end
   graphics._canvas = canvas
end
function graphics.Canvas:draw(...)     return self.t:draw(...) end
function graphics.Canvas:setFilter(...)return self.t:setFilter(...) end
function graphics.Canvas:getFilter(...)return self.t:getFilter(...) end
function graphics.Canvas:setWrap(...)  return self.t:setWrap(...) end
function graphics.Canvas:getWrap(...)  return self.t:getWrap(...) end
function graphics.Canvas:getDimensions(...) return self.t:getDimensions(...) end
function graphics.Canvas:getWidth(...) return self.t:getWidth(...) end
function graphics.Canvas:getHeight(...)return self.t:getHeight(...) end


-- unimplemented
function graphics.setLineStyle( style )
   love._unimplemented()
end
function graphics.setBlendMode( mode )
   love._unimplemented()
end


-- Set some sane defaults.
local _pixelcode = [[
vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
{
   vec4 texcolor = texture2D(tex, texture_coords);
   return texcolor * color;
}
]]
local _vertexcode = [[
vec4 position( mat4 transform_projection, vec4 vertex_position )
{
   return transform_projection * vertex_position;
}
]]
graphics.setDefaultFilter( "linear", "linear", 1 )
graphics.setNewFont( 12 )
--graphics.origin()
graphics._shader_default = graphics.newShader( _pixelcode, _vertexcode )
graphics.setShader( graphics._shader_default )
graphics.setCanvas( nil )

return graphics
