unit fb_viewer;
{$mode objfpc}{$H+}

Interface

uses
  CRT, SDL2, SysUtils, Math, Classes, uGfx_fb, data_loaders, uConTiles, 
  StatusPanel, uMonster, uItems, uDisplay, uAudioSDL;

type

   TBoolGrid7 = array[-3..3, -3..3] of Boolean;   // 7x7 grid of booleans for occlusion

type
  TEntranceKind = (
    ekNone,
    ekTown0, ekTown1, ekTown2, ekTown3, ekTown4, ekTown5, // Balinor..Myron
    ekCastle,
    ekDungeonA, ekDungeonB,
    ekRuinA, ekRuinB,
    ekVCastle,
    ekAfterlife
  );

type
  TSignRec = packed record
    X, Y : Byte;         // stored like the old files (1..50)
    Msg1 : ShortString;  // String[70] in TP
    Msg2 : ShortString;  // String[70]
  end;

type
  TInputMode = (imNormal, imLook);

type
  TPendingAction = (paNone, paLook, paTalk, paClimb);

var
 
  WorldMapA: TMap;
  ReturnWorldX, ReturnWorldY: Integer;
  // --- Local map level tracking ---
  ActiveMapPath    : string = '';  // e.g., 'data\town.map', 'data\dungeon.map', ...
  ActiveLevelIndex : Integer = 0;  // which 50x50 chunk currently loaded
  ActiveLevelCount : Integer = 1;  // derived from file size / 2500 (50*50)
  ActiveEntrance: TEntranceKind = ekNone;
  SignNum: Integer = 0; // old SignNum
  LookPending: Boolean = False;
  TalkPending : Boolean = False;
  PendingAction: TPendingAction = paNone;

var
  Event: TSDL_Event;
  Running: Boolean;
  //World: TWorldState;
  FrameCount: Integer;
  LastTime: UInt32;

procedure AM_SetActiveToWorld;
//procedure InitializeWorld;
procedure DrawBorder;
function MapGet(const X, Y: Integer): Byte; inline;
procedure LoadWorldMap(const Filename: string);
function InBounds(const x, y: Integer): Boolean; inline;
function IsValidPosition(x, y: Integer): Boolean;
function TileFreeForNPC(const x, y: Integer): Boolean;
procedure MovePlayer(dx, dy: Integer);
function GetTownMonTile_Int(idx: Integer): PUInt32; inline;
function GetDungMonTile_Int(idx: Integer): PUInt32; inline;
function GetRuinMonTile_Int(idx: Integer): PUInt32; inline;
function GetLifeMonTile_Int(idx: Integer): PUInt32; inline;

function BaseDir: string;
function LoadLocalChunk50x50(const FN: AnsiString; index: Integer; out M: TMap): Boolean;
function LoadActiveLocalLevel(const newIndex: Integer): Boolean;
procedure LoadEncountersForCurrentLevel;
function Map_GetTileID(x, y: Integer): Byte; inline;

  Implementation

//*********************************************** AM_SetActiveToWorld ***********************************************
procedure AM_SetActiveToWorld;
begin
  ActiveKind := mkWorld;
  ActiveMap := WorldMapA; // shallow copy is fine
  Mons_Clear;             // << no NPCs on the world map
end;



//**************************************** Initialize World ************************************

//procedure InitializeWorld;
//begin
  // Initialize world state
  //FillChar(World, SizeOf(World), 0);
  //World.VisibilityEnabled := True;
  //World.TileViewerScrollY := 0;
  // Load game data
  //LoadVampyrLogo;
  // Set up player position (example)
//end;

//**************************************** Draw Border ****************************************

