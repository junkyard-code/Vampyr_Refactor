unit uGfx;
{$mode objfpc}{$H+}

interface

uses
  SDL2, SysUtils;

const
  SCREEN_WIDTH = 640;  // Adjust to your game's resolution
  SCREEN_HEIGHT = 480;
  SCREEN_SCALE = 2;    // Integer scaling for pixel art

type
  TColor = UInt32;  // ARGB format
  
var
  FB: array of TColor;  // Our software framebuffer
  Palette: array[0..255] of TColor;  // 256-color palette

// Initialization and cleanup
function GfxInit: Boolean;
procedure GfxQuit;

// Basic drawing primitives
procedure Clear(Color: TColor);
procedure Present;
procedure PutPixel(X, Y: Integer; Color: TColor); inline;
procedure HLine(X1, X2, Y: Integer; Color: TColor);
procedure VLine(X, Y1, Y2: Integer; Color: TColor);
procedure FillRect(X, Y, W, H: Integer; Color: TColor);
procedure BlitSprite(X, Y, W, H: Integer; Sprite: array of Byte; TransparentIdx: Integer = -1);

implementation

var
  Window: PSDL_Window = nil;
  Renderer: PSDL_Renderer = nil;
  Texture: PSDL_Texture = nil;

function GfxInit: Boolean;
begin
  // Initialize SDL
  if SDL_Init(SDL_INIT_VIDEO) <> 0 then
    Exit(False);

  // Create window and renderer
  Window := SDL_CreateWindow('Vampyr Refactor',
    SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
    SCREEN_WIDTH * SCREEN_SCALE, SCREEN_HEIGHT * SCREEN_SCALE,
    SDL_WINDOW_SHOWN);
    
  if Window = nil then
    Exit(False);
    
  Renderer := SDL_CreateRenderer(Window, -1, 
    SDL_RENDERER_ACCELERATED or SDL_RENDERER_PRESENTVSYNC);
    
  if Renderer = nil then
  begin
    SDL_DestroyWindow(Window);
    Exit(False);
  end;
  
  // Create streaming texture
  Texture := SDL_CreateTexture(Renderer,
    SDL_PIXELFORMAT_ARGB8888,
    SDL_TEXTUREACCESS_STREAMING,
    SCREEN_WIDTH, SCREEN_HEIGHT);
    
  if Texture = nil then
  begin
    SDL_DestroyRenderer(Renderer);
    SDL_DestroyWindow(Window);
    Exit(False);
  end;
  
  // Initialize framebuffer
  SetLength(FB, SCREEN_WIDTH * SCREEN_HEIGHT);
  
  // Set default palette (grayscale)
  for var I := 0 to 255 do
    Palette[I] := $FF000000 or (I shl 16) or (I shl 8) or I;
    
  Result := True;
end;

procedure GfxQuit;
begin
  if Assigned(Texture) then
    SDL_DestroyTexture(Texture);
  if Assigned(Renderer) then
    SDL_DestroyRenderer(Renderer);
  if Assigned(Window) then
    SDL_DestroyWindow(Window);
    
  SDL_Quit;
  FB := nil;
end;

procedure Clear(Color: TColor);
var
  I: Integer;
begin
  for I := 0 to High(FB) do
    FB[I] := Color;
end;

procedure Present;
var
  Pitch: Integer;
  Pixels: Pointer;
begin
  // Lock texture for direct pixel access
  if SDL_LockTexture(Texture, nil, @Pixels, @Pitch) = 0 then
  try
    // Copy our framebuffer to the texture
    Move(FB[0], Pixels^, SCREEN_WIDTH * SCREEN_HEIGHT * SizeOf(TColor));
  finally
    SDL_UnlockTexture(Texture);
  end;
  
  // Render the texture to the screen
  SDL_RenderClear(Renderer);
  SDL_RenderCopy(Renderer, Texture, nil, nil);
  SDL_RenderPresent(Renderer);
end;

procedure PutPixel(X, Y: Integer; Color: TColor);
begin
  if (X >= 0) and (X < SCREEN_WIDTH) and
     (Y >= 0) and (Y < SCREEN_HEIGHT) then
    FB[Y * SCREEN_WIDTH + X] := Color;
end;

procedure HLine(X1, X2, Y: Integer; Color: TColor);
var
  X: Integer;
begin
  if (Y < 0) or (Y >= SCREEN_HEIGHT) then Exit;
  if X1 > X2 then
  begin
    X := X1; X1 := X2; X2 := X;
  end;
  
  X1 := Max(0, X1);
  X2 := Min(SCREEN_WIDTH - 1, X2);
  
  for X := X1 to X2 do
    FB[Y * SCREEN_WIDTH + X] := Color;
end;

procedure VLine(X, Y1, Y2: Integer; Color: TColor);
var
  Y: Integer;
begin
  if (X < 0) or (X >= SCREEN_WIDTH) then Exit;
  if Y1 > Y2 then
  begin
    Y := Y1; Y1 := Y2; Y2 := Y;
  end;
  
  Y1 := Max(0, Y1);
  Y2 := Min(SCREEN_HEIGHT - 1, Y2);
  
  for Y := Y1 to Y2 do
    FB[Y * SCREEN_WIDTH + X] := Color;
end;

procedure FillRect(X, Y, W, H: Integer; Color: TColor);
var
  I, J: Integer;
begin
  for J := Y to Y + H - 1 do
    for I := X to X + W - 1 do
      if (I >= 0) and (I < SCREEN_WIDTH) and
         (J >= 0) and (J < SCREEN_HEIGHT) then
        FB[J * SCREEN_WIDTH + I] := Color;
end;

procedure BlitSprite(X, Y, W, H: Integer; Sprite: array of Byte; TransparentIdx: Integer = -1);
var
  SrcX, SrcY, DstX, DstY, SrcIdx: Integer;
  Color: TColor;
begin
  for SrcY := 0 to H - 1 do
  begin
    DstY := Y + SrcY;
    if (DstY < 0) or (DstY >= SCREEN_HEIGHT) then Continue;
    
    for SrcX := 0 to W - 1 do
    begin
      DstX := X + SrcX;
      if (DstX < 0) or (DstX >= SCREEN_WIDTH) then Continue;
      
      SrcIdx := SrcY * W + SrcX;
      if (SrcIdx < 0) or (SrcIdx > High(Sprite)) then Continue;
      
      if (TransparentIdx = -1) or (Sprite[SrcIdx] <> TransparentIdx) then
      begin
        Color := Palette[Sprite[SrcIdx] and $FF];
        FB[DstY * SCREEN_WIDTH + DstX] := Color;
      end;
    end;
  end;
end;

end.
