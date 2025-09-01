program fb_viewer;

{$mode objfpc}{$H+}

uses
  SDL2, SysUtils, Math, ugfx_fb, uGameTypes, data_loaders, Classes;

const
  // World map dimensions (100 columns x 110 rows)
  WORLD_WIDTH = 100;
  WORLD_HEIGHT = 110;
  
  // Scaled Resolution (X = 2x, Y = 3x original)
  ORIGINAL_WIDTH = 640;
  ORIGINAL_HEIGHT = 200;
  SCREEN_WIDTH = 1280;   // 640 * 2
  SCREEN_HEIGHT = 600;   // 200 * 3
  
  // UI Constants - Scaled 2x from original
  BORDER_WIDTH = 10;      // 5 pixels * 2 (original was 5 pixels)
  
  // Border Divider Location and Width
  DIVIDER_X = 514;       // 258 * 2
  DIVIDER_Y = 388;       // 131 * 3
  
  // 7x7 Tile Area Region (scaled 2x from original)
  MAP_AREA_X = 10;       // 6 * 2
  MAP_AREA_Y = 10;        // 3 * 2
  MAP_AREA_WIDTH = (2* 36) * 7;  // 252 * 2
  MAP_AREA_HEIGHT = (3* 18) * 7;  // 126 * 3
  
  // Status Area Region
  STATUS_AREA_X = 524;   // 264 * 2
  STATUS_AREA_Y = 10;     // 3 * 2
  STATUS_AREA_WIDTH = 743; // 371 * 2
  STATUS_AREA_HEIGHT = 378; // 126 * 3
  
  // Message Area Region
  MESSAGE_AREA_X = 10;   // 6 * 2
  MESSAGE_AREA_Y = 399;  // 133 * 3
  MESSAGE_AREA_WIDTH = 1260; // 635 * 2
  MESSAGE_AREA_HEIGHT = 190; // 59 * 3
  
  // Colors in ARGB format (8 bits per component)
  // Note: SDL uses ABGR format
  COLOR_BLACK = $FF000000;     // Black background
  COLOR_WHITE = $FFFFFFFF;     // White for text/borders
  COLOR_RED = $FFFF0000;       // Bright red for border
  
  // Map view state tracking
  MapViewInitialized: Boolean = False;
  LastPlayerX: Integer = -1;
  LastPlayerY: Integer = -1;

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



//*********************************************** EGA to RGB ***********************************************

function EGAtoRGB(ColorIndex: Byte): LongWord;
begin
  if ColorIndex > High(EGAPalette) then
    ColorIndex := 0; // Default to black if color index is out of range
    
  with EGAPalette[ColorIndex] do
    Result := $FF000000 or (R shl 16) or (G shl 8) or B;
end;

//*********************************************** Draw Text ***********************************************

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
  LOGO_SCALED_HEIGHT = 75;  // 25 * 3 (changed from 50)
  LOGO_TOP_MARGIN = 10;     // Pixels from top of status area
  HORIZONTAL_SCALE = 4;     // 4x horizontal scaling
  VERTICAL_SCALE = 3;       // 3x vertical scaling (changed from 2)
  
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
  logoY := STATUS_AREA_Y + LOGO_TOP_MARGIN;
  
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
  

//**************************************** Initialize World ************************************

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

//**************************************** Draw Border ****************************************

