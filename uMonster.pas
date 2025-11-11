unit UMonster;

{$mode objfpc}{$H+}
{$H-}
{$PACKRECORDS 1}

interface

uses
  SysUtils, Math;

type
  // Which per-location monster family we're using (maps to *.CON/*.DAT choice)
  TMonSetKind = (msTown, msDungeon, msRuin, msLife);
type
  TBlitScaledProc = procedure(src: PDWord; x, y, w, h: LongInt);

type
  TCanOccupyFunc = function(x, y: Integer): Boolean;

  // Encounter index range within ENCONTER.SET (inclusive)
  TEncounterRange = record
    StartIndex: Integer;
    EndIndex: Integer;
  end;
type
  // Weight config for wandering NPCs (values are relative weights; percentages OK)
  TWanderWeights = record
    Stay, Up, Down, Left, Right: Word;
  end;

  // Function type to fetch a pointer to a 32-bit RGBA 18x18 tile (scaled by caller)
  // idx ∈ [0..25] for 26 monster frames (13 base + 13 alt)
  TGetMonTilePtr = function(idx: Integer): PUInt32;

procedure Mons_Init(const DataDir: string);
procedure Mons_Clear;
procedure Mons_LoadSet(const Kind: TMonSetKind; const Range: TEncounterRange; GetTile: TGetMonTilePtr;
          const SetFileName: string = 'ENCONTER.SET');
procedure Mons_Update(const nowMs: QWord);
procedure Mons_Draw7x7_UsingMaskAndBlitter(centerX, centerY: Integer; var VMask; tileX, tileY, tileW,
          tileH: Integer; BlitProc: TBlitScaledProc);
function  Mons_NPCAt(const x, y: Integer): Integer;  // returns idx in internal list, -1 if none
function  Mons_IsBlocked(const x, y: Integer): Boolean;
function  MakeRange(a, b: Integer): TEncounterRange; inline;
procedure Mons_TakeTurn(CanOccupy: TCanOccupyFunc; const PlayerX, PlayerY: Integer);
procedure Mons_SetWanderWeights(Stay, Up, Down, Left, Right: Integer);
function Mons_GetNPCName(const idx: Integer): ShortString;
procedure Mons_GetNPCMsgs(const idx: Integer; out s1, s2: ShortString);
procedure Mons_GetNPCInfo(const idx: Integer; out Name: ShortString; 
  out NumInGroup: Byte; out Weapon, Armor: Byte);



implementation

type
  // On-disk ENCONTER.SET record (147 bytes)
  TSetMonOnDisk = packed record
    MonsterName : Byte;      // 0..12 (index into current monster stats/tiles)
    Status      : Byte;      // 0 Ambush, 1 Attack, 2 Run, 3 Steal, 4 Stand, 5 Wander
    NumInGroup  : Byte;
    X, Y        : Byte;      // 0..49 within 50x50 entry maps
    Msg1        : String[70];
    Msg2        : String[70];
  end;

  // On-disk Monster stats (28 bytes) — matches 1989 Turbo Pascal layout
  TMonsterStat = packed record
    Name          : String[15];
    HitPts        : SmallInt;
    XPVal         : Word;
    Offensive     : Byte;
    Defensive     : Byte;
    Weapon        : Byte;
    Armor         : Byte;
    MaxNumInGroup : Byte;
    MagicRes      : Byte;
    TreasureType  : Byte;
    SpecialAttack : Byte;
  end;

  // Runtime NPC instance (from ENCONTER.SET)
  TNPC = record
    MonIdx       : Byte;     // 0..12
    Status       : Byte;
    NumInGroup   : Byte;
    X, Y         : Byte;
    Msg1, Msg2   : ShortString;
    HasAltFrame  : Boolean;  // true if MonIdx+13 < 26
  end;

  PBoolGrid7 = ^TBoolGrid7;
  TBoolGrid7 = array[-3..3, -3..3] of Boolean;

var
  GDataDir   : string;
  GKind      : TMonSetKind;
  GGetTile   : TGetMonTilePtr;
  GStats     : array[0..12] of TMonsterStat;
  GNPCs      : array of TNPC;
  GOcc       : array[0..49,0..49] of Boolean; // simple 50x50 occupancy (friendly locations are 50x50)
  GAnimOn    : Boolean;
  GNextFlip  : QWord;
  GFlipMs    : QWord = 400;  // ~2.5 Hz classic DOS blink
  GWanderWeights: TWanderWeights = (Stay: 60;  Up: 10;  Down: 10;  Left: 10;  Right: 10);

//*************************************** StatsFileNameForKind *************************************
function  StatsFileNameForKind(k: TMonSetKind): string;
begin
  case k of
    msTown:    Result := 'TOWNMON.DAT';
    msDungeon: Result := 'DUNGMON.DAT';
    msRuin:    Result := 'RUINMON.DAT';
    msLife:    Result := 'LIFEMON.DAT';
  end;
end;

// **************************************** MakeRange ****************************************
function MakeRange(a,b: Integer): TEncounterRange; inline;
begin
  Result.StartIndex := a;
  Result.EndIndex   := b;
end;

// **************************************** ClearOcc ****************************************
procedure ClearOcc;
var x,y: Integer;
begin
  for y := 0 to 49 do
    for x := 0 to 49 do
      GOcc[x,y] := False;
end;

// **************************************** Mons_Init ****************************************
procedure Mons_Init(const DataDir: string);
begin
  GDataDir := IncludeTrailingPathDelimiter(DataDir);
  SetLength(GNPCs, 0);
  ClearOcc;
  GAnimOn := False;
  GNextFlip := 0;
  Randomize;

end;

// **************************************** Mons_Clear ****************************************
procedure Mons_Clear;
begin
  SetLength(GNPCs, 0);
  ClearOcc;
  GAnimOn := False;
  GNextFlip := 0;
end;

// **************************************** LoadStatsForKind ****************************************
procedure LoadStatsForKind(const k: TMonSetKind);
var
  f: File;
  i: Integer;
  fname: string;
begin
  fname := GDataDir + StatsFileNameForKind(k);
  if not FileExists(fname) then
  begin
    // No hard fail — leave stats zeroed; names may be blank in viewer
    FillChar(GStats, SizeOf(GStats), 0);
    Exit;
  end;
  Assign(f, fname);
  Reset(f, SizeOf(TMonsterStat));
  try
    // read 13 records (0..12) if present
    for i := 0 to 12 do
    begin
      if FilePos(f) >= FileSize(f) then Break;
      Seek(f, i);
      BlockRead(f, GStats[i], 1);
    end;
  finally
    Close(f);
  end;
end;

// **************************************** Mons_LoadSet ****************************************
procedure Mons_LoadSet(const Kind: TMonSetKind; const Range: TEncounterRange;
                       GetTile: TGetMonTilePtr; const SetFileName: string);
var
  f: File;
  rec: TSetMonOnDisk;
  i, n, idx: Integer;
  nx, ny: Integer;
  fname: string;
begin
  GKind := Kind;
  GGetTile := GetTile;

  // Stats for this location family
  LoadStatsForKind(Kind);

  // Read ENCONTER.SET slice
  fname := GDataDir + SetFileName;
  SetLength(GNPCs, 0);
  ClearOcc;

  if not FileExists(fname) then Exit;

  Assign(f, fname);
  Reset(f, 147); // exact record size
  try
    n := Range.EndIndex - Range.StartIndex + 1;
    if n < 0 then Exit;
    SetLength(GNPCs, n);
    idx := 0;

    for i := Range.StartIndex to Range.EndIndex do
    begin
    Seek(f, i);
    BlockRead(f, rec, 1);

    // Accept 1..50 from original data (defensive)
    if (rec.MonsterName > 12) or (rec.X < 1) or (rec.X > 50) or (rec.Y < 1) or (rec.Y > 50) then
        Continue;

    // 👉 zero-base + clamp to 0..49
    // (Math.Min/Max are fine since you’ve added Math)
    // If you prefer no clamp, assume data is 1..50 and just subtract 1.
    nx := rec.X - 1; ny := rec.Y - 1;
    // I’ll keep the clamp to be safe:
    // var nx := Max(0, Min(49, rec.X - 1));
    // var ny := Max(0, Min(49, rec.Y - 1));

    GNPCs[idx].MonIdx      := rec.MonsterName;
    GNPCs[idx].Status      := rec.Status;
    GNPCs[idx].NumInGroup  := rec.NumInGroup;
    GNPCs[idx].X           := nx;        // 👉 use adjusted
    GNPCs[idx].Y           := ny;        // 👉 use adjusted
    GNPCs[idx].Msg1        := rec.Msg1;
    GNPCs[idx].Msg2        := rec.Msg2;
    GNPCs[idx].HasAltFrame := (rec.MonsterName + 13) < 26;

    // 👉 mark occupancy with adjusted coords
    GOcc[nx, ny] := True;

    Inc(idx);
    end;

    // shrink if any were skipped
    if idx <> n then
      SetLength(GNPCs, idx);

  finally
    Close(f);
  end;

  // Reset animation
  GAnimOn := False;
  GNextFlip := 0;
