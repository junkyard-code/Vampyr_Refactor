unit ugfx_fb;
{$mode objfpc}{$H+}

{* 
  Framebuffer Graphics Unit
  -----------------------
  This unit provides a simple framebuffer interface for rendering graphics
  using SDL2. It includes basic drawing functions and dirty rectangle
  optimization to minimize screen updates.
  
  Key Features:
  - Simple pixel manipulation
  - Dirty rectangle tracking for optimized rendering
  - Double buffered display
  
  Note: All coordinates are 0-based (top-left origin)
*}

interface
uses 
  {* SDL2 - Used for hardware-accelerated rendering and window management *}
  SDL2;

type
  // UI Region identifiers
  TRegionID = (riMapView, riStatusArea, riMessageArea);

function GfxInit(W,H,Scale: Integer): Boolean;
procedure GfxQuit;
procedure ClearFB(Color: LongWord);
procedure PutPixel(x,y: Integer; c: LongWord); inline;
procedure Present;

// Region management
function IsRegionDirty(Region: TRegionID): Boolean; inline;
procedure GetRegionRect(Region: TRegionID; out Rect: TSDL_Rect);
procedure MarkRegionDirty(Region: TRegionID; X, Y, W, H: Integer);
procedure MarkMapViewDirty; inline;
procedure MarkStatusAreaDirty; inline;
procedure MarkMessageAreaDirty; inline;
procedure MarkAllRegionsDirty;
procedure MarkAllRegionsClean;


const
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


var
  FB: array of LongWord;
  ScreenW, ScreenH: Integer;
  AnyDirty: Boolean;  // Tracks if any region is dirty

implementation

uses
  TypInfo,  // For GetEnumName and TypeInfo
  SysUtils; // For FillChar
  
procedure FillDWord(var Dest; Count: Integer; Value: DWORD);
var
  I: Integer;
  P: PDWORD;
begin
  P := @Dest;
  for I := 0 to Count - 1 do
  begin
    P^ := Value;
    Inc(P);
  end;
end;

{* 
  Internal Types and Variables
  ---------------------------
  These are used internally by the graphics system and should not be
  accessed directly from outside this unit.
*}
type
  // Tracks dirty regions of the screen that need updating
  TDirtyRegion = record
    X, Y: Integer;  // Top-left corner of dirty region
    W, H: Integer;  // Width and height of dirty region
    IsDirty: Boolean; // Whether the region needs updating
  end;
  

var
  // SDL2 handles
  Win: PSDL_Window = nil;    // Main application window
  Ren: PSDL_Renderer = nil;  // Hardware-accelerated 2D renderer
  Tex: PSDL_Texture = nil;   // Texture that holds our framebuffer
  
  // Track dirty state for each UI region
  DirtyRegions: array[TRegionID] of TDirtyRegion;



//***************************************** GfxInit *****************************************

function GfxInit(W, H, Scale: Integer): Boolean;
var
  i: TRegionID;
begin
  Result := False;
  
  // Initialize SDL video subsystem
  if SDL_Init(SDL_INIT_VIDEO) < 0 then
    Exit;
    
  // Create window
  Win := SDL_CreateWindow('Vampyr Refactor',
    SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
    W * Scale, H * Scale,
    SDL_WINDOW_SHOWN);
  if Win = nil then
    Exit;
    
  // Create renderer
  Ren := SDL_CreateRenderer(Win, -1, SDL_RENDERER_ACCELERATED or SDL_RENDERER_PRESENTVSYNC);
  if Ren = nil then
    Exit;
    
  // Create texture that stays in GPU memory
  Tex := SDL_CreateTexture(Ren, SDL_PIXELFORMAT_ARGB8888,
    LongInt(SDL_TEXTUREACCESS_STREAMING), W, H);
  if Tex = nil then
    Exit;
    
  // Set up screen dimensions and scaling
  ScreenW := W;
  ScreenH := H;
  
  // Set up scaling
  SDL_RenderSetScale(Ren, Scale, Scale);
  
  // Initialize framebuffer
  SetLength(FB, W * H);
  
  // Clear the framebuffer
  FillDWord(FB[0], W * H, $FF000000);
  
  // Initialize dirty regions
  for i := Low(TRegionID) to High(TRegionID) do
    DirtyRegions[i].IsDirty := False;
  AnyDirty := False;
  
  // Initialize region bounds
  with DirtyRegions[riMapView] do
  begin
    // Map view area (7x7 grid within the frame)
    X := 6; Y := 6; W := 504; H := 378;
  end;
  with DirtyRegions[riStatusArea] do
  begin
    // Player status area (red boxed area below the logo in status region)
    X := 538; Y := 86; W := 722; H := 258;  // Adjust these coordinates as needed
  end;
  with DirtyRegions[riMessageArea] do
  begin
    // Message area (gray box area)
    X := 20; Y := 271; W := 1240; H := 168;  // Slightly smaller than the full area to stay within the frame
  end;
  
  Result := True;
