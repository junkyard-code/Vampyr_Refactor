unit ugfx_fb;
{$mode objfpc}{$H+}

{* 
  Framebuffer Graphics Unit
  -----------------------
  This unit provides a simple framebuffer interface for rendering graphics
  using SDL2. It includes basic drawing functions and dirty rectangle
  optimization to minimize screen updates.
  
  Key Features:
  - Simple pixel manipulation
  - Dirty rectangle tracking for optimized rendering
  - Double buffered display
  
  Note: All coordinates are 0-based (top-left origin)
*}

interface
uses 
  {* SDL2 - Used for hardware-accelerated rendering and window management *}
  SDL2,
  Font6x8Data,  // Font 6x8 font
  Font8x8;

// Basic text config for the message line
const
  FONT6X8_FIRST = 32;  // SPACE
  FONT6X8_LAST  = 90;  // 'Z'
  FONT6X8_COLS = 6;

  // Non-square “pixel” replication for the 6×8 font
  FONT_X_REP = 3;   // horizontal repeats per source pixel (try 2)
  FONT_Y_REP = 4;   // vertical repeats per source pixel (try 4)
  FONT_GLYPH_COLS = 5;  // DrawChar6x8_5w uses 5 visible columns from the 6×8 data
  FONT_TRACK_SP   = 1;  // 1 source-pixel column of tracking between glyphs


type
  // UI Region identifiers
  TRegionID = (riMapView, riStatusArea, riMessageArea);

function GfxInit(W,H,Scale: Integer): Boolean;
procedure GfxQuit;
procedure ClearFB(Color: LongWord);
procedure PutPixel(const x, y: Integer; const c: LongWord); inline;
procedure Present;
procedure BlitText6x8(const S: AnsiString; X, Y: Integer; Color: LongWord; Scale: Integer);
procedure FillRect(x, y, w, h: Integer; color: LongWord);
procedure DarkenScreen(Amount: Byte);  // Amount: 0 (no darkening) to 255 (fully black)

var
  FB: array of LongWord;
  ScreenW, ScreenH: Integer;

implementation

uses
  TypInfo,  // For GetEnumName and TypeInfo
  SysUtils; // For FillChar


var
  // SDL2 handles
  Win: PSDL_Window = nil;    // Main application window
  Ren: PSDL_Renderer = nil;  // Hardware-accelerated 2D renderer
  Tex: PSDL_Texture = nil;   // Texture that holds our framebuffer

//************************************************ Fill DWord ************************************************
procedure FillDWord(var Dest; Count: SizeInt; Value: LongWord);
var
  I: SizeInt;
  P: PLongWord;
begin
  P := @Dest;
  for I := 0 to Count - 1 do
  begin
    P^ := Value;
    Inc(P);
  end;
end;

//************************************************ Fill Rect ************************************************
// Draw a filled rectangle into the framebuffer.
// Parameters: x,y = top-left corner; w,h = width and height in pixels;
//             color = ARGB (0xAARRGGBB).
procedure FillRect(x, y, w, h: Integer; color: LongWord);
var
  yy, xx, startIdx: Integer;
begin
  if (w <= 0) or (h <= 0) then Exit;

  // Clip against screen bounds
  if x < 0 then begin w := w + x; x := 0; end;
  if y < 0 then begin h := h + y; y := 0; end;
  if (x >= ScreenW) or (y >= ScreenH) then Exit;
  if x + w > ScreenW then w := ScreenW - x;
  if y + h > ScreenH then h := ScreenH - y;

  // Row by row fill
  for yy := 0 to h - 1 do
  begin
    startIdx := (y + yy) * ScreenW + x;
    for xx := 0 to w - 1 do
      FB[startIdx + xx] := color;
  end;
end;


//************************************************ GfxInit ************************************************
function GfxInit(W, H, Scale: Integer): Boolean;
begin
  Result := False;

  if Scale < 1 then Scale := 1;

  // Init SDL (video only)
  if SDL_Init(SDL_INIT_VIDEO) < 0 then
  begin
    WriteLn('SDL_Init failed: ', SDL_GetError);
    Exit;
  end;

  // Hint: linear scaling (optional; ignore failure)
{$IFDEF ENABLE_SDL_HINTS}
  SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, 'nearest');
{$ENDIF}


  // Window
  Win := SDL_CreateWindow(
    'Vampyr Refactor',
    SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
    W * Scale, H * Scale,
    SDL_WINDOW_SHOWN
  );
  if Win = nil then
  begin
    WriteLn('SDL_CreateWindow failed: ', SDL_GetError);
    Exit;
  end;

  // Renderer (vsync on; change flags if you want immediate mode)
  Ren := SDL_CreateRenderer(Win, -1, SDL_RENDERER_ACCELERATED or SDL_RENDERER_PRESENTVSYNC);
  if Ren = nil then
  begin
    WriteLn('SDL_CreateRenderer failed: ', SDL_GetError);
    Exit;
  end;

  // Texture (streaming ARGB8888 for our ARGB32 FB)
