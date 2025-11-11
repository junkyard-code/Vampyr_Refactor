unit uDisplay;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Math, SDL2,
  ugfx_fb,           // your framebuffer put/get & Present
  uContiles,
  StatusPanel,       // Status_Draw, logos, etc.
  uMonster;          // TBlitScaledProc + Mons_* draw/update


{======================== UI / Layout (2x/3x scale) ========================}
const
  // World map dimensions (100 columns x 110 rows)
  WORLD_WIDTH  = 110; // X: 0..109 (columns)
  WORLD_HEIGHT = 100; // Y: 0..99  (rows)
  
  // Scaled Resolution (X = 2x, Y = 3x original)
  ORIGINAL_WIDTH = 640;
  ORIGINAL_HEIGHT = 200;
  SCREEN_WIDTH = 1280;   // 640 * 2
  SCREEN_HEIGHT = 800;   // 200 * 4
  
  // UI Constants - Scaled 2x from original
  BORDER_WIDTH = 12;      // 5 pixels * 2 (original was 5 pixels)
  
  // Border Divider Location and Width
  DIVIDER_X = 516;       // 258 * 2
  DIVIDER_Y = 516;       // 131 * 3
  
  // 7x7 Tile Area Region (scaled 2x from original)
  MAP_AREA_X = 12;       // 6 * 2
  MAP_AREA_Y = 12;        // 3 * 2
  MAP_AREA_WIDTH = (2* 36) * 7;  // 252 * 2
  MAP_AREA_HEIGHT = (4* 18) * 7;  // 126 * 3
  
  // Status Area Region
  STATUS_AREA_X = 528;   // 264 * 2
  STATUS_AREA_Y = 110;     // 3 * 2
  STATUS_AREA_WIDTH = 740; // 371 * 2
  STATUS_AREA_HEIGHT = 278; // 126 * 3
  
  MSG_SCALE       = 1;
  MSG_GAP_SRC     = 1; // in 6x8 source pixel rows
  MSG_LINE_HEIGHT = (8 * FONT_Y_REP * MSG_SCALE) + (MSG_GAP_SRC * FONT_Y_REP * MSG_SCALE);
  MSG_MAX_LINES  = 7;

  MSG_COLOR      = $FF5555FF; // ARGB
  MSG_HISTORY    = 256;
  MSG_PROMPT     = '---<ANY KEY TO CONTINUE>---';

  // Message Area Region
  MESSAGE_AREA_X = 20;   // 6 * 2
  MESSAGE_AREA_Y = 532;  // 133 * 3
  MESSAGE_AREA_WIDTH = 1256; // 635 * 2
  MESSAGE_AREA_HEIGHT = (MSG_LINE_HEIGHT * MSG_MAX_LINES)+8; // 59 * 3

  VIEW_TILES = 7;
  TILE_W_BASE = 18;
  TILE_H_BASE = 18;
  SCALE_X = 2;
  SCALE_Y = 4;


  // Colors in ARGB format (8 bits per component)
  // Note: SDL uses ABGR format
  COLOR_BLACK = $FF000000;     // Black background
  COLOR_WHITE = $FFFFFFFF;     // White for text/borders
  COLOR_RED = $FFFF5555;       // Bright red for border
  COLOR_RED_DARK = $FFAA0000;  // Darker red for border outline
  COLOR_BLUE_DARK = $FF400000; // Dark blue for status area
  COLOR_GRAY_DARK = $FF202020; // Dark gray for message area
  COLOR_GREEN = $FF00FF00;     // Green for player
  COLOR_GRAY = $FF808080;      // Medium gray for UI elements

type
  // local helper for occlusion masks (untyped Var is used on cross-unit calls)
  TBoolGrid7 = array[-3..3, -3..3] of Boolean;

type
  // Type for the Vampyr logo (145x25 pixels in original, 290x50 in 2x scale)
  TVampyrLogo = array[1..145, 1..25] of Byte;

type
  TPlayerSpriteRef = record
    src: TTileSource;
    index: Word;
    hasOverride: Boolean;  // if true: always use (src,index). If false: fall back to your default logic (race, etc.)
  end;

type
  TMap = record
    W, H: Integer;
    Data: array of Byte; // X-major: Data[X + Y*W]
  end;

type

  
  // EGA color palette (RGB values)
  TEGAColor = record
    R, G, B: Byte;
  end;

type
  TRenderHook = procedure;

var
  VampyrLogo: TVampyrLogo;
  LogoLoaded: Boolean = False;
  ActiveMap: TMap;
  // first index = X (0..WORLD_WIDTH-1), second index = Y (0..WORLD_HEIGHT-1)
  WorldMap: array[0..WORLD_WIDTH-1, 0..WORLD_HEIGHT-1] of Byte; // [X,Y]
  EnableCollision : Boolean = True;   // F1 can toggle if you want
  EnableOcclusion : Boolean = True;   // F2 can toggle if you want
  GDisplayFrozen: Boolean = False;

const
  // EGA color palette (16 colors)
  EGAPalette: array[0..15] of TEGAColor = (
    (R: 0;   G: 0;   B: 0),      // 0: Black
    (R: 0;   G: 0;   B: 170),    // 1: Blue
    (R: 0;   G: 170; B: 0),      // 2: Green
    (R: 0;   G: 170; B: 170),    // 3: Cyan
    (R: 170; G: 0;   B: 0),      // 4: Red
    (R: 170; G: 0;   B: 170),    // 5: Magenta
    (R: 170; G: 85;  B: 0),      // 6: Brown
    (R: 170; G: 170; B: 170),    // 7: Light Gray
    (R: 85;  G: 85;  B: 85),     // 8: Dark Gray
    (R: 85;  G: 85;  B: 255),    // 9: Light Blue
    (R: 85;  G: 255; B: 85),     // 10: Light Green
    (R: 85;  G: 255; B: 255),    // 11: Light Cyan
    (R: 255; G: 85;  B: 85),     // 12: Light Red
    (R: 255; G: 85;  B: 255),    // 13: Light Magenta
    (R: 255; G: 255; B: 85),     // 14: Yellow
    (R: 255; G: 255; B: 255)     // 15: White
  );


