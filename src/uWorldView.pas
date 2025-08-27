unit uWorldView;
{$mode objfpc}{$H+}

interface

uses
  SDL2, SysUtils, Classes, data_loaders, uMapping, uGameTypes, renderer, uGameLogic;

procedure InitWorld(var S: TWorldState; var R: TRenderer; const DataDir: AnsiString);
procedure FreeWorld(var S: TWorldState; var R: TRenderer);
procedure HandleEvent(var S: TWorldState; var R: TRenderer; const E: TSDL_Event; var Running: Boolean);
procedure UpdateWorld(var S: TWorldState; Win: PSDL_Window);
procedure RenderWorld(var R: TRenderer; var S: TWorldState);
procedure TryEnterLocation(var S: TWorldState; var R: TRenderer);
procedure TryExitLocation(var S: TWorldState; var R: TRenderer);
function CanMoveTo(const S: TWorldState; NewX, NewY: Integer): Boolean;
function GetMapClickInfo(var S: TWorldState; R: TRenderer; mx, my: Integer): AnsiString;
procedure MovePlayer(var S: TWorldState; var R: TRenderer; dX, dY: Integer);

procedure RenderTileViewer(var R: TRenderer; var S: TWorldState);

implementation


function TownOffset(const S: TWorldState): Integer; inline;
begin
  Result := S.univCount;
end;

function LandOffset(const S: TWorldState): Integer; inline;
begin
  Result := S.univCount;
end;

procedure BuildReverseMap(var S: TWorldState);
var
  i, idRange, mappedIdx: Integer;
  tref: TTileRef;
  mapFunc: function(ID: Integer): TTileRef;
  offset: Integer;
begin
  SetLength(S.reverseMap, S.mergedCount);
  for i := 0 to S.mergedCount - 1 do S.reverseMap[i] := -1; // Init

  offset := 0;
  case S.CurrentMapType of
    mtWorld: 
    begin
      idRange := 21;
      mapFunc := @MapWorldID;
      offset := LandOffset(S);
    end;
    mtTown, mtCastle: 
    begin
      idRange := 27; // Cover all possible tiles from spreadsheet
      mapFunc := @MapTownID;
      offset := TownOffset(S);
    end;
    mtDungeon, mtRuin, mtVampyrCastle:
    begin
      idRange := 19; // Cover all possible tiles from spreadsheet
      mapFunc := @MapDungeonID;
      offset := TownOffset(S); // Uses same offset logic as town
    end;
    else exit; // No reverse map for this type
  end;

  for i := 0 to idRange do
  begin
    tref := mapFunc(i);
    if tref.Frame1 >= 0 then
    begin
      if tref.Kind = SK_UNIV then mappedIdx := tref.Frame1 else mappedIdx := offset + tref.Frame1;
      if (mappedIdx < S.mergedCount) and (S.reverseMap[mappedIdx] = -1) then S.reverseMap[mappedIdx] := i;
    end;
    if tref.Frame2 >= 0 then
    begin
      if tref.Kind = SK_UNIV then
        mappedIdx := tref.Frame2
      else
        mappedIdx := offset + tref.Frame2;
      if (mappedIdx < S.mergedCount) and (S.reverseMap[mappedIdx] = -1) then S.reverseMap[mappedIdx] := i;
    end;
  end;
end;

procedure BuildDrawMapForWorld(out dst: TTileMap; const S: TWorldState; const useAlt: Boolean);
var
  i, w, h, idLocal, mapped: Integer;
  tref: TTileRef;
  isOccluding: Boolean;
begin
  w := S.worldIDs.Width; h := S.worldIDs.Height;
  dst.Width := w; dst.Height := h; dst.IndexSize := 1;
  SetLength(dst.Data, w*h);
  for i := 0 to w*h-1 do
  begin
    idLocal := S.worldIDs.Data[i];
    tref := MapWorldID(idLocal);

    if tref.Kind = SK_UNIV then
      mapped := tref.Frame1
    else
      mapped := LandOffset(S) + tref.Frame1;

    if useAlt and (tref.Frame2 >= 0) then
    begin
      if tref.Kind = SK_UNIV then
        mapped := tref.Frame2
      else // SK_LAND
        mapped := LandOffset(S) + tref.Frame2;
    end;

    dst.Data[i] := mapped;
  end;
end;

procedure BuildDrawMapForTown(out dst: TTileMap; const S: TWorldState; const useAlt: Boolean);
var
  i, w, h, idLocal, mapped: Integer;
  tref: TTileRef;
  isOccluding: Boolean;
begin
  w := S.worldIDs.Width; h := S.worldIDs.Height;
  dst.Width := w; dst.Height := h; dst.IndexSize := 1;
  SetLength(dst.Data, w*h);
  for i := 0 to w*h-1 do
  begin
    idLocal := S.worldIDs.Data[i];
    tref := MapTownID(idLocal);

    if tref.Kind = SK_UNIV then
      mapped := tref.Frame1
    else // SK_TOWN
      mapped := TownOffset(S) + tref.Frame1;

    if useAlt and (tref.Frame2 >= 0) then
    begin
      if tref.Kind = SK_UNIV then
        mapped := tref.Frame2
      else // SK_TOWN
        mapped := TownOffset(S) + tref.Frame2;
    end;

    dst.Data[i] := mapped;
  end;
end;

procedure BuildDrawMapForDungeon(out dst: TTileMap; const S: TWorldState; const useAlt: Boolean);
var
  i, w, h, idLocal, mapped: Integer;
  tref: TTileRef;
  isOccluding: Boolean;