procedure DrawBorder;
  // Helper procedure to draw a horizontal line
  procedure DrawHorizontalLine(x1, x2, y: Integer; color: LongWord);
  var
    x: Integer;
  begin
    for x := x1 to x2 do
      PutPixel(x, y, color);
  end;
  
  // Helper procedure to draw a vertical line
  procedure DrawVerticalLine(x, y1, y2: Integer; color: LongWord);
  var
    y: Integer;
  begin
    for y := y1 to y2 do
      PutPixel(x, y, color);
  end;
  
  // Procedure to draw a border rectangle with 3D effect
  procedure DrawBorderRect();
 
  begin
 
      // Top and bottom borders
      DrawHorizontalLine(0, SCREEN_WIDTH-1, 0, COLOR_RED_DARK);      
      DrawHorizontalLine(0, SCREEN_WIDTH-1, 1, COLOR_RED_DARK);     
      DrawHorizontalLine(0, SCREEN_WIDTH-1, 2, COLOR_RED_DARK);  
      DrawHorizontalLine(0, SCREEN_WIDTH-1, 3, COLOR_RED_DARK);  
      DrawHorizontalLine(4, SCREEN_WIDTH-5, 4, COLOR_RED);  
      DrawHorizontalLine(4, SCREEN_WIDTH-5, 5, COLOR_RED);  
      DrawHorizontalLine(4, SCREEN_WIDTH-5, 6, COLOR_RED); 
      DrawHorizontalLine(4, SCREEN_WIDTH-5, 7, COLOR_RED);   
      DrawHorizontalLine(6, SCREEN_WIDTH-7, 8, COLOR_RED_DARK);      
      DrawHorizontalLine(6, SCREEN_WIDTH-7, 9, COLOR_RED_DARK);     
      DrawHorizontalLine(6, SCREEN_WIDTH-7, 10, COLOR_RED_DARK);  
      DrawHorizontalLine(6, SCREEN_WIDTH-7, 11, COLOR_RED_DARK);  

      DrawHorizontalLine(6, SCREEN_WIDTH-7, SCREEN_HEIGHT-12, COLOR_RED_DARK);  
      DrawHorizontalLine(6, SCREEN_WIDTH-7, SCREEN_HEIGHT-11, COLOR_RED_DARK);      
      DrawHorizontalLine(6, SCREEN_WIDTH-7, SCREEN_HEIGHT-10, COLOR_RED_DARK);     
      DrawHorizontalLine(6, SCREEN_WIDTH-7, SCREEN_HEIGHT-9, COLOR_RED_DARK); 
      DrawHorizontalLine(5, SCREEN_WIDTH-5, SCREEN_HEIGHT-8, COLOR_RED);  
      DrawHorizontalLine(5, SCREEN_WIDTH-5, SCREEN_HEIGHT-7, COLOR_RED);   
      DrawHorizontalLine(5, SCREEN_WIDTH-5, SCREEN_HEIGHT-6, COLOR_RED);  
      DrawHorizontalLine(5, SCREEN_WIDTH-5, SCREEN_HEIGHT-5, COLOR_RED);  
      DrawHorizontalLine(0, SCREEN_WIDTH-1, SCREEN_HEIGHT-4, COLOR_RED_DARK);  
      DrawHorizontalLine(0, SCREEN_WIDTH-1, SCREEN_HEIGHT-3, COLOR_RED_DARK);      
      DrawHorizontalLine(0, SCREEN_WIDTH-1, SCREEN_HEIGHT-2, COLOR_RED_DARK);     
      DrawHorizontalLine(0, SCREEN_WIDTH-1, SCREEN_HEIGHT-1, COLOR_RED_DARK);  

      // Left and Right Borders
      DrawVerticalLine(0, 0, SCREEN_HEIGHT-1, COLOR_RED_DARK);      
      DrawVerticalLine(1, 0, SCREEN_HEIGHT-1, COLOR_RED_DARK);     
      DrawVerticalLine(2, 0, SCREEN_HEIGHT-1, COLOR_RED_DARK);  
      DrawVerticalLine(3, 0, SCREEN_HEIGHT-1, COLOR_RED_DARK); 
      DrawVerticalLine(4, 4, SCREEN_HEIGHT-5, COLOR_RED); 
      DrawVerticalLine(5, 4, SCREEN_HEIGHT-5, COLOR_RED);  
      DrawVerticalLine(6, 4, SCREEN_HEIGHT-5, COLOR_RED);  
      DrawVerticalLine(7, 4, SCREEN_HEIGHT-5, COLOR_RED); 
      DrawVerticalLine(8, 8, SCREEN_HEIGHT-10, COLOR_RED_DARK);      
      DrawVerticalLine(9, 8, SCREEN_HEIGHT-10, COLOR_RED_DARK);     
      DrawVerticalLine(10, 8, SCREEN_HEIGHT-10, COLOR_RED_DARK);  
      DrawVerticalLine(11, 8, SCREEN_HEIGHT-10, COLOR_RED_DARK); 

      DrawVerticalLine(SCREEN_WIDTH-12, 8, SCREEN_HEIGHT-10, COLOR_RED_DARK);   
      DrawVerticalLine(SCREEN_WIDTH-11, 8, SCREEN_HEIGHT-10, COLOR_RED_DARK);      
      DrawVerticalLine(SCREEN_WIDTH-10, 8, SCREEN_HEIGHT-10, COLOR_RED_DARK);     
      DrawVerticalLine(SCREEN_WIDTH-9, 8, SCREEN_HEIGHT-10, COLOR_RED_DARK);  
      DrawVerticalLine(SCREEN_WIDTH-8, 4, SCREEN_HEIGHT-5, COLOR_RED);  
      DrawVerticalLine(SCREEN_WIDTH-7, 4, SCREEN_HEIGHT-5, COLOR_RED); 
      DrawVerticalLine(SCREEN_WIDTH-6, 4, SCREEN_HEIGHT-5, COLOR_RED);  
      DrawVerticalLine(SCREEN_WIDTH-5, 4, SCREEN_HEIGHT-5, COLOR_RED);
      DrawVerticalLine(SCREEN_WIDTH-4, 0, SCREEN_HEIGHT-1, COLOR_RED_DARK);   
      DrawVerticalLine(SCREEN_WIDTH-3, 0, SCREEN_HEIGHT-1, COLOR_RED_DARK);      
      DrawVerticalLine(SCREEN_WIDTH-2, 0, SCREEN_HEIGHT-1, COLOR_RED_DARK);     
      DrawVerticalLine(SCREEN_WIDTH-1, 0, SCREEN_HEIGHT-1, COLOR_RED_DARK);  
  end;

