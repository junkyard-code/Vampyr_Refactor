unit uMapping;
{$mode objfpc}{$H+}

interface

uses
  uGameTypes;

type
  TSourceKind = (SK_UNIV, SK_LAND, SK_TOWN, SK_DUNGEON);
  TTileRef = record
    Kind: TSourceKind;
    Frame1: Integer;
    Frame2: Integer; // -1 if no animation
  end;

function MapWorldID(ID: Integer): TTileRef;
function MapTownID(ID: Integer): TTileRef;
function MapDungeonID(ID: Integer): TTileRef;
function IsTileTraversable(MapType: TMapType; TileID: Integer): Boolean;
function IsTileOccluding(MapType: TMapType; TileID: Integer): Boolean;

implementation

const
  // Hard mapping from user's cross-reference
  WORLD_SRC: array[0..21] of Byte = (
    0,0,0,0,0,0,0,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
  );

  WORLD_IDX: array[0..21] of Byte = (
    0,1,2,3,4,5,6,
    0,2,1,10,11,5,6,7,8,9,3,4,12,13,14
  );

  // Second-frame index within the same .CON; -1 = no animation
  WORLD_IDX2: array[0..21] of SmallInt = (
    12, 13, -1, -1, -1, -1, -1, 15, 17, 16, -1, -1, -1, -1, -1, -1, -1, -1, 18, 19, -1, -1
  );

  // Collision data from spreadsheet
  WORLD_TRAVERSABLE: array[0..21] of Boolean = (
    False, False, True, True, True, True, True, True, True, True, True, True, False, True, True, True, True, True, True, True, True, True
  );

  // Occlusion data from spreadsheet
  WORLD_OCCLUDING: array[0..21] of Boolean = (
    False, False, False, True, False, False, False, False, False, False, False, False, True, True, False, True, False, False, False, False, False, False
  );

  // Collision data for Towns/Castles from spreadsheet
  TOWN_CASTLE_TRAVERSABLE: array[0..27] of Boolean = (
    False, False, True, True, True, True, True, True, False, True, False, True, False, False, True, False, False, False, False, False, False, False, False, True, True, False, True, False
  );

  TOWN_CASTLE_OCCLUDING: array[0..27] of Boolean = (
    False, False, False, True, False, False, False, False, True, False, True, False, False, True, True, True, True, True, True, True, True, False, False, False, False, True, False, False
  );

  // Collision data for Dungeons/Vampyr's Castle from spreadsheet
  DUNGEON_VAMPYR_TRAVERSABLE: array[0..25] of Boolean = (
    False, False, True,  True,  True,  True,  True,  True,  False, True,  True,  False, True,  True,  True,  True,  True,  False, True,  True,  False, True,  False, False, False, False
  );

  DUNGEON_VAMPYR_OCCLUDING: array[0..25] of Boolean = (
    False, False, False, True,  False, False, False, False, False, False, False, False, False, False, False, False, False, True,  True,  False, False, True,  False, True,  True,  False
  );

  DUNGEON_VAMPYR_IDX2: array[0..25] of SmallInt = (
    12, 13, -1, -1, -1, -1, -1, -1, 18, 19, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
  );

function MapWorldID(ID: Integer): TTileRef;
var
  safeID: Integer;
begin
  if (ID < 0) or (ID > 21) then safeID := 0 else safeID := ID;

  if WORLD_SRC[safeID] = 0 then
    Result.Kind := SK_UNIV
  else
    Result.Kind := SK_LAND;

  Result.Frame1 := WORLD_IDX[safeID];
  Result.Frame2 := WORLD_IDX2[safeID];
end;

function MapTownID(ID: Integer): TTileRef;
var
  safeID: Integer;
begin
  if (ID < 0) or (ID > 255) then safeID := 0 else safeID := ID;

  Result.Frame2 := -1; // Default to no animation

  if (safeID >= 0) and (safeID < 8) then
  begin
    // UNIV tiles are mapped directly (Logical ID 0-7 -> UNIV tile 0-7)
    Result.Kind := SK_UNIV;
    Result.Frame1 := safeID;
    Result.Frame2 := WORLD_IDX2[safeID]; // Override for animated UNIV tiles
  end
  else if (safeID >= 8) and (safeID <= 27) then
  begin
    // TOWN tiles (Logical ID 8-27 -> TOWN tile 0-19)
    Result.Kind := SK_TOWN;
    Result.Frame1 := safeID - 8;
  end
  else
  begin
    // Any other logical ID is unmapped and should not be rendered.
    // We return a reference to a transparent tile (UNIV tile 15).
    Result.Kind := SK_UNIV;
    Result.Frame1 := 15;
  end;
end;

function MapDungeonID(ID: Integer): TTileRef;
var
  safeID: Integer;
begin
  if (ID < 0) or (ID > 25) then safeID := 0 else safeID := ID;

  Result.Frame2 := DUNGEON_VAMPYR_IDX2[safeID];

  if (safeID >= 0) and (safeID < 8) then
  begin
    // UNIV tiles are mapped directly (Logical ID 0-7 -> UNIV tile 0-7)
    Result.Kind := SK_UNIV;
    Result.Frame1 := safeID;
  end
  else if (safeID >= 8) and (safeID <= 25) then
  begin
    // DUNGEON tiles (Logical ID 8-25 -> DUNGEON tile 0-17)
    Result.Kind := SK_DUNGEON;
    Result.Frame1 := safeID - 8;
  end
  else
  begin
    // Fallback to a transparent tile for any unhandled ID.
    Result.Kind := SK_UNIV;
    Result.Frame1 := 15;
  end;
end;

function IsTileTraversable(MapType: TMapType; TileID: Integer): Boolean;
var
  Ref: TTileRef;
begin
  case MapType of
    mtWorld:
    begin
      if (TileID >= 0) and (TileID <= 21) then
        Result := WORLD_TRAVERSABLE[TileID]
      else
        Result := False; // Out of bounds is non-traversable
    end;
    mtTown, mtCastle:
    begin
      if (TileID >= 0) and (TileID <= 27) then
        Result := TOWN_CASTLE_TRAVERSABLE[TileID]
      else
        Result := False; // Out of bounds is non-traversable
    end;
    mtDungeon, mtRuin, mtVampyrCastle:
    begin
      if (TileID >= 0) and (TileID <= 25) then
        Result := DUNGEON_VAMPYR_TRAVERSABLE[TileID]
      else
        Result := False; // Out of bounds is non-traversable
    end;
    else Result := False;
  end;
end;

function IsTileOccluding(MapType: TMapType; TileID: Integer): Boolean;
begin
  case MapType of
    mtWorld:
    begin
      if (TileID >= 0) and (TileID <= 21) then
        Result := WORLD_OCCLUDING[TileID]
      else
        Result := True; // Out of bounds is occluding
    end;
    mtTown, mtCastle:
    begin
      if (TileID >= 0) and (TileID <= 27) then
        Result := TOWN_CASTLE_OCCLUDING[TileID]
      else
        Result := True; // Out of bounds is occluding
    end;
    mtDungeon, mtRuin, mtVampyrCastle:
    begin
      if (TileID >= 0) and (TileID <= 25) then
        Result := DUNGEON_VAMPYR_OCCLUDING[TileID]
      else
        Result := True; // Out of bounds is occluding
    end;
    else Result := False;
  end;
end;

end.