begin
  w := S.worldIDs.Width; h := S.worldIDs.Height;
  dst.Width := w; dst.Height := h; dst.IndexSize := 1;
  SetLength(dst.Data, w*h);
  for i := 0 to w*h-1 do
  begin
    idLocal := S.worldIDs.Data[i];
    tref := MapDungeonID(idLocal);

    if tref.Kind = SK_UNIV then
      mapped := tref.Frame1
    else // SK_DUNGEON
      mapped := TownOffset(S) + tref.Frame1;

    if useAlt and (tref.Frame2 >= 0) then
    begin
      if tref.Kind = SK_UNIV then
        mapped := tref.Frame2
      else // SK_DUNGEON
        mapped := TownOffset(S) + tref.Frame2;
    end;

    dst.Data[i] := mapped;
  end;
end;

procedure BuildDrawMapForSimpleMap(out dst: TTileMap; const S: TWorldState);
var
  i, w, h: Integer;
begin
  w := S.worldIDs.Width; h := S.worldIDs.Height;
  dst.Width := w; dst.Height := h; dst.IndexSize := 1;
  SetLength(dst.Data, w*h);
  for i := 0 to w*h-1 do
  begin
    dst.Data[i] := S.worldIDs.Data[i];
  end;
end;

procedure InitWorld(var S: TWorldState; var R: TRenderer; const DataDir: AnsiString);
begin
  FillChar(S, sizeof(S), 0);
  S.DataDir := DataDir;

  // Load tiles
  if not LoadCON(DataPath(DataDir, 'UNIV.CON'), S.univPixels, S.univCount, False, True) then
    writeln('Failed to load UNIV.CON');
  if not LoadCON(DataPath(DataDir, 'LAND.CON'), S.landPixels, S.landCount, False, True) then
    writeln('Failed to load LAND.CON');
  // Manually concatenate tilesets to ensure correct order: UNIV then LAND
  S.mergedCount := S.univCount + S.landCount;
  GetMem(S.mergedPixels, S.mergedCount * TILE_W * TILE_H * SizeOf(UInt32));
  System.Move(S.univPixels^, S.mergedPixels^, S.univCount * TILE_W * TILE_H * SizeOf(UInt32));
  System.Move(S.landPixels^, Pointer(NativeUInt(S.mergedPixels) + S.univCount * TILE_W * TILE_H * SizeOf(UInt32))^, S.landCount * TILE_W * TILE_H * SizeOf(UInt32));

  BuildTileTexture(R.FSDLRenderer, S.tiles, S.mergedPixels, S.mergedCount);

  // Load world map (110x100, column-major)
  S.worldIDs := LoadMAPOrdered(DataPath(DataDir, 'WORLD.MAP'), 110, 100, 1, true);


  // Build pre-rendered animation frames
  BuildDrawMapForWorld(S.drawMapA, S, False);
  BuildDrawMapForWorld(S.drawMapB, S, True);

  // Init LOS map
  S.visibilityMap.Width := S.worldIDs.Width;
  S.visibilityMap.Height := S.worldIDs.Height;
  SetLength(S.visibilityMap.Data, S.worldIDs.Width * S.worldIDs.Height);

  S.CurrentMapType := mtWorld;

  // Init state
  S.animEnabled := True;
  S.animDelayMs := 380;
  S.nextSwap := SDL_GetTicks + S.animDelayMs;
  S.CollisionEnabled := True;
  S.debugTileView := False; // 7x7 view is default, F12 toggles to tile viewer
  S.TileViewerScrollY := 0; // Reset scroll position

  // Init Player
  S.Player.XLoc := 55;
  S.Player.YLoc := 50;
  S.Player.Race := 0; // Default to race 0 for now
  LoadPlayerTile(R, DataPath(DataDir, ''), S.Player.Race);

  S.losRadius := 7;
end;

procedure FreeWorld(var S: TWorldState; var R: TRenderer);
begin
  FreeTileSet(R.PlayerTileSet);
  FreeTileSet(S.tiles);
  FreeTileSet(S.debugTownTiles);
  FreeTileMap(S.worldIDs);
  FreeTileMap(S.drawMapA);
  FreeTileMap(S.drawMapB);
  FreeBooleanGrid(S.visibilityMap);

  // Free any loaded pixel data
  if S.univPixels <> nil then FreePixels(S.univPixels);
  if S.landPixels <> nil then FreePixels(S.landPixels);
  if S.townPixels <> nil then FreePixels(S.townPixels);
  if S.mergedPixels <> nil then FreePixels(S.mergedPixels);
end;

procedure UpdateVisibilityHardcoded(var S: TWorldState);
const
  SIGHT_RANGE = 3;
