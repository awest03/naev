/*
 * See Licensing and Copyright notice in naev.h
 */

/**
 * @file nlua_gfx.c
 *
 * @brief Handles the rendering of graphics on the screen.
 */

/** @cond */
#include <lauxlib.h>

#include "naev.h"
/** @endcond */

#include "nlua_gfx.h"

#include "font.h"
#include "log.h"
#include "ndata.h"
#include "nlua_col.h"
#include "nlua_font.h"
#include "nlua_shader.h"
#include "nlua_tex.h"
#include "nlua_transform.h"
#include "nlua_canvas.h"
#include "nluadef.h"
#include "opengl.h"


/* GFX methods. */
static int gfxL_dim( lua_State *L );
static int gfxL_renderTex( lua_State *L );
static int gfxL_renderTexRaw( lua_State *L );
static int gfxL_renderTexH( lua_State *L );
static int gfxL_renderRect( lua_State *L );
static int gfxL_renderRectH( lua_State *L );
static int gfxL_renderCircle( lua_State *L );
static int gfxL_renderCircleH( lua_State *L );
static int gfxL_fontSize( lua_State *L );
/* TODO get rid of printDim and print in favour of printfDim and printf */
static int gfxL_printfDim( lua_State *L );
static int gfxL_printfWrap( lua_State *L );
static int gfxL_printRestoreClear( lua_State *L );
static int gfxL_printRestoreLast( lua_State *L );
static int gfxL_printf( lua_State *L );
static int gfxL_printH( lua_State *L );
static int gfxL_printDim( lua_State *L );
static int gfxL_print( lua_State *L );
static int gfxL_printText( lua_State *L );
static const luaL_Reg gfxL_methods[] = {
   /* Information. */
   { "dim", gfxL_dim },
   /* Render stuff. */
   { "renderTex", gfxL_renderTex },
   { "renderTexRaw", gfxL_renderTexRaw },
   { "renderTexH", gfxL_renderTexH },
   { "renderRect", gfxL_renderRect },
   { "renderRectH", gfxL_renderRectH },
   { "renderCircle", gfxL_renderCircle },
   { "renderCircleH", gfxL_renderCircleH },
   /* Printing. */
   { "fontSize", gfxL_fontSize },
   { "printfDim", gfxL_printfDim },
   { "printfWrap", gfxL_printfWrap },
   { "printRestoreClear", gfxL_printRestoreClear },
   { "printRestoreLast", gfxL_printRestoreLast },
   { "printf", gfxL_printf },
   { "printH", gfxL_printH },
   { "printDim", gfxL_printDim },
   { "print", gfxL_print },
   { "printText", gfxL_printText },
   {0,0}
}; /**< GFX methods. */


/**
 * @brief Loads the graphics library.
 *
 *    @param env Environment to load graphics library into.
 *    @return 0 on success.
 */
int nlua_loadGFX( nlua_env env )
{
   /* Register the values */
   nlua_register(env, "gfx", gfxL_methods, 0);

   /* We also load the texture, colour, font, and transform modules as dependencies. */
   nlua_loadCol( env );
   nlua_loadTex( env );
   nlua_loadFont( env );
   nlua_loadTransform( env );
   nlua_loadShader( env );
   nlua_loadCanvas( env );

   return 0;
}


/**
 * @brief Lua bindings to interact with rendering and the Naev graphical environment.
 *
 * An example would be:
 * @code
 * t  = tex.open( GFX_PATH"foo/bar.png" ) -- Loads the texture
 * gfx.renderTex( t, 0., 0. ) -- Draws texture at origin
 * @endcode
 *
 * @luamod gfx
 */


/**
 * @brief Gets the dimensions of the Naev window.
 *
 * @usage screen_w, screen_h = gfx.dim()
 *
 *    @luatreturn number The width of the Naev window.
 *    @luatreturn number The height of the Naev window.
 *    @luatreturn scale The scaling factor.
 * @luafunc dim
 */
static int gfxL_dim( lua_State *L )
{
   lua_pushnumber( L, SCREEN_W );
   lua_pushnumber( L, SCREEN_H );
   lua_pushnumber( L, gl_screen.scale );
   return 3;
}


