unit renderer;

{$mode objfpc}{$H+}

interface

uses SDL2, uGameTypes;

const
  TILE_W = 18;
  TILE_H = 18;

type
  TRenderer = record
    FSDLRenderer: PSDL_Renderer;
    FScaleX: single;
    FScaleY: single;
    FZoom: single;
    MergedTileSet: TTileSet;
    PlayerTileSet: TTileSet; // For the player icon
  end;


procedure SetScale(ax, ay, factor: Integer);
procedure BuildTileTexture(renderer: PSDL_Renderer; var tiles: TTileSet;
                          pixels: PUInt32; tilesCount: Integer);
procedure FreeTileTexture;
procedure FreeTileSet(var t: TTileSet);
procedure FreeTileMap(var m: TTileMap);
procedure DrawTile(renderer: PSDL_Renderer; const tiles: TTileSet; tileIndex: Integer; x, y: Integer);
procedure DrawMap(renderer: PSDL_Renderer; const tiles: TTileSet;
                  const drawMap: TTileMap; const idMap: TTileMap;
                  const mapType: TMapType; camX, camY: Integer);
procedure LoadPlayerTile(var Renderer: TRenderer; const DataPath: string; PlayerRace: byte);
procedure DrawPlayerTile(var Renderer: TRenderer; DstX, DstY: integer);
procedure DrawNumber(renderer: PSDL_Renderer; n, x, y: Integer);
procedure DrawTransparentRect(renderer: PSDL_Renderer; const rect: TSDL_Rect; r, g, b, a: Byte);

var
  PIXEL_SCALE_X: Integer = 2;
  PIXEL_SCALE_Y: Integer = 1;

implementation

uses
  SysUtils, Classes, data_loaders, uMapping;

procedure SetScale(ax, ay, factor: Integer);
begin
  PIXEL_SCALE_X := ax * factor;
  PIXEL_SCALE_Y := ay * factor;
end;

procedure FreeTileTexture;
begin
  // This is now a no-op. The surface is freed in BuildTileTexture.
end;

procedure FreeTileSet(var t: TTileSet);
var
  TexPtr: PSDL_Texture;
begin
  // Save the texture pointer to a local variable first
  TexPtr := t.Atlas;
  writeln('  FreeTileSet called, Atlas: $', IntToHex(NativeUInt(TexPtr), SizeOf(Pointer)*2));
  
  // Clear the texture reference before destroying it
  t.Atlas := nil;
  
  if TexPtr <> nil then
  begin
    try
      writeln('  - Destroying texture...');
      SDL_DestroyTexture(TexPtr);
      writeln('  - Texture destroyed successfully');
    except
      on E: Exception do
      begin
        writeln('  ERROR in FreeTileSet: ', E.ClassName, ': ', E.Message);
        writeln('    Attempting to continue...');
        // Don't re-raise to prevent crashes from texture cleanup
      end;
    end;
  end
  else
  begin
    writeln('  - No texture to destroy');
  end;
  
  // Reset all tile set properties
  t.Count := 0;
  t.AtlasCols := 0;
  t.AtlasRows := 0;
  
  // Clear any pixel data if present
  if t.Pixels <> nil then
  begin
    try
      FreePixels(t.Pixels);
      t.Pixels := nil;
    except
      on E: Exception do
        writeln('  WARNING: Error freeing tile set pixels: ', E.Message);
    end;
  end;
  
  writeln('  TileSet reset complete');
end;

procedure FreeTileMap(var m: TTileMap);
var
  DataPtr: Pointer;
  DataLen: Integer;