var
  px, py, x, y, wx, wy, i: Integer;
  is_occluding: array[-SIGHT_RANGE..SIGHT_RANGE, -SIGHT_RANGE..SIGHT_RANGE] of Boolean;

  procedure SetVisible(dx, dy: Integer);
  var
    checkX, checkY: Integer;
  begin
    if (dx < -SIGHT_RANGE) or (dx > SIGHT_RANGE) or (dy < -SIGHT_RANGE) or (dy > SIGHT_RANGE) then exit;
    checkX := px + dx;
    checkY := py + dy;
    if (checkX >= 0) and (checkX < S.visibilityMap.Width) and
       (checkY >= 0) and (checkY < S.visibilityMap.Height) then
    begin
      S.visibilityMap.Data[checkY * S.visibilityMap.Width + checkX] := True;
    end;
  end;

  procedure CastLOS(x1, y1, x2, y2: Integer);
  var
    dx, dy, sx, sy, err, e2: Integer;
  begin
    dx := abs(x2 - x1);
    dy := -abs(y2 - y1);
    if x1 < x2 then sx := 1 else sx := -1;
    if y1 < y2 then sy := 1 else sy := -1;
    err := dx + dy;

    while true do
    begin
      SetVisible(x1, y1);
      if is_occluding[x1, y1] and not ((x1 = 0) and (y1 = 0)) then exit;
      if (x1 = x2) and (y1 = y2) then exit;
      e2 := 2 * err;
      if e2 >= dy then
      begin
        err := err + dy;
        x1 := x1 + sx;
      end;
      if e2 <= dx then
      begin
        err := err + dx;
        y1 := y1 + sy;
      end;
    end;
  end;

begin
  px := S.Player.Xloc;
  py := S.Player.Yloc;

  FillByte(S.visibilityMap.Data[0], S.visibilityMap.Width * S.visibilityMap.Height, 0);

  for y := -SIGHT_RANGE to SIGHT_RANGE do
  begin
    for x := -SIGHT_RANGE to SIGHT_RANGE do
    begin
      wx := px + x;
      wy := py + y;
      if (wx >= 0) and (wx < S.worldIDs.Width) and (wy >= 0) and (wy < S.worldIDs.Height) then
        is_occluding[x, y] := IsTileOccluding(S.CurrentMapType, S.worldIDs.Data[wy * S.worldIDs.Width + wx])
      else
        is_occluding[x, y] := true;
    end;
  end;

  for i := -SIGHT_RANGE to SIGHT_RANGE do
  begin
    CastLOS(0, 0, i, -SIGHT_RANGE);
    CastLOS(0, 0, i, SIGHT_RANGE);
    CastLOS(0, 0, -SIGHT_RANGE, i);
    CastLOS(0, 0, SIGHT_RANGE, i);
  end;
end;

procedure UpdateWorld(var S: TWorldState; Win: PSDL_Window);
const
  CHASE_RADIUS = 5;
var
  viewW, viewH, tw, th, maxX, maxY, i: Integer;
  dist: Single;
begin
  // Position viewport in top-left corner
  tw := TILE_W * PIXEL_SCALE_X; 
  th := TILE_H * PIXEL_SCALE_Y;
  
  // Calculate viewport dimensions (7x7 tiles)
  viewW := 7 * tw;
  viewH := 7 * th;
  
  // Set camera to player position, offset by 1 tile from top-left
  S.cameraX := (S.Player.XLoc - 1) * tw;
  S.cameraY := (S.Player.YLoc - 1) * th;
  
  // Clamp camera to map boundaries
  if S.CurrentMapType = mtWorld then
  begin
    maxX := S.worldIDs.Width * tw - viewW;
    maxY := S.worldIDs.Height * th - viewH;
    if S.cameraX < 0 then S.cameraX := 0 else if S.cameraX > maxX then S.cameraX := maxX;
    if S.cameraY < 0 then S.cameraY := 0 else if S.cameraY > maxY then S.cameraY := maxY;
  end;

  // Update animation frame
  if S.animEnabled and (SDL_GetTicks >= S.nextSwap) then
  begin
    S.animAltNow := not S.animAltNow;
    S.nextSwap := SDL_GetTicks + S.animDelayMs;
  end;

  UpdateVisibilityHardcoded(S);

  // Monster functionality removed
end;

procedure RenderGameView(var R: TRenderer; var S: TWorldState);
var
  viewW, viewH, tw, th, viewX, viewY, worldX, worldY, tileID, screenX, screenY, maxX, maxY, viewportX, viewportY: Integer;
begin
  tw := TILE_W * PIXEL_SCALE_X;
  th := TILE_H * PIXEL_SCALE_Y;
  
  // Calculate viewport dimensions (7x7 tiles)
  viewW := 7 * tw;
  viewH := 7 * th;
  
  // Calculate the top-left corner of the viewport
  viewportX := 6;  // 6-pixel offset from left
  viewportY := 6;  // 6-pixel offset from top


  // Draw the 7x7 grid around the player
  for viewY := 0 to 6 do
  begin
    for viewX := 0 to 6 do
    begin
      // Calculate world coordinates relative to player
      worldX := S.Player.XLoc - 3 + viewX;
      worldY := S.Player.YLoc - 3 + viewY;
      
      // Check if world coordinates are within map bounds
      if (worldX >= 0) and (worldX < S.worldIDs.Width) and 
         (worldY >= 0) and (worldY < S.worldIDs.Height) then
      begin
        // Use visibilityMap to decide whether to draw the tile
        if (not S.VisibilityEnabled) or S.visibilityMap.Data[worldY * S.visibilityMap.Width + worldX] then
        begin
          if S.animEnabled and S.animAltNow then
            tileID := S.drawMapB.Data[worldY * S.worldIDs.Width + worldX]
          else
            tileID := S.drawMapA.Data[worldY * S.worldIDs.Width + worldX];

          if tileID > 0 then
          begin
            screenX := viewportX + viewX * tw;
            screenY := viewportY + viewY * th;
            DrawTile(R.FSDLRenderer, S.tiles, tileID, screenX, screenY);
          end;
        end;
      end;
    end;
  end;

  // Draw player (centered in the 7x7 grid)
  screenX := viewportX + 3 * tw;
  screenY := viewportY + 3 * th;
  DrawPlayerTile(R, screenX, screenY);
