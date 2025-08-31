program fb_viewer;

{$mode objfpc}{$H+}

uses
  SDL2, SysUtils, Math, ugfx_fb, uGameTypes, data_loaders, Classes;

const
  // Original game resolution (EGA 16-color)
  ORIGINAL_WIDTH = 640;
  ORIGINAL_HEIGHT = 200;
  
  // World map dimensions (100 columns x 110 rows)
  WORLD_WIDTH = 100;
  WORLD_HEIGHT = 110;
  
  // Scaled resolution (2x original)
  SCREEN_WIDTH = 1280;   // 640 * 2
  SCREEN_HEIGHT = 400;   // 200 * 2
  
  // UI Constants - Scaled 2x from original
  BORDER_SIZE = 10;      // 5 pixels * 2 (original was 5 pixels)
  
  // Main UI Areas (scaled 2x from original)
  MAP_VIEW_X = 6;       // 6 * 2
  MAP_VIEW_Y = 6;        // 3 * 2
  MAP_VIEW_WIDTH = 504;  // 252 * 2
  MAP_VIEW_HEIGHT = 252; // 126 * 2
  
  // Divider between map and status (x position)
  DIVIDER_X = 513;       // 258 * 2
  DIVIDER_WIDTH = 12;    // 6 * 2
  
  // Status area
  STATUS_AREA_X = 528;   // 264 * 2
  STATUS_AREA_Y = 6;     // 3 * 2
  STATUS_AREA_WIDTH = 742; // 371 * 2
  STATUS_AREA_HEIGHT = 252; // 126 * 2
  
  // Message area
  MESSAGE_AREA_Y = 261;  // 132 * 2
  MESSAGE_AREA_HEIGHT = 132; // 66 * 2
  
  // Colors in ARGB format (8 bits per component)
  // Note: SDL uses ABGR format
  COLOR_BLACK = $FF000000;     // Black background
  COLOR_WHITE = $FFFFFFFF;     // White for text/borders
  COLOR_RED = $FFFF0000;       // Bright red for border
  COLOR_RED_DARK = $FFA00000;  // Darker red for border outline
  COLOR_BLUE_DARK = $FF400000; // Dark blue for status area
  COLOR_GRAY_DARK = $FF202020; // Dark gray for message area
  COLOR_GREEN = $FF00FF00;     // Green for player
  COLOR_GRAY = $FF808080;      // Medium gray for UI elements
  
  // Tile colors (from tile mapping - using ABGR format)
  TILE_COLORS: array[0..21] of LongWord = (
    $FF0000FF,  // 0: Deep Water (Blue)
    $FF1E90FF,  // 1: Shallow Water (Dodger Blue)
    $FF8B4513,  // 2: Bridge (Sandy Brown)
    $FF00FF00,  // 3: Forest (Dark Green)
    $FF55FF55,  // 4: Bushes (Light Green)
    $FF8B4513,  // 5: Sign (Saddle Brown)
    $FF32CD32,  // 6: Grass (Lime Green)
    $FF808080,  // 7: Vampyr's Castle [top] (Gray)
    $FFA9A9A9,  // 8: Town [LEFT] (Dark Gray)
    $FFA9A9A9,  // 9: Town [RIGHT] (Dark Gray)
    $FFA9A9A9,  // 10: Castle [LEFT] (Dark Gray)
    $FFA9A9A9,  // 11: Ruin [LEFT] (Dark Gray)
    $FFD2691E,  // 12: Mountains (Chocolate)
    $FFD2691E,  // 13: Mountains with Dungeon (Chocolate)
    $FF55FF55,  // 14: Swamp (Light Green)
    $FF00FF00,  // 15: Tropical Trees (Dark Green)
    $FF00008B,  // 16: Boat (Dark Blue)
    $FFA9A9A9,  // 17: Castle [RIGHT] (Dark Gray)
    $FFA9A9A9,  // 18: Ruin [RIGHT] (Dark Gray)
    $FFA9A9A9,  // 19: Vampyr's Castle [Bottom] (Dark Gray)
    $FF8B4513,  // 20: Hills (Sandy Brown)
    $FF8B4513   // 21: Clearing (Sandy Brown)
  );
  
type
  TWorldMap = array[0..WORLD_HEIGHT-1, 0..WORLD_WIDTH-1] of Byte;  // 100x110 map
  