procedure DrawBorder;
var
  x, y, i, dx, dy: Integer;

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
  var
    i, y: Integer;
  begin
 
      // Top and bottom borders
      DrawHorizontalLine(0, SCREEN_WIDTH-1, 0, COLOR_RED_DARK);      
      DrawHorizontalLine(0, SCREEN_WIDTH-1, 1, COLOR_RED_DARK);     
      DrawHorizontalLine(0, SCREEN_WIDTH-1, 2, COLOR_RED_DARK);  
      DrawHorizontalLine(0, SCREEN_WIDTH-1, 3, COLOR_RED_DARK);  
      DrawHorizontalLine(4, SCREEN_WIDTH-5, 4, COLOR_RED);  
      DrawHorizontalLine(4, SCREEN_WIDTH-5, 5, COLOR_RED);  
      DrawHorizontalLine(6, SCREEN_WIDTH-7, 6, COLOR_RED_DARK);      
      DrawHorizontalLine(6, SCREEN_WIDTH-7, 7, COLOR_RED_DARK);     
      DrawHorizontalLine(6, SCREEN_WIDTH-7, 8, COLOR_RED_DARK);  
      DrawHorizontalLine(6, SCREEN_WIDTH-7, 9, COLOR_RED_DARK);  

      DrawHorizontalLine(6, SCREEN_WIDTH-7, SCREEN_HEIGHT-10, COLOR_RED_DARK);  
      DrawHorizontalLine(6, SCREEN_WIDTH-7, SCREEN_HEIGHT-9, COLOR_RED_DARK);      
      DrawHorizontalLine(6, SCREEN_WIDTH-7, SCREEN_HEIGHT-8, COLOR_RED_DARK);     
      DrawHorizontalLine(6, SCREEN_WIDTH-7, SCREEN_HEIGHT-7, COLOR_RED_DARK); 
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
      DrawVerticalLine(6, 6, SCREEN_HEIGHT-7, COLOR_RED_DARK);      
      DrawVerticalLine(7, 6, SCREEN_HEIGHT-7, COLOR_RED_DARK);     
      DrawVerticalLine(8, 6, SCREEN_HEIGHT-7, COLOR_RED_DARK);  
      DrawVerticalLine(9, 6, SCREEN_HEIGHT-7, COLOR_RED_DARK); 

      DrawVerticalLine(SCREEN_WIDTH-10, 6, SCREEN_HEIGHT-7, COLOR_RED_DARK);   
      DrawVerticalLine(SCREEN_WIDTH-9, 6, SCREEN_HEIGHT-7, COLOR_RED_DARK);      
      DrawVerticalLine(SCREEN_WIDTH-8, 6, SCREEN_HEIGHT-7, COLOR_RED_DARK);     
      DrawVerticalLine(SCREEN_WIDTH-7, 6, SCREEN_HEIGHT-7, COLOR_RED_DARK);  
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
  DrawHorizontalLine(6, SCREEN_WIDTH-7, DIVIDER_Y, COLOR_RED_DARK);      
  DrawHorizontalLine(6, SCREEN_WIDTH-7, DIVIDER_Y+1, COLOR_RED_DARK);     
  DrawHorizontalLine(6, SCREEN_WIDTH-7, DIVIDER_Y+2, COLOR_RED_DARK);  
  DrawHorizontalLine(6, SCREEN_WIDTH-7, DIVIDER_Y+3, COLOR_RED_DARK);  
  DrawHorizontalLine(4, SCREEN_WIDTH-5, DIVIDER_Y+4, COLOR_RED);  
  DrawHorizontalLine(4, SCREEN_WIDTH-5, DIVIDER_Y+5, COLOR_RED); 
  DrawHorizontalLine(4, SCREEN_WIDTH-5, DIVIDER_Y+6, COLOR_RED);  
  DrawHorizontalLine(6, SCREEN_WIDTH-7, DIVIDER_Y+7, COLOR_RED_DARK);      
  DrawHorizontalLine(6, SCREEN_WIDTH-7, DIVIDER_Y+8, COLOR_RED_DARK);     
  DrawHorizontalLine(6, SCREEN_WIDTH-7, DIVIDER_Y+9, COLOR_RED_DARK);  
  DrawHorizontalLine(6, SCREEN_WIDTH-7, DIVIDER_Y+10, COLOR_RED_DARK);  

  // Draw vertical divider between map and status areas (5 pixels wide)
  DrawVerticalLine(DIVIDER_X, 6, DIVIDER_Y, COLOR_RED_DARK);   
  DrawVerticalLine(DIVIDER_X+1, 6, DIVIDER_Y, COLOR_RED_DARK);      
  DrawVerticalLine(DIVIDER_X+2, 6, DIVIDER_Y, COLOR_RED_DARK);     
  DrawVerticalLine(DIVIDER_X+3, 6, DIVIDER_Y, COLOR_RED_DARK);  
  DrawVerticalLine(DIVIDER_X+4, 4, DIVIDER_Y+5, COLOR_RED);  
  DrawVerticalLine(DIVIDER_X+5, 4, DIVIDER_Y+5, COLOR_RED); 
  DrawVerticalLine(DIVIDER_X+6, 6, DIVIDER_Y, COLOR_RED_DARK);   
  DrawVerticalLine(DIVIDER_X+7, 6, DIVIDER_Y, COLOR_RED_DARK);      
  DrawVerticalLine(DIVIDER_X+8, 6, DIVIDER_Y, COLOR_RED_DARK);     
  DrawVerticalLine(DIVIDER_X+9, 6, DIVIDER_Y, COLOR_RED_DARK);  

  // Fill message area with gray background first
  for y := MESSAGE_AREA_Y to MESSAGE_AREA_Y + MESSAGE_AREA_HEIGHT do
    for x := MESSAGE_AREA_X to MESSAGE_AREA_X + MESSAGE_AREA_WIDTH do
      PutPixel(x, y, $FF303030);  // Light gray background
 
  // Fill status area with gray background first
  for y := STATUS_AREA_Y to STATUS_AREA_Y + STATUS_AREA_HEIGHT do
    for x := STATUS_AREA_X to STATUS_AREA_X + STATUS_AREA_WIDTH do
      PutPixel(x, y, $FF000030);  // Light blue background