end;

procedure RenderTileViewer(var R: TRenderer; var S: TWorldState);
var
  i, x, y, tw, th, idRange, physicalIdx, cols, viewW, viewH, hSpacing, vSpacing, offsetX, offsetY: Integer;
  tref: TTileRef;
  mapFunc: function(ID: Integer): TTileRef;
  offset: Integer;
begin
  if (S.tiles.Atlas = nil) or (S.mergedCount = 0) then exit;

  tw := TILE_W * PIXEL_SCALE_X;
  th := TILE_H * PIXEL_SCALE_Y;

  // Determine the range of logical IDs and the mapping function for the current map type
  offset := 0;
  case S.CurrentMapType of
    mtWorld:
    begin
      idRange := 21;
      mapFunc := @MapWorldID;
      offset := LandOffset(S);
    end;
    mtTown, mtCastle:
    begin
      idRange := 27; 
      mapFunc := @MapTownID;
      offset := TownOffset(S);
    end;
    mtDungeon, mtRuin, mtVampyrCastle:
    begin
      idRange := 19; 
      mapFunc := @MapDungeonID;
      offset := TownOffset(S);
    end;
    else exit;
  end;

  for i := 0 to idRange do
  begin
    tref := mapFunc(i);
    if tref.Frame1 < 0 then continue;

    if tref.Kind = SK_UNIV then
      physicalIdx := tref.Frame1
    else
      physicalIdx := offset + tref.Frame1;

      // Fixed 7x7 grid layout with 6-pixel offset from top-left
    hSpacing := tw div 3;  // 1/3 of tile width for horizontal spacing
    vSpacing := th div 2;  // 1/2 of tile height for vertical spacing
    cols := 7;  // Fixed 7 columns for the grid

    // Calculate fixed grid positions starting at (6,6)
    x := 6 + (i mod cols) * (tw + hSpacing);
    y := 6 + (i div cols) * (th + vSpacing) - S.TileViewerScrollY;

    // Calculate offset as 1/9 of the scaled tile size (was 4px fixed)
    offsetX := tw div 9;
    offsetY := th div 9;
    
    // Draw the tile with proportional offset
    DrawTile(R.FSDLRenderer, S.tiles, physicalIdx, x + offsetX, y + offsetY);

    // Draw Logical TileID below the tile with proportional spacing
    DrawNumber(R.FSDLRenderer, i, x + offsetX, y + th + (offsetY div 2));
  end;
end;


procedure LogMemory(const Msg: string; Ptr: Pointer);
begin
  if Ptr = nil then
    writeln('  MEMORY: ', Msg, ': nil')
  else
    writeln('  MEMORY: ', Msg, ': $', IntToHex(NativeUInt(Ptr), SizeOf(Pointer)*2));
end;

procedure LoadNewMap(var S: TWorldState; var R: TRenderer; const MapFile: string; NewMapType: TMapType; MapW, MapH: Integer; IsColMajor: Boolean; NewPlayerX, NewPlayerY, MapIndex: Integer);
var
  FullPath: string;
  i: Integer;
  OldMapType: TMapType;
  dataPtr: Pointer;
  dataSize: Integer;