var
  WorldMap: TWorldMap;
  PlayerX, PlayerY: Integer;  // Player position in world coordinates

type
  // Type for the Vampyr logo (145x25 pixels in original, 290x50 in 2x scale)
  TVampyrLogo = array[1..145, 1..25] of Byte;
  
  // EGA color palette (RGB values)
  TEGAColor = record
    R, G, B: Byte;
  end;
  
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

var
  Event: TSDL_Event;
  Running: Boolean;
  World: TWorldState;
  FrameCount: Integer;
  LastTime: UInt32;
  VampyrLogo: TVampyrLogo;
  LogoLoaded: Boolean = False;



//************ Load Vampyr Logo ************

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


//************ EGA to RGB ************

function EGAtoRGB(ColorIndex: Byte): LongWord;
begin
  if ColorIndex > High(EGAPalette) then
    ColorIndex := 0; // Default to black if color index is out of range
    
  with EGAPalette[ColorIndex] do
    Result := $FF000000 or (R shl 16) or (G shl 8) or B;
end;

//************ Draw Text ************

procedure DrawText(x, y: Integer; const Text: String; Color: LongWord);
var
  i: Integer;
  ch: Char;
  charX, charY: Integer;
  charWidth, charHeight: Integer;
  charData: Byte;
  bit: Byte;
  px, py: Integer;
begin
  // Simple 8x8 font rendering
  charWidth := 8;
  charHeight := 8;
  
  for i := 1 to Length(Text) do
  begin
    ch := UpCase(Text[i]);
    // Simple character rendering - just draw a rectangle for each character
    // In a real implementation, you'd want to use a proper font rendering function
    for charY := 0 to charHeight - 1 do
    begin
      for charX := 0 to charWidth - 1 do
      begin
        // Simple pattern to make characters visible
        if ((charX = 0) or (charX = charWidth - 1) or (charY = 0) or (charY = charHeight - 1)) then
          PutPixel(x + (i-1) * charWidth + charX, y + charY, Color);
      end;
    end;
  end;
end;

//************ Draw Vampyr Logo ************

procedure DrawVampyrLogo;
const
  LOGO_SCALED_WIDTH = 580;  // 145 * 4
  LOGO_SCALED_HEIGHT = 50;  // 25 * 2
  LOGO_TOP_MARGIN = 10;     // Pixels from top of status area
  
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
  // Scaled: 580x50 pixels (4x horizontal, 2x vertical)
  
  // Center horizontally in status area, with margin from top
  logoX := STATUS_AREA_X + (STATUS_AREA_WIDTH - LOGO_SCALED_WIDTH) div 2;
  logoY := STATUS_AREA_Y + LOGO_TOP_MARGIN;

  
  // Draw the logo with 4x horizontal and 2x vertical scaling
  for y := 1 to 25 do
  begin
    for x := 1 to 145 do
    begin
      colorIndex := VampyrLogo[x, y];
      if colorIndex > 0 then
      begin
        color := EGAtoRGB(colorIndex);
        // Draw 4x2 block for each pixel (4x horizontal, 2x vertical)
        for dx := 0 to 3 do  // 4x horizontal
          for dy := 0 to 1 do  // 2x vertical
            PutPixel(logoX + (x-1)*4 + dx, logoY + (y-1)*2 + dy, color);
      end;
    end;
  end;
  
end;

//************ Initialize World ************

procedure InitializeWorld;
begin
  // Initialize world state
  FillChar(World, SizeOf(World), 0);
  World.VisibilityEnabled := True;
  World.TileViewerScrollY := 0;
  writeln('World Init');
  // Load game data
  //LoadVampyrLogo;
  // Set up player position (example)
  World.Player.XLoc := 8;
  World.Player.YLoc := 8;
end;

//************ Draw Border ************