begin

  // Draw outer window border
  DrawBorderRect();
  
  // Draw horizontal divider above message area (5 pixels high)
  DrawHorizontalLine(8, SCREEN_WIDTH-10, DIVIDER_Y, COLOR_RED_DARK);      
  DrawHorizontalLine(8, SCREEN_WIDTH-10, DIVIDER_Y+1, COLOR_RED_DARK);     
  DrawHorizontalLine(8, SCREEN_WIDTH-10, DIVIDER_Y+2, COLOR_RED_DARK);  
  DrawHorizontalLine(8, SCREEN_WIDTH-10, DIVIDER_Y+3, COLOR_RED_DARK);  
  DrawHorizontalLine(4, SCREEN_WIDTH-5, DIVIDER_Y+4, COLOR_RED);  
  DrawHorizontalLine(4, SCREEN_WIDTH-5, DIVIDER_Y+5, COLOR_RED); 
  DrawHorizontalLine(4, SCREEN_WIDTH-5, DIVIDER_Y+6, COLOR_RED);  
  DrawHorizontalLine(4, SCREEN_WIDTH-5, DIVIDER_Y+7, COLOR_RED); 
  DrawHorizontalLine(8, SCREEN_WIDTH-10, DIVIDER_Y+8, COLOR_RED_DARK);      
  DrawHorizontalLine(8, SCREEN_WIDTH-10, DIVIDER_Y+9, COLOR_RED_DARK);     
  DrawHorizontalLine(8, SCREEN_WIDTH-10, DIVIDER_Y+10, COLOR_RED_DARK);  
  DrawHorizontalLine(8, SCREEN_WIDTH-10, DIVIDER_Y+11, COLOR_RED_DARK);  

  // Draw vertical divider between map and status areas (5 pixels wide)
  DrawVerticalLine(DIVIDER_X, 8, DIVIDER_Y, COLOR_RED_DARK);   
  DrawVerticalLine(DIVIDER_X+1, 8, DIVIDER_Y, COLOR_RED_DARK);      
  DrawVerticalLine(DIVIDER_X+2, 8, DIVIDER_Y, COLOR_RED_DARK);     
  DrawVerticalLine(DIVIDER_X+3, 8, DIVIDER_Y, COLOR_RED_DARK);  
  DrawVerticalLine(DIVIDER_X+4, 4, DIVIDER_Y+5, COLOR_RED);  
  DrawVerticalLine(DIVIDER_X+5, 4, DIVIDER_Y+5, COLOR_RED); 
  DrawVerticalLine(DIVIDER_X+6, 4, DIVIDER_Y+5, COLOR_RED);  
  DrawVerticalLine(DIVIDER_X+7, 4, DIVIDER_Y+5, COLOR_RED); 
  DrawVerticalLine(DIVIDER_X+8, 8, DIVIDER_Y, COLOR_RED_DARK);   
  DrawVerticalLine(DIVIDER_X+9, 8, DIVIDER_Y, COLOR_RED_DARK);      
  DrawVerticalLine(DIVIDER_X+10, 8, DIVIDER_Y, COLOR_RED_DARK);     
  DrawVerticalLine(DIVIDER_X+11, 8, DIVIDER_Y, COLOR_RED_DARK);  

  // Fill message area with gray background first
  //for y := MESSAGE_AREA_Y to MESSAGE_AREA_Y + MESSAGE_AREA_HEIGHT do
  //  for x := MESSAGE_AREA_X to MESSAGE_AREA_X + MESSAGE_AREA_WIDTH do
  //    PutPixel(x, y, $FF303030);  // Light gray background
 
  // Fill status area with gray background first
  //for y := STATUS_AREA_Y to STATUS_AREA_Y + STATUS_AREA_HEIGHT do
  //  for x := STATUS_AREA_X to STATUS_AREA_X + STATUS_AREA_WIDTH do
  //    PutPixel(x, y, $FF000030);  // Light blue background