/**
 * @brief Renders a texture.
 *
 * This function has variable parameters depending on how you want to render.
 *
 * @usage gfx.renderTex( tex, 0., 0. ) -- Render tex at origin
 * @usage gfx.renderTex( tex, 0., 0., col ) -- Render tex at origin with colour col
 * @usage gfx.renderTex( tex, 0., 0., 4, 3 ) -- Render sprite at position 4,3 (top-left is 1,1)
 * @usage gfx.renderTex( tex, 0., 0., 4, 3, col ) -- Render sprite at position 4,3 (top-left is 1,1) with colour col
 *
 *    @luatparam Tex tex Texture to render.
 *    @luatparam number pos_x X position to render texture at.
 *    @luatparam number pos_y Y position to render texture at.
 *    @luatparam[opt=0] int sprite_x X sprite to render.
 *    @luatparam[opt=0] int sprite_y Y sprite to render.
 *    @luatparam[opt] Colour colour Colour to use when rendering.
 * @luafunc renderTex
 */
static int gfxL_renderTex( lua_State *L )
{
   glTexture *tex;
   glColour *col;
   double x, y;
   int sx, sy;

   NLUA_CHECKRW(L);

   /* Parameters. */
   col = NULL;
   tex = luaL_checktex( L, 1 );
   x   = luaL_checknumber( L, 2 );
   y   = luaL_checknumber( L, 3 );
   if (lua_isnumber( L, 4 )) {
      sx    = luaL_checkinteger( L, 4 ) - 1;
      sy    = luaL_checkinteger( L, 5 ) - 1;
      if (lua_iscolour(L, 6))
         col = luaL_checkcolour(L,6);
   }
   else {
      sx    = 0;
      sy    = 0;
      if (lua_iscolour(L, 4))
         col = luaL_checkcolour(L,4);
   }

   /* Some safety checking. */
#if DEBUGGING
   if (sx >= tex->sx)
      NLUA_ERROR( L, _("Texture '%s' trying to render out of bounds (X position) sprite: %d > %d."),
            tex->name, sx+1, tex->sx );
   if (sx >= tex->sx)
      NLUA_ERROR( L, _("Texture '%s' trying to render out of bounds (Y position) sprite: %d > %d."),
            tex->name, sy+1, tex->sy );
#endif /* DEBUGGING */

   /* Render. */
   gl_blitStaticSprite( tex, x, y, sx, sy, col );

   return 0;
}


/**
 * @brief Renders a texture using the core render function.
 *
 * This function is far more complex than renderTex, however it allows much
 *  more fine grained control over the entire render process and puts you
 *  closer to the actual OpenGL calls.
 *
 * @usage gfx.renderTexRaw( tex, 0., 0., 100., 100., 1, 1, 0., 0., 0.5, 0.5 ) -- Renders the bottom quarter of the sprite 1,1 of the image.
 *
 *    @luatparam Tex tex Texture to render.
 *    @luatparam number pos_x X position to render texture at.
 *    @luatparam number pos_y Y position to render texture at.
 *    @luatparam number pos_w Width of the image on screen.
 *    @luatparam number pos_h Height of the image on screen.
 *    @luatparam number sprite_x X sprite to render.
 *    @luatparam number sprite_y Y sprite to render.
 *    @luatparam number tex_x X sprite texture offset as [0.:1.].
 *    @luatparam number tex_y Y sprite texture offset as [0.:1.].
 *    @luatparam number tex_w Sprite width to display as [-1.:1.]. Note if negative, it will flip the image horizontally.
 *    @luatparam number tex_h Sprite height to display as [-1.:1.] Note if negative, it will flip the image vertically.
 *    @luatparam[opt] Colour colour Colour to use when rendering.
 *    @luatparam[opt] number angle Angle to rotate in radians.
 * @luafunc renderTexRaw
 */