{============================= Public API ==================================}

procedure DrawMapView;
procedure DrawStatusArea;
procedure DrawMessageArea;

// Optional: one call to do a full frame
procedure RenderFrame;
function AM_Get(const X, Y: Integer): Byte; inline;
procedure BlitTileScaledFromPtr_PutPixel(const Src: PLongWord;
                                         const DstX, DstY, DestW, DestH: Integer);
procedure DrawVampyrLogo;
function LoadVampyrLogo: Boolean;
procedure Display_SetOcclusionRadius(r: Integer);  // 0..3 (center..full view)
procedure Display_ClearOcclusionOverride;
procedure PlayerSprite_Set(const src: TTileSource; const index: Word);
procedure PlayerSprite_ClearOverride;
procedure PlayerSprite_SetByRace(const race0based: Integer);
procedure PlayerSprite_Get(out src: TTileSource; out index: Word);

procedure Message_Init;
procedure Message_Clear;
procedure Message_SetRenderHook(AHook: TRenderHook);
procedure Message_SetAutoDelay(ms: Cardinal);
procedure Message_Render;
procedure Message_Add(const S: string);
procedure Message_AddWrapped(const S: string; maxCols: Integer);
procedure Message_ShowPaged(const Lines: array of string);

procedure Message_WaitForPage(const Prompt: string = MSG_PROMPT);
procedure Message_FlushAndPage;

function Message_WaitAnyKey(const Prompt: string = MSG_PROMPT): LongInt;
function Message_PromptYesNo(const Prompt: string; defaultYes: Boolean = False): Boolean;
function Message_PromptNumber(const Prompt: string; minVal, maxVal: Integer): Integer;
function Message_PromptChoice(const Prompt: string; const Choices: array of string): Integer;
function Message_PromptDirection(out dx, dy: Integer): Boolean;
function Message_PromptLetterChoice(const Prompt, Choices: string): Char;

function Message_PromptLetterInline(const Prompt, Allowed: string): Char;
function Message_PromptYesNoInline(const Prompt: string): Boolean;
function Message_PromptDigitInline(const Prompt: string; MinVal, MaxVal: Integer; out Value: Integer): Boolean;
function UpperKeyChar: Char;

procedure WriteMessage(const S: string);


implementation

var
  GOcclOverrideActive: Boolean = False;
  GOcclRadius: Integer = 3; // 0..3 for a 7×7 centered view
  GPlayerSprite: TPlayerSpriteRef = (src: tsPlayer; index: 0; hasOverride: False);
  Hist: array[0..MSG_HISTORY-1] of AnsiString;
  HistHead: Integer = 0;
  HistLen: Integer = 0;
  AutoDelayMS: Cardinal = 0;
  RenderHook: TRenderHook = nil;

procedure Message_Init;
begin
  Message_Clear;
end;

procedure Message_Clear;
begin
  HistHead := 0;
  HistLen := 0;
end;

procedure Message_SetRenderHook(AHook: TRenderHook);
begin
  RenderHook := AHook;
end;

procedure Message_SetAutoDelay(ms: Cardinal);
begin
  AutoDelayMS := ms;
end;

procedure WriteMessage(const S: string);
begin
  // Back-compat wrapper
  Hist[HistHead] := S;
  HistHead := (HistHead + 1) mod MSG_HISTORY;
  if HistLen < MSG_HISTORY then Inc(HistLen);

  if (HistLen >= MSG_MAX_LINES) and (AutoDelayMS > 0) then
  begin
    if Assigned(RenderHook) then RenderHook();
    SDL_Delay(AutoDelayMS);
  end;
end;

procedure Message_Add(const S: string);
begin
  WriteMessage(S);
end;

procedure Message_AddWrapped(const S: string; maxCols: Integer);
var
  i, start, lastSpace: Integer;
  line: string;
begin
  if maxCols <= 0 then
  begin
    Message_Add(S);
    Exit;
  end;

  i := 1;
  while i <= Length(S) do
  begin
    start := i;
    lastSpace := -1;
    while (i <= Length(S)) and (i - start < maxCols) do
    begin
      if S[i] = ' ' then lastSpace := i;
      Inc(i);
    end;

    if (i <= Length(S)) and (S[i] <> ' ') and (lastSpace <> -1) then
    begin
      line := Copy(S, start, lastSpace - start);
      i := lastSpace + 1;
    end
    else
    begin
      line := Copy(S, start, i - start);
      while (i <= Length(S)) and (S[i] = ' ') do Inc(i);
    end;

    Message_Add(line);
  end;
end;

procedure DrawPanel;
begin
  // Fully-qualify FillRect so it binds to your gfx unit.
  // Signature expected: FillRect(x, y, w, h, color)
  ugfx_fb.FillRect(
    MESSAGE_AREA_X - 8, 
    MESSAGE_AREA_Y - 2, 
    MESSAGE_AREA_WIDTH, 
    MESSAGE_AREA_HEIGHT,  // Calculate total height for all lines
    $CC000000
  );