end;


//***************************************** GfxQuit *****************************************


procedure GfxQuit;
var
  i: TRegionID;
begin
  // Clean up SDL resources in reverse order of creation
  if Tex <> nil then 
  begin
    SDL_DestroyTexture(Tex);
    Tex := nil;
  end;
  
  if Ren <> nil then 
  begin
    SDL_DestroyRenderer(Ren);
    Ren := nil;
  end;
  
  if Win <> nil then 
  begin
    SDL_DestroyWindow(Win);
    Win := nil;
  end;
  
  // Shut down SDL and clean up
  SDL_Quit;
  
  // Reset framebuffer and screen dimensions
  FB := nil;
  ScreenW := 0;
  ScreenH := 0;
  
  // Reset dirty regions
  for i := Low(TRegionID) to High(TRegionID) do
    FillChar(DirtyRegions[i], SizeOf(DirtyRegions[i]), 0);
  AnyDirty := False;
end;




//***************************************** Clear Framebuffer *****************************************

{
  Fills the entire framebuffer with the specified color and marks the entire screen as dirty.
  
  Parameters:
    Color: 32-bit ARGB color value (0xAARRGGBB format)
}
procedure ClearFB(Color: LongWord);
var 
  i: SizeInt;
  j: Integer;
begin
  // Fill the framebuffer with the specified color
  for i := 0 to High(FB) do 
    FB[i] := Color;
    
  // Mark all regions as dirty
  for j := 0 to Integer(High(TRegionID)) do
    DirtyRegions[TRegionID(j)].IsDirty := True;
  AnyDirty := True;
end;



//***************************************** Put Pixel *****************************************

{
  Draws a single pixel at the specified coordinates and marks the region as dirty.
  
  Parameters:
    x, y: Pixel coordinates (0-based, top-left origin)
    c: 32-bit ARGB color value (0xAARRGGBB format)
    
  Note: Coordinates are automatically clipped to screen bounds
}
procedure PutPixel(x, y: Integer; c: LongWord); inline;
begin
  // Check if coordinates are within screen bounds
  if (UInt32(x) < UInt32(ScreenW)) and (UInt32(y) < UInt32(ScreenH)) then
  begin
    // Update the framebuffer
    FB[y * ScreenW + x] := c;
    
    // Determine which region this pixel is in and mark it dirty
    if (y >= 6) and (y < 384) then
    begin
      if (x >= 6) and (x < 510) then
        MarkRegionDirty(riMapView, x, y, 1, 1)
      else if (x >= 528) and (x < ScreenW) then
        MarkRegionDirty(riStatusArea, x, y, 1, 1);
    end
    // Message area - include the entire width including borders
    else if (y >= 350) and (y < 518) then
      MarkRegionDirty(riMessageArea, x, y, 1, 1);
  end;
end;



//********************************** Mark All Regions Dirty **********************************

{
  Marks all regions as dirty.
  
  This should be called after presenting a frame to reset the dirty state.
}
procedure MarkAllRegionsDirty;
var
  i: TRegionID;
begin
  for i := Low(TRegionID) to High(TRegionID) do
  begin
    DirtyRegions[i].IsDirty := True;
  end;
  AnyDirty := True;
end;





