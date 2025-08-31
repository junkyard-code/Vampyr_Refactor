program simple_map_viewer;

{$mode objfpc}{$H+}

uses
  SDL2, SysUtils, ugfx_fb;

const
  // Colors in ARGB format (8 bits per component)
  COLOR_BLACK = $FF000000;     // Black background
  COLOR_WHITE = $FFFFFFFF;     // White for text/borders
  COLOR_GREEN = $FF00FF00;     // Green for player
  
  // Map dimensions
  MAP_WIDTH = 110;
  MAP_HEIGHT = 100;
  TILE_SIZE = 16;  // Size of each tile in pixels
  
  // Viewport settings
  VIEW_TILES_X = 15;  // Number of tiles visible horizontally
  VIEW_TILES_Y = 15;  // Number of tiles visible vertically
  
  // Tile types
  TILE_GRASS = 0;
  TILE_MOUNTAIN = 1;
  TILE_WATER = 2;

var
  Running: Boolean = True;
  GameMap: array[0..MAP_WIDTH-1, 0..MAP_HEIGHT-1] of Byte;
  PlayerX, PlayerY: Integer;

{ Draw a filled rectangle }
procedure FillRect(x, y, w, h: Integer; color: LongWord);
var
  i, j: Integer;
begin
  for i := y to y + h - 1 do
    for j := x to x + w - 1 do
      PutPixel(j, i, color);
end;

{ Draw a rectangle outline }
procedure DrawRect(x, y, w, h: Integer; color: LongWord);
var
  i: Integer;
begin
  // Top and bottom lines
  for i := x to x + w - 1 do
  begin
    PutPixel(i, y, color);
    PutPixel(i, y + h - 1, color);
  end;
  
  // Left and right lines
  for i := y to y + h - 1 do
  begin
    PutPixel(x, i, color);
    PutPixel(x + w - 1, i, color);
  end;
end;

{ Initialize the game map with test data }
procedure InitGameMap;
var
  x, y: Integer;
begin
  // Fill with grass
  for y := 0 to MAP_HEIGHT - 1 do
    for x := 0 to MAP_WIDTH - 1 do
      GameMap[x, y] := TILE_GRASS;
      
  // Add some water
  for y := 10 to 20 do
    for x := 10 to 20 do
      if (x + y) mod 3 = 0 then
        GameMap[x, y] := TILE_WATER;
        
  // Add some mountains
  for y := 30 to 40 do
    for x := 30 to 40 do
      if (x + y) mod 2 = 0 then
        GameMap[x, y] := TILE_MOUNTAIN;
  
  // Set player start position
  PlayerX := 55;
  PlayerY := 50;
end;

{ Draw the world map with grid centered on player }
procedure DrawWorldMap;
var
  startX, startY, tx, ty, mapX, mapY, x, y: Integer;
  tileColor: LongWord;
begin
  // Calculate top-left corner of visible map area to center on player
  startX := PlayerX - (VIEW_TILES_X div 2);
  startY := PlayerY - (VIEW_TILES_Y div 2);
  
  // Draw visible portion of the map
  for ty := 0 to VIEW_TILES_Y - 1 do
  begin
    for tx := 0 to VIEW_TILES_X - 1 do
    begin
      // Calculate map coordinates
      mapX := startX + tx;
      mapY := startY + ty;
      
      // Get tile color
      if (mapX >= 0) and (mapX < MAP_WIDTH) and 
         (mapY >= 0) and (mapY < MAP_HEIGHT) then
      begin
        case GameMap[mapX, mapY] of
          TILE_GRASS: tileColor := $FF008000;  // Green
          TILE_MOUNTAIN: tileColor := $FF808080; // Gray
          TILE_WATER: tileColor := $FF0000FF;   // Blue
          else tileColor := $FF000000;          // Black
        end;
      end
      else
        tileColor := $FF000000;  // Black for out of bounds
      
      // Calculate screen position
      x := tx * TILE_SIZE;
      y := ty * TILE_SIZE;
      
      // Draw tile
      FillRect(x, y, TILE_SIZE, TILE_SIZE, tileColor);
      
      // Draw border
      DrawRect(x, y, TILE_SIZE, TILE_SIZE, COLOR_WHITE);
      
      // Draw player
      if (mapX = PlayerX) and (mapY = PlayerY) then
        FillRect(x + 2, y + 2, TILE_SIZE - 4, TILE_SIZE - 4, COLOR_GREEN);
    end;
  end;
end;

{ Handle keyboard input }
procedure HandleInput;
var
  Event: TSDL_Event;
begin
  while SDL_PollEvent(@Event) = 1 do
  begin
    if Event.type_ = SDL_QUITEV then
      Running := False
    else if Event.type_ = SDL_KEYDOWN then
    begin
      case Event.key.keysym.sym of
        SDLK_ESCAPE: 
          Running := False;
          
        SDLK_LEFT: 
          if PlayerX > 0 then 
            Dec(PlayerX);
            
        SDLK_RIGHT: 
          if PlayerX < MAP_WIDTH - 1 then 
            Inc(PlayerX);
            
        SDLK_UP: 
          if PlayerY > 0 then 
            Dec(PlayerY);
            
        SDLK_DOWN: 
          if PlayerY < MAP_HEIGHT - 1 then 
            Inc(PlayerY);
      end;
    end;
  end;
end;

{ Main program }
begin
  // Initialize SDL
  if SDL_Init(SDL_INIT_VIDEO) <> 0 then
  begin
    WriteLn('SDL_Init failed: ', SDL_GetError);
    Halt(1);
  end;

  // Initialize framebuffer
  if not GfxInit(VIEW_TILES_X * TILE_SIZE, VIEW_TILES_Y * TILE_SIZE, 'Vampyr Map Viewer') then
  begin
    WriteLn('Failed to initialize graphics');
    Halt(1);
  end;
  
  // Initialize game state
  Randomize;
  InitGameMap;
  
  try
    // Main game loop
    while Running do
    begin
      // Handle input
      HandleInput;
      
      // Clear screen
      ClearFB(COLOR_BLACK);
      
      // Draw everything
      DrawWorldMap;
      
      // Update display
      Present;
      
      // Cap frame rate
      SDL_Delay(16); // ~60 FPS
    end;
    
    // Cleanup
    GfxQuit;
    SDL_Quit;
    
    WriteLn('Viewer closed');
    
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.Message);
      Halt(1);
    end;
  end;
end.