end;

//**************************************** Load World Map ***************************************

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
      for x := 0 to WORLD_HEIGHT-1 do
        for y := 0 to WORLD_WIDTH-1 do
          begin
          BlockRead(F, WorldMap[y, x], 1);
          writeln('Tile: ', y, ',', x, ' = ', WorldMap[y, x]);
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

//**************************************** Move Player ***************************************

procedure MovePlayer(dx, dy: Integer);
var
  newX, newY: Integer;
  moved: Boolean;
begin
  newX := PlayerX + dx;
  newY := PlayerY + dy;
  moved := False;
  
  if IsValidPosition(newX, newY) then
  begin
    PlayerX := newX;
    PlayerY := newY;
    moved := True;
  end;
  
  // If the player moved, mark the map view as dirty
  if moved then
  begin
    MarkMapViewDirty;
  end;
end;

//**************************************** Draw Map View **************************************

{*
  Draws a 7x7 grid of tiles centered on the player's position.
  Always redraws all tiles for simplicity.
*}
procedure DrawMapView;
var
  tx, ty, x, y, dx, dy, wx, wy, px, py: Integer;
  RedrawAll: Boolean = True;
  tileColor: LongWord;
  tileSizeX, tileSizeY: Integer;
begin
  // Calculate tile size to fit 7x7 grid in the map view area
  tileSizeX := MAP_AREA_WIDTH div 7;
  tileSizeY := MAP_AREA_HEIGHT div 7;
  
  // Draw 7x7 grid centered on player
  for ty := -3 to 3 do
  begin
    for tx := -3 to 3 do
    begin
      // Calculate world coordinates
      wx := PlayerX + tx;
      wy := PlayerY + ty;
      
      // Calculate screen position
      x := MAP_AREA_X + (tx + 3) * tileSizeX;
      y := MAP_AREA_Y + (ty + 3) * tileSizeY;
      
      // Get tile color (default to black for out of bounds)
      tileColor := COLOR_BLACK;
      if (wx >= 0) and (wx < 110) and (wy >= 0) and (wy < 100) then
      begin
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
        // Draw player (red square in center of tile)
        px := x + tileSizeX div 2 - 2;  // Center player in tile
        py := y + tileSizeY div 2 - 2;  // Center player in tile
        
        // Draw a red square for the player (5x5 pixels)
        for dy := 0 to 4 do
          for dx := 0 to 4 do
            PutPixel(px + dx, py + dy, $FFFF0000);  // Red color
      end;
    end;
  end;
  
  // Mark the entire map view as dirty if we made any changes
  if RedrawAll then
    MarkMapViewDirty;
end;

//************************************ Draw Status Area ************************************