begin
  // Save the current state for logging
  DataPtr := Pointer(m.Data);
  DataLen := Length(m.Data);
  
  writeln('  FreeTileMap called, Data: $', IntToHex(NativeUInt(DataPtr), SizeOf(Pointer)*2), 
          ', Size: ', DataLen, ' bytes');
  
  // First, clear the reference to the data to prevent any dangling pointers
  m.Width := 0;
  m.Height := 0;
  m.IndexSize := 0;
  
  // Then safely free the data
  if DataLen > 0 then
  begin
    try
      // Use a local variable to avoid any potential issues with the record
      SetLength(m.Data, 0);
      // Ensure the array is really cleared
      if Length(m.Data) > 0 then
      begin
        writeln('  WARNING: Array not properly cleared! Forcing finalization...');
        Finalize(m.Data);
        SetLength(m.Data, 0);
      end;
      writeln('  TileMap reset complete');
    except
      on E: Exception do
      begin
        writeln('  ERROR in FreeTileMap: ', E.ClassName, ': ', E.Message);
        writeln('    Attempting to recover...');
        try
          // Last resort: try to finalize the array directly
          if DataPtr <> nil then
            FinalizeArray(DataPtr, TypeInfo(TByteArray), 1);
          SetLength(m.Data, 0);
          writeln('    Recovery successful');
        except
          on E2: Exception do
          begin
            writeln('    Recovery failed: ', E2.ClassName, ': ', E2.Message);
            // Continue with the original exception
            raise E;
          end;
        end;
      end;
    end;
  end
  else
  begin
    writeln('  TileMap already empty');
  end;
end;

procedure BuildTileTexture(renderer: PSDL_Renderer; var tiles: TTileSet;
                          pixels: PUInt32; tilesCount: Integer);
const
  COLS = 20;
var
  rows: Integer;
  atlasW, atlasH: Integer;
  surf: PSDL_Surface;
  pitch: Integer;
  dst: PUInt32;
  tile, tx, ty, x, y: Integer;
  src: PUInt32;
begin
  tiles.Count := tilesCount;
  rows := (tilesCount + COLS - 1) div COLS;
  tiles.AtlasCols := COLS;
  tiles.AtlasRows := rows;

  atlasW := TILE_W * COLS;
  atlasH := TILE_H * rows;
  surf := SDL_CreateRGBSurface(0, atlasW, atlasH, 32,
                               $00FF0000, $0000FF00, $000000FF, $FF000000);
  if surf = nil then Exit;
  SDL_LockSurface(surf);
  pitch := surf^.pitch div 4;
  dst := PUInt32(surf^.pixels);

  for tile := 0 to tilesCount-1 do
  begin
    tx := tile mod COLS;
    ty := tile div COLS;
    for y := 0 to TILE_H-1 do
      for x := 0 to TILE_W-1 do
      begin
        src := pixels + (tile * TILE_W * TILE_H) + (y * TILE_W + x);
        dst[(ty*TILE_H + y)*pitch + (tx*TILE_W + x)] := src^;
      end;
  end;

  SDL_UnlockSurface(surf);
  tiles.Atlas := SDL_CreateTextureFromSurface(renderer, surf);
  if surf <> nil then
    SDL_FreeSurface(surf);
end;

procedure DrawMap(renderer: PSDL_Renderer; const tiles: TTileSet;
                  const drawMap: TTileMap; const idMap: TTileMap;
                  const mapType: TMapType; camX, camY: Integer);
var
  tw, th: Integer;
  viewW, viewH: Integer;
  x, y, idx, originalID: Integer;
  srcRect, dstRect: TSDL_Rect;
  cols: Integer;
begin
  tw := TILE_W * PIXEL_SCALE_X;
  th := TILE_H * PIXEL_SCALE_Y;
  cols := tiles.AtlasCols;
  SDL_GetRendererOutputSize(renderer, @viewW, @viewH);

  for y := 0 to drawMap.Height-1 do
    for x := 0 to drawMap.Width-1 do
    begin
      // Draw the base tile
      idx := drawMap.Data[y*drawMap.Width + x];
      srcRect.x := (idx mod cols) * TILE_W;
      srcRect.y := (idx div cols) * TILE_H;
      srcRect.w := TILE_W; srcRect.h := TILE_H;

      dstRect.x := x*tw - camX;
      dstRect.y := y*th - camY;
      dstRect.w := tw; dstRect.h := th;

      SDL_RenderCopy(renderer, tiles.Atlas, @srcRect, @dstRect);

      // Overlay non-traversable tiles
      originalID := idMap.Data[y*idMap.Width + x];
      if not IsTileTraversable(mapType, originalID) then
      begin
        DrawTransparentRect(renderer, dstRect, 255, 0, 0, 80); // Red, semi-transparent
      end;
    end;
end;

procedure DrawTile(renderer: PSDL_Renderer; const tiles: TTileSet; tileIndex: Integer; x, y: Integer);
var
  srcRect, dstRect: TSDL_Rect;
  cols: Integer;
  tw, th: Integer;