static int gfxL_renderTexRaw( lua_State *L )
{
   glTexture *t;
   const glColour *col;
   double px,py, pw,ph, tx,ty, tw,th;
   double angle;
   int sx, sy;

   NLUA_CHECKRW(L);

   /* Parameters. */
   t  = luaL_checktex( L, 1 );
   px = luaL_checknumber( L, 2 );
   py = luaL_checknumber( L, 3 );
   pw = luaL_checknumber( L, 4 );
   ph = luaL_checknumber( L, 5 );
   sx = luaL_checkinteger( L, 6 ) - 1;
   sy = luaL_checkinteger( L, 7 ) - 1;
   tx = luaL_checknumber( L, 8 );
   ty = luaL_checknumber( L, 9 );
   tw = luaL_checknumber( L, 10 );
   th = luaL_checknumber( L, 11 );
   col = luaL_optcolour(L, 12, &cWhite );
   angle = luaL_optnumber(L,13,0.);

   /* Some safety checking. */
#if DEBUGGING
   if (sx >= t->sx)
      NLUA_ERROR( L, _("Texture '%s' trying to render out of bounds (X position) sprite: %d > %d."),
            t->name, sx+1, t->sx );
   if (sx >= t->sx)
      NLUA_ERROR( L, _("Texture '%s' trying to render out of bounds (Y position) sprite: %d > %d."),
            t->name, sy+1, t->sy );
#endif /* DEBUGGING */

   /* Translate as needed. */
   tx = (tx * t->sw + t->sw * (double)(sx)) / t->w;
   tw = tw * t->srw;
   if (tw < 0)
      tx -= tw;
   ty = (ty * t->sh + t->sh * (t->sy - (double)sy-1)) / t->h;
   th = th * t->srh;
   if (th < 0)
      ty -= th;

   gl_blitTexture( t, px, py, pw, ph, tx, ty, tw, th, col, angle );
   return 0;
}


/**
 * @brief
 */
static int gfxL_renderTexH( lua_State *L )
{
   glTexture *t;
   const glColour *col;
   LuaShader_t *shader;
   gl_Matrix4 *H;

   NLUA_CHECKRW(L);

   /* Parameters. */
   t     = luaL_checktex( L,1 );
   shader = luaL_checkshader( L,2 );
   H     = luaL_checktransform( L,3 );
   col   = luaL_optcolour(L,4,&cWhite);

   glUseProgram( shader->program );

   /* Set the vertex. */
   glEnableVertexAttribArray( shader->VertexPosition );
   gl_vboActivateAttribOffset( gl_squareVBO, shader->VertexPosition,
         0, 2, GL_FLOAT, 0 );

   if (shader->VertexTexCoord >= 0) {
      glEnableVertexAttribArray( shader->VertexTexCoord );
      gl_vboActivateAttribOffset( gl_squareVBO, shader->VertexTexCoord,
            0, 2, GL_FLOAT, 0 );
   }

   /* Set the texture. */
   glBindTexture( GL_TEXTURE_2D, t->texture );
   glUniform1i( shader->MainTex, 0 );

   /* Set shader uniforms. */
   gl_uniformColor( shader->ConstantColor, col );
   gl_Matrix4_Uniform( shader->ClipSpaceFromLocal, *H );

   /* Draw. */
   glDrawArrays( GL_TRIANGLE_STRIP, 0, 4 );

   /* Clear state. */
   glDisableVertexAttribArray( shader->VertexPosition );
   if (shader->VertexTexCoord >= 0)
      glDisableVertexAttribArray( shader->VertexTexCoord );

   /* anything failed? */
   gl_checkErr();

   glUseProgram(0);

   return 0;
}


/**
 * @brief Renders a rectangle.
 *
 * @usage gfx.renderRect( 10., 30,. 40., 40., col ) -- Renders a 40 side square at position 10,30 of colour col
 * @usage gfx.renderRect( 10., 30,. 40., 40., col, True ) -- Renders a 40 side empty square at position 10,30 of colour col
 *
 *    @luatparam number x X position to render at.
 *    @luatparam number y Y position to render at.
 *    @luatparam number w Width of the rectangle.
 *    @luatparam number h Height of the rectangle.
 *    @luatparam Colour col Colour to use.
 *    @luatparam[opt=false] boolean empty Whether or not it should be empty.
 * @luafunc renderRect
 */
static int gfxL_renderRect( lua_State *L )
{
   glColour *col;
   double x,y, w,h;
   int empty;

   NLUA_CHECKRW(L);

   /* Parse parameters. */
   x     = luaL_checknumber( L, 1 );
   y     = luaL_checknumber( L, 2 );
   w     = luaL_checknumber( L, 3 );
   h     = luaL_checknumber( L, 4 );
   col   = luaL_checkcolour( L, 5 );
   empty = lua_toboolean( L, 6 );

   /* Render. */
   if (empty)
      gl_renderRectEmpty( x, y, w, h, col );
   else
      gl_renderRect( x, y, w, h, col );

   return 0;
}


