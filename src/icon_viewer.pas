program icon_viewer;

{$mode objfpc}{$H+}

uses
  SDL2, SysUtils, data_loaders, Types, Classes;

const
  TILE_W = 18;
  TILE_H = 18;
  COLS = 20;
  SCALE = 4;
  DIGIT_W = 3;
  DIGIT_H = 5;

  DIGITS: array[0..9,0..DIGIT_H-1] of string[3] = (
    ('111','101','101','101','111'), // 0
    ('010','110','010','010','111'), // 1
    ('111','001','111','100','111'), // 2
    ('111','001','111','001','111'), // 3
    ('101','101','111','001','001'), // 4
    ('111','100','111','001','111'), // 5
    ('111','100','111','101','111'), // 6
    ('111','001','001','001','001'), // 7
    ('111','101','111','101','111'), // 8
    ('111','101','111','001','111')  // 9
  );

type
  TTileSet = record
    Count: Integer;
    Atlas: PSDL_Texture;
    AtlasCols: Integer;
    AtlasRows: Integer;
  end;

var
  Window: PSDL_Window;
  SDLRenderer: PSDL_Renderer;
  Event: TSDL_Event;
  Running: Boolean;
  pixels: PUInt32;
  tileCount: Integer;
  tiles: TTileSet;
  i, dx, dy: Integer;

procedure FreeTileSet(var t: TTileSet);
begin
  if t.Atlas <> nil then
  begin
    SDL_DestroyTexture(t.Atlas);
    t.Atlas := nil;
  end;
  t.Count := 0;
end;

procedure BuildTileTexture(renderer: PSDL_Renderer; var tiles: TTileSet;
                          pixels: PUInt32; tilesCount: Integer);
const
  COLS = 20;
var
  rows: Integer;
  atlasW, atlasH: Integer;
  surf: PSDL_Surface;
  pitch: Integer;
  dst: PUInt32;
  tile, tx, ty, x, y: Integer;
  src: PUInt32;
begin
  tiles.Count := tilesCount;
  rows := (tilesCount + COLS - 1) div COLS;
  tiles.AtlasCols := COLS;
  tiles.AtlasRows := rows;

  atlasW := TILE_W * COLS;
  atlasH := TILE_H * rows;
  surf := SDL_CreateRGBSurface(0, atlasW, atlasH, 32,
                               $00FF0000, $0000FF00, $000000FF, $FF000000);
  if surf = nil then Exit;
  SDL_LockSurface(surf);
  pitch := surf^.pitch div 4;
  dst := PUInt32(surf^.pixels);

  for tile := 0 to tilesCount-1 do
  begin
    tx := tile mod COLS;
    ty := tile div COLS;
    for y := 0 to TILE_H-1 do
      for x := 0 to TILE_W-1 do
      begin
        src := pixels + (tile * TILE_W * TILE_H) + (y * TILE_W + x);
        dst[(ty*TILE_H + y)*pitch + (tx*TILE_W + x)] := src^;
      end;
  end;

  SDL_UnlockSurface(surf);
  tiles.Atlas := SDL_CreateTextureFromSurface(renderer, surf);
  if surf <> nil then
    SDL_FreeSurface(surf);
end;

procedure DrawTile(renderer: PSDL_Renderer; const tiles: TTileSet; tileIndex: Integer; x, y: Integer);
var
  srcRect, dstRect: TSDL_Rect;
  cols: Integer;
  tw, th: Integer;
begin
  if (renderer = nil) or (tiles.Atlas = nil) or (tileIndex < 0) or (tileIndex >= tiles.Count) then Exit;

  cols := tiles.AtlasCols;
  tw := TILE_W * SCALE;
  th := TILE_H * SCALE;

  srcRect.x := (tileIndex mod cols) * TILE_W;
  srcRect.y := (tileIndex div cols) * TILE_H;
  srcRect.w := TILE_W;
  srcRect.h := TILE_H;

  dstRect.x := x;
  dstRect.y := y;
  dstRect.w := tw;
  dstRect.h := th;

  SDL_RenderCopy(renderer, tiles.Atlas, @srcRect, @dstRect);
end;

procedure DrawDigit(x, y, d, scale: integer);
var
  r, c: integer;
  row: ShortString;
  ch: char;
  rx, ry: integer;
begin
  if (d < 0) or (d > 9) then exit;
  for r := 0 to DIGIT_H-1 do
  begin
    row := DIGITS[d, r];
    for c := 0 to DIGIT_W-1 do
    begin
      ch := row[c+1];
      if ch = '1' then
      begin
        for ry := 0 to scale-1 do
          for rx := 0 to scale-1 do
            SDL_RenderDrawPoint(SDLRenderer, x + c*scale + rx, y + r*scale + ry);
      end;
    end;
  end;
end;

procedure DrawNumber(x, y, n, scale: integer);
var
  s: string;
  i, dx: integer;
begin
  s := IntToStr(n);
  dx := 0;
  for i := 1 to Length(s) do
  begin
    DrawDigit(x + dx, y, Ord(s[i]) - Ord('0'), scale);
    dx := dx + (DIGIT_W + 1) * scale;
  end;
end;

begin
  if ParamCount < 1 then
  begin
    writeln('Usage: icon_viewer.exe <path_to_con_file>');
    halt(1);
  end;

  if not LoadCON(ParamStr(1), pixels, tileCount) then
  begin
    writeln('Failed to load ', ParamStr(1));
    halt(1);
  end;

  if SDL_Init(SDL_INIT_VIDEO) <> 0 then halt(1);

  Window := SDL_CreateWindow(PAnsiChar('Icon Viewer: ' + ParamStr(1)),
    SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
    TILE_W * SCALE * COLS, TILE_H * SCALE * ((tileCount + COLS -1) div COLS),
    SDL_WINDOW_SHOWN);
  if Window = nil then halt(1);

  SDLRenderer := SDL_CreateRenderer(Window, -1, SDL_RENDERER_ACCELERATED);
  if SDLRenderer = nil then halt(1);

  BuildTileTexture(SDLRenderer, tiles, pixels, tileCount);
  FreeMem(pixels);

  Running := True;
  while Running do
  begin
    while SDL_PollEvent(@Event) = 1 do
    begin
      if Event.type_ = SDL_QUIT then Running := False;
    end;

    SDL_SetRenderDrawColor(SDLRenderer, 220, 220, 220, 255);
    SDL_RenderClear(SDLRenderer);

    for i := 0 to tileCount - 1 do
    begin
        dx := (i mod COLS) * TILE_W * SCALE;
        dy := (i div COLS) * TILE_H * SCALE;
        DrawTile(SDLRenderer, tiles, i, dx, dy);
        DrawNumber(dx + 2, dy + 2, i, 2);
    end;

    SDL_RenderPresent(SDLRenderer);
    SDL_Delay(100);
  end;

  FreeTileSet(tiles);
  SDL_DestroyRenderer(SDLRenderer);
  SDL_DestroyWindow(Window);
  SDL_Quit;
end.
