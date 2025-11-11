program after_viewer;

{$mode objfpc}{$H+}

uses
  SysUtils, Math, Classes,
  SDL2,
  uGfx_fb;   // reuse your framebuffer, PutPixel, Present, etc.

const
  SCREEN_WIDTH  = 1280;
  SCREEN_HEIGHT = 600;

  DATA_DIR      = 'data';
  CON_FILE      = 'AFTER.CON';

  // draw size per tile on screen
  TILE_DRAW_W   = 36;
  TILE_DRAW_H   = 18;

  // grid layout
  COLS          = 16;  // tiles per row
  MARGIN_X      = 8;
  MARGIN_Y      = 8;
  GAP_X         = 4;
  GAP_Y         = 4;

type
  // One decoded ARGB tile (18x18)
  TTileARGB  = array[0..(18*18)-1] of LongWord;
  PTileARGB  = ^TTileARGB;
  TTileArray = array of TTileARGB;

  // simple viewport/scroller
  TView = record
    Rows: Integer;     // total rows in grid
    ScrollY: Integer;  // first visible row
  end;

var
  Tiles   : TTileArray;
  V       : TView;
  Running : Boolean = True;
  Event   : TSDL_Event;

{------------------------- minimal EGA palette -------------------------}

function EGAtoARGB(const idx: Byte): LongWord; inline;
const
  // 0..15 classic EGA. Index 0 treated as transparent? For viewer we’ll show it.
  // Format ARGB = $AARRGGBB
  P: array[0..15] of LongWord = (
    $FF000000, // 0 black
    $FF0000AA, // 1 Blue
    $FF00AA00, // 2 Green
    $FF00AAAA, // 3 Cyan
    $FFAA0000, // 4 Red
    $FFAA00AA, // 5 Magenta
    $FFAA5500, // 6 Brown
    $FFAAAAAA, // 7 Light Gray
    $FF555555, // 8 Dark Gray
    $FF5555FF, // 9 Light Blue
    $FF55FF55, // 10 Light Green
    $FF55FFFF, // 11 Light Cyan
    $FFFF5555, // 12 Light Red
    $FFFF55FF, // 13 Light Magenta
    $FFFFFF55, // 14 Yellow
    $FFFFFFFF  // 15 White
  );
begin
  Result := P[idx and $0F];
end;

{------------------------- file helpers -------------------------}

function ReadAllBytes(const FileName: string; out bytes: TBytes): Boolean;
var
  fs: TFileStream;
begin
  Result := False;
  SetLength(bytes, 0);
  if not FileExists(FileName) then Exit(False);
  fs := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    SetLength(bytes, fs.Size);
    if Length(bytes) > 0 then
      fs.ReadBuffer(bytes[0], Length(bytes));
    Result := True;
  finally
    fs.Free;
  end;
end;

procedure DecodeCON18x18(const src: PByte; out dst: TTileARGB; const zeroIsTransparent: Boolean);
var
  i: Integer;
  c: Byte;
begin
  // 324 bytes, row-major 18x18, 1 byte/pixel (EGA index)
  for i := 0 to (18*18)-1 do
  begin
    c := src[i];
    if zeroIsTransparent and (c = 0) then
      dst[i] := $00000000    // fully transparent
    else
      dst[i] := EGAtoARGB(c);
  end;
end;

function LoadCON_AsTiles(const path: string; out tiles: TTileArray; const zeroIsTransparent: Boolean): Boolean;
var
  bytes: TBytes;
  usable, count, i: Integer;
  ptr: PByte;
  t: TTileARGB;
begin
  Result := False;
  SetLength(tiles, 0);
  if not ReadAllBytes(path, bytes) then Exit;
  usable := Length(bytes);
  if usable < 324 then Exit;
  count := usable div 324; // 18*18
  SetLength(tiles, count);
  for i := 0 to count - 1 do
  begin
    ptr := @bytes[i*324];
    DecodeCON18x18(ptr, t, zeroIsTransparent);
    tiles[i] := t;
  end;
  Result := True;
end;

{------------------------- drawing helpers -------------------------}

function ClampI(v, lo, hi: Integer): Integer; inline;
begin
  if v < lo then Exit(lo);
  if v > hi then Exit(hi);
  Exit(v);
end;

procedure ClearScreen(c: LongWord);
begin
  FillDWord(FB[0], SCREEN_WIDTH*SCREEN_HEIGHT, c);
end;

// Nearest-neighbor scale with optional flip + 90° CW rotate (for quick checks)
procedure BlitTileScaled_Transform(src: PUInt32; dstX, dstY, dstW, dstH: Integer;
                                   const flipH, rot90CW: Boolean);
var
  dx, dy, sx, sy, sStride: Integer;
  fx, fy: Integer;