begin
  if (renderer = nil) or (tiles.Atlas = nil) or (tileIndex < 0) or (tileIndex >= tiles.Count) then Exit;

  cols := tiles.AtlasCols;
  tw := TILE_W * PIXEL_SCALE_X;
  th := TILE_H * PIXEL_SCALE_Y;

  srcRect.x := (tileIndex mod cols) * TILE_W;
  srcRect.y := (tileIndex div cols) * TILE_H;
  srcRect.w := TILE_W;
  srcRect.h := TILE_H;

  dstRect.x := x;
  dstRect.y := y;
  dstRect.w := tw;
  dstRect.h := th;

  SDL_RenderCopy(renderer, tiles.Atlas, @srcRect, @dstRect);
end;

procedure LoadPlayerTile(var Renderer: TRenderer; const DataPath: string; PlayerRace: byte);
var
  IconData: TIconData;
  Pixels: T32BitPixels;
  FileName: string;
begin
  FileName := IncludeTrailingPathDelimiter(DataPath) + 'player.con';
  if not LoadCONFileTile(FileName, PlayerRace, IconData) then
  begin
    writeln('Error: Could not load player tile from ', FileName);
    Exit;
  end;

  ConvertIconTo32Bit(IconData, Pixels);
  // The player tile set will contain just one tile.
  BuildTileTexture(Renderer.FSDLRenderer, Renderer.PlayerTileSet, @Pixels[0], 1);
end;

procedure DrawPlayerTile(var Renderer: TRenderer; DstX, DstY: integer);
begin
  if Renderer.PlayerTileSet.Count > 0 then
    DrawTile(Renderer.FSDLRenderer, Renderer.PlayerTileSet, 0, DstX, DstY);
end;

const
  // A simple 3x5 bitmap font for digits 0-9
  DIGIT_W = 3;
  DIGIT_H = 5;
  Digits: array[0..9, 0..DIGIT_H-1] of Byte = (
    ($E, $A, $A, $A, $E), // 0
    ($4, $C, $4, $4, $E), // 1
    ($E, $2, $E, $8, $E), // 2
    ($E, $2, $C, $2, $E), // 3
    ($A, $A, $E, $2, $2), // 4
    ($E, $8, $E, $2, $E), // 5
    ($E, $8, $E, $A, $E), // 6
    ($E, $2, $4, $4, $4), // 7
    ($E, $A, $E, $A, $E), // 8
    ($E, $A, $E, $2, $E)  // 9
  );

procedure DrawDigit(renderer: PSDL_Renderer; digit, x, y: Integer);
var
  row, col: Integer;
  rect: TSDL_Rect;
begin
  if (digit < 0) or (digit > 9) then exit;

  // Using white for high visibility
  SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);

  for row := 0 to DIGIT_H - 1 do
  begin
    for col := 0 to DIGIT_W - 1 do
    begin
      if (Digits[digit, row] and (1 shl (DIGIT_W - col))) <> 0 then
      begin
        // Draw a 1x1 pixel, scaled up
        rect.x := x + col * 2; // Use a fixed scale for clarity
        rect.y := y + row * 2;
        rect.w := 2;
        rect.h := 2;
        SDL_RenderFillRect(renderer, @rect);
      end;
    end;
  end;
end;

procedure DrawNumber(renderer: PSDL_Renderer; n, x, y: Integer);
var
  s: string;
  i, digit, dx: Integer;
begin
  s := IntToStr(n);
  dx := 0;
  for i := 1 to Length(s) do
  begin
    digit := StrToInt(s[i]);
    DrawDigit(renderer, digit, x + dx, y);
    dx := dx + (DIGIT_W + 1) * 2; // Add 1 pixel spacing, scaled
  end;
end;

procedure DrawTransparentRect(renderer: PSDL_Renderer; const rect: TSDL_Rect; r, g, b, a: Byte);
var
  oldMode: TSDL_BlendMode;
begin
  // Save the old blend mode
  SDL_GetRenderDrawBlendMode(renderer, @oldMode);
  // Set to alpha blending
  SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
  // Set the draw color with alpha
  SDL_SetRenderDrawColor(renderer, r, g, b, a);
  // Draw the rectangle
  SDL_RenderFillRect(renderer, @rect);
  // Restore the old blend mode
  SDL_SetRenderDrawBlendMode(renderer, oldMode);
end;

end.