procedure DrawBorder;
var
  x, y: Integer;
  BORDER_WIDTH: Integer = 5;  // 5-pixel wide borders
  
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
  procedure DrawBorderRect(x1, y1, x2, y2: Integer; color: LongWord);
  var
    i: Integer;
  begin
    // Draw outer border (darker red, 3 pixels)
    for i := 0 to 2 do  // First 3 pixels (0,1,2)
    begin
      // Top and bottom borders
      DrawHorizontalLine(x1, x2, y1 + i, COLOR_RED_DARK);      // Top border (outer)
      DrawHorizontalLine(x1, x2, y2 - i, COLOR_RED_DARK);      // Bottom border (outer)
      
      // Left and right borders
      DrawVerticalLine(x1 + i, y1, y2, COLOR_RED_DARK);        // Left border (outer)
      DrawVerticalLine(x2 - i, y1, y2, COLOR_RED_DARK);        // Right border (outer)
    end;
    
    // Draw inner border (brighter red, middle 4 pixels)
    for i := 3 to BORDER_WIDTH - 1 do  // Next 2 pixels (3,4)
    begin
      // Top and bottom borders
      DrawHorizontalLine(x1, x2, y1 + i, COLOR_RED);          // Top border (inner)
      DrawHorizontalLine(x1, x2, y2 - i, COLOR_RED);          // Bottom border (inner)
      
      // Left and right borders
      DrawVerticalLine(x1 + i, y1, y2, COLOR_RED);            // Left border (inner)
      DrawVerticalLine(x2 - i, y1, y2, COLOR_RED);            // Right border (inner)
    end;
  end;

begin
  // Draw outer window border
  DrawBorderRect(0, 0, SCREEN_WIDTH - 1, SCREEN_HEIGHT - 1, COLOR_RED);
  
  // Draw vertical divider between map and status areas (5 pixels wide)
  for x := DIVIDER_X - (BORDER_WIDTH div 2) to DIVIDER_X + (BORDER_WIDTH div 2) do
  begin
    // First 3 pixels (top to bottom) use darker red
    if x <= DIVIDER_X - 1 then
      DrawVerticalLine(x, BORDER_WIDTH, MESSAGE_AREA_Y+2 - BORDER_WIDTH, COLOR_RED_DARK)
    // Next 2 pixels use brighter red
    else
      DrawVerticalLine(x, BORDER_WIDTH, MESSAGE_AREA_Y+2 - BORDER_WIDTH, COLOR_RED);
  end;
  
  // Draw horizontal divider above message area (5 pixels high)
  for y := MESSAGE_AREA_Y - (BORDER_WIDTH div 2) to MESSAGE_AREA_Y + (BORDER_WIDTH div 2) do
  begin
    // First 3 pixels (left to right) use darker red
    if y <= MESSAGE_AREA_Y - 1 then
      DrawHorizontalLine(BORDER_WIDTH, SCREEN_WIDTH - BORDER_WIDTH - 1, y, COLOR_RED_DARK)
    // Next 2 pixels use brighter red
    else
      DrawHorizontalLine(BORDER_WIDTH, SCREEN_WIDTH - BORDER_WIDTH - 1, y, COLOR_RED);
  end;
end;

//************ Load World Map ************

procedure LoadWorldMap(const Filename: string);
var
  F: File;
  x, y: Integer;
begin
writeln('Loading World Map');
  if not FileExists(Filename) then
  begin
    WriteLn('Error: Could not find ', Filename);
    Halt(1);
  end;
  
  AssignFile(F, Filename);
  try
    Reset(F, 1);
    try
      for y := 0 to 99 do
        for x := 0 to 109 do
        begin
          BlockRead(F, WorldMap[y, x], 1);
          writeln('Tile: ', x, ',', y, ' = ', WorldMap[y, x]);
        end;
      finally
      CloseFile(F);
    end;
  except
    on E: Exception do
    begin
      WriteLn('Error loading world map: ', E.Message);
      Halt(1);
    end;
  end;
  
  // Set player's starting position to [55, 50]
  PlayerX := 55;
  PlayerY := 50;
end;

function IsValidPosition(x, y: Integer): Boolean;
begin
  // Allow movement within the full map bounds (0-109 for x, 0-99 for y)
  Result := (x >= 0) and (x < 110) and (y >= 0) and (y < 100);
end;

//************ Move Player ************

procedure MovePlayer(dx, dy: Integer);
var
  newX, newY: Integer;
begin
  newX := PlayerX + dx;
  newY := PlayerY + dy;
  
  if IsValidPosition(newX, newY) then
  begin
    PlayerX := newX;
    PlayerY := newY;
  end;
end;

//************ Draw Map View ************

procedure DrawMapView;
var
  tx, ty, x, y, dx, dy, wx, wy: Integer;
  tileColor: LongWord;
  tileSizeX, tileSizeY: Integer;
