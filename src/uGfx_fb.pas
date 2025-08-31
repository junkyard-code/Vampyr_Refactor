unit ugfx_fb;
{$mode objfpc}{$H+}

interface
uses SDL2;

function GfxInit(W,H,Scale: Integer): Boolean;
procedure GfxQuit;
procedure ClearFB(Color: LongWord);
procedure PutPixel(x,y: Integer; c: LongWord); inline;
procedure Present;

var
  FB: array of LongWord;
  ScreenW, ScreenH: Integer;

implementation

var
  Win: PSDL_Window = nil;
  Ren: PSDL_Renderer = nil;
  Tex: PSDL_Texture = nil;

function GfxInit(W,H,Scale: Integer): Boolean;
const
  SDL_TEXTUREACCESS_STREAMING_INT = 1; // some headers want integer
begin
  ScreenW := W; ScreenH := H;
  SetLength(FB, ScreenW*ScreenH);
  if SDL_Init(SDL_INIT_VIDEO) <> 0 then exit(False);
  Win := SDL_CreateWindow('Vampyr', SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                          W*Scale, H*Scale, SDL_WINDOW_SHOWN);
  Ren := SDL_CreateRenderer(Win, -1, SDL_RENDERER_ACCELERATED or SDL_RENDERER_PRESENTVSYNC);
  Tex := SDL_CreateTexture(Ren, SDL_PIXELFORMAT_ARGB8888,
                           SDL_TEXTUREACCESS_STREAMING_INT, W, H);
  Result := (Win<>nil) and (Ren<>nil) and (Tex<>nil);
end;

procedure GfxQuit;
begin
  if Tex<>nil then SDL_DestroyTexture(Tex);
  if Ren<>nil then SDL_DestroyRenderer(Ren);
  if Win<>nil then SDL_DestroyWindow(Win);
  SDL_Quit;
  FB := nil;
  ScreenW := 0; ScreenH := 0;
end;

procedure ClearFB(Color: LongWord);
var i: SizeInt;
begin
  for i := 0 to High(FB) do FB[i] := Color;
end;

procedure PutPixel(x,y: Integer; c: LongWord); inline;
begin
  if (UInt32(x) < UInt32(ScreenW)) and (UInt32(y) < UInt32(ScreenH)) then
    FB[y*ScreenW + x] := c;
end;

procedure Present;
var pixels: Pointer; pitch, y: Integer;
begin
  if SDL_LockTexture(Tex, nil, @pixels, @pitch)=0 then
  begin
    for y:=0 to ScreenH-1 do
      Move(FB[y*ScreenW], PByte(pixels)[y*pitch], ScreenW*SizeOf(LongWord));
    SDL_UnlockTexture(Tex);
  end;
  SDL_RenderClear(Ren);
  SDL_RenderCopy(Ren, Tex, nil, nil);
  SDL_RenderPresent(Ren);
end;

end.