begin
  OldMapType := S.CurrentMapType;
  writeln('LoadNewMap called with MapFile: ', MapFile, ', Type: ', Ord(NewMapType), 
          ' (Previous map type: ', Ord(OldMapType), ')');
  
  // Free all previous map resources
  writeln('  Freeing previous map resources...');
  writeln('  TileSet.Atlas before free: ', PtrUInt(S.tiles.Atlas));
  
  writeln('  - Freeing tiles.Atlas...');
  if S.tiles.Atlas <> nil then
  begin
    SDL_DestroyTexture(S.tiles.Atlas);
    S.tiles.Atlas := nil;
  end;
  
  writeln('  - Freeing tileset...');
  FreeTileSet(S.tiles);
  
  writeln('  - Freeing draw maps...');
  FreeTileMap(S.drawMapA);
  FreeTileMap(S.drawMapB);
  
  writeln('  - Freeing visibility map...');
  FreeBooleanGrid(S.visibilityMap);
  
  writeln('  - Freeing world IDs...');
  try
    writeln('    worldIDs before free - Addr: $', IntToHex(NativeUInt(@S.worldIDs), SizeOf(Pointer)*2), 
            ', Data: $', IntToHex(NativeUInt(Pointer(S.worldIDs.Data)), SizeOf(Pointer)*2), 
            ', Size: ', Length(S.worldIDs.Data) * SizeOf(S.worldIDs.Data[0]), ' bytes');
    
    // Free the tile map
    FreeTileMap(S.worldIDs);
    
    // Validate the tile map was properly cleared
    if (Length(S.worldIDs.Data) <> 0) or (S.worldIDs.Width <> 0) or (S.worldIDs.Height <> 0) then
      writeln('    WARNING: TileMap not properly reset after FreeTileMap');
      
    writeln('    worldIDs after free - Addr: $', IntToHex(NativeUInt(@S.worldIDs), SizeOf(Pointer)*2), 
            ', Data: $', IntToHex(NativeUInt(Pointer(S.worldIDs.Data)), SizeOf(Pointer)*2), 
            ', Size: ', Length(S.worldIDs.Data) * SizeOf(S.worldIDs.Data[0]), ' bytes');
  except
    on E: Exception do
    begin
      writeln('    ERROR freeing worldIDs: ', E.ClassName, ': ', E.Message);
      // Try to recover by forcing the array to nil
      SetLength(S.worldIDs.Data, 0);
      S.worldIDs.Width := 0;
      S.worldIDs.Height := 0;
      S.worldIDs.IndexSize := 0;
    end;
  end;
  
  writeln('  Previous map resources freed successfully.');
  
  // Log memory addresses before freeing
  writeln('  Memory addresses before freeing:');
  LogMemory('univPixels', S.univPixels);
  LogMemory('landPixels', S.landPixels);
  LogMemory('townPixels', S.townPixels);
  LogMemory('mergedPixels', S.mergedPixels);
  
  // Free and nil pixel data
  writeln('  Freeing pixel data...');
  if S.univPixels <> nil then 
  begin
    FreePixels(S.univPixels);
    S.univPixels := nil;
  end;
  if S.landPixels <> nil then 
  begin
    FreePixels(S.landPixels);
    S.landPixels := nil;
  end;
  if S.townPixels <> nil then 
  begin
    FreePixels(S.townPixels);
    S.townPixels := nil;
  end;
  if S.mergedPixels <> nil then 
  begin
    FreePixels(S.mergedPixels);
    S.mergedPixels := nil;
  end;
  writeln('  Pixel data freed.');

  // Initialize structures to known state
  writeln('  Initializing structures...');
  try
    FillChar(S.tiles, SizeOf(S.tiles), 0);
    S.tiles.Atlas := nil;
    
    // Initialize draw maps with proper dimensions
    S.drawMapA.Width := 0;
    S.drawMapA.Height := 0;
    S.drawMapA.IndexSize := 0;
    SetLength(S.drawMapA.Data, 0);
    
    S.drawMapB.Width := 0;
    S.drawMapB.Height := 0;
    S.drawMapB.IndexSize := 0;
    SetLength(S.drawMapB.Data, 0);
    
    // Initialize world IDs
    try
      writeln('  Initializing worldIDs - Size: ', MapW, 'x', MapH, ', Total bytes: ', MapW * MapH * SizeOf(Word));
      
      // Clear any existing data first
      SetLength(S.worldIDs.Data, 0);
      S.worldIDs.Width := 0;
      S.worldIDs.Height := 0;
      S.worldIDs.IndexSize := 0;
      
      // Allocate new data
      SetLength(S.worldIDs.Data, MapW * MapH);
      S.worldIDs.Width := MapW;
      S.worldIDs.Height := MapH;
      S.worldIDs.IndexSize := 2; // 16-bit indices
      
      // Initialize to zero
      FillChar(S.worldIDs.Data[0], Length(S.worldIDs.Data) * SizeOf(Word), 0);
      
      writeln('    worldIDs after init - Addr: $', IntToHex(NativeUInt(@S.worldIDs), SizeOf(Pointer)*2), 
              ', Data: $', IntToHex(NativeUInt(Pointer(S.worldIDs.Data)), SizeOf(Pointer)*2), 
              ', Size: ', Length(S.worldIDs.Data) * SizeOf(S.worldIDs.Data[0]), ' bytes');
    except
      on E: Exception do
      begin
        writeln('  ERROR initializing worldIDs: ', E.ClassName, ': ', E.Message);
        // Ensure we don't leave invalid state
        SetLength(S.worldIDs.Data, 0);
        S.worldIDs.Width := 0;
        S.worldIDs.Height := 0;
        S.worldIDs.IndexSize := 0;
        raise; // Re-raise to fail the map load
      end;
    end;
    
    // Initialize visibility map
    S.visibilityMap.Width := 0;
    S.visibilityMap.Height := 0;
    SetLength(S.visibilityMap.Data, 0);
    
    S.univCount := 0;
    S.landCount := 0;
    S.townCount := 0;
    S.mergedCount := 0;
    writeln('  Structures initialized.');
  except
    on E: Exception do
    begin
      writeln('  Error initializing structures: ', E.Message);
      raise;
    end;
  end;

  // Set the new map type before loading
  S.CurrentMapType := NewMapType;
  
  // Load tilesets and build draw maps based on the new map type
  writeln('  Loading new map type: ', Ord(NewMapType));
  case NewMapType of
    mtWorld:
    begin
      try
        writeln('  Loading WORLD.MAP...');
        FullPath := DataPath(S.DataDir, 'WORLD.MAP');
        writeln('  Path: ', FullPath);
        S.worldIDs := LoadMAPOrdered(FullPath, 110, 100, 1, True);
        writeln('  WORLD.MAP loaded. Width: ', S.worldIDs.Width, ', Height: ', S.worldIDs.Height);
        
        writeln('  Loading UNIV.CON...');
        FullPath := DataPath(S.DataDir, 'UNIV.CON');
        writeln('  Path: ', FullPath);
        if not LoadCON(FullPath, S.univPixels, S.univCount, False, True) then
          writeln('  Failed to load UNIV.CON');
        
        writeln('  Loading LAND.CON...');
        FullPath := DataPath(S.DataDir, 'LAND.CON');
        writeln('  Path: ', FullPath);
        if not LoadCON(FullPath, S.landPixels, S.landCount, False, True) then
          writeln('  Failed to load LAND.CON');

        // Manually concatenate tilesets to ensure correct order: UNIV then LAND
        writeln('  Merging tilesets...');
        S.mergedCount := S.univCount + S.landCount;
        writeln('  Allocating ', S.mergedCount * TILE_W * TILE_H * SizeOf(UInt32), ' bytes for merged pixels...');
        GetMem(S.mergedPixels, S.mergedCount * TILE_W * TILE_H * SizeOf(UInt32));
        
        writeln('  Copying UNIV tiles...');
        System.Move(S.univPixels^, S.mergedPixels^, S.univCount * TILE_W * TILE_H * SizeOf(UInt32));
        
        writeln('  Copying LAND tiles...');
        System.Move(S.landPixels^, Pointer(NativeUInt(S.mergedPixels) + S.univCount * TILE_W * TILE_H * SizeOf(UInt32))^, S.landCount * TILE_W * TILE_H * SizeOf(UInt32));
        
        writeln('  Building tile texture...');
        BuildTileTexture(R.FSDLRenderer, S.tiles, S.mergedPixels, S.mergedCount);
        
        writeln('  Building draw maps...');
        BuildDrawMapForWorld(S.drawMapA, S, False);
        BuildDrawMapForWorld(S.drawMapB, S, True);
        
        writeln('  Building reverse map...');
        BuildReverseMap(S);
        
        writeln('  World map loading complete.');
      except
        on E: Exception do
        begin
          writeln('  Error loading world map: ', E.Message);
          raise;
        end;
      end;
    end;
    mtTown, mtCastle:
    begin
      try
        writeln('  Loading town map: ', MapFile);
        try
          S.worldIDs := LoadMAPSlice(DataPath(S.DataDir, MapFile), MapW, MapH, 1, IsColMajor, MapIndex);
          writeln('  Town map loaded successfully');
          
          writeln('  Loading UNIV.CON...');
          if not LoadCON(DataPath(S.DataDir, 'UNIV.CON'), S.univPixels, S.univCount, False, True) then
            raise Exception.Create('Failed to load UNIV.CON');
          writeln('  UNIV.CON loaded: ', S.univCount, ' tiles');
          writeln('  Loading TOWN.CON...');
          S.townPixels := nil;
          S.townCount := 0;
          if not LoadCON(DataPath(S.DataDir, 'TOWN.CON'), S.townPixels, S.townCount, False, True) then
            raise Exception.Create('Failed to load TOWN.CON');
          if (S.townPixels = nil) or (S.townCount = 0) then
            raise Exception.Create('Failed to load TOWN.CON - no data loaded');
            
          writeln('  Merging tilesets...');
          if S.mergedPixels <> nil then
          begin
            FreePixels(S.mergedPixels);
            S.mergedPixels := nil;
            S.mergedCount := 0;
          end;
            
          if not MergeTilesets(S.univPixels, S.univCount, S.townPixels, S.townCount, S.mergedPixels, S.mergedCount) then
            raise Exception.Create('Failed to merge tilesets');
            
          writeln('  Building tile texture...');
          FreeTileSet(S.tiles);
          BuildTileTexture(R.FSDLRenderer, S.tiles, S.mergedPixels, S.mergedCount);
          if S.tiles.Atlas = nil then
            raise Exception.Create('Failed to build tile texture');

          writeln('  Building draw map...');
          SetLength(S.drawMapA.Data, 0);
          BuildDrawMapForTown(S.drawMapA, S, False);
          if Length(S.drawMapA.Data) = 0 then
            raise Exception.Create('Failed to build draw map - no data generated');
            
          writeln('  Setting up animation map...');
          S.drawMapB.Width := S.drawMapA.Width;
          S.drawMapB.Height := S.drawMapA.Height;
          S.drawMapB.IndexSize := S.drawMapA.IndexSize;
          SetLength(S.drawMapB.Data, Length(S.drawMapA.Data));
          if Length(S.drawMapA.Data) > 0 then
            Move(S.drawMapA.Data[0], S.drawMapB.Data[0], Length(S.drawMapA.Data) * SizeOf(S.drawMapA.Data[0]));
            
          writeln('  Town map loading completed successfully');
        except
          on E: Exception do
          begin
            writeln('  ERROR in town map loading: ', E.ClassName, ': ', E.Message);
            // Clean up any partially allocated resources
            if S.mergedPixels <> nil then
            begin
              FreePixels(S.mergedPixels);
              S.mergedPixels := nil;
            end;
            raise; // Re-raise the exception
          end;
        end;
        
        writeln('  Building reverse map...');
        BuildReverseMap(S);
        
        writeln('  Town map loading complete.');
      except
        on E: Exception do
        begin
          writeln('  Error loading town map: ', E.Message);
          raise;
        end;
      end;
    end;
    mtDungeon, mtRuin, mtVampyrCastle:
    begin
      S.worldIDs := LoadMAPSlice(DataPath(S.DataDir, MapFile), MapW, MapH, 1, IsColMajor, MapIndex);
      LoadCON(DataPath(S.DataDir, 'UNIV.CON'), S.univPixels, S.univCount, False, True);
      LoadCON(DataPath(S.DataDir, 'DUNGEON.CON'), S.townPixels, S.townCount, False, True);
      MergeTilesets(S.univPixels, S.univCount, S.townPixels, S.townCount, S.mergedPixels, S.mergedCount);
      BuildTileTexture(R.FSDLRenderer, S.tiles, S.mergedPixels, S.mergedCount);

      BuildDrawMapForDungeon(S.drawMapA, S, False);
      BuildDrawMapForDungeon(S.drawMapB, S, True);
      BuildReverseMap(S);
    end;
  end;

  try
    // Initialize visibility map for the new map
    writeln('  Initializing visibility map...');
    writeln('  Visibility map size: ', MapW, 'x', MapH);
    S.visibilityMap.Width := MapW;
    S.visibilityMap.Height := MapH;
    writeln('  Allocating ', (MapW * MapH), ' bytes for visibility map');
    SetLength(S.visibilityMap.Data, MapW * MapH);
    if Length(S.visibilityMap.Data) > 0 then
      FillChar(S.visibilityMap.Data[0], Length(S.visibilityMap.Data), 0);

    // Update player position
    writeln('  Setting player position to (', NewPlayerX, ', ', NewPlayerY, ')');
    S.Player.XLoc := NewPlayerX;
    S.Player.YLoc := NewPlayerY;

    // Reset camera and animation state
    writeln('  Resetting camera and animation state...');
    S.cameraX := 0;
    S.cameraY := 0;
    S.animAltNow := False;
    S.nextSwap := SDL_GetTicks + S.animDelayMs;
    
    writeln('LoadNewMap completed successfully.');
  except
    on E: Exception do
    begin
      writeln('  Error in final setup: ', E.Message);
      raise;
    end;
  end;