end;


// *************************************** MapGet ***************************************
function MapGet(const X, Y: Integer): Byte; inline;
begin
  if (Cardinal(X) < Cardinal(WORLD_WIDTH)) and (Cardinal(Y) < Cardinal(WORLD_HEIGHT)) then
    Result := WorldMap[X, Y]
  else
    Result := 0; // OOB -> black
end;

procedure MapSet(const X, Y: Integer; const V: Byte); inline;
begin
  if (Cardinal(X) < Cardinal(WORLD_WIDTH)) and (Cardinal(Y) < Cardinal(WORLD_HEIGHT)) then
    WorldMap[X, Y] := V;
end;

//**************************************** Load World Map ****************************************
procedure LoadWorldMap(const Filename: string);
var
  F: File;
  Need, Got: Integer;
  Buf: array of Byte;
  x, y, i: Integer;
begin
  Need := WORLD_WIDTH * WORLD_HEIGHT; // 110 * 100 = 11000

  AssignFile(F, Filename); Reset(F, 1);
  try
    SetLength(Buf, Need);
    BlockRead(F, Buf[0], Need, Got);
    if Got <> Need then
    begin
      WriteLn('WORLD.MAP size mismatch: got ', Got, ' expected ', Need);
      Halt(1);
    end;
  finally
    CloseFile(F);
  end;

  // FILE IS X-MAJOR (from MAPMAKER): for each X, Y runs fastest
  i := 0;
  for x := 0 to WORLD_WIDTH - 1 do
    for y := 0 to WORLD_HEIGHT - 1 do
    begin
      MapSet(x, y, Buf[i]);
      Inc(i);
    end;
  
  // Also fill flattened world map and activate it
  WorldMapA.W := WORLD_WIDTH;
  WorldMapA.H := WORLD_HEIGHT;
  SetLength(WorldMapA.Data, WORLD_WIDTH * WORLD_HEIGHT);
  i := 0;
  for x := 0 to WORLD_WIDTH - 1 do
    for y := 0 to WORLD_HEIGHT - 1 do
    begin
      WorldMapA.Data[x + y * WORLD_WIDTH] := WorldMap[x, y];
    end;
  AM_SetActiveToWorld;
Player.xloc := WORLD_WIDTH  div 2; // e.g. 55
  Player.YLoc := WORLD_HEIGHT div 2; // e.g. 50
end;



// ******************************************** InBounds ********************************************
// Check if a coordinate is within the map bounds 50x50
function InBounds(const x, y: Integer): Boolean; inline;
begin
  Result := (x >= 2) and (y >= 2) and (x < ActiveMap.W-2) and (y < ActiveMap.H-2);
end;


//**************************************** IsValidPosition ****************************************
function IsValidPosition(x, y: Integer): Boolean;
begin
  // Keep existing margin rule for locals (world return logic relies on this)
  Result := (x >= 3) and (x < ActiveMap.W-3) and (y >= 3) and (y < ActiveMap.H-3);