/**
 * @brief Renders a rectangle given a transformation matrix.
 *
 *    @luatparam Transform H Transformation matrix to use.
 *    @luatparam[opt=white] Colour col Colour to use.
 *    @luatparam[opt=false] boolean empty Whether or not it should be empty.
 * @luafunc renderRectH
 */
static int gfxL_renderRectH( lua_State *L )
{
   NLUA_CHECKRW(L);

   /* Parse parameters. */
   const gl_Matrix4 *H = luaL_checktransform(L,1);
   const glColour *col = luaL_optcolour(L,2,&cWhite);
   int empty = lua_toboolean(L,3);

   /* Render. */
   gl_renderRectH( H, col, !empty );

   return 0;
}


/**
 * @brief Renders a circle
 *
 *    @luatparam number x X position to render at.
 *    @luatparam number y Y position to render at.
 *    @luatparam number r Radius of the circle.
 *    @luatparam Colour col Colour to use.
 *    @luatparam[opt=false] boolean empty Whether or not it should be empty.
 * @luafunc renderCircle
 */
static int gfxL_renderCircle( lua_State *L )
{
   glColour *col;
   double x,y, r;
   int empty;

   NLUA_CHECKRW(L);

   /* Parse parameters. */
   x     = luaL_checknumber( L, 1 );
   y     = luaL_checknumber( L, 2 );
   r     = luaL_checknumber( L, 3 );
   col   = luaL_checkcolour( L, 4 );
   empty = lua_toboolean( L, 5 );

   /* Render. */
   gl_drawCircle( x, y, r, col, !empty );

   return 0;
}


/**
 * @brief Renders a circle given a transformation matrix.
 *
 *    @luatparam Transform H Transformation matrix to use.
 *    @luatparam[opt=white] Colour col Colour to use.
 *    @luatparam[opt=false] boolean empty Whether or not it should be empty.
 * @luafunc renderCircleH
 */
static int gfxL_renderCircleH( lua_State *L )
{
   NLUA_CHECKRW(L);

   /* Parse parameters. */
   const gl_Matrix4 *H = luaL_checktransform(L,1);
   const glColour *col = luaL_optcolour(L,2,&cWhite);
   int empty = lua_toboolean(L,3);

   /* Render. */
   gl_drawCircleH( H, col, !empty );

   return 0;
}


/**
 * @brief Gets the size of the font.
 *
 *    @luatparam boolean small Whether or not to get the size of the small font.
 *    @luatreturn[opt=false] The size in pixels of the font.
 * @luafunc fontSize
 */
static int gfxL_fontSize( lua_State *L )
{
   int small;
   small = lua_toboolean(L,1);
   lua_pushnumber( L, small ? gl_smallFont.h : gl_defFont.h );
   return 1;
}


/**
 * @brief Gets the size of the text to print.
 *
 * @usage len = gfx.printDim( nil, _("Hello World!") ) -- Length of string with normal font
 * @usage height = gfx.printDim( true, _([["Longer text"]]), 20 ) -- Dimensions of text block
 *
 *    @luatparam boolean small Whether or not to use the small font.
 *    @luatparam string str Text to calculate length of.
 *    @luatparam[opt] int width Optional parameter to indicate it is a block of text and to use this width.
 * @luafunc printDim
 */
static int gfxL_printDim( lua_State *L )
{
   const char *str;
   int width;
   glFont *font;

   /* Parse parameters. */
   font  = lua_toboolean(L,1) ? &gl_smallFont : &gl_defFont;
   str   = luaL_checkstring(L,2);
   width = luaL_optinteger(L,3,0);

   /* Print length. */
   if (width == 0)
      lua_pushnumber( L, gl_printWidthRaw( font, str ) );
   else
      lua_pushnumber( L, gl_printHeightRaw( font, width, str ) );
   return 1;
}


/**
 * @brief Gets the size of the text to print.
 *
 *    @luatparam font font Font to use.
 *    @luatparam string str Text to calculate length of.
 *    @luatparam[opt] int width Optional parameter to indicate it is a block of text and to use this width.
 * @luafunc printfDim
 */