begin
  // Calculate tile size to fit 7x7 grid in the map view area
  tileSizeX := MAP_VIEW_WIDTH div 7;
  tileSizeY := MAP_VIEW_HEIGHT div 7;
  
  // Draw 7x7 grid centered on player
  for ty := -3 to 3 do
  begin
    for tx := -3 to 3 do
    begin
      // Calculate world coordinates
      wx := PlayerX + tx;
      wy := PlayerY + ty;
      
      // Calculate screen position
      x := MAP_VIEW_X + (tx + 3) * tileSizeX;
      y := MAP_VIEW_Y + (ty + 3) * tileSizeY;
      
      // Get tile color (default to black for out of bounds)
      tileColor := COLOR_BLACK;
      if (wx >= 0) and (wx < 110) and (wy >= 0) and (wy < 100) then
      begin
      //writeln('Tile: ', wx, ',', wy, ' = ', WorldMap[wy, wx]);
        // Use tile color from map, default to black if invalid
        if WorldMap[wy, wx] <= High(TILE_COLORS) then
          tileColor := TILE_COLORS[WorldMap[wy, wx]]
        else
          tileColor := $FF000000;  // Black for invalid tile IDs
      end;
      
      // Draw tile background
      for dy := 0 to tileSizeY - 1 do
        for dx := 0 to tileSizeX - 1 do
          PutPixel(x + dx, y + dy, tileColor);
      
      // Draw grid lines (white border)
      for dx := 0 to tileSizeX - 1 do
      begin
        PutPixel(x + dx, y, COLOR_WHITE);
        PutPixel(x + dx, y + tileSizeY - 1, COLOR_WHITE);
      end;
      for dy := 0 to tileSizeY - 1 do
      begin
        PutPixel(x, y + dy, COLOR_WHITE);
        PutPixel(x + tileSizeX - 1, y + dy, COLOR_WHITE);
      end;
      
      // Draw player in center tile
      if (tx = 0) and (ty = 0) then
      begin
        for dy := -4 to 4 do
          for dx := -4 to 4 do
            if (dx*dx + dy*dy) <= 16 then  // Draw a circle
              PutPixel(x + (tileSizeX div 2) + dx, y + (tileSizeY div 2) + dy, COLOR_GREEN);
      end;
    end;
  end;
  
  // Draw coordinates
  // Note: You'll need to implement a text rendering function for coordinates
end;

//************ Draw Status Area ************

procedure DrawStatusArea;
var
  x, y: Integer;
begin
  // Draw status area background (dark blue)
  for y := STATUS_AREA_Y+76 to STATUS_AREA_Y + 248 do
    for x := STATUS_AREA_X to SCREEN_WIDTH - BORDER_SIZE - 5 do
      PutPixel(x, y, $FF400000);  // Dark blue
  
  // Draw border around status area
  //for x := STATUS_AREA_X - 2 to SCREEN_WIDTH - BORDER_SIZE - 3 do
  //begin
  //  PutPixel(x, STATUS_AREA_Y + 6, COLOR_WHITE);
  //  PutPixel(x, STATUS_AREA_Y + 160, COLOR_WHITE);
  //end;
  //for y := STATUS_AREA_Y + 6 to STATUS_AREA_Y + 160 do
  //begin
  //  PutPixel(STATUS_AREA_X - 2, y, COLOR_WHITE);
  //  PutPixel(SCREEN_WIDTH - BORDER_SIZE - 3, y, COLOR_WHITE);
  //end;
  
  // TODO: Add player stats and logo
end;

//************ Draw Message Area ************

procedure DrawMessageArea;
var
  x, y, dy: Integer;
begin
  // Draw message area background (dark gray)
  // Start 5 pixels below the top of the message area to account for border
  // and leave 5 pixels at the bottom for the border
  for y := MESSAGE_AREA_Y + 7 to SCREEN_HEIGHT - BORDER_SIZE do
    for x := BORDER_SIZE to SCREEN_WIDTH - BORDER_SIZE do
      PutPixel(x, y, $FF202020);
  
  // Draw border around message area - adjust to match the 5-pixel border style
  //for x := BORDER_SIZE to SCREEN_WIDTH - BORDER_SIZE - 1 do
  //begin
    // Top border of message area (5 pixels high)
    //for dy := 0 to 4 do
     // PutPixel(x, MESSAGE_AREA_Y + dy, COLOR_RED);
      
    // Bottom border (already handled by the main border)
  //end;