end;

procedure Message_Render;
var
  visible, start, idx, i: Integer;
begin
  DrawPanel;
  if HistLen = 0 then Exit;

  visible := MSG_MAX_LINES;
  if visible > HistLen then visible := HistLen;

  start := (HistHead - visible + MSG_HISTORY) mod MSG_HISTORY;

  for i := 0 to visible - 1 do
  begin
    idx := (start + i) mod MSG_HISTORY;
    BlitText6x8(Hist[idx], MESSAGE_AREA_X, MESSAGE_AREA_Y + i * MSG_LINE_HEIGHT, MSG_COLOR, MSG_SCALE);
  end;
end;

procedure Message_ShowPaged(const Lines: array of string);
var
  i, countOnPage: Integer;
begin
  countOnPage := 0;
  for i := 0 to High(Lines) do
  begin
    Message_Add(Lines[i]);
    Inc(countOnPage);
    if countOnPage = MSG_MAX_LINES then
    begin
      Message_WaitForPage(MSG_PROMPT);
      countOnPage := 0;
    end;
  end;
end;


function UpperKeyChar: Char;
var
  ev: TSDL_Event;
  sym: LongInt;
begin
  Result := #0;

  // Wait for a keydown event
  while SDL_WaitEvent(@ev) <> 0 do
  begin
    if ev.type_ = SDL_KEYDOWN then
    begin
      sym := ev.key.keysym.sym;
      case sym of
        SDLK_a..SDLK_z:
          Result := Chr(Ord('A') + (sym - SDLK_a));
        SDLK_0..SDLK_9:
          Result := Chr(Ord('0') + (sym - SDLK_0));
        SDLK_ESCAPE:
          Result := #27;
      else
        Result := #0;
      end;
      Break;
    end
    else if ev.type_ = SDL_QUITEV then
      Exit(#27);  // treat quit as ESC
  end;
end;


// ------------------- Event loop helpers -------------------

procedure PumpWhileWaiting;
begin
  if Assigned(RenderHook) then RenderHook();
  SDL_Delay(10);
end;

function WaitKey(out key: LongInt): Boolean;
var
  ev: TSDL_Event;
  waiting: Boolean;
begin
  waiting := True;
  key := 0;
  Result := False;

  while waiting do
  begin
    PumpWhileWaiting;

    while SDL_PollEvent(@ev) <> 0 do
    begin
      if ev.type_ = SDL_KEYDOWN then
      begin
        key := ev.key.keysym.sym;
        Result := True;
        waiting := False;
        Break;
      end
      else if ev.type_ = SDL_QUITEV then
      begin
        waiting := False;
        Exit(False);
      end;
    end;

    SDL_Delay(10);
  end;
end;

// Normalize letter key to lowercase ASCII if applicable.
function KeyToLowerChar(key: LongInt): Char;
begin
  if (key >= Ord('A')) and (key <= Ord('Z')) then
    Exit(Char(key + 32))
  else
    Exit(Char(key));
end;

function KeyIsEnter(key: LongInt): Boolean;
begin
  Result := (key = SDLK_RETURN) or (key = SDLK_KP_ENTER);
end;

function KeyDigit(key: LongInt): Integer;
begin
  // returns 0..9 for main row
  if (key >= SDLK_0) and (key <= SDLK_9) then
    Exit(key - SDLK_0)
  else
  // keypad digits
  if (key >= SDLK_KP_0) and (key <= SDLK_KP_9) then
    Exit(key - SDLK_KP_0)
  else
    Exit(-1);
end;

// ------------------- Paging & prompts -------------------

procedure Message_WaitForPage(const Prompt: string);
var
  key: LongInt;
begin
  Message_Add(Prompt);
  Message_Render;
  if Assigned(RenderHook) then RenderHook();
  if not WaitKey(key) then Exit;
  Message_Add(''); // visual divider
end;

procedure Message_FlushAndPage;
begin
  Message_WaitForPage(MSG_PROMPT);
end;

function Message_WaitAnyKey(const Prompt: string): LongInt;
var
  key: LongInt;
begin
  Message_Add(Prompt);
  Message_Render;
  if Assigned(RenderHook) then RenderHook();
  if not WaitKey(key) then Exit(0);
  Result := key;
end;

function Message_PromptYesNo(const Prompt: string; defaultYes: Boolean): Boolean;
var
  key: LongInt;
  suffix: string;
  c: Char;
begin
  if defaultYes then suffix := ' [Y/n]' else suffix := ' [y/N]';
  Message_Add(Prompt + suffix);
  Message_Render;
  if Assigned(RenderHook) then RenderHook();

  while True do
  begin
    if not WaitKey(key) then Exit(defaultYes);

    if KeyIsEnter(key) then Exit(defaultYes);
    if key = SDLK_ESCAPE then Exit(False);

    c := KeyToLowerChar(key);
    if c = 'y' then Exit(True);
    if c = 'n' then Exit(False);
  end;
end;


// Map SDL keycode to an uppercase ASCII-like char we care about
function SymToUpperChar(sym: LongInt): Char;
begin
  case sym of
    SDLK_a..SDLK_z: Result := Chr(Ord('A') + (sym - SDLK_a));
    SDLK_0..SDLK_9: Result := Chr(Ord('0') + (sym - SDLK_0));
    SDLK_ESCAPE:    Result := #27;
    SDLK_RETURN:    Result := #13;
    else            Result := #0;
  end;
end;

// Block until a KEYDOWN, return its SDL keycode; false if quit
function WaitKeySymBlocking(out sym: LongInt): Boolean;
var ev: TSDL_Event;
begin
  while SDL_WaitEvent(@ev) <> 0 do
  begin
    if ev.type_ = SDL_KEYDOWN then
    begin
      sym := ev.key.keysym.sym;
      Exit(True);
    end
    else if ev.type_ = SDL_QUITEV then
      Exit(False);
  end;
  Result := False;
end;

// Print a prompt (no extra frame/dividers), return an allowed LETTER (uppercase)
function Message_PromptLetterInline(const Prompt, Allowed: string): Char;
var sym: LongInt; c: Char;
begin
  WriteMessage(Prompt);
  Result := #0;
  while True do
  begin
    if not WaitKeySymBlocking(sym) then Exit(#0);
    c := SymToUpperChar(sym);
    if (c <> #0) and (Pos(c, Allowed) > 0) then
      Exit(c);
    if c = #27 then Exit(#0); // ESC cancels
  end;
end;

// Print prompt, return true for Y, false for N/ESC
function Message_PromptYesNoInline(const Prompt: string): Boolean;
var ch: Char;
begin
  ch := Message_PromptLetterInline(Prompt + ' [Y/N]', 'YN');
  Result := (ch = 'Y');
end;

// Print prompt, wait for a digit 0..9; parse+clamp to Min..Max; ESC returns false
function Message_PromptDigitInline(const Prompt: string; MinVal, MaxVal: Integer; out Value: Integer): Boolean;
var sym: LongInt; c: Char; n: Integer;
begin
  WriteMessage(Prompt);
  Value := 0;
  while True do
  begin
    if not WaitKeySymBlocking(sym) then Exit(False);
    c := SymToUpperChar(sym);
    if c = #27 then Exit(False); // ESC
    if (c >= '0') and (c <= '9') then
    begin
      n := Ord(c) - Ord('0');
      if n < MinVal then n := MinVal;
      if n > MaxVal then n := MaxVal;
      Value := n;
      Exit(True);
    end;
  end;
end;


function Message_PromptNumber(const Prompt: string; minVal, maxVal: Integer): Integer;
var
  key: LongInt;
  s: string;
  d: Integer;
  promptEcho: string;
begin
  if minVal > maxVal then
  begin
    Result := minVal;
    Exit;
  end;

  promptEcho := Format('%s (%d..%d): ', [Prompt, minVal, maxVal]);
  Message_Add(promptEcho);
  Message_Render;
  if Assigned(RenderHook) then RenderHook();

  s := '';
  while True do
  begin
    if not WaitKey(key) then Exit(0);

    d := KeyDigit(key);
    if d <> -1 then
      s += Chr(Ord('0') + d)
    else if (key = SDLK_BACKSPACE) and (Length(s) > 0) then
      Delete(s, Length(s), 1)
    else if KeyIsEnter(key) then
    begin
      if s = '' then Continue;
      Result := StrToIntDef(s, minVal);
      if (Result < minVal) then Result := minVal;
      if (Result > maxVal) then Result := maxVal;
      Exit;
    end
    else if key = SDLK_ESCAPE then
      Exit(0);

    // echo onto the last line in history
    Hist[(HistHead - 1 + MSG_HISTORY) mod MSG_HISTORY] := promptEcho + s;
    Message_Render;
    if Assigned(RenderHook) then RenderHook();
  end;
end;

function Message_PromptChoice(const Prompt: string; const Choices: array of string): Integer;
var
  i: Integer;
  key: LongInt;
  d: Integer;
begin
  Message_Add(Prompt);
  for i := 0 to High(Choices) do
    Message_Add(Format('%d) %s', [i+1, Choices[i]]));

  Message_Render;
  if Assigned(RenderHook) then RenderHook();

  while True do
  begin
    if not WaitKey(key) then Exit(0);
    if key = SDLK_ESCAPE then Exit(0);

    d := KeyDigit(key);
    if (d >= 1) and (d <= Length(Choices)) then
      Exit(d);
  end;
end;

function Message_PromptLetterChoice(const Prompt, Choices: string): Char;
var
  key: LongInt;
  c: Char;
  upperChoices: string;
begin
  // Convert choices to uppercase for case-insensitive comparison
  upperChoices := UpperCase(Choices);
  
  // Display the prompt
  Message_Add(Prompt);
  Message_Render;
  if Assigned(RenderHook) then RenderHook();

  while True do
  begin
    if not WaitKey(key) then Exit(#0);
    if key = SDLK_ESCAPE then Exit(#0);
    c := SymToUpperChar(key);
    if Pos(c, upperChoices) > 0 then
      Exit(c);
  end;
end;

function Message_PromptDirection(out dx, dy: Integer): Boolean;
var
  key: LongInt;
begin
  Message_Add('Choose a direction (arrow keys).');
  Message_Render;
  if Assigned(RenderHook) then RenderHook();

  while True do
  begin
    if not WaitKey(key) then Exit(False);

    dx := 0; dy := 0;
    if key = SDLK_UP    then begin dy := -1; Exit(True); end;
    if key = SDLK_DOWN  then begin dy :=  1; Exit(True); end;
    if key = SDLK_LEFT  then begin dx := -1; Exit(True); end;
    if key = SDLK_RIGHT then begin dx :=  1; Exit(True); end;
    if key = SDLK_ESCAPE then Exit(False);
  end;
end;



procedure Display_SetOcclusionRadius(r: Integer);
begin
  if r < 0 then r := 0 else if r > 3 then r := 3;
  GOcclOverrideActive := True;
  GOcclRadius := r;
end;

procedure Display_ClearOcclusionOverride;
begin
  GOcclOverrideActive := False;
end;

function NowMs: QWord; inline;
begin
  {$IFDEF SDL}
  Result := SDL_GetTicks;
  {$ELSE}
  Result := GetTickCount64;
  {$ENDIF}
end;

procedure DrawRect(const x, y, w, h, color: LongInt); inline;
begin
  FillRect(x, y, w, h, color);
end;

procedure DrawBorderRect(const x, y, w, h, border, color: LongInt); inline;
begin
  FillRect(x, y, w, h, color);
  // you can add decorative edges here if needed
end;

//*********************************************** AM_Get ***********************************************

function AM_Get(const X, Y: Integer): Byte; inline;
begin
  if (Cardinal(X) < Cardinal(ActiveMap.W)) and (Cardinal(Y) < Cardinal(ActiveMap.H)) then
    Result := ActiveMap.Data[X + Y * ActiveMap.W]
  else
    Result := 0;
end;


//*********************************************** EGA to RGB ***********************************************

function EGAtoRGB(ColorIndex: Byte): LongWord;
begin
  if ColorIndex > High(EGAPalette) then
    ColorIndex := 0; // Default to black if color index is out of range
    
  with EGAPalette[ColorIndex] do
    Result := $FF000000 or (R shl 16) or (G shl 8) or B;
end;



// ********************************** BlitTileScaledFromPtr_PutPixel ************************************
// Blitter that takes a tile pointer (so we can pass the alt frame directly):
procedure BlitTileScaledFromPtr_PutPixel(const Src: PLongWord;
                                         const DstX, DstY, DestW, DestH: Integer);
var
  dx, dy, sx, sy: Integer;
  color: LongWord;
begin
  if Src = nil then Exit;
  for dy := 0 to DestH - 1 do
  begin
    sy := (dy * TILE_H) div DestH;
    for dx := 0 to DestW - 1 do
    begin
      sx := (dx * TILE_W) div DestW;
      color := Src[sy * TILE_W + sx];
      if (color and $FF000000) <> 0 then            // only draw non-transparent
        PutPixel(DstX + dx, DstY + dy, color);
    end;
  end;
end;

{=== the pixel-level tile blitter used by monsters (top-level, not nested) ===}
// IMPORTANT: Signature EXACTLY matches TBlitScaledProc
procedure BlitShim(src: PDWord; x, y, w, h: LongInt); inline;
begin
  BlitTileScaledFromPtr_PutPixel(src, x, y, w, h);
end;

procedure BlitPlayerTileOverlay_PutPixel(const idx, x, y, w, h: Integer);
var src: PUInt32;
begin
  src := Tiles_GetPlayerTile(idx);
  if src <> nil then
    BlitTileScaledFromPtr_PutPixel(src, x, y, w, h);
end;


function Display_GetMonsterBlitter: TBlitScaledProc;
begin
  Result := @BlitShim;
end;

procedure BlitTileOverlayFromSource_PutPixel(const srcKind: TTileSource;
                                             const index: Word;
                                             const DstX, DstY, DestW, DestH: Integer);
var
  src: PLongWord;  // ARGB32 tile pixels (TILE_W*TILE_H)
  dx, dy: Integer;
  sx, sy: Integer;
  color: LongWord;
begin
  // UConTiles already provides a unifier; use it:
  src := TilePtrBySource(srcKind, index);
  if src = nil then Exit;

  for dy := 0 to DestH - 1 do
  begin
    sy := (dy * TILE_H) div DestH;
    for dx := 0 to DestW - 1 do
    begin
      sx := (dx * TILE_W) div DestW;
      color := src[sy * TILE_W + sx];
      if (color and $FF000000) <> 0 then  // draw only non-transparent
        PutPixel(DstX + dx, DstY + dy, color);
    end;
  end;
end;

//**************************************** BuildOccluderGrid ****************************************
// Build a 7x7 grid of booleans for occlusion
procedure BuildOccluderGrid(out O: TBoolGrid7);
var rx, ry, wx, wy: Integer; tid: Byte;
begin
  for ry := -3 to 3 do
    for rx := -3 to 3 do
    begin
      wx := Player.XLoc + rx;
      wy := Player.YLoc + ry;
      if (wx >= 0) and (wy >= 0) and (wx < ActiveMap.W) and (wy < ActiveMap.H) then
      begin
        tid := AM_Get(wx, wy);
        O[rx, ry] := TileOccludes(ActiveKind, tid);
      end
      else
        O[rx, ry] := True; // out-of-bounds acts like occluder (world edge)
    end;
end;



//************************************************ In7 ***********************************************
// Check if a coordinate is within the 7x7 grid
function In7(const x,y: Integer): Boolean; inline;
begin
  Result := (x>=-3) and (x<=3) and (y>=-3) and (y<=3);
end;

//****************************************** HardOcclusion7 *******************************************
// Exact-order port of DISPLAY.PAS: DisplayBlock to [-3..3] coordinates.
// BooMap[1..7,1..7] <-> V[-3..3,-3..3]; S[3..5,3..5] records neighbor occluders.
// O[rx,ry]=True means the tile at (rx,ry) is an occluder (not “visible”).
procedure HardOcclusion7(const O: TBoolGrid7; out V: TBoolGrid7);
type
  TBoo = array[1..7,1..7] of Boolean;
  TSnap = array[3..5,3..5] of Boolean;

  function Rx(i: Integer): Integer; inline; begin Result := i - 4; end;   // 1..7 -> -3..3
  function Idx(r: Integer): Integer; inline; begin Result := r + 4; end;   // -3..3 -> 1..7

  procedure SetAll(var M: TBoo; value: Boolean);
  var i,j: Integer; begin for j:=1 to 7 do for i:=1 to 7 do M[i,j]:=value; end;

  function Occludes(i,j: Integer): Boolean; inline;
  begin
    // i,j are 1..7; map to rx,ry and read O
    Result := O[Rx(i), Rx(j)];
  end;

var
  Boo: TBoo;      // visibility being built (True = visible)
  S  : TSnap;     // snapshot of the 3×3 neighbor “non-occluder” flags
  i,j: Integer;

  procedure CommitToV;
  var i,j: Integer;
  begin
    for j:=1 to 7 do
      for i:=1 to 7 do
        V[Rx(i), Rx(j)] := Boo[i,j];
  end;

begin
  // (A) Pre-fill Boo from occluder grid: visible unless occluder
  for j := 1 to 7 do
    for i := 1 to 7 do
      Boo[i,j] := not O[Rx(i), Rx(j)];

  // (B) Exact-order cascade (port of your DisplayBlock):

  // "3rd loop": force the border ring visible (matches original order)
  for i := 1 to 7 do begin
    if not Boo[i,1] then Boo[i,1] := True;
    if not Boo[i,7] then Boo[i,7] := True;
    if not Boo[1,i] then Boo[1,i] := True;
    if not Boo[7,i] then Boo[7,i] := True;
  end;

  // "1st loop": take snapshot S of the 3×3 around the player (rows/cols 3..5),
  // then force that 3×3 visible.
  S[3,3] := Boo[3,3];  S[4,3] := Boo[4,3];  S[5,3] := Boo[5,3];
  S[3,4] := Boo[3,4];                       S[5,4] := Boo[5,4];
  S[3,5] := Boo[3,5];  S[4,5] := Boo[4,5];  S[5,5] := Boo[5,5];

  Boo[3,3] := True; Boo[4,3] := True; Boo[5,3] := True;
  Boo[3,4] := True; Boo[4,4] := True; Boo[5,4] := True;
  Boo[3,5] := True; Boo[4,5] := True; Boo[5,5] := True;

  // fan hides behind ring-1 occluders (matches your exact coordinates)
  if not S[3,3] then begin Boo[2,2]:=False; Boo[3,2]:=False; Boo[2,3]:=False; end; // NW
  if not S[4,3] then begin Boo[4,2]:=False;                                          end; // N
  if not S[5,3] then begin Boo[6,2]:=False; Boo[5,2]:=False; Boo[6,3]:=False; end; // NE
  if not S[5,4] then begin Boo[6,4]:=False;                                          end; // E
  if not S[5,5] then begin Boo[6,6]:=False; Boo[6,5]:=False; Boo[5,6]:=False; end; // SE
  if not S[4,5] then begin Boo[4,6]:=False;                                          end; // S
  if not S[3,5] then begin Boo[2,6]:=False; Boo[2,5]:=False; Boo[3,6]:=False; end; // SW
  if not S[3,4] then begin Boo[2,4]:=False;                                          end; // W

  // "2nd loop": if a ring-2 cell is hidden (e.g., it’s an occluder),
  // hide the outer ring behind it; then restore that ring-2 cell if the
  // corresponding ring-1 snapshot S was clear (exactly like original).
  if not Boo[2,2] then begin Boo[1,2]:=False; Boo[1,1]:=False; Boo[2,1]:=False; if S[3,3] then Boo[2,2]:=True; end;
  if not Boo[3,2] then begin Boo[2,1]:=False; Boo[3,1]:=False;                    if S[3,3] then Boo[3,2]:=True; end;
  if not Boo[4,2] then begin Boo[4,1]:=False; Boo[3,1]:=False; Boo[5,1]:=False;  if S[4,3] then Boo[4,2]:=True; end;
  if not Boo[5,2] then begin Boo[5,1]:=False; Boo[6,1]:=False;                    if S[5,3] then Boo[5,2]:=True; end;
  if not Boo[6,2] then begin Boo[6,1]:=False; Boo[7,1]:=False; Boo[7,2]:=False;  if S[5,3] then Boo[6,2]:=True; end;
  if not Boo[6,3] then begin Boo[7,2]:=False; Boo[7,3]:=False;                    if S[5,3] then Boo[6,3]:=True; end;
  if not Boo[6,4] then begin Boo[7,4]:=False; Boo[7,3]:=False; Boo[7,5]:=False;  if S[5,4] then Boo[6,4]:=True; end;
  if not Boo[6,5] then begin Boo[7,5]:=False; Boo[7,6]:=False;                    if S[5,5] then Boo[6,5]:=True; end;
  if not Boo[6,6] then begin Boo[7,6]:=False; Boo[7,7]:=False; Boo[6,7]:=False;  if S[5,5] then Boo[6,6]:=True; end;
  if not Boo[5,6] then begin Boo[5,7]:=False; Boo[6,7]:=False;                    if S[5,5] then Boo[5,6]:=True; end;
  if not Boo[4,6] then begin Boo[4,7]:=False; Boo[3,7]:=False; Boo[5,7]:=False;  if S[4,5] then Boo[4,6]:=True; end;
  if not Boo[3,6] then begin Boo[3,7]:=False; Boo[2,7]:=False;                    if S[3,5] then Boo[3,6]:=True; end;
  if not Boo[2,6] then begin Boo[1,6]:=False; Boo[1,7]:=False; Boo[2,7]:=False;  if S[3,5] then Boo[2,6]:=True; end;
  if not Boo[2,5] then begin Boo[1,5]:=False; Boo[1,6]:=False;                    if S[3,5] then Boo[2,5]:=True; end;
  if not Boo[2,4] then begin Boo[1,4]:=False; Boo[1,3]:=False; Boo[1,5]:=False;  if S[3,4] then Boo[2,4]:=True; end;
  if not Boo[2,3] then begin Boo[1,3]:=False; Boo[1,2]:=False;                    if S[3,3] then Boo[2,3]:=True; end;

  // Player tile (center) remains visible
  Boo[4,4] := True;

  // Commit to V (convert 1..7 back to −3..+3)
  for j := 1 to 7 do
    for i := 1 to 7 do
      V[Rx(i), Rx(j)] := Boo[i,j];
end;


// *************************************** Choose Player Tile Index **************************************

function ChoosePlayerTileIndex: Integer;
var
  i, n: Integer;
  p: PUInt32;
  staticIdx: Integer = -1;

function HasOpaque(p: PUInt32): Boolean;
var i: Integer;
begin
  Result := False;
  if p = nil then Exit(False);
  for i := 0 to TILE_W*TILE_H - 1 do
    if (p[i] and $FF000000) <> 0 then Exit(True);
end;

begin
  // If you have Player.Race (0-based), prefer it when valid:
  if (Player.Race >= 0) and (Player.Race < Tiles_PlayerCount) then Exit(Player.Race);

  if staticIdx >= 0 then Exit(staticIdx);

  n := Tiles_PlayerCount;
  for i := 0 to n - 1 do
  begin
    p := Tiles_GetPlayerTile(i);
    if HasOpaque(p) then
    begin
      staticIdx := i;
      Exit(i);
    end;
  end;

  // Fallback if all tiles are transparent/empty
  Result := 0;
end;


// Set player tile that will be used in the 7 x 7 map viewer
procedure PlayerSprite_Set(const src: TTileSource; const index: Word);
begin
  GPlayerSprite.src := src;
  GPlayerSprite.index := index;
  GPlayerSprite.hasOverride := True;
end;

procedure PlayerSprite_ClearOverride;
begin
  GPlayerSprite.hasOverride := False;
end;

// Optional convenience if you keep Player.Race in scope:
procedure PlayerSprite_SetByRace(const race0based: Integer);
begin
  GPlayerSprite.src := tsPlayer;
  GPlayerSprite.index := Max(0, race0based);
  GPlayerSprite.hasOverride := True;
end;

// Resolve current (src,index), falling back to your old chooser when override is off.
procedure PlayerSprite_Get(out src: TTileSource; out index: Word);
begin
  if GPlayerSprite.hasOverride then
  begin
    src := GPlayerSprite.src;
    index := GPlayerSprite.index;
  end
  else
  begin
    // old behavior (kept): use your existing chooser
    src := tsPlayer;
    index := ChoosePlayerTileIndex;  // this is already in uDisplay.pas
  end;
end;



// **************************************** DrawMapView ****************************************
procedure DrawMapView;
var
  tx, ty, x, y, wx, wy, dx, dy: Integer;
  rx, ry: Integer;
  tileSizeX, tileSizeY: Integer;
  idx: Integer;
  tnow: QWord;
  src: PUInt32;
  useOcc: Boolean;
  O: TBoolGrid7;
  V: TBoolGrid7;
  ringVisible: Boolean;
  psSrc: TTileSource;
  psIdx: Word;

begin
  // tile size for the 7x7 view
  tileSizeX := MAP_AREA_WIDTH  div 7;
  tileSizeY := MAP_AREA_HEIGHT div 7;

  useOcc := EnableOcclusion;
  tnow := NowMs;

  // Build visibility mask (or mark everything visible if occlusion is off)
  if useOcc then
  begin
    BuildOccluderGrid(O);
    HardOcclusion7(O, V);
  end
  else
  begin
    for ry := -3 to 3 do
      for rx := -3 to 3 do
        V[rx,ry] := True;
  end;

  // Draw 7x7 tiles
  for ty := -3 to 3 do
  begin
    for tx := -3 to 3 do
    begin
      // relative coords for mask lookup
      rx := tx; ry := ty;

     // Chebyshev-distance ring (3 = full 7×7 … 0 = center only)
     if GOcclOverrideActive then
     ringVisible := (Max(Abs(rx), Abs(ry)) <= GOcclRadius)
     else
     ringVisible := True;

      wx := Player.XLoc + tx;
      wy := Player.YLoc + ty;

      x := MAP_AREA_X + (tx + 3) * tileSizeX;
      y := MAP_AREA_Y + (ty + 3) * tileSizeY;

      // Occlusion: draw black tile if invisible
      if (not ringVisible) or (useOcc and (not V[rx, ry])) then
      begin
      for dy := 0 to tileSizeY - 1 do
          for dx := 0 to tileSizeX - 1 do
          PutPixel(x + dx, y + dy, COLOR_BLACK);
      Continue;
      end;

      // Normal draw
      if (wx >= 0) and (wx < ActiveMap.W) and (wy >= 0) and (wy < ActiveMap.H) then
      begin
        src := GetTilePtrForActive(AM_Get(wx, wy), tnow);
        BlitTileScaledFromPtr_PutPixel(src, x, y, tileSizeX, tileSizeY);
      end
      else
      begin
        for dy := 0 to tileSizeY - 1 do
          for dx := 0 to tileSizeX - 1 do
            PutPixel(x + dx, y + dy, COLOR_BLACK);
      end;
    end;
  end;

// NPC overlay pass (on top of terrain, under player)
Mons_Draw7x7_UsingMaskAndBlitter(
  Player.XLoc, Player.YLoc,
  V,                         // occlusion mask you already built
  MAP_AREA_X, MAP_AREA_Y,
  tileSizeX, tileSizeY,
  @BlitShim
);

// Player overlay (center of the 7x7)
PlayerSprite_Get(psSrc, psIdx);
BlitTileOverlayFromSource_PutPixel(
  psSrc, psIdx,
  MAP_AREA_X + (3 * tileSizeX),
  MAP_AREA_Y + (3 * tileSizeY),
  tileSizeX, tileSizeY
);
end;

//*********************************************** Load Vampyr Logo ***********************************************

function LoadVampyrLogo: Boolean;
var
  F: File;
  FilePath: String;
  BytesRead: Integer;
begin
WriteLn('Loading Vampyr logo...LoadVampyrLogo');
  Result := False;
  FilePath := 'data\VAMPYR.001';
  
  if not FileExists(FilePath) then
  begin
    FilePath := '..\data\VAMPYR.001'; // Try relative path
    if not FileExists(FilePath) then
    begin
      WriteLn('Error: Could not find VAMPYR.001');
      Exit;
    end;
  end;
  
  try
    AssignFile(F, FilePath);
    FileMode := 0; // Read-only
    Reset(F, 1);
    try
      // Read the entire file into our buffer
      BlockRead(F, VampyrLogo, SizeOf(VampyrLogo), BytesRead);
      if BytesRead <> SizeOf(VampyrLogo) then
      begin
        WriteLn('Error: Invalid Vampyr logo file size');
        Exit;
      end;
      
      Result := True;
      LogoLoaded := True;
      WriteLn('Vampyr logo loaded successfully');
    finally
      CloseFile(F);
    end;
  except
    on E: Exception do
      WriteLn('Error loading Vampyr logo: ', E.Message);
  end;
end;

//*********************************************** Draw Vampyr Logo ************************************

procedure DrawVampyrLogo;
const
  LOGO_SCALED_WIDTH = 580;  // 145 * 4
  LOGO_SCALED_HEIGHT = 100;  // 25 * 3 (changed from 50)
  LOGO_TOP_MARGIN = 10;     // Pixels from top of status area
  HORIZONTAL_SCALE = 4;     // 4x horizontal scaling
  VERTICAL_SCALE = 4;       // 3x vertical scaling (changed from 2)
  
var
  x, y, dx, dy: Integer;
  logoX, logoY: Integer;
  colorIndex: Byte;
  color: LongWord;
begin
  if not LogoLoaded then
  begin
    // Try to load the logo if not loaded
    if not LoadVampyrLogo then
      Exit;
  end;
  
  // Calculate position to center the logo in the status area
  // Original: 145x25 pixels
  // Scaled: 580x75 pixels (4x horizontal, 3x vertical)
  
  // Center horizontally in status area, with margin from top
  logoX := STATUS_AREA_X + (STATUS_AREA_WIDTH - LOGO_SCALED_WIDTH) div 2;
  logoY := 10 + LOGO_TOP_MARGIN;
  
  // Draw the logo with 4x horizontal and 3x vertical scaling
  for y := 1 to 25 do
  begin
    for x := 1 to 145 do
    begin
      colorIndex := VampyrLogo[x, y];
      if colorIndex > 0 then
      begin
        color := EGAtoRGB(colorIndex);
        // Draw 4x3 block for each pixel (4x horizontal, 3x vertical)
        for dx := 0 to HORIZONTAL_SCALE - 1 do
          for dy := 0 to VERTICAL_SCALE - 1 do
            PutPixel(logoX + (x-1)*HORIZONTAL_SCALE + dx, 
                     logoY + (y-1)*VERTICAL_SCALE + dy, 
                     color);
      end;
    end;
  end;
end;
  

//**************************************** Draw Status Area ****************************************
procedure DrawStatusArea;
const
  BG = $FF000000;   // lighter gray so it's clearly visible
  PAD = 6;
var
  x0, y0, w, h: Integer;
  i, j: Integer;
begin
  x0 := STATUS_AREA_X;
  y0 := STATUS_AREA_Y;
  w  := STATUS_AREA_WIDTH;
  h  := STATUS_AREA_HEIGHT;

  // Fill background
  for j := 0 to h - 1 do
    for i := 0 to w - 1 do
      PutPixel(x0 + i, y0 + j, BG);

  // Draw the Vampyr logo AFTER filling the panel so it stays visible
  DrawVampyrLogo;

end;

//**************************************** Draw Message Area ****************************************
procedure DrawMessageArea;
var x0, y0, w, h, i, j: Integer;
begin
  x0 := MESSAGE_AREA_X - 8;        // optional left padding for a nicer margin
  y0 := MESSAGE_AREA_Y;
  w  := ScreenW - x0 - 12;     // or whatever width you want
  h  := MESSAGE_AREA_HEIGHT;

  // fill black to erase message area between renders
  for j := 0 to h - 1 do
    for i := 0 to w - 1 do
      PutPixel(x0 + i, y0 + j, $FF000000);
end;



// ********************************************** Render Frame **********************************************
procedure RenderFrame;
var tnow: QWord;
begin
  //if GDisplayFrozen then Exit;
  tnow := NowMs;
  Mons_Update(tnow);
  DrawMapView;       // background / animated tiles
  DrawStatusArea;    // fills panel + draws logo each frame
  Status_Draw;
  DrawMessageArea;   // fills panel
  Message_Render;      // draw messages
  Present;           // uploads whole framebuffer
end;

end.