static int gfxL_printfDim( lua_State *L )
{
   const char *str;
   int width;
   glFont *font;

   /* Parse parameters. */
   font  = luaL_checkfont(L,1);
   str   = luaL_checkstring(L,2);
   width = luaL_optinteger(L,3,0);

   /* Print length. */
   if (width == 0)
      lua_pushnumber( L, gl_printWidthRaw( font, str ) );
   else
      lua_pushnumber( L, gl_printHeightRaw( font, width, str ) );
   return 1;
}


/**
 * @brief Gets the wrap for text.
 *
 *    @luatparam font font Font to use.
 *    @luatparam string str Text to calculate length of.
 *    @luatparam int width Width to wrap at.
 *    @luatreturn table A table containing pairs of text and their width.
 *    @luatreturn number Maximum width of all the lines.
 * @luafunc printfWrap
 */
static int gfxL_printfWrap( lua_State *L )
{
   const char *s;
   int width, outw, maxw;
   glFont *font;
   int p, l, slen;
   int linenum;
   char *tmp;

   /* Parse parameters. */
   font  = luaL_checkfont(L,1);
   s     = luaL_checkstring(L,2);
   width = luaL_checkinteger(L,3);
   if (width < 0)
      NLUA_ERROR(L,_("width has to be a positive value."));

   /* Process output into table. */
   lua_newtable(L);
   tmp = strdup(s);
   slen = strlen(s);
   p = 0;
   linenum = 1;
   maxw = 0;
   do {
      int lp = p;
      if ((tmp[p] == ' ') || (tmp[p] == '\n'))
         p++;
      /* Don't handle tab for now. */
      if (tmp[p]=='\t')
         tmp[p] = ' ';
      l = gl_printWidthForText(font, &tmp[p], width, &outw );
      if (outw > maxw)
         maxw = outw;

      /* Create entry of form { string, width } in the table. */
      lua_pushnumber(L, linenum++);    /* t, n */
      lua_newtable(L);                 /* t, n, t */
      lua_pushinteger(L, 1);           /* t, n, t, 1 */
      lua_pushlstring(L, &tmp[p], l);  /* t, n, t, 1, s */
      lua_rawset(L, -3);               /* t, n, t */
      lua_pushinteger(L, 2);           /* t, n, t, 2 */
      lua_pushinteger(L, outw);        /* t, n, t, 2, n */
      lua_rawset(L, -3);               /* t, n, t */
      lua_rawset(L, -3);               /* t */

      p += l;
      if (lp==p)
         break;
   } while (p < slen);

   /* Push max width. */
   lua_pushinteger(L, maxw);

   free( tmp );
   return 2;
}


/**
 * @brief Clears the saved internal colour state.
 * @luafunc printRestoreClear
 */
static int gfxL_printRestoreClear( lua_State *L )
{
   (void) L;
   gl_printRestoreClear();
   return 0;
}


/**
 * @brief Restores the last saved internal colour state.
 * @luafunc printRestoreLast
 */
static int gfxL_printRestoreLast( lua_State *L )
{
   (void) L;
   gl_printRestoreLast();
   return 0;
}


/**
 * @brief Prints text on the screen using a font.
 *
 * @usage gfx.printf( font, _("Hello World!"), 50, 50, colour.new("Red") ) -- Displays text in red at 50,50.
 *
 *    @luatparam font font Font to use.
 *    @luatparam string str String to print.
 *    @luatparam number x X position to print at.
 *    @luatparam number y Y position to print at.
 *    @luatparam Colour col Colour to print text.
 *    @luatparam[opt] int max Maximum width to render up to.
 *    @luatparam[opt] boolean center Whether or not to center it.
 * @luafunc printf
 */
static int gfxL_printf( lua_State *L )
{
   glFont *font;
   const char *str;
   double x, y;
   glColour *col;
   int max, mid;

   NLUA_CHECKRW(L);

   /* Parse parameters. */
   font  = luaL_checkfont(L,1);
   str   = luaL_checkstring(L,2);
   x     = luaL_checknumber(L,3);
   y     = luaL_checknumber(L,4);
   col   = luaL_checkcolour(L,5);
   max   = luaL_optinteger(L,6,0);
   mid   = lua_toboolean(L,7);

   /* Render. */
   if (mid)
      gl_printMidRaw( font, max, x, y, col, 0., str );
   else if (max > 0)
      gl_printMaxRaw( font, max, x, y, col, 0., str );
   else
      gl_printRaw( font, x, y, col, 0., str );
   return 0;
}