Tex := SDL_CreateTexture(
         Ren,
         SDL_PIXELFORMAT_ARGB8888,
         LongInt(SDL_TEXTUREACCESS_STREAMING),  // <-- cast avoids enum mismatch
         W, H
       );
  if Tex = nil then
  begin
    WriteLn('SDL_CreateTexture failed: ', SDL_GetError);
    Exit;
  end;

  // Logical dimensions
  ScreenW := W;
  ScreenH := H;

  // Render scale (pixel-doubling style)
  SDL_RenderSetScale(Ren, Scale, Scale);

  // Allocate framebuffer and clear to opaque black
  SetLength(FB, W * H);
  if Length(FB) <> W * H then
  begin
    WriteLn('Framebuffer allocation failed.');
    Exit;
  end;
  FillDWord(FB[0], W * H, $FF000000);

  // Clear the renderer once so the first Present has a clean base
  SDL_SetRenderDrawColor(Ren, 0, 0, 0, 255);
  SDL_RenderClear(Ren);
  SDL_RenderPresent(Ren);

  Result := True;
end;


//************************************************ GfxQuit ************************************************

procedure GfxQuit;

begin
  // Clean up SDL resources in reverse order of creation
  if Tex <> nil then 
  begin
    SDL_DestroyTexture(Tex);
    Tex := nil;
  end;
  
  if Ren <> nil then 
  begin
    SDL_DestroyRenderer(Ren);
    Ren := nil;
  end;
  
  if Win <> nil then 
  begin
    SDL_DestroyWindow(Win);
    Win := nil;
  end;
  
  // Shut down SDL and clean up
  SDL_Quit;
  
  // Reset framebuffer and screen dimensions
  FB := nil;
  ScreenW := 0;
  ScreenH := 0;
  
end;


//************************************************ Clear Framebuffer ************************************************

{
  Fills the entire framebuffer with the specified color and marks the entire screen as dirty.
  
  Parameters:
    Color: 32-bit ARGB color value (0xAARRGGBB format)
}
procedure ClearFB(Color: LongWord);
var 
  i: SizeInt;

begin
  // Fill the framebuffer with the specified color
  for i := 0 to High(FB) do 
    FB[i] := Color;
    
end;



//*************************************************** Put Pixel **************************************************
// Draws a single pixel at (x,y) in ARGB (0xAARRGGBB). No dirty tracking.
// Coordinates are clipped to the screen bounds.
procedure PutPixel(const x, y: Integer; const c: LongWord); inline;
begin
  // Use unsigned compares for fast in-range checks
  if (Cardinal(x) < Cardinal(ScreenW)) and (Cardinal(y) < Cardinal(ScreenH)) then
    FB[y * ScreenW + x] := c;
end;


// ===== Minimal 6x8 monospace font + text helpers ============================
// Each glyph is 6 px wide by 8 px tall. Bits LSB->MSB are left->right.
// We support SPACE, digits, A..Z, and a few punctuations used by messages.



//********************************************* Font Row 6x8 *********************************************
function FontRow6x8(ch: Char; row: Integer): Byte; inline;
var c: Integer;
begin
  if (row < 0) or (row > 7) then Exit(0);
  c := Ord(ch);
  // let Font6x8Data handle full ASCII 32..126
  if (c < Font6x8Data.FONT6X8_FIRST) or (c > Font6x8Data.FONT6X8_LAST) then Exit(0);
  Result := Font6x8Data.FONT6X8[c, row];
end;

//********************************************* Draw Char 6x8 *********************************************
//procedure DrawChar6x8(x, y: Integer; ch: Char; color: LongWord; scale: Integer);
//var r, b, cx, cy: Integer; rowBits: Byte;
//begin
//  for r := 0 to 7 do
//  begin
//    rowBits := FontRow6x8(ch, r);
//    for b := 0 to 5 do
//      if (rowBits and (1 shl (5 - b))) <> 0 then      // MSB-left (note 5-b)
//        for cy := 0 to scale - 1 do
//          for cx := 0 to scale - 1 do
//            PutPixel(x + b*scale + cx, y + r*scale + cy, color);
//  end;
//end;


