program simple_viewer;

{$mode objfpc}{$H+}

uses
  SysUtils, Math, ugfx_fb, uGameTypes, SDL2;

const
  // Screen dimensions
  SCREEN_WIDTH = 640;
  SCREEN_HEIGHT = 400;
  
  // Map dimensions
  WORLD_MAP_WIDTH = 110;
  WORLD_MAP_HEIGHT = 100;
  
  // Tile settings
  TILE_SIZE = 32;  // Size of each tile in pixels
  
  // View settings (7x7 grid)
  VIEW_TILES_X = 7;
  VIEW_TILES_Y = 7;
  PLAYER_OFFSET_X = 3;  // Player is at position 3,3 in the 7x7 grid (0-based)
  PLAYER_OFFSET_Y = 3;
  
  // Colors (ARGB format)
  COLOR_BLACK = $FF000000;
  COLOR_WHITE = $FFFFFFFF;
  COLOR_GREEN = $FF00FF00;
  COLOR_BLUE = $FF0000FF;
  COLOR_BROWN = $FF8B4513;
  COLOR_GRAY = $FF808080;
  
  // SDL key scancodes
  SDL_SCANCODE_ESCAPE = 41;
  SDL_SCANCODE_LEFT = 80;
  SDL_SCANCODE_RIGHT = 79;
  SDL_SCANCODE_UP = 82;
  SDL_SCANCODE_DOWN = 81;
  
  // Tile types
  TILE_GRASS = 0;
  TILE_WATER = 1;
  TILE_MOUNTAIN = 2;
  TILE_TOWN = 3;

var
  Running: Boolean;
  WorldMap: array[0..WORLD_MAP_WIDTH-1, 0..WORLD_MAP_HEIGHT-1] of Byte;
  PlayerX, PlayerY: Integer;
  FrameCount: Integer;
  LastTime: LongWord;

// Forward declarations
procedure DrawPlayer(cx, cy: Integer); forward;
procedure LoadWorldMap(const FileName: string); forward;

function GetTileColor(TileType: Byte): LongWord;
begin
  case TileType of
    TILE_GRASS: Result := COLOR_GREEN;
    TILE_WATER: Result := COLOR_BLUE;
    TILE_MOUNTAIN: Result := COLOR_GRAY;
    TILE_TOWN: Result := COLOR_BROWN;
    else Result := COLOR_BLACK;
  end;
end;

// Helper procedure to draw a filled rectangle
procedure FillRect(x, y, w, h: Integer; color: LongWord);
var
  i, j: Integer;
begin
  for i := y to y + h - 1 do
    for j := x to x + w - 1 do
      PutPixel(j, i, color);
end;

// Helper procedure to draw a rectangle outline
procedure DrawRect(x, y, w, h: Integer; color: LongWord);
var
  i: Integer;
begin
  // Top and bottom edges
  for i := x to x + w - 1 do
  begin
    PutPixel(i, y, color);
    PutPixel(i, y + h - 1, color);
  end;
  
  // Left and right edges
  for i := y to y + h - 1 do
  begin
    PutPixel(x, i, color);
    PutPixel(x + w - 1, i, color);
  end;
end;

procedure DrawWorldMap;
var
  startX, startY, x, y, screenX, screenY, centerX, centerY, mapX, mapY: Integer;
  tileColor: LongWord;
begin
  // Calculate top-left corner of the view to center player
  startX := PlayerX - PLAYER_OFFSET_X;
  startY := PlayerY - PLAYER_OFFSET_Y;
  
  // Calculate center position on screen
  centerX := (SCREEN_WIDTH - (VIEW_TILES_X * TILE_SIZE)) div 2;
  centerY := (SCREEN_HEIGHT - (VIEW_TILES_Y * TILE_SIZE)) div 2;
  
  // Draw visible portion of the map (7x7 tiles centered on player)
  for y := 0 to VIEW_TILES_Y - 1 do
    for x := 0 to VIEW_TILES_X - 1 do
    begin
      // Calculate screen coordinates
      screenX := centerX + (x * TILE_SIZE);
      screenY := centerY + (y * TILE_SIZE);
      
      // Calculate map coordinates
      mapX := startX + x;
      mapY := startY + y;
      
      // Check if within map bounds
      if (mapX >= 0) and (mapX < WORLD_MAP_WIDTH) and
         (mapY >= 0) and (mapY < WORLD_MAP_HEIGHT) then
      begin
        // Draw tile
        tileColor := GetTileColor(WorldMap[mapX, mapY]);
        FillRect(screenX, screenY, TILE_SIZE, TILE_SIZE, tileColor);
        
        // Draw grid
        DrawRect(screenX, screenY, TILE_SIZE, TILE_SIZE, $40FFFFFF);
      end;
    end;
  
  // Draw player (centered on screen)
  DrawPlayer(
    centerX + (PLAYER_OFFSET_X * TILE_SIZE) + (TILE_SIZE div 2),
    centerY + (PLAYER_OFFSET_Y * TILE_SIZE) + (TILE_SIZE div 2)
  );
end;

procedure DrawPlayer(cx, cy: Integer);
var
  x, y, r: Integer;
