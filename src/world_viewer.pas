program world_viewer;

{$mode objfpc}{$H+}

uses
  SDL2, SysUtils, Math;

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
  
  // Colors (RGBA format for SDL)
  COLOR_BLACK = $000000FF;
  COLOR_WHITE = $FFFFFFFF;
  COLOR_GREEN = $00FF00FF;
  COLOR_BLUE = $0000FFFF;
  COLOR_BROWN = $8B4513FF;
  COLOR_GRAY = $808080FF;
  
  // SDL variables
var
  window: PSDL_Window;
  renderer: PSDL_Renderer;
  
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
  LastTime: UInt32;

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

procedure FillRect(x, y, w, h: Integer; color: LongWord);
var
  rect: TSDL_Rect;
  r, g, b, a: Byte;
begin
  r := (color shr 24) and $FF;
  g := (color shr 16) and $FF;
  b := (color shr 8) and $FF;
  a := color and $FF;
  
  rect.x := x;
  rect.y := y;
  rect.w := w;
  rect.h := h;
  
  SDL_SetRenderDrawColor(renderer, r, g, b, a);
  SDL_RenderFillRect(renderer, @rect);
end;

procedure DrawRect(x, y, w, h: Integer; color: LongWord);
var
  rect: TSDL_Rect;
  r, g, b, a: Byte;
begin
  r := (color shr 24) and $FF;
  g := (color shr 16) and $FF;
  b := (color shr 8) and $FF;
  a := color and $FF;
  
  rect.x := x;
  rect.y := y;
  rect.w := w;
  rect.h := h;
  
  SDL_SetRenderDrawColor(renderer, r, g, b, a);
  SDL_RenderDrawRect(renderer, @rect);
end;

procedure DrawText(x, y: Integer; const Text: string; fg, bg: LongWord);
begin
  // Simple text drawing using rectangles for now
  // We'll implement proper text rendering later
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
  
  // Draw coordinates
  DrawText(10, 10, Format('Position: %d, %d', [PlayerX, PlayerY]), COLOR_WHITE, COLOR_BLACK);
  
  // Draw player (centered on screen)
  DrawPlayer(
    centerX + (PLAYER_OFFSET_X * TILE_SIZE) + (TILE_SIZE div 2),
    centerY + (PLAYER_OFFSET_Y * TILE_SIZE) + (TILE_SIZE div 2)
  );
end;

procedure DrawPlayer(cx, cy: Integer);
var
  r: Integer;
  dest: TSDL_Rect;
begin
  r := TILE_SIZE div 2;
  dest.x := cx - r;
  dest.y := cy - r;
  dest.w := r * 2;
  dest.h := r * 2;
  SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
  SDL_RenderFillRect(renderer, @dest);
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

procedure HandleInput;
var
  Event: TSDL_Event;
  Moved: Boolean;
begin
  while SDL_PollEvent(@Event) = 1 do
  begin
    if Event.type_ = SDL_QUITEV then
      Running := False
    else if Event.type_ = SDL_KEYDOWN then
    begin
      Moved := False;
      
      case Event.key.keysym.sym of
        SDLK_ESCAPE: Running := False;
        SDLK_LEFT: 
          if PlayerX > PLAYER_OFFSET_X then
          begin
            Dec(PlayerX);
            Moved := True;
          end;
        SDLK_RIGHT: 
          if PlayerX < WORLD_MAP_WIDTH - 1 - PLAYER_OFFSET_X then
          begin
            Inc(PlayerX);
            Moved := True;
          end;
        SDLK_UP: 
          if PlayerY > PLAYER_OFFSET_Y then
          begin
            Dec(PlayerY);
            Moved := True;
          end;
        SDLK_DOWN: 
          if PlayerY < WORLD_MAP_HEIGHT - 1 - PLAYER_OFFSET_Y then
          begin
            Inc(PlayerY);
            Moved := True;
          end;
      end;
      
      if Moved then
        WriteLn('Player moved to: ', PlayerX, ', ', PlayerY);
    end;
  end;
end;

procedure RenderFrame;
begin
  // Clear screen
  SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
  SDL_RenderClear(renderer);
  
  // Draw world map
  DrawWorldMap;
  
  // Update the display
  SDL_RenderPresent(renderer);
  Inc(FrameCount);
end;

// Main program
begin
  // Initialize SDL
  if SDL_Init(SDL_INIT_VIDEO) <> 0 then
  begin
    WriteLn('SDL_Init failed: ', SDL_GetError);
    Halt(1);
  end;

  // Set up window and renderer
  window := SDL_CreateWindow('Vampyr World Viewer',
    SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
    SCREEN_WIDTH, SCREEN_HEIGHT, 0);
  
  if window = nil then
  begin
    WriteLn('SDL_CreateWindow failed: ', SDL_GetError);
    Halt(1);
  end;
  
  renderer := SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED or SDL_RENDERER_PRESENTVSYNC);
  if renderer = nil then
  begin
    WriteLn('SDL_CreateRenderer failed: ', SDL_GetError);
    Halt(1);
  end;
  
  // Load world map
  LoadWorldMap('data\WORLD.MAP');
  
  // Initialize player position (center of map, but keep within edges)
  PlayerX := Max(PLAYER_OFFSET_X, Min(WORLD_MAP_WIDTH - 1 - PLAYER_OFFSET_X, WORLD_MAP_WIDTH div 2));
  PlayerY := Max(PLAYER_OFFSET_Y, Min(WORLD_MAP_HEIGHT - 1 - PLAYER_OFFSET_Y, WORLD_MAP_HEIGHT div 2));
  
  try
    Running := True;
    FrameCount := 0;
    LastTime := SDL_GetTicks();
    
    // Main game loop
    while Running do
    begin
      HandleInput;
      RenderFrame;
      
      // Cap at ~60 FPS
      if (SDL_GetTicks() - LastTime) < 16 then
        SDL_Delay(1);
      LastTime := SDL_GetTicks();
    end;
    
  finally
    // Cleanup
    if renderer <> nil then
      SDL_DestroyRenderer(renderer);
    if window <> nil then
      SDL_DestroyWindow(window);
    SDL_Quit();
  end;
  
  WriteLn('Frames rendered: ', FrameCount);
end.