// Draw a single 5×8 glyph, sampling bits 5..1 (cropping the rightmost column bit0)
procedure DrawChar6x8_5w(x, y: Integer; c: Char; color: LongWord; scale: Integer);
var
  cx, cy, b, r: Integer;
  chRow: Byte;
begin
  for r := 0 to 7 do
  begin
    chRow := Font6x8[Ord(c), r];
    for b := 0 to 5 do
      if (chRow and (1 shl (5 - b))) <> 0 then
        for cy := 0 to FONT_Y_REP - 1 do
          for cx := 0 to FONT_X_REP - 1 do
            PutPixel(x + b * FONT_X_REP + cx, y + r * FONT_Y_REP + cy, color);
  end;
end;




//********************************************* Draw Char 8x8 *********************************************
// ---- 8x8 character drawing using CP437 bitmap if available ----
{procedure DrawChar8x8(X, Y: Integer; Ch: Char; Color: LongWord; Scale: Integer);
var
  row, col, sx, sy: Integer;
  bits: Byte;
begin
  if Font8x8.FONT8_LOADED then
  begin
    for row := 0 to 7 do
    begin
      bits := Font8x8Row(Ord(Ch), row);        // bits 7..0 == left..right
      for col := 0 to 7 do
        if (bits and (1 shl (7 - col))) <> 0 then
          for sy := 0 to Scale - 1 do
            for sx := 0 to Scale - 1 do
              PutPixel(X + col*Scale + sx, Y + row*Scale + sy, Color);
    end;
  end
  else
  begin
    // Fallback to your 6x8 raster if CP437 not loaded
    DrawChar6x8(X, Y, Ch, Color, Scale);
  end;
end;}


//********************************************* Blit Text 6x8 *********************************************
// Draw a full line using 5×8 glyphs with 1px spacing (scaled)
procedure BlitText6x8(const S: AnsiString; X, Y: Integer; Color: LongWord; Scale: Integer);
var
  i, advance: Integer;
begin
  // Ignore "Scale" for width; use our non-square replication instead
  advance := (FONT_GLYPH_COLS + FONT_TRACK_SP) * FONT_X_REP;
  for i := 1 to Length(S) do
  begin
    DrawChar6x8_5w(X, Y, S[i], Color, Scale);  // Scale can be ignored inside
    X := X + advance;
  end;
end;


//********************************************* Blit Text *********************************************
// ---- Text blit (single line; no wrapping) ----
{procedure BlitText(const S: AnsiString; X, Y, Scale: Integer; Color: LongWord);
var
  i, cx: Integer;
begin
  cx := X;
  for i := 1 to Length(S) do
  begin
    case S[i] of
      #10: begin Y := Y + 8 * Scale; cx := X; end; // optional newline
      #13: ; // ignore CR
    else
      DrawChar8x8(cx, Y, S[i], Color, Scale);
      cx := cx + 8 * Scale;
    end;
  end;
end;}


//**************************************************** Present ***************************************************
procedure Present;
begin
  // Upload the entire framebuffer to the texture
  if SDL_UpdateTexture(Tex, nil, @FB[0], ScreenW * SizeOf(LongWord)) <> 0 then
  begin
    WriteLn('SDL_UpdateTexture failed: ', SDL_GetError);
    Exit;
  end;

  // Render the full texture to the window and present
  SDL_RenderClear(Ren);
  SDL_RenderCopy(Ren, Tex, nil, nil);
  SDL_RenderPresent(Ren);
end;

// ********************************************* Darken Screen *********************************************
procedure DarkenScreen(Amount: Byte);
var
  r: TSDL_Rect;
begin
  if Ren = nil then Exit;
  
  // Enable blending
  SDL_SetRenderDrawBlendMode(Ren, SDL_BLENDMODE_BLEND);
  SDL_SetRenderDrawColor(Ren, 0, 0, 0, Amount);
  
  // Fill the screen with semi-transparent black
  r.x := 0; r.y := 0; 
  r.w := ScreenW; r.h := ScreenH;
  SDL_RenderFillRect(Ren, @r);
  
  // Update the screen
  SDL_RenderPresent(Ren);
end;

end.