begin
  r := TILE_SIZE div 4;  // Player size relative to tile size
  for y := -r to r do
    for x := -r to r do
      if (x*x + y*y) <= (r*r) then
        PutPixel(cx + x, cy + y, COLOR_WHITE);
end;

procedure LoadWorldMap(const FileName: string);
var
  F: File;
  x, y: Integer;
  Buffer: array[0..WORLD_MAP_HEIGHT-1] of Byte;
begin
  if not FileExists(FileName) then
  begin
    WriteLn('Error: Could not find map file: ', FileName);
    // Initialize with test pattern if file not found
    for y := 0 to WORLD_MAP_HEIGHT - 1 do
      for x := 0 to WORLD_MAP_WIDTH - 1 do
        WorldMap[x, y] := (x + y) mod 4;  // Simple pattern for testing
    Exit;
  end;
  
  try
    AssignFile(F, FileName);
    Reset(F, 1);
    try
      // Read map data (column-major order)
      for x := 0 to WORLD_MAP_WIDTH - 1 do
      begin
        BlockRead(F, Buffer[0], WORLD_MAP_HEIGHT);
        for y := 0 to WORLD_MAP_HEIGHT - 1 do
          WorldMap[x, y] := Buffer[y] mod 4;  // Ensure valid tile type
      end;
    finally
      CloseFile(F);
    end;
  except
    on E: Exception do
    begin
      WriteLn('Error loading map: ', E.Message);
      Halt(1);
    end;
  end;
end;

function IsKeyDown(key: Integer): Boolean;
var
  keystate: PUint8;
begin
  keystate := SDL_GetKeyboardState(nil);
  Result := (keystate[key] <> 0);
end;

procedure HandleInput;
var
  Event: TSDL_Event;
  Moved: Boolean;
begin
  Moved := False;
  
  while SDL_PollEvent(@Event) = 1 do
  begin
    if Event.type_ = SDL_QUITEV then
      Running := False
    else if Event.type_ = SDL_KEYDOWN then
    begin
      case Event.key.keysym.scancode of
        SDL_SCANCODE_ESCAPE: Running := False;
        SDL_SCANCODE_LEFT:
          if PlayerX > PLAYER_OFFSET_X then
          begin
            Dec(PlayerX);
            Moved := True;
          end;
        SDL_SCANCODE_RIGHT:
          if PlayerX < WORLD_MAP_WIDTH - 1 - PLAYER_OFFSET_X then
          begin
            Inc(PlayerX);
            Moved := True;
          end;
        SDL_SCANCODE_UP:
          if PlayerY > PLAYER_OFFSET_Y then
          begin
            Dec(PlayerY);
            Moved := True;
          end;
        SDL_SCANCODE_DOWN:
          if PlayerY < WORLD_MAP_HEIGHT - 1 - PLAYER_OFFSET_Y then
          begin
            Inc(PlayerY);
            Moved := True;
          end;
      end;
    end;
  end;
  
  if Moved then
    WriteLn('Player moved to: ', PlayerX, ', ', PlayerY);
end;

procedure RenderFrame;
begin
  // Clear screen
  FillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, COLOR_BLACK);
  
  // Draw world map
  DrawWorldMap;
  
  // Update the display
  Present;
  Inc(FrameCount);
end;

// Main program
begin
  WriteLn('Starting Vampyr World Viewer...');
  
  // Initialize graphics
  WriteLn('Initializing graphics...');
  if not GfxInit(SCREEN_WIDTH, SCREEN_HEIGHT, 1) then
  begin
    WriteLn('Failed to initialize graphics');
    Halt(1);
  end;
  WriteLn('Graphics initialized successfully');
  
  // Load world map
  WriteLn('Loading world map...');
  try
    LoadWorldMap('data\WORLD.MAP');
    WriteLn('World map loaded successfully');
  except
    on E: Exception do
    begin
      WriteLn('Error loading world map: ', E.Message);
      Halt(1);
    end;
  end;
  
  // Initialize player position (center of map, but keep within edges)
  PlayerX := Max(PLAYER_OFFSET_X, Min(WORLD_MAP_WIDTH - 1 - PLAYER_OFFSET_X, WORLD_MAP_WIDTH div 2));
  PlayerY := Max(PLAYER_OFFSET_Y, Min(WORLD_MAP_HEIGHT - 1 - PLAYER_OFFSET_Y, WORLD_MAP_HEIGHT div 2));
  WriteLn('Player initialized at position: ', PlayerX, ', ', PlayerY);

  try
    Running := True;
    FrameCount := 0;
    LastTime := SDL_GetTicks();
    
    // Main game loop
    WriteLn('Entering main game loop...');
    while Running do
    begin
      HandleInput;
      RenderFrame;
      
      // Cap at ~60 FPS
      if (SDL_GetTicks() - LastTime) < 16 then
        SDL_Delay(1);
      LastTime := SDL_GetTicks();
      
      // Exit after 10 seconds for testing
      if FrameCount > 600 then  // 60 FPS * 10 seconds
      begin
        WriteLn('Test completed successfully');
        Running := False;
      end;
    end;
    
  finally
    // Cleanup
    WriteLn('Cleaning up...');
    GfxQuit;
    WriteLn('Cleanup complete');
  end;
  
  WriteLn('Frames rendered: ', FrameCount);
  WriteLn('Press Enter to exit...');
  ReadLn;
end.
