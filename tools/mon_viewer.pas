program mon_viewer;

{$mode objfpc}{$H+}

uses
  SDL2, SysUtils, uGfx_fb, UConTiles, GameTypes;

const
  SCR_W = 1280;
  SCR_H = 600;

  TILEW = 18;
  TILEH = 18;

  PAD_X = 6;   // left margin
  PAD_Y = 6;   // top margin
  GAP_X = 4;   // space between tiles
  GAP_Y = 4;

type
  TSetSel = (ssTown, ssDungeon, ssRuin, ssLife);

var
  Running   : Boolean = True;
  SetSel    : TSetSel = ssTown;
  StartIdx  : Integer = 0;      // first index to show (scroll)
  Cols      : Integer;
  Rows      : Integer;
  ShowIdx   : Boolean = True;   // draw tiny indices over tiles
  Event     : TSDL_Event;

function BaseDir: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'data' + DirectorySeparator;
end;

function GetMonTilePtr(Index: Integer): PUInt32; inline;
begin
  case SetSel of
    ssTown:    Exit(Tiles_Get_TownMon(Index));
    ssDungeon: Exit(Tiles_Get_DungeonMon(Index));
    ssRuin:    Exit(Tiles_Get_RuinMon(Index));
    ssLife:    Exit(Tiles_Get_LifeMon(Index));
  end;
  Result := nil;
end;

function MonCount: Integer; inline;
begin
  case SetSel of
    ssTown:    Exit(Tiles_MonCount(mkTown));
    ssDungeon: Exit(Tiles_MonCount(mkDungeon));
    ssRuin:    Exit(Tiles_MonCount(mkRuin));
    ssLife:    Exit(Tiles_MonCount(mkAfterlife));
  end;
  Result := 0;
end;

// 1:1 blit (no scaling) to the framebuffer at (dstX,dstY)
procedure Blit18x18(const src: PUInt32; const dstX, dstY: Integer);
var
  y, x: Integer;
  color: LongWord;
begin
  if src = nil then Exit;
  for y := 0 to TILEH-1 do
    for x := 0 to TILEW-1 do
    begin
      color := src[y * TILEW + x];
      PutPixel(dstX + x, dstY + y, color);
    end;
end;

// tiny index overlay (very simple 3×5 “pixel” numerals)
procedure DrawDigit(const dx, dy: Integer; d: Integer; col: LongWord);
const
  DIG: array[0..9, 0..14] of Byte = (
    // 0..9, 3 wide × 5 high, flattened row-major (3*5 = 15 cells)
    // 0
    (1,1,1,
     1,0,1,
     1,0,1,
     1,0,1,
     1,1,1),
    // 1
    (0,1,0,
     1,1,0,
     0,1,0,
     0,1,0,
     1,1,1),
    // 2
    (1,1,1,
     0,0,1,
     1,1,1,
     1,0,0,
     1,1,1),
    // 3
    (1,1,1,
     0,0,1,
     0,1,1,
     0,0,1,
     1,1,1),
    // 4
    (1,0,1,
     1,0,1,
     1,1,1,
     0,0,1,
     0,0,1),
    // 5
    (1,1,1,
     1,0,0,
     1,1,1,
     0,0,1,
     1,1,1),
    // 6
    (1,1,1,
     1,0,0,
     1,1,1,
     1,0,1,
     1,1,1),
    // 7
    (1,1,1,
     0,0,1,
     0,1,0,
     0,1,0,
     0,1,0),
    // 8
    (1,1,1,
     1,0,1,
     1,1,1,
     1,0,1,
     1,1,1),
    // 9
    (1,1,1,
     1,0,1,
     1,1,1,
     0,0,1,
     1,1,1)
  );
var r,c,i: Integer;
begin
  if (d < 0) or (d > 9) then Exit;
  i := 0;
  for r := 0 to 4 do
    for c := 0 to 2 do
    begin
      if DIG[d, i] <> 0 then PutPixel(dx + c, dy + r, col);
      Inc(i);
    end;
end;

procedure DrawIndexSmall(const x, y, n: Integer);
var
  s: string;
  i: Integer;
  px: Integer;