end;


// ******************************************** CanStepTo ******************************************
// Player movement collision detection
function CanStepTo(const fromX, fromY, toX, toY: Integer): Boolean;
var
  t: Byte;
begin
  // Hard bounds
  if not InBounds(toX, toY) then Exit(False);

  // Testing toggle
  if not EnableCollision then Exit(True);

  // Terrain collision
  t := AM_Get(toX, toY);
  if TileCollides(ActiveKind, t) then begin
    if ActiveKind = mkWorld then begin
    PlayPunchSound;
    WriteMessage('Blocked!');
    Exit(False);
    end
    else begin
      PlayPunchSound;
      WriteMessage('Watch were you''re going!');
      Exit(False);
    end;
  end;
  // NPC collision (locals only)
  if (ActiveKind <> mkWorld) and Mons_IsBlocked(toX, toY) then begin
    PlayPunchSound;
    WriteMessage('Watch were you''re going!');
    Exit(False);
  end;

  Result := True;
end;


// *********************************************** TileFreeForNPC ************************************
function TileFreeForNPC(const x, y: Integer): Boolean;
var t: Byte;
begin
  if not InBounds(x, y) then Exit(False);
  t := AM_Get(x, y);
  if TileCollides(ActiveKind, t) then Exit(False);
  // do not allow two NPCs on the same tile
  if Mons_IsBlocked(x, y) then Exit(False);
  Result := True;
end;

// ******************************************** TileFreeForNPC_CB *******************************************
// --- add this near TileFreeForNPC, or anywhere above MovePlayer ---

function TileFreeForNPC_CB(x, y: LongInt): Boolean;
begin
  // just forward to the real checker; no const in the signature
  Result := TileFreeForNPC(x, y);
end;

//*********************************************** Move Player ***********************************************
procedure MovePlayer(dx, dy: Integer);
var
  newX, newY: Integer;
begin
  if (dx = 0) and (dy = 0) then Exit;

  newX := Player.xloc + dx;
  newY := Player.YLoc + dy;

  // If still inside the “valid pad”, attempt to step (tile+NPC aware)
  if IsValidPosition(newX, newY) then
  begin
    if CanStepTo(Player.xloc, Player.YLoc, newX, newY) then
    begin
      Player.xloc := newX;
      Player.YLoc := newY;
      writeln('Player moved to [', Player.xloc, ', ', Player.YLoc,']');
      writeln('ReturnWorldX: ', ReturnWorldX, ', ReturnWorldY: ', ReturnWorldY);
      writeln('Player.xloc: ', Player.xloc, ', Player.YLoc: ', Player.YLoc);

      // turn-based: NPCs move after the player moves
      Mons_TakeTurn(@TileFreeForNPC_CB, Player.xloc, Player.YLoc);
    end;
    Exit;
  end;

  // Crossing the edge: only locals pop back to world
  if ActiveKind <> mkWorld then
  begin
    AM_SetActiveToWorld;
    Player.xloc := ReturnWorldX;
    Player.YLoc := ReturnWorldY;
    WriteMessage('Returning to Quilinor...');
    SignNum := 0;
  end;
end;


//************************************************** FillRect ***********************************************

procedure FillRect(const X, Y, W, H: Integer; const Color: LongWord);
var i, j: Integer;

begin
  for j := 0 to H - 1 do
    for i := 0 to W - 1 do
      PutPixel(X + i, Y + j, Color);
end;

//************************************************** DrawRect **********************************************

procedure DrawRect(const X, Y, W, H: Integer; const Color: LongWord);
var i, j: Integer;

begin
  // top & bottom
  for i := 0 to W - 1 do begin
    PutPixel(X + i, Y, Color);
    PutPixel(X + i, Y + H - 1, Color);
  end;
  // left & right
  for j := 0 to H - 1 do begin
    PutPixel(X, Y + j, Color);
    PutPixel(X + W - 1, Y + j, Color);
  end;
end;

// ************************************* Town Monster Tile Access *************************************
function Tiles_Get_TownMon(const Index: Word): PUInt32;
begin
  Result := UConTiles.Tiles_Get_TownMon(Index);
end;