var
  // Track if UI areas were drawn before
  StatusAreaDrawn: Boolean = False;
  MessageAreaDrawn: Boolean = False;
  FirstFrame: Boolean = True;

procedure DrawStatusArea;
var
  x, y: Integer;
  needsRedraw: Boolean;
begin
  // Only redraw if this is the first draw or if explicitly marked dirty
  needsRedraw := not StatusAreaDrawn;
  StatusAreaDrawn := True;
  
  if needsRedraw then
  begin
    // Draw status area background (dark blue)
    //for y := STATUS_AREA_Y to STATUS_AREA_Y + 248 do
     // for x := STATUS_AREA_X to SCREEN_WIDTH - BORDER_WIDTH - 5 do
      //  PutPixel(x, y, $FF004000);  // Dark blue
  
   
    // Draw left and right borders
    //for y := STATUS_AREA_Y + 75 to STATUS_AREA_Y + 249 do
    //begin
    //  PutPixel(STATUS_AREA_X - 1, y, COLOR_RED);
    //  PutPixel(SCREEN_WIDTH - BORDER_WIDE - 4, y, COLOR_RED);
    //end;
    
    // Mark the status area as dirty
    //MarkStatusAreaDirty;
    
    // TODO: Add actual status information
    // For now, just draw some placeholder text
    // DrawText('STATUS', STATUS_AREA_X + 10, STATUS_AREA_Y + 85, COLOR_WHITE);
  end;
end;

//************************************ Draw Message Area ************************************

procedure DrawMessageArea;
var
  x, y: Integer;
  needsRedraw: Boolean;
begin
  // Only redraw if this is the first draw or if explicitly marked dirty
  needsRedraw := not MessageAreaDrawn;
  MessageAreaDrawn := True;
  
  if needsRedraw then
  begin
    // Mark the message area as dirty
    //MarkMessageAreaDirty;
    
    // TODO: Add message display logic here
    // For now, just draw some placeholder text
    // DrawText('MESSAGES', BORDER_WIDTH + 10, MESSAGE_AREA_Y + 15, COLOR_WHITE);
  end;
end;

//************************************ Render Frame ************************************

procedure RenderFrame;
begin
  try
    //WriteLn('RenderFrame: Start');
    
    try
      if FirstFrame then
      begin
        WriteLn('RenderFrame: First frame');
        // On first frame, mark all regions as dirty to ensure everything is drawn
        FirstFrame := False;
        MarkAllRegionsDirty;
        ClearFB(COLOR_BLACK);
        WriteLn('RenderFrame: Cleared framebuffer');
        DrawBorder;
        WriteLn('RenderFrame: Drew border');
        DrawVampyrLogo;
        WriteLn('RenderFrame: Drew Vampyr logo');
        WriteLn('RenderFrame: First frame drawing complete');
      end;
      
      // Only draw regions that are dirty
      if IsRegionDirty(riMapView) then
      begin
        WriteLn('RenderFrame: Drawing map view (dirty)');
        DrawMapView;
        WriteLn('RenderFrame: Map view drawn');
      end;
      
      // Draw UI elements if their regions are dirty
      if IsRegionDirty(riStatusArea) then
      begin
        WriteLn('RenderFrame: Drawing status area (dirty)');
        DrawStatusArea;
        WriteLn('RenderFrame: Status area drawn');
      end;
      
      if IsRegionDirty(riMessageArea) then
      begin
        WriteLn('RenderFrame: Drawing message area (dirty)');
        DrawMessageArea;
        WriteLn('RenderFrame: Message area drawn');
      end;
      
      // Only present if there were dirty regions
      if AnyDirty then
      begin
        WriteLn('RenderFrame: Presenting dirty regions');
        try
          Present;
          //WriteLn('RenderFrame: Present completed');
        except
          on E: Exception do
          begin
            WriteLn('Error in Present: ', E.ClassName, ' - ', E.Message);
            WriteLn('Dumping framebuffer info:');
            WriteLn('  ScreenW: ', ScreenW);
            WriteLn('  ScreenH: ', ScreenH);
            WriteLn('  FB Length: ', Length(FB));
            raise;
          end;
        end;
        
        // Mark all regions as clean after presenting
        //WriteLn('RenderFrame: Marking regions clean');
        MarkAllRegionsClean;
      end
      else
      begin
        //WriteLn('RenderFrame: No dirty regions, skipping present');
        // Small delay to prevent CPU overuse when nothing changes
        SDL_Delay(16);
      end;
      //WriteLn('RenderFrame: Complete');
    except
      on E: Exception do
      begin
        WriteLn('Error in frame rendering: ', E.ClassName, ' - ', E.Message);
        WriteLn('FrameCount: ', FrameCount);
        WriteLn('FirstFrame: ', FirstFrame);
        raise;
      end;
    end;
    
    // Small delay to prevent CPU overuse
    SDL_Delay(1);
    
  except
    on E: Exception do
    begin
      WriteLn('FATAL ERROR in RenderFrame: ', E.ClassName, ' - ', E.Message);
      WriteLn('FrameCount: ', FrameCount);
      WriteLn('FirstFrame: ', FirstFrame);
      WriteLn('Screen dimensions: ', ScreenW, 'x', ScreenH);
      WriteLn('FB Length: ', Length(FB));
      WriteLn('Press any key to exit...');
      ReadLn;
      Halt(1);
    end;
  end;