//********************************** Mark a specific region as dirty **********************************

procedure MarkRegionDirty(Region: TRegionID; X, Y, W, H: Integer);
var
  x1, y1, x2, y2: Integer;
  
  function Min(a, b: Integer): Integer;
  begin
    if a < b then Result := a else Result := b;
  end;
  
  function Max(a, b: Integer): Integer;
  begin
    if a > b then Result := a else Result := b;
  end;
  
  function ClipValue(Value, MinVal, MaxVal: Integer): Integer;
  begin
    Result := Value;
    if Result < MinVal then Result := MinVal;
    if Result > MaxVal then Result := MaxVal;
  end;
  
begin
  // For message area, ensure we cover the full width to prevent artifacts
  if Region = riMessageArea then
  begin
    X := 0;
    W := ScreenW;
  end;
  
  // Clip coordinates to screen bounds
  X := ClipValue(X, 0, ScreenW - 1);
  Y := ClipValue(Y, 0, ScreenH - 1);
  W := ClipValue(W, 1, ScreenW - X);
  H := ClipValue(H, 1, ScreenH - Y);
  
  with DirtyRegions[Region] do
  begin
    if not IsDirty then
    begin
      // First dirty region
      DirtyRegions[Region].X := X;
      DirtyRegions[Region].Y := Y;
      DirtyRegions[Region].W := W;
      DirtyRegions[Region].H := H;
      IsDirty := True;
    end
    else
    begin
      // Expand to include new region
      x1 := Min(DirtyRegions[Region].X, X);
      y1 := Min(DirtyRegions[Region].Y, Y);
      x2 := Max(DirtyRegions[Region].X + DirtyRegions[Region].W, X + W);
      y2 := Max(DirtyRegions[Region].Y + DirtyRegions[Region].H, Y + H);
      
      DirtyRegions[Region].X := x1;
      DirtyRegions[Region].Y := y1;
      DirtyRegions[Region].W := x2 - x1;
      DirtyRegions[Region].H := y2 - y1;
    end;
    AnyDirty := True;
  end;
end;



//********************************** Present **********************************


{
  Updates the screen with the current framebuffer contents.
  Only the dirty regions are updated for optimal performance.
  
  Note: This should be called once per frame after all drawing operations
  are complete.
}
procedure Present;
var 
  pixels: Pointer; 
  pitch, y, i: Integer;
  region: TRegionID;
  srcRect, dstRect: TSDL_Rect;
  updated: Boolean;
  srcIndex, destOffset, copyWidth: Integer;
  maxY: Integer;  // Maximum Y coordinate we can safely access
begin
  //WriteLn('Present: Checking if any regions are dirty...');
  if not AnyDirty then
  begin
    WriteLn('Present: No dirty regions, exiting');
    Exit;
  end;
    
  updated := False;
    //WriteLn('Present: Starting to process dirty regions');
  
  // Process each region
  for i := 0 to Integer(High(TRegionID)) do
  begin
    region := TRegionID(i);
    
    // Only process if the region is dirty
    if DirtyRegions[region].IsDirty then
    begin
      // Get the region's rectangle
      GetRegionRect(region, srcRect);
      
      // Skip empty regions
      if (srcRect.w <= 0) or (srcRect.h <= 0) then
        Continue;
          
      // Lock the texture for direct pixel access
      if SDL_LockTexture(Tex, @srcRect, @pixels, @pitch) = 0 then
      begin
        try
          // Calculate maximum Y coordinate we can safely access
          maxY := ScreenH - 1;
            
          // Only copy the dirty region from the framebuffer to the texture
          y := 0;
          while y < srcRect.h do
          begin
            // Calculate source position in framebuffer
            srcIndex := (srcRect.y + y) * ScreenW + srcRect.x;
            
            // Skip this row if it's completely outside the framebuffer
            if (srcRect.y + y) > maxY then
              Break;
            
            // Calculate destination offset in texture
            destOffset := y * (pitch div SizeOf(LongWord));
            
            // Calculate safe copy width
            copyWidth := srcRect.w;
            if (srcRect.x + copyWidth) > ScreenW then
              copyWidth := ScreenW - srcRect.x;
            
            // Only proceed if we have something to copy
            if (copyWidth > 0) and (srcIndex >= 0) and 
               ((srcIndex + copyWidth) <= Length(FB)) then
            begin
              Move(
                FB[srcIndex],
                PByte(pixels)[y * pitch],
                copyWidth * SizeOf(LongWord)
              );
            end;
            
            Inc(y);
          end;
        finally
          SDL_UnlockTexture(Tex);
        end;
      end
      else
      begin
        //WriteLn('Present: Failed to lock texture: ', SDL_GetError);
      end;
      
            // Copy the entire texture to the renderer
      SDL_RenderCopy(Ren, Tex, nil, nil);
      
      // Mark this region as clean
      DirtyRegions[region].IsDirty := False;
      updated := True;
    end;
  end; // End of for loop
  
  // Present the rendered frame if anything was updated
  if updated then
  begin
    //WriteLn('Present: Calling SDL_RenderPresent');
    SDL_RenderPresent(Ren);
  end;
    
  AnyDirty := False;
  //WriteLn('Present: Finished');