/**
 * @brief Prints text on the screen using a font with a transformation matirx.
 *
 *    @luatparam Transform H transformation matrix to use.
 *    @luatparam font font Font to use.
 *    @luatparam string str String to print.
 *    @luatparam Colour col Colour to print text.
 * @luafunc printH
 */
static int gfxL_printH( lua_State *L )
{
   const gl_Matrix4 *H;
   glFont *font;
   const char *str;
   const glColour *col;

   NLUA_CHECKRW(L);

   /* Parse parameters. */
   H     = luaL_checktransform(L,1);
   font  = luaL_checkfont(L,2);
   str   = luaL_checkstring(L,3);
   col   = luaL_optcolour(L,4,&cWhite);

   /* Render. */
   gl_printRawH( font, H, col, 0., str );
   return 0;
}


/**
 * @brief Prints text on the screen.
 *
 * @usage gfx.print( nil, _("Hello World!"), 50, 50, colour.new("Red") ) -- Displays text in red at 50,50.
 * @usage gfx.print( true, _("Hello World!"), 50, 50, col, 100 ) -- Displays text to a maximum of 100 pixels wide.
 * @usage gfx.print( true, str, 50, 50, col, 100, true ) -- Displays centered text to a maximum of 100 pixels.
 *
 *    @luatparam boolean small Whether or not to use a small font.
 *    @luatparam string str String to print.
 *    @luatparam number x X position to print at.
 *    @luatparam number y Y position to print at.
 *    @luatparam Colour col Colour to print text.
 *    @luatparam[opt] int max Maximum width to render up to.
 *    @luatparam[opt] boolean center Whether or not to center it.
 * @luafunc print
 */
static int gfxL_print( lua_State *L )
{
   glFont *font;
   const char *str;
   double x, y;
   glColour *col;
   int max, mid;

   NLUA_CHECKRW(L);

   /* Parse parameters. */
   font  = lua_toboolean(L,1) ? &gl_smallFont : &gl_defFont;
   str   = luaL_checkstring(L,2);
   x     = luaL_checknumber(L,3);
   y     = luaL_checknumber(L,4);
   col   = luaL_checkcolour(L,5);
   max   = luaL_optinteger(L,6,0);
   mid   = lua_toboolean(L,7);

   /* Render. */
   if (mid)
      gl_printMidRaw( font, max, x, y, col, -1., str );
   else if (max > 0)
      gl_printMaxRaw( font, max, x, y, col, -1., str );
   else
      gl_printRaw( font, x, y, col, -1., str );
   return 0;
}


/**
 * @brief Prints a block of text on the screen.
 *
 * @usage gfx.printText( true, 100, 50, 50, 100, 100, col ) -- Displays a 100x100 block of text
 *
 *    @luatparam boolean small Whether or not to use a small font.
 *    @luatparam string str String to print.
 *    @luatparam number x X position to print at.
 *    @luatparam number y Y position to print at.
 *    @luatparam number w Width of the block of text.
 *    @luatparam number h Height of the block of text.
 *    @luatparam Colour col Colour to print text.
 *    @luatparam line_height Height of each line to print.
 * @luafunc printText
 */
static int gfxL_printText( lua_State *L )
{
   glFont *font;
   const char *str;
   int w, h, lh;
   double x, y;
   glColour *col;

   NLUA_CHECKRW(L);

   /* Parse parameters. */
   font  = lua_toboolean(L,1) ? &gl_smallFont : &gl_defFont;
   str   = luaL_checkstring(L,2);
   x     = luaL_checknumber(L,3);
   y     = luaL_checknumber(L,4);
   w     = luaL_checkinteger(L,5);
   h     = luaL_checkinteger(L,6);
   col   = luaL_checkcolour(L,7);
   lh    = luaL_optinteger(L,8,0);

   /* Render. */
   gl_printTextRaw( font, w, h, x, y, lh, col, -1., str );

   return 0;
}