begin
  if src = nil then Exit;
  sStride := 18;

  for dy := 0 to dstH - 1 do
  begin
    sy := (dy * sStride) div dstH;
    for dx := 0 to dstW - 1 do
    begin
      sx := (dx * sStride) div dstW;

      if rot90CW then
      begin
        // (sx,sy) -> (sy, 17 - sx)
        fx := sy;
        fy := (sStride - 1) - sx;
      end
      else
      begin
        fx := sx; fy := sy;
      end;

      if flipH then fx := (sStride - 1) - fx;

      PutPixel(dstX + dx, dstY + dy, src[fy*sStride + fx]);
    end;
  end;
end;

procedure DrawRect(x,y,w,h: Integer; c: LongWord);
var i: Integer;
begin
  for i := 0 to w-1 do begin
    PutPixel(x+i, y, c);
    PutPixel(x+i, y+h-1, c);
  end;
  for i := 0 to h-1 do begin
    PutPixel(x, y+i, c);
    PutPixel(x+w-1, y+i, c);
  end;
end;

{------------------------- render & loop -------------------------}

procedure Render(const flipH, rot90CW, showGrid: Boolean);
var
  total, rowsVisible, idxStart, idxEnd: Integer;
  r, c, gx, gy, ox, oy: Integer;
  tileW, tileH: Integer;
  idx: Integer;
  p: PUInt32;
begin
  ClearScreen($FF000000);

  total := Length(Tiles);
  tileW := TILE_DRAW_W;
  tileH := TILE_DRAW_H;

  rowsVisible := (SCREEN_HEIGHT - 2*MARGIN_Y + GAP_Y) div (tileH + GAP_Y);
  if rowsVisible < 1 then rowsVisible := 1;

  V.ScrollY := ClampI(V.ScrollY, 0, Max(0, V.Rows - rowsVisible));

  ox := MARGIN_X; oy := MARGIN_Y;

  idxStart := V.ScrollY * COLS;
  idxEnd   := Min(idxStart + rowsVisible*COLS - 1, total - 1);

  // log page window once per frame (optional)
  //WriteLn('Show ', idxStart, '..', idxEnd, ' / ', total-1, ' scrollY=', V.ScrollY);

  idx := idxStart;
  for r := 0 to rowsVisible - 1 do
  begin
    gy := oy + r*(tileH + GAP_Y);
    for c := 0 to COLS - 1 do
    begin
      if idx > idxEnd then Break;
      gx := ox + c*(tileW + GAP_X);
      p := @Tiles[idx][0];
      BlitTileScaled_Transform(p, gx, gy, tileW, tileH, flipH, rot90CW);
      if showGrid then DrawRect(gx, gy, tileW, tileH, $FF404040);
      Inc(idx);
    end;
  end;

  Present;
end;

procedure RunViewer;
var
  total, rows: Integer;
  flipH, rot90CW, showGrid: Boolean;
begin
  flipH := False;
  rot90CW := False;
  showGrid := True;

  total := Length(Tiles);
  rows  := Ceil(total / COLS);
  if rows < 1 then rows := 1;

  V.Rows := rows;
  V.ScrollY := 0;

  WriteLn('AFTER.CON viewer');
  WriteLn('Tiles decoded: ', total, ' (18x18 ARGB)');
  WriteLn('Keys: Up/Down/PgUp/PgDn scroll,  R rotate,  F flipH,  G grid,  Esc quit');

  while Running do
  begin
    while SDL_PollEvent(@Event) <> 0 do
    begin
      if Event.type_ = SDL_QUITEV then Running := False
      else if Event.type_ = SDL_KEYDOWN then
      begin
        case TSDL_keysym(Event.key.keysym).sym of
          SDLK_ESCAPE: Running := False;
          SDLK_g: showGrid := not showGrid;
          SDLK_f: flipH := not flipH;
          SDLK_r: rot90CW := not rot90CW;
          SDLK_UP:       V.ScrollY := V.ScrollY - 1;
          SDLK_DOWN:     V.ScrollY := V.ScrollY + 1;
          SDLK_PAGEUP:   V.ScrollY := V.ScrollY - 5;
          SDLK_PAGEDOWN: V.ScrollY := V.ScrollY + 5;
        end;
      end;
    end;

    Render(flipH, rot90CW, showGrid);
    SDL_Delay(16);
  end;
end;

var
  ok: Boolean;
  path: string;
begin
  if not GfxInit(SCREEN_WIDTH, SCREEN_HEIGHT, 1) then
  begin
    WriteLn('Failed to init graphics');
    Halt(1);
  end;

  try
    path := IncludeTrailingPathDelimiter(DATA_DIR) + CON_FILE;
    if not FileExists(path) then
    begin
      WriteLn('ERROR: ', path, ' not found.');
      Halt(1);
    end;

    ok := LoadCON_AsTiles(path, Tiles, False {show index 0, not transparent});
    if not ok then
    begin
      WriteLn('Failed to load ', path);
      Halt(1);
    end;

    RunViewer;

  finally
    GfxQuit;
  end;
end.