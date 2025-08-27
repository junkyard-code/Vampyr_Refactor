unit uGameTypes;
{$mode objfpc}{$H+}
{$PACKRECORDS 1}

interface

uses
  SysUtils,
  SDL2;

type
  TTileSet = record
    Count: Integer;
    Atlas: PSDL_Texture;
    AtlasCols: Integer;
    AtlasRows: Integer;
  end;

  TMapType = (mtWorld, mtTown, mtCastle, mtDungeon, mtRuin, mtVampyrCastle);

  TStats = array[1..6] of Byte;
  TByteArray = array of Byte;
  TIntegerDynArray = array of Integer;

  TBooleanDynArray = array of Boolean;

  TBooleanGrid = record
    Width, Height: Integer;
    Data: TBooleanDynArray;
  end;

  TTileMap = record
    Width, Height, IndexSize: Integer;
    Data: TByteArray;
  end;

  TSkills = array[1..9] of Byte;

  TPlayer = record
    Name: String[10];
    Race: Byte;
    Level: Byte;
    Life, CLife, Gold: Integer;
    XP: LongInt;
    Magic, CMagic: Byte;
    Stats: TStats;
    TempSkills: array[1..4] of Byte;
    Skills: TSkills;
    Weapon, Armor: Byte;
    Mission: array[1..6] of Boolean;
    KingTalk: array[1..5] of Boolean;
    Items: array[1..4] of Boolean;
    XLoc, YLoc: Byte;
    MiscMagic, StepsWalked: Byte;
    BackPack: array[1..5] of Byte;
    WeaponDur: array[0..5] of ShortInt;
    ArmorDur: ShortInt;
  end;

  TWorldState = record
    // Raw data
    worldIDs: TTileMap;
    tiles: TTileSet;
    univPixels, landPixels, townPixels, mergedPixels: PUInt32;
    univCount, landCount, townCount, mergedCount: Integer;
    debugTownTiles: TTileSet;
    drawMapA, drawMapB: TTileMap; // Pre-calculated maps for animation
    visibilityMap: TBooleanGrid;     // Final map with LOS applied
    reverseMap: TIntegerDynArray;      // Reverse map: merged index -> logical TileID

    // Animation state
    animEnabled: Boolean;
    animAltNow: Boolean;
    animDelayMs: Cardinal;
    nextSwap: Cardinal;

    // Camera & input state
    cameraX, cameraY: Integer;
    lastWorldX, lastWorldY: Integer;

    // Game state
    debugTileView: Boolean;
    TileViewerScrollY: Integer;
    VisibilityEnabled: Boolean;
    CollisionEnabled: Boolean;
    losRadius: Integer;
    Player: TPlayer;
    DataDir: AnsiString;
    CurrentMapType: TMapType;
  end;

var
  UNIV_TRAVERSABLE: array[0..15] of Boolean;
  LAND_TRAVERSABLE: array[0..16] of Boolean;
  TOWN_TRAVERSABLE: array[0..19] of Boolean;
  DUNGEON_TRAVERSABLE: array[0..34] of Boolean;

function DataPath(const BaseDir, name: string): string;

procedure InitializeTraversalData;
procedure FreeTileMap(var M: TTileMap);
procedure FreeBooleanGrid(var G: TBooleanGrid);

implementation

function DataPath(const BaseDir, name: string): string;
begin
  // Use absolute path to the data directory
  Result := 'C:\Users\Gamer\Documents\Vampyr_Refactor\data\' + name;
  writeln('Looking for file: ', Result);
  if not FileExists(Result) then
    writeln('File not found: ', Result);
end;


procedure InitializeTraversalData;
var i: Integer;
begin
  // Initialize all to True (traversable)
  for i := Low(UNIV_TRAVERSABLE) to High(UNIV_TRAVERSABLE) do UNIV_TRAVERSABLE[i] := True;
  for i := Low(LAND_TRAVERSABLE) to High(LAND_TRAVERSABLE) do LAND_TRAVERSABLE[i] := True;
  for i := Low(TOWN_TRAVERSABLE) to High(TOWN_TRAVERSABLE) do TOWN_TRAVERSABLE[i] := True;
  for i := Low(DUNGEON_TRAVERSABLE) to High(DUNGEON_TRAVERSABLE) do DUNGEON_TRAVERSABLE[i] := True;

  // Set non-traversable tiles based on spreadsheet
  // UNIV.CON
  UNIV_TRAVERSABLE[0] := False;
  UNIV_TRAVERSABLE[1] := False;
  for i := 8 to 14 do UNIV_TRAVERSABLE[i] := False;

  // LAND.CON
  LAND_TRAVERSABLE[5] := False;
  LAND_TRAVERSABLE[6] := False;
  LAND_TRAVERSABLE[8] := False;

  // TOWN.CON
  for i := 4 to 19 do TOWN_TRAVERSABLE[i] := False;

  // DUNGEON.CON
  for i := 0 to 15 do DUNGEON_TRAVERSABLE[i] := False;
  DUNGEON_TRAVERSABLE[18] := False;
  DUNGEON_TRAVERSABLE[19] := False;
end;

procedure FreeTileMap(var M: TTileMap);
begin
  M.Data := nil;
end;

procedure FreeBooleanGrid(var G: TBooleanGrid);
begin
  G.Data := nil;
end;

end.