end;

procedure TryExitLocation(var S: TWorldState; var R: TRenderer);
begin
  // For now, any spot is an exit. This can be refined later.
  if S.CurrentMapType <> mtWorld then
  begin
    WriteLn('Returning to Quilinor...');
    LoadNewMap(S, R, 'WORLD.MAP', mtWorld, 110, 100, true, S.lastWorldX, S.lastWorldY, 0);
  end;
end;

procedure TryEnterLocation(var S: TWorldState; var R: TRenderer);
var
  shouldEnter: Boolean;
  entryName: string;
  mapFileName: string;
  newMapType: TMapType;
  mapIndex: Integer;
  newPlayerX, newPlayerY: Integer;
begin
  if S.CurrentMapType <> mtWorld then exit; // Can only enter from world map

  shouldEnter := false;
  entryName := '';
  mapFileName := '';
  mapIndex := -1;
  newPlayerX := 46; // All locations use X=46
  newPlayerY := 25; // Default entry Y

  // Check for entry based on player coordinates
  case S.Player.Yloc of
    // Towns (Y-coords are 1-based in original, so subtract 1)
    42: if (S.Player.Xloc in [44,45]) then begin shouldEnter := True; entryName := 'the town of Balinar'; mapFileName := 'TOWN.MAP'; newMapType := mtTown; mapIndex := 0; end;
    56: if (S.Player.Xloc in [14,15]) then begin shouldEnter := True; entryName := 'the town of Rendyr'; mapFileName := 'TOWN.MAP'; newMapType := mtTown; mapIndex := 1; end;
    58: if (S.Player.Xloc in [85,86]) then begin shouldEnter := True; entryName := 'the town of Maninox'; mapFileName := 'TOWN.MAP'; newMapType := mtTown; mapIndex := 2; end;
    84: if (S.Player.Xloc in [19,20]) then begin shouldEnter := True; entryName := 'the town of Zachul'; mapFileName := 'TOWN.MAP'; newMapType := mtTown; mapIndex := 3; end;
    80: if (S.Player.Xloc in [39,40]) then begin shouldEnter := True; entryName := 'the town of Trocines'; mapFileName := 'TOWN.MAP'; newMapType := mtTown; mapIndex := 4; end;
    91: if (S.Player.Xloc in [55,56]) then begin shouldEnter := True; entryName := 'the town of Myron'; mapFileName := 'TOWN.MAP'; newMapType := mtTown; mapIndex := 5; end;
    // Other locations
    40: if (S.Player.Xloc in [41,42]) then begin shouldEnter := True; entryName := 'a castle'; mapFileName := 'CASTLE.MAP'; newMapType := mtCastle; mapIndex := 2; end;
    3:  if (S.Player.Xloc = 44) then begin shouldEnter := True; entryName := 'a dungeon'; mapFileName := 'DUNGEON.MAP'; newMapType := mtDungeon; mapIndex := 0; newPlayerY := 26; end;
    9:  if (S.Player.Xloc = 104) then begin shouldEnter := True; entryName := 'a dungeon'; mapFileName := 'DUNGEON.MAP'; newMapType := mtDungeon; mapIndex := 3; newPlayerY := 26; end;
    57: if (S.Player.Xloc in [59,60]) then begin shouldEnter := True; entryName := 'a ruin'; mapFileName := 'RUIN.MAP'; newMapType := mtRuin; mapIndex := 0; newPlayerY := 26; end;
    17: if (S.Player.Xloc in [20,21]) then begin shouldEnter := True; entryName := 'a ruin'; mapFileName := 'RUIN.MAP'; newMapType := mtRuin; mapIndex := 1; newPlayerY := 26; end;
    92, 93: if (S.Player.Xloc = 97) then begin shouldEnter := True; entryName := 'Vampyr''s Castle'; mapFileName := 'VCASTLE.MAP'; newMapType := mtVampyrCastle; mapIndex := 1; newPlayerY := 26; end;
  end;

  if shouldEnter then
  begin
    WriteLn('Entering ', entryName, '...');
    S.lastWorldX := S.Player.Xloc;
    S.lastWorldY := S.Player.Yloc;
    LoadNewMap(S, R, mapFileName, newMapType, 50, 50, false, newPlayerX, newPlayerY, mapIndex);
  end;