begin
  s := IntToStr(n);
  // top-left of tile (with 1px padding)
  px := x + 1;
  for i := 1 to Length(s) do
  begin
    DrawDigit(px, y + 1, Ord(s[i]) - Ord('0'), $FFFFFFFF);
    Inc(px, 4); // 3px glyph + 1px space
  end;
end;

procedure ComputeGrid;
begin
  Cols := (SCR_W - PAD_X) div (TILEW + GAP_X);
  Rows := (SCR_H - PAD_Y) div (TILEH + GAP_Y);
  if Cols < 1 then Cols := 1;
  if Rows < 1 then Rows := 1;
end;

procedure ClampStart;
var maxFirst: Integer;
begin
  maxFirst := MonCount - (Cols * Rows);
  if maxFirst < 0 then maxFirst := 0;
  if StartIdx < 0 then StartIdx := 0;
  if StartIdx > maxFirst then StartIdx := maxFirst;
end;

procedure Render;
var
  total, i, r, c, x, y: Integer;
  idx: Integer;
  p: PUInt32;
begin
  ClearFB($FF000000);

  total := MonCount;
  if total <= 0 then
  begin
    // brief info
    // (white line at top if nothing loaded)
    for x := 0 to SCR_W-1 do PutPixel(x, 0, $FFFFFFFF);
    Present;
    Exit;
  end;

  idx := StartIdx;
  for r := 0 to Rows-1 do
  begin
    for c := 0 to Cols-1 do
    begin
      if idx >= total then Break;

      x := PAD_X + c * (TILEW + GAP_X);
      y := PAD_Y + r * (TILEH + GAP_Y);

      p := GetMonTilePtr(idx);
      Blit18x18(p, x, y);

      if ShowIdx then DrawIndexSmall(x, y, idx);

      Inc(idx);
    end;
  end;

  Present;
end;

procedure HandleInput;
var
  totalPage: Integer;
begin
  while SDL_PollEvent(@Event) <> 0 do
  begin
    case Event.type_ of
      SDL_QUITEV: Running := False;
      SDL_KEYDOWN:
        case TSDL_keysym(Event.key.keysym).sym of
          SDLK_ESCAPE: Running := False;

          // Switch sets
          SDLK_1: begin SetSel := ssTown;    StartIdx := 0; WriteLn('Set: TOWNMON');    end;
          SDLK_2: begin SetSel := ssDungeon; StartIdx := 0; WriteLn('Set: DUNGMON');    end;
          SDLK_3: begin SetSel := ssRuin;    StartIdx := 0; WriteLn('Set: RUINMON');    end;
          SDLK_4: begin SetSel := ssLife;    StartIdx := 0; WriteLn('Set: LIFEMON');    end;

          // Scroll
          SDLK_RIGHT: Inc(StartIdx);
          SDLK_LEFT : Dec(StartIdx);
          SDLK_DOWN : Inc(StartIdx, Cols);         // next row
          SDLK_UP   : Dec(StartIdx, Cols);
          SDLK_PAGEUP:
            begin
              totalPage := Cols * Rows;
              Dec(StartIdx, totalPage);
            end;
          SDLK_PAGEDOWN:
            begin
              totalPage := Cols * Rows;
              Inc(StartIdx, totalPage);
            end;

          // Toggle index overlay
          SDLK_i: ShowIdx := not ShowIdx;
        end;
    end;
  end;
  ClampStart;
end;

procedure Run;
begin
  if not GfxInit(SCR_W, SCR_H, 1) then
  begin
    WriteLn('Failed to init framebuffer');
    Halt(1);
  end;

  if not Tiles_Init(BaseDir) then
  begin
    WriteLn('Tiles_Init failed (check data folder).');
    Halt(1);
  end;

  try
    ComputeGrid;
    WriteLn('MON Viewer');
    WriteLn('1:TOWNMON  2:DUNGMON  3:RUINMON  4:LIFEMON');
    WriteLn('Arrows/PgUp/PgDn to scroll, I toggles indices, ESC to quit.');

    Running := True;
    while Running do
    begin
      HandleInput;
      Render;
      SDL_Delay(16);
    end;
  finally
    Tiles_Done;
    GfxQuit;
  end;
end;

begin
  Run;
end.