end;

// **************************************** Mons_Update ****************************************
procedure Mons_Update(const nowMs: QWord);
begin
  if nowMs >= GNextFlip then
  begin
    GAnimOn := not GAnimOn;
    GNextFlip := nowMs + GFlipMs;
  end;
end;

// ************************************** VisibleFromMask ****************************************
function VisibleFromMask(var VMask; rx, ry: Integer): Boolean; inline;
var
  p: PBoolGrid7;
begin
  p := @VMask;
  Result := p^[rx, ry];
end;

// ******************************* Mons_Draw7x7_UsingMaskAndBlitter *******************************
procedure Mons_Draw7x7_UsingMaskAndBlitter(centerX, centerY: Integer; var VMask; tileX, tileY,
                                          tileW, tileH: Integer; BlitProc: TBlitScaledProc);
var
  i: Integer;
  wx0, wy0: Integer;
  rx, ry: Integer;
  sx, sy: Integer;
  frameIdx: Integer;
  tilePtr: PUInt32;
begin
  if (Length(GNPCs) = 0) or (not Assigned(GGetTile)) or (not Assigned(BlitProc)) then Exit;

  wx0 := centerX - 3;
  wy0 := centerY - 3;

  for i := 0 to High(GNPCs) do
  begin
    rx := GNPCs[i].X - wx0;
    ry := GNPCs[i].Y - wy0;
    if (rx < 0) or (rx > 6) or (ry < 0) or (ry > 6) then
      Continue;

    if not VisibleFromMask(VMask, rx - 3, ry - 3) then
      Continue;

    if GNPCs[i].HasAltFrame and GAnimOn then
      frameIdx := GNPCs[i].MonIdx + 13
    else
      frameIdx := GNPCs[i].MonIdx;

    tilePtr := GGetTile(frameIdx);
    if tilePtr = nil then Continue;

    sx := tileX + (rx * tileW);
    sy := tileY + (ry * tileH);
    BlitProc(tilePtr, sx, sy, tileW, tileH);
  end;
end;

// **************************************** Mons_NPCAt ****************************************
function Mons_NPCAt(const x, y: Integer): Integer;
var
  i: Integer;
begin
  for i := 0 to High(GNPCs) do
    if (GNPCs[i].X = x) and (GNPCs[i].Y = y) then
      Exit(i);
  Result := -1;
end;

// *************************************** Mons_IsBlocked *****************************************
function Mons_IsBlocked(const x, y: Integer): Boolean;
begin
  if (x < 0) or (y < 0) or (x > 49) or (y > 49) then Exit(False);
  Result := GOcc[x, y];
end;


//************************************* Mons_SetWanderWeights ************************************
procedure Mons_SetWanderWeights(Stay, Up, Down, Left, Right: Integer);
function Clamp0(v: Integer): Word;
  begin
    if v < 0 then Exit(0) else if v > High(Word) then Exit(High(Word)) else Exit(v);
  end;
begin
  GWanderWeights.Stay  := Clamp0(Stay);
  GWanderWeights.Up    := Clamp0(Up);
  GWanderWeights.Down  := Clamp0(Down);
  GWanderWeights.Left  := Clamp0(Left);
  GWanderWeights.Right := Clamp0(Right);
end;