end;

function CanMoveTo(const S: TWorldState; NewX, NewY: Integer): Boolean;
var
  MergedIndex: Integer;
  TileID: Integer;
  isOccluding: Boolean;
begin
  // If collision is disabled, movement is always allowed (except out of bounds)
  if not S.CollisionEnabled then
  begin
    Result := (NewX >= 0) and (NewX < S.drawMapA.Width) and 
              (NewY >= 0) and (NewY < S.drawMapA.Height);
    Exit;
  end;

  // Otherwise check boundaries
  if (NewX < 0) or (NewX >= S.drawMapA.Width) or (NewY < 0) or (NewY >= S.drawMapA.Height) then
  begin
    Result := False;
    Exit;
  end;

  // Get the logical TileID directly from the source map data
  TileID := S.worldIDs.Data[NewY * S.worldIDs.Width + NewX];
  Result := IsTileTraversable(S.CurrentMapType, TileID);
end;

procedure HandleEvent(var S: TWorldState; var R: TRenderer; const E: TSDL_Event; var Running: Boolean);
begin
  if E.type_ = SDL_KEYDOWN then
  begin
    case E.key.keysym.scancode of
      SDL_SCANCODE_ESCAPE: 
        if S.CurrentMapType = mtWorld then 
          Running := False;
      SDL_SCANCODE_F5: S.animEnabled := not S.animEnabled;
      SDL_SCANCODE_F12:
      begin
        S.debugTileView := not S.debugTileView;
        if S.debugTileView then S.TileViewerScrollY := 0; // Reset scroll on enter
      end;
      // P key is available for future use
      SDL_SCANCODE_V:
      begin
        S.VisibilityEnabled := not S.VisibilityEnabled;
        S.CollisionEnabled := S.VisibilityEnabled; // Keep them in sync
        writeln('Visibility toggled to: ', S.VisibilityEnabled, ', Collision toggled to: ', S.CollisionEnabled);
      end;

      SDL_SCANCODE_UP:    if S.debugTileView then S.TileViewerScrollY := S.TileViewerScrollY - 24 else MovePlayer(S, R, 0, -1);
      SDL_SCANCODE_DOWN:  if S.debugTileView then S.TileViewerScrollY := S.TileViewerScrollY + 24 else MovePlayer(S, R, 0, 1);

      // These keys only work in normal mode
      SDL_SCANCODE_LEFT:  if not S.debugTileView then MovePlayer(S, R, -1, 0);
      SDL_SCANCODE_RIGHT: if not S.debugTileView then MovePlayer(S, R, 1, 0);
      SDL_SCANCODE_E:
        if not S.debugTileView then
        begin
          if S.CurrentMapType = mtWorld then
            TryEnterLocation(S, R)
          else
            TryExitLocation(S, R);
        end;
    end;
  end;