// ************************************* Dungeon Monster Tile Access *************************************
// Later, if you add more monster sheets:
function Tiles_Get_DungeonMon(const Index: Word): PUInt32;
begin
  // hook to GDungeonMon once you load it
  Result := nil;
end;

// ************************************* Ruin Monster Tile Access *************************************
function Tiles_Get_RuinMon(const Index: Word): PUInt32;
begin
  // hook to GRuinMon once you load it
  Result := nil;
end;


// ************************************ Choose Monster Tile Index ***********************************
function GetActiveMonTilePtr(const idx: Integer): PUInt32;
begin
  case ActiveKind of
    mkTown, mkCastle:   Result := Tiles_Get_TownMon(idx);
    mkDungeon:          Result := Tiles_Get_DungeonMon(idx);
    mkRuin, mkVCastle:  Result := Tiles_Get_RuinMon(idx);
    mkAfterlife:        Result := Tiles_Get_LifeMon(idx);
  else
    Result := Tiles_Get_TownMon(idx); // safe fallback for testing
  end;
end;

// *************************************** GetTownMonTile_Int ****************************************
// --- Monster tile getters with the exact signature uMonster expects ---
function GetTownMonTile_Int(idx: Integer): PUInt32; inline;
begin
  Result := UConTiles.Tiles_Get_TownMon(Word(idx));
end;

function GetDungMonTile_Int(idx: Integer): PUInt32; inline;
begin
  Result := UConTiles.Tiles_Get_DungeonMon(Word(idx));
end;

function GetRuinMonTile_Int(idx: Integer): PUInt32; inline;
begin
  Result := UConTiles.Tiles_Get_RuinMon(Word(idx));
end;

function GetLifeMonTile_Int(idx: Integer): PUInt32; inline;
begin
  Result := UConTiles.Tiles_Get_LifeMon(Word(idx));
end;


// ******************************** Load Encounters for Current Level ********************************
procedure LoadEncountersForCurrentLevel;
var
  lvl   : Integer; // 1-based
begin
  // floor level is 1-based in the old code
  lvl := ActiveLevelIndex + 1;

  case ActiveEntrance of
    // Towns (fixed, one “level” each)
    ekTown0: Mons_LoadSet(msTown, MakeRange(  0,  24), @GetTownMonTile_Int, 'ENCONTER.SET');
    ekTown1: Mons_LoadSet(msTown, MakeRange( 25,  49), @GetTownMonTile_Int, 'ENCONTER.SET');
    ekTown2: Mons_LoadSet(msTown, MakeRange( 50,  74), @GetTownMonTile_Int, 'ENCONTER.SET');
    ekTown3: Mons_LoadSet(msTown, MakeRange( 75,  99), @GetTownMonTile_Int, 'ENCONTER.SET');
    ekTown4: Mons_LoadSet(msTown, MakeRange(100, 124), @GetTownMonTile_Int, 'ENCONTER.SET');
    ekTown5:
      begin
        // Old game had mission gating for Myron (125..149 OR 280..297).
        // Use the vanilla slice for now; you can branch later based on missions.
        Mons_LoadSet(msTown, MakeRange(125, 149), @GetTownMonTile_Int, 'ENCONTER.SET');
      end;

    // Castle (3 floors, each 25 records):
    // old formula: LoadSetMon(125 + lvl*25, 149 + lvl*25)
    ekCastle: Mons_LoadSet(msTown, MakeRange(125 + lvl*25, 149 + lvl*25), @GetTownMonTile_Int, 'ENCONTER.SET');

    // Dungeon A: LoadSetMon(263 + lvl*2, 264 + lvl*2)
    ekDungeonA: Mons_LoadSet(msDungeon, MakeRange(263 + lvl*2, 264 + lvl*2), @GetDungMonTile_Int, 'ENCONTER.SET');

    // Dungeon B (the old code had a TODO there — no explicit slice).
    // Leave empty for now or point at a placeholder if you have one.
    ekDungeonB:
      begin
        // TODO: decide the real slice for this entrance
        // Mons_LoadSet(msDungeon, MakeRange(...), @GetDungMonTile_Int, 'ENCONTER.SET');
        Mons_Clear; // safest until you confirm
      end;

    // Ruins: fixed slices by entrance in the old entry logic
    ekRuinA: Mons_LoadSet(msRuin, MakeRange(255, 264), @GetRuinMonTile_Int, 'ENCONTER.SET');
    ekRuinB: Mons_LoadSet(msRuin, MakeRange(250, 254), @GetRuinMonTile_Int, 'ENCONTER.SET');

    // Vampyr's Castle: 3-record slices, level-based:
    // LoadSetMon(268 + lvl*3, 270 + lvl*3)
    // (Old special case with items → 271..272 for lvl=1; add later if needed.)
    ekVCastle:
      Mons_LoadSet(msRuin, MakeRange(268 + lvl*3, 270 + lvl*3), @GetRuinMonTile_Int, 'ENCONTER.SET');

    // Afterlife (single slice)
    ekAfterlife:
      Mons_LoadSet(msLife, MakeRange(225, 249), @GetLifeMonTile_Int, 'ENCONTER.SET');

  else
    Mons_Clear;
  end;