end;

//************ Render Frame ************

procedure RenderFrame;
begin
  // Clear screen to black
  ClearFB(COLOR_BLACK);
  
  // Draw UI elements
  DrawBorder;
  DrawMapView;
  DrawStatusArea;
  DrawVampyrLogo;
  DrawMessageArea;
  
  // Update the display
  Present;
end;

//************ Handle Input ************

procedure HandleInput;
begin
  while SDL_PollEvent(@Event) <> 0 do
  begin
    case Event.type_ of
      SDL_QUITEV: Running := False;
      SDL_KEYDOWN:
        case Event.key.keysym.sym of
          SDLK_ESCAPE: Running := False;
          SDLK_LEFT: MovePlayer(-1, 0);
          SDLK_RIGHT: MovePlayer(1, 0);
          SDLK_UP: MovePlayer(0, -1);
          SDLK_DOWN: MovePlayer(0, 1);
        end;
    end;
  end;
end;

//************ Run Game ************

procedure RunGame;
begin
  // Initialize SDL and framebuffer with 1:1 pixel scaling
  if not GfxInit(SCREEN_WIDTH, SCREEN_HEIGHT, 1) then
  begin
    WriteLn('Failed to initialize graphics');
    Halt(1);
  end;
  
  try
    // Initialize game state
    InitializeWorld;
    writeln('World Init done -- rungame');
    Running := True;
    FrameCount := 0;
    LastTime := SDL_GetTicks();
    
    // Load world map
    WriteLn('Loading world map...');
    LoadWorldMap('..\data\world.map');
    WriteLn('World map loaded. Dimensions: ', WORLD_WIDTH, 'x', WORLD_HEIGHT);
    
    // Print sample tile information
    WriteLn('Sample tile information:');
    WriteLn('  TILE_COLORS has ', High(TILE_COLORS) + 1, ' entries (0-', High(TILE_COLORS), ')');
    
    // Print tile ID at player position
  WriteLn('Player tile ID: ', IntToHex(WorldMap[PlayerY, PlayerX], 2), 
    ' at [', PlayerY, ',', PlayerX, ']');
  
  // Print a few sample tile IDs
  WriteLn('Sample tile IDs:');
  WriteLn('  [0,0]: ', IntToHex(WorldMap[0,0], 2));
  WriteLn('  [', PlayerY, ',', PlayerX-1, ']: ', IntToHex(WorldMap[PlayerY, PlayerX-1], 2));
  WriteLn('  [', PlayerY, ',', PlayerX+1, ']: ', IntToHex(WorldMap[PlayerY, PlayerX+1], 2));
  WriteLn('  [', WORLD_HEIGHT-1, ',', WORLD_WIDTH-1, ']: ', 
    IntToHex(WorldMap[WORLD_HEIGHT-1, WORLD_WIDTH-1], 2));
    
    // Check for out of range tile IDs
    if (WorldMap[PlayerY, PlayerX] > High(TILE_COLORS)) then
      WriteLn('WARNING: Tile ID ', WorldMap[PlayerY, PlayerX], ' at player position is out of range for TILE_COLORS (max=', High(TILE_COLORS), ')');
      
    // Run the game
    while Running do
    begin
      HandleInput;
      RenderFrame;
      SDL_Delay(16);  // Cap at ~60 FPS
      Inc(FrameCount);
    end;
    
  finally
    GfxQuit;
  end;
  
  WriteLn('Average FPS: ', FrameCount / ((SDL_GetTicks() - LastTime) / 1000):0:2);
end;


//************ Main Begin ************

begin
  // Initialize SDL and framebuffer with 1:1 pixel scaling
  if not GfxInit(SCREEN_WIDTH, SCREEN_HEIGHT, 1) then
  begin
    WriteLn('Failed to initialize graphics');
    Halt(1);
  end;
  
  try
    // Initialize game state
    InitializeWorld;
    Running := True;
    FrameCount := 0;
    LastTime := SDL_GetTicks();
    
    // Main game loop
    //while Running do
    //begin
      //HandleInput;
      //RenderFrame;
      
      // Simple frame rate limiting
      //SDL_Delay(16);  // ~60 FPS
    //end;

   RunGame;

  finally
    GfxQuit;
  end;
  
  WriteLn('Average FPS: ', FrameCount / ((SDL_GetTicks() - LastTime) / 1000):0:2);
end.