end;

procedure RenderWorld(var R: TRenderer; var S: TWorldState);
begin
  if S.debugTileView then
    RenderTileViewer(R, S)
  else
    RenderGameView(R, S);
end;

function GetMapClickInfo(var S: TWorldState; R: TRenderer; mx, my: Integer): AnsiString;
var 
  p: TPoint; 
  id: Integer; 
  tref: TTileRef; 
  kindStr: string;
  scaleX, scaleY: single;
begin
  SDL_RenderGetScale(R.FSDLRenderer, @scaleX, @scaleY);
  p.x := (round(mx / scaleX) + S.cameraX) div (TILE_W * PIXEL_SCALE_X);
  p.y := (round(my / scaleY) + S.cameraY) div (TILE_H * PIXEL_SCALE_Y);
  if (p.x < 0) or (p.y < 0) or (p.x >= S.worldIDs.Width) or (p.y >= S.worldIDs.Height) then Exit('');

  id := S.worldIDs.Data[p.Y*S.worldIDs.Width + p.X];
  if S.CurrentMapType = mtWorld then
  begin
    tref := MapWorldID(id);
    if tref.Kind = SK_UNIV then kindStr := 'UNIV' else kindStr := 'LAND';
    Result := Format('Click at (%d,%d): ID=%d -> %s[%d]', [p.X, p.Y, id, kindStr, tref.Frame1]);
  end
  else
  begin
    Result := Format('Click at (%d,%d): TileID=%d', [p.X, p.Y, id]);
  end;
end;

procedure MovePlayer(var S: TWorldState; var R: TRenderer; dX, dY: Integer);
const
  BORDER_SIZE = 3;
var
  NewX, NewY, MapW, MapH: Integer;
begin
  NewX := S.Player.XLoc + dX;
  NewY := S.Player.YLoc + dY;

  if not CanMoveTo(S, NewX, NewY) then
    Exit;

  if S.CurrentMapType <> mtWorld then
  begin
    MapW := S.worldIDs.Width;
    MapH := S.worldIDs.Height;
    if (NewX < BORDER_SIZE) or (NewX >= MapW - BORDER_SIZE) or
       (NewY < BORDER_SIZE) or (NewY >= MapH - BORDER_SIZE) then
    begin
      TryExitLocation(S, R);
    end
    else
    begin
      S.Player.XLoc := NewX;
      S.Player.YLoc := NewY;
    end;
  end
  else // On world map
  begin
    S.Player.XLoc := NewX;
    S.Player.YLoc := NewY;
  end;
end;

end.