end;


// ******************************** Local Map Loader (50x50 chunks) *****************************

function LoadLocalChunk50x50(const FN: AnsiString; index: Integer; out M: TMap): Boolean;
var
  F: File;
  Got: Integer;
  Buf: array[0..2500-1] of Byte; // 50*50
  x,y,i: Integer;
  offset: LongInt;
begin
  Result := False;

  // Basic existence + size sanity
  if not FileExists(FN) then
  begin
    WriteLn('LoadLocalChunk50x50: missing file: ', FN);
    Exit;
  end;

  // Open as byte-addressed file
  AssignFile(F, FN);
  {$I-} Reset(F, 1); {$I+}
  if IOResult <> 0 then
  begin
    WriteLn('LoadLocalChunk50x50: cannot open: ', FN);
    Exit;
  end;

  // Seek to the chunk: index * 2500 bytes
  offset := index * 2500;
  {$I-} Seek(F, offset); {$I+}
  if IOResult <> 0 then
  begin
    WriteLn('LoadLocalChunk50x50: seek failed: ', FN, ' offset=', offset);
    CloseFile(F);
    Exit;
  end;

  // Read exactly 2500 bytes
  Got := 0;
  {$I-} BlockRead(F, Buf[0], 2500, Got); {$I+}
  CloseFile(F);
  if Got <> 2500 then
  begin
    WriteLn('LoadLocalChunk50x50: short read: got=', Got, ' expected=2500  (', FN, ' index=', index, ')');
    Exit;
  end;

  // Build 50x50 X-major map (Data[X + Y*W])
  M.W := 50; M.H := 50;
  SetLength(M.Data, 50*50);

  i := 0;
  // NOTE: if tiles look transposed/rotated, flip the loop order below.
  for x := 0 to 49 do
    for y := 0 to 49 do
    begin
      M.Data[x + y*50] := Buf[i];
      Inc(i);
    end;

  Result := True;
end;

// **************************************** LoadActiveLocalLevel ****************************************
function LoadActiveLocalLevel(const newIndex: Integer): Boolean;
var
  M: TMap;  // whatever your local map record type is (same as you use now)
begin
  Result := False;
  if (ActiveMapPath = '') or (ActiveKind = mkWorld) then Exit;
  if (newIndex < 0) or (newIndex >= ActiveLevelCount) then Exit;

  if LoadLocalChunk50x50(ActiveMapPath, newIndex, M) then
  begin
    ActiveMap := M;
    ActiveLevelIndex := newIndex;

    // Keep player at same (x,y), or push to center if you prefer:
    // Player.xloc := 25; Player.YLoc := 25;
    // For now, keep same tile; K is explicit so you won't “auto-loop”.
    Result := True;
  end;
end;

// ************************************************ BaseDir ************************************************
function BaseDir: string;
begin
  // Always point to the \"data\" folder under the executable directory
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'data' + DirectorySeparator;
end;

// **************************************** Map_SetTileID ****************************************
procedure Map_SetTileID(x, y: Integer; tile: Byte); inline;
begin
  if (Cardinal(x) < Cardinal(ActiveMap.W)) and (Cardinal(y) < Cardinal(ActiveMap.H)) then
    ActiveMap.Data[x + y * ActiveMap.W] := tile;
end;

// **************************************** Map_GetTileID ****************************************
function Map_GetTileID(x, y: Integer): Byte; inline;
begin
  Result := AM_Get(x, y);
end;


end.