end;

//************************************ Handle Input ************************************

procedure HandleInput;
begin
  while SDL_PollEvent(@Event) <> 0 do
  begin
    if Event.type_ = SDL_QUITEV then
      Running := False
    else if Event.type_ = SDL_KEYDOWN then
    begin
      case TSDL_keysym(Event.key.keysym).sym of
        SDLK_ESCAPE: Running := False;
        SDLK_LEFT: MovePlayer(-1, 0);
        SDLK_RIGHT: MovePlayer(1, 0);
        SDLK_UP: MovePlayer(0, -1);
        SDLK_DOWN: MovePlayer(0, 1);
      end;
    end;
  end;
end;

//************************************ Run Game ************************************

procedure RunGame;
begin
  // Initialize SDL and framebuffer with 1:1 pixel scaling
  if not GfxInit(SCREEN_WIDTH, SCREEN_HEIGHT, 1) then
  begin
    WriteLn('Failed to initialize graphics');
    Halt(1);
  end;
  
  try
    WriteLn('Initializing game state...');
    InitializeWorld;
    writeln('World Init done -- rungame');
    Running := True;
    FrameCount := 0;
    LastTime := SDL_GetTicks();
    
    // Load world map
    WriteLn('Loading world map...');
    LoadWorldMap('data\WORLD.MAP');
    WriteLn('World map loaded. Dimensions: ', WORLD_WIDTH, 'x', WORLD_HEIGHT);
    
    // Print sample tile information
    WriteLn('Sample tile information:');
    WriteLn('  TILE_COLORS has ', High(TILE_COLORS) + 1, ' entries (0-', High(TILE_COLORS), ')');
    
    // Print tile ID at player position
    WriteLn('Player tile ID: ', IntToHex(WorldMap[PlayerY, PlayerX], 2), 
      ' at [', PlayerY, ',', PlayerX, ']');
    
    // Print sample tile IDs
    WriteLn('Sample tile IDs:');
    WriteLn('  [0,0]: ', IntToHex(WorldMap[0, 0], 2));
    WriteLn('  [50,54]: ', IntToHex(WorldMap[50, 54], 2));
    WriteLn('  [50,56]: ', IntToHex(WorldMap[50, 56], 2));
    WriteLn('  [109,99]: ', IntToHex(WorldMap[109, 99], 2));
    
    // Load Vampyr logo
    WriteLn('Loading Vampyr logo...');
    if not LoadVampyrLogo then
      WriteLn('Warning: Could not load Vampyr logo');
    WriteLn('Vampyr logo loaded successfully');
    
    WriteLn('Entering main game loop...');
    // Run the game
   
      MarkStatusAreaDirty;
      MarkMessageAreaDirty; 
   
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

//************************************ Main Begin ************************************

begin
  // Run the game with all initialization handled in RunGame
  try
    RunGame;
  except
    on E: Exception do
      WriteLn('Error: ', E.Message);
  end;
end.