//*************************************** Mons_TakeTurn *********************************************
procedure Mons_TakeTurn(CanOccupy: TCanOccupyFunc; const PlayerX, PlayerY: Integer);
const
  // 0..4: Up, Down, Left, Right, Stay
  DIRS: array[0..4] of record dx,dy: ShortInt end = (
    (dx:  0; dy: -1),  // up
    (dx:  0; dy:  1),  // down
    (dx: -1; dy:  0),  // left
    (dx:  1; dy:  0),  // right
    (dx:  0; dy:  0)   // stay
  );

  // how many attempts to sample a valid direction before giving up
  MAX_TRIES = 5;

var
  i, tries: Integer;

  function PickDirIndexWeighted: Integer;
  var
    total, r, acc: LongInt;
  begin
    // compute total weight (treat all-zero as "stay")
    total := LongInt(GWanderWeights.Stay) + GWanderWeights.Up + GWanderWeights.Down +
             GWanderWeights.Left + GWanderWeights.Right;
    if total <= 0 then Exit(4); // stay

    r := Random(total); // 0..total-1
    acc := GWanderWeights.Up;
    if r < acc then Exit(0);                   // up
    acc := acc + GWanderWeights.Down;
    if r < acc then Exit(1);                   // down
    acc := acc + GWanderWeights.Left;
    if r < acc then Exit(2);                   // left
    acc := acc + GWanderWeights.Right;
    if r < acc then Exit(3);                   // right
    Result := 4;                               // stay
  end;

var
  dirIdx: Integer;
  nx, ny: Integer;
begin
  if not Assigned(CanOccupy) then Exit;

  for i := 0 to High(GNPCs) do
  begin
    // Status = 5 means “wander”
    if GNPCs[i].Status <> 5 then Continue;

    tries := 0;
    repeat
      Inc(tries);
      dirIdx := PickDirIndexWeighted;

      // stay: do nothing this turn
      if dirIdx = 4 then Break;

      nx := GNPCs[i].X + DIRS[dirIdx].dx;
      ny := GNPCs[i].Y + DIRS[dirIdx].dy;

      // local bounds 0..49 (locals are 50×50)
      if (nx < 0) or (ny < 0) or (nx > 49) or (ny > 49) then
        Continue;

      // cannot step onto the player
      if (nx = PlayerX) and (ny = PlayerY) then
        Continue;

      // map + NPC occupancy check via callback
      if not CanOccupy(nx, ny) then
        Continue;

      // move: update occupancy then coords
      GOcc[GNPCs[i].X, GNPCs[i].Y] := False;
      GNPCs[i].X := nx;
      GNPCs[i].Y := ny;
      GOcc[nx, ny] := True;
      Break; // done for this NPC
    until tries >= MAX_TRIES;
    // If no valid move found in tries, the NPC effectively stays.
  end;
end;

function Mons_GetNPCName(const idx: Integer): ShortString;
begin
  if (idx >= 0) and (idx <= High(GNPCs)) and
     (GNPCs[idx].MonIdx >= 0) and (GNPCs[idx].MonIdx <= High(GStats)) then
    Result := GStats[GNPCs[idx].MonIdx].Name
  else
    Result := '';
end;

procedure Mons_GetNPCMsgs(const idx: Integer; out s1, s2: ShortString);
begin
  if (idx >= 0) and (idx <= High(GNPCs)) then
  begin
    s1 := GNPCs[idx].Msg1;
    s2 := GNPCs[idx].Msg2;
  end
  else
  begin
    s1 := '';
    s2 := '';
  end;
end;

procedure Mons_GetNPCInfo(const idx: Integer; out Name: ShortString; 
  out NumInGroup: Byte; out Weapon, Armor: Byte);
var
  npc: ^TNPC;  // Add this line
begin
  if (idx < 0) or (idx > High(GNPCs)) then
  begin
    Name := '';
    NumInGroup := 0;
    Weapon := 0;
    Armor := 0;
    Exit;
  end;
  
  npc := @GNPCs[idx];  // Get a pointer to the NPC
  Name := GStats[npc^.MonIdx].Name;
  NumInGroup := npc^.NumInGroup;  // Now this correctly gets the NPC's NumInGroup
  Weapon := GStats[npc^.MonIdx].Weapon;
  Armor := GStats[npc^.MonIdx].Armor;
end;

end.