end;




//********************************** Mark Map View Dirty **********************************

// Public region marking procedures
procedure MarkMapViewDirty; inline;
begin
  // Map view area (7x7 grid within the frame)
  MarkRegionDirty(riMapView, 6, 6, 504, 252);
end;



//********************************** Mark Status Area Dirty **********************************

procedure MarkStatusAreaDirty; inline;
begin
  // Player status area (red boxed area below the logo in status region)
  MarkRegionDirty(riStatusArea, 538, 86, 722, 172);
end;


//********************************** Mark Message Area Dirty **********************************

procedure MarkMessageAreaDirty; inline;
begin
  // Message area (gray box area)
  MarkRegionDirty(riMessageArea, 20, 271, 1240, 112);
end;


//********************************** Is Region Dirty **********************************

{
  Marks all regions as clean.
  
  This should be called after presenting a frame to reset the dirty state.
}
function IsRegionDirty(Region: TRegionID): Boolean; inline;
begin
  Result := DirtyRegions[Region].IsDirty;
end;



//********************************** Mark All Regions Clean **********************************

procedure MarkAllRegionsClean;
var
  i: TRegionID;
begin
  for i := Low(TRegionID) to High(TRegionID) do
  begin
    DirtyRegions[i].IsDirty := False;
  end;
  AnyDirty := False;
end;



//********************************** Get Region Rect **********************************

{ Returns the rectangle for a given UI region }
procedure GetRegionRect(Region: TRegionID; out Rect: TSDL_Rect);
begin
  case Region of
    riMapView:
      begin
        // Map view takes up most of the screen
        Rect.x := MAP_AREA_X - 10;
        Rect.y := MAP_AREA_Y - 10;
        Rect.w := MAP_AREA_WIDTH + 15;
        Rect.h := MAP_AREA_HEIGHT + 15; // Leave space for status/message areas
      end;
      
    riStatusArea:
      begin
        // Status area at the bottom of the screen
        Rect.x := STATUS_AREA_X - 5;  // 524 + 2
        Rect.y := STATUS_AREA_Y - 10;   // 70 + 2
        Rect.w := STATUS_AREA_WIDTH + 19;  // 742 - 1
        Rect.h := STATUS_AREA_HEIGHT + 15;  // 265 - 5
      end;
      
    riMessageArea:
      begin
        // Message area below status area
        Rect.x := MESSAGE_AREA_X - 10;
        Rect.y := MESSAGE_AREA_Y - 6;
        Rect.w := MESSAGE_AREA_WIDTH + 19;
        Rect.h := MESSAGE_AREA_HEIGHT + 19;
      end;
  end;
  
  // Ensure the rectangle is within screen bounds
  //if Rect.x < 0 then Rect.x := 0;
  //if Rect.y < 0 then Rect.y := 0;
  //if Rect.x + Rect.w > ScreenW then Rect.w := ScreenW - Rect.x;
  //if Rect.y + Rect.h > ScreenH then Rect.h := ScreenH - Rect.y;
end;

end.
