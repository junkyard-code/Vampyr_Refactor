unit data_loaders;

{$mode objfpc}{$H+}

interface

uses SysUtils, Classes, SDL2, renderer, uGameTypes;

const
  // Rotate decoded tiles by 90-degree steps (0,1,2,3). 1 = 90° clockwise.
  ROT_QUADS = 3;


type
  TUInt32Array = array[0..$3FFFFFF] of UInt32;
  PUInt32Array = ^TUInt32Array;

  TIconData = array[0..TILE_W * TILE_H - 1] of Byte;
  T32BitPixels = array[0..TILE_W * TILE_H - 1] of UInt32;

function LoadSetMonsters(const FileName: string; out SetMonsters: TSetMonsterDataArray): Boolean;
function LoadCON(const fileName: AnsiString; out pixels: PUInt32; out count: Integer; FlipHorizontal, ApplyRotation: Boolean): Boolean;
function MergeTilesets(const univPixels: PUInt32; const univCount: Integer;
                       const landPixels: PUInt32; const landCount: Integer;
                       out merged: PUInt32; out mergedCount: Integer): Boolean;
function LoadMAPSlice(const Filename: string; W, H, BytesPerIndex: Integer; ColMajor: Boolean; MapIndex: Integer): TTileMap;
function LoadMAPOrdered(const fileName: AnsiString; width, height: Integer;
                        indexSize: Integer; columnMajor: Boolean): TTileMap;
function LoadCONFileTile(const FileName: string; TileIndex: integer; out IconData: TIconData): boolean;
function LoadMonsterPictures(const FileName: string; R: PSDL_Renderer; out TileSet: TTileSet): Boolean;
procedure ConvertIconTo32Bit(const IconData: TIconData; out Pixels: T32BitPixels);

procedure FreePixels(p: PUInt32);

implementation

const
  TILE_W = renderer.TILE_W;
  TILE_H = renderer.TILE_H;
  TILE_PIX = TILE_W * TILE_H;

type
  TRGB = packed record r,g,b: Byte; end;

var
  PALETTE: array[0..15] of TRGB = (
    (r:0;   g:0;   b:0  ), // 0 black
    (r:0;   g:0;   b:170), // 1 blue
    (r:0;   g:170; b:0  ), // 2 green
    (r:0;   g:170; b:170), // 3 cyan
    (r:170; g:0;   b:0  ), // 4 red
    (r:170; g:0;   b:170), // 5 magenta
    (r:170; g:85;  b:0  ), // 6 brown
    (r:170; g:170; b:170), // 7 light gray
    (r:85;  g:85;  b:85 ), // 8 dark gray
    (r:85;  g:85;  b:255), // 9 bright blue
    (r:85;  g:255; b:85 ), // 10 bright green
    (r:85;  g:255; b:255), // 11 bright cyan
    (r:255; g:85;  b:85 ), // 12 bright red
    (r:255; g:85;  b:255), // 13 bright magenta
    (r:255; g:255; b:85 ), // 14 yellow
    (r:255; g:255; b:255)  // 15 white
  );

function Color32(idx: Byte): UInt32; inline;
var c: TRGB;
begin
  c := PALETTE[idx and $0F];
  Result := (UInt32($FF) shl 24) or (UInt32(c.r) shl 16) or (UInt32(c.g) shl 8) or UInt32(c.b);
end;

function LoadFileBytes(const fileName: AnsiString): TBytes;
var fs: TFileStream; n: integer;
begin
  SetLength(Result, 0);
  if not FileExists(fileName) then Exit;
  fs := TFileStream.Create(fileName, fmOpenRead or fmShareDenyWrite);
  try
    n := fs.Size;
    if n > 0 then begin
      SetLength(Result, n);
      fs.ReadBuffer(Result[0], n);
    end;
  finally
    fs.Free;
  end;
end;

function LoadCON(const fileName: AnsiString; out pixels: PUInt32; out count: Integer; FlipHorizontal, ApplyRotation: Boolean): Boolean;
var
  data: TBytes;
  i, t, x, y: Integer;
  ofs: Integer;
  totalPix: Integer;
begin
  pixels := nil; count := 0;
  data := LoadFileBytes(fileName);
  if Length(data) = 0 then Exit(False);
  count := Length(data) div (TILE_PIX); // 324 bytes per icon
  if count <= 0 then Exit(False);

  totalPix := count * TILE_PIX;
  GetMem(pixels, totalPix * SizeOf(UInt32));
  ofs := 0;
  for t := 0 to count-1 do
    for y := 0 to TILE_H-1 do
      for x := 0 to TILE_W-1 do
      begin
        // Apply rotation by ROT_QUADS
        if ApplyRotation then
        begin
          if FlipHorizontal then
            case ROT_QUADS of // Rotated and Flipped
              0: PUInt32Array(pixels)^[t*TILE_PIX + y*TILE_W + (TILE_W - 1 - x)] := Color32(data[ofs]);
              1: PUInt32Array(pixels)^[t*TILE_PIX + (TILE_H - 1 - x)*TILE_W + (TILE_W - 1 - y)] := Color32(data[ofs]);
              2: PUInt32Array(pixels)^[t*TILE_PIX + (TILE_H - 1 - y)*TILE_W + x] := Color32(data[ofs]);
              3: PUInt32Array(pixels)^[t*TILE_PIX + x*TILE_W + y] := Color32(data[ofs]);
            end
          else
            case ROT_QUADS of // Rotated only
              0: PUInt32Array(pixels)^[t*TILE_PIX + y*TILE_W + x] := Color32(data[ofs]);
              1: PUInt32Array(pixels)^[t*TILE_PIX + (TILE_H - 1 - x)*TILE_W + y] := Color32(data[ofs]);
              2: PUInt32Array(pixels)^[t*TILE_PIX + (TILE_H - 1 - y)*TILE_W + (TILE_W - 1 - x)] := Color32(data[ofs]);
              3: PUInt32Array(pixels)^[t*TILE_PIX + x*TILE_W + (TILE_H - 1 - y)] := Color32(data[ofs]);
            end;
        end
        else
        begin
           if FlipHorizontal then // Flipped only
             PUInt32Array(pixels)^[t*TILE_PIX + y*TILE_W + (TILE_W - 1 - x)] := Color32(data[ofs])
           else // No rotation, no flip
             PUInt32Array(pixels)^[t*TILE_PIX + y*TILE_W + x] := Color32(data[ofs]);
        end;
        Inc(ofs);
      end;
  Result := True;
end;

function MergeTilesets(const univPixels: PUInt32; const univCount: Integer;
                       const landPixels: PUInt32; const landCount: Integer;
                       out merged: PUInt32; out mergedCount: Integer): Boolean;
var
  total: Integer;
begin
  merged := nil; mergedCount := 0;
  total := univCount + landCount;
  if total <= 0 then Exit(False);
  GetMem(merged, total * TILE_PIX * SizeOf(UInt32));
  move(univPixels^, merged^, univCount * TILE_PIX * SizeOf(UInt32));
  move(landPixels^, (merged + univCount*TILE_PIX)^, landCount * TILE_PIX * SizeOf(UInt32));
  mergedCount := total;
  Result := True;
end;

function ConvertMapToRowMajor(const ColMajorMap: TTileMap): TTileMap;
var
  x, y: Integer;
begin
  Result.Width := ColMajorMap.Width;
  Result.Height := ColMajorMap.Height;
  Result.IndexSize := ColMajorMap.IndexSize;
  SetLength(Result.Data, ColMajorMap.Width * ColMajorMap.Height);
  for y := 0 to ColMajorMap.Height - 1 do
    for x := 0 to ColMajorMap.Width - 1 do
      Result.Data[y * ColMajorMap.Width + x] := ColMajorMap.Data[x * ColMajorMap.Height + y];
end;

function LoadMAPSlice(const Filename: string; W, H, BytesPerIndex: Integer; ColMajor: Boolean; MapIndex: Integer): TTileMap;
var
  F: TFileStream;
  mapBytes: Integer;
  mapOffset: Int64;
  byteData: TBytes;
  i: Integer;
begin
  Result.Width := 0; Result.Height := 0; Result.IndexSize := 0; Result.Data := nil;
  if not FileExists(Filename) then Exit;

  // All slice-based maps in the original game used a fixed 2500-byte record size.
  // The logical dimensions (W, H) might differ, but the file structure is constant.
  mapOffset := MapIndex * 2500;

  F := TFileStream.Create(Filename, fmOpenRead);
  try
    if F.Size < mapOffset + (W*H) then Exit; // Not enough data for this map index

    F.Position := mapOffset;
    Result.Width := W;
    Result.Height := H;
    Result.IndexSize := BytesPerIndex;
    SetLength(Result.Data, W * H);
    FillChar(Result.Data[0], Length(Result.Data) * SizeOf(Integer), 0);

    if BytesPerIndex = 1 then
    begin
      SetLength(byteData, W*H);
      F.ReadBuffer(byteData[0], W*H);
      for i := 0 to (W*H)-1 do Result.Data[i] := byteData[i];
    end;

  finally
    F.Free;
  end;

  if ColMajor then
    Result := ConvertMapToRowMajor(Result);
end;

function LoadMAPOrdered(const fileName: AnsiString; width, height: Integer;
                        indexSize: Integer; columnMajor: Boolean): TTileMap;
var
  bytes: TBytes;
  x, y, i: Integer;
begin
  bytes := LoadFileBytes(fileName);
  Result.Width := width;
  Result.Height := height;
  Result.IndexSize := indexSize;
  SetLength(Result.Data, width*height);
  // Directly copy bytes first
  for i := 0 to width*height-1 do
    if i < Length(bytes) then Result.Data[i] := bytes[i] else Result.Data[i] := 0;

  // If the source is column-major, we must convert it to row-major for the engine
  if columnMajor then
  begin
    Result := ConvertMapToRowMajor(Result);
  end;
end;

procedure FreePixels(p: PUInt32);
begin
  if p <> nil then FreeMem(p);
end;

function LoadCONFileTile(const FileName: string; TileIndex: integer; out IconData: TIconData): boolean;
var
  f: TFileStream;
begin
  Result := False;
  if not FileExists(FileName) then
  begin
    writeln('File not found: ', FileName);
    Exit;
  end;

  f := TFileStream.Create(FileName, fmOpenRead);
  try
    if f.Size < (TileIndex + 1) * SizeOf(TIconData) then
    begin
      writeln('Error: Tile index is out of bounds in ', FileName);
      Exit;
    end;

    f.Position := TileIndex * SizeOf(TIconData);
    f.ReadBuffer(IconData, SizeOf(TIconData));
    Result := True;
  finally
    f.Free;
  end;
end;

function LoadSetMonsters(const FileName: string; out SetMonsters: TSetMonsterDataArray): Boolean;
var
  F: TFileStream;
  numRecords: Integer;
begin
  Result := False;
  if not FileExists(FileName) then
  begin
    writeln('File not found: ', FileName);
    Exit;
  end;

  F := TFileStream.Create(FileName, fmOpenRead);
  try
    numRecords := F.Size div SizeOf(TSetMonsterData);
    if numRecords <= 0 then
    begin
      writeln('No set monster records found in ', FileName);
      Exit;
    end;

    SetLength(SetMonsters, numRecords);
    F.ReadBuffer(SetMonsters[0], numRecords * SizeOf(TSetMonsterData));
    Result := True;
  finally
    F.Free;
  end;
end;


procedure ConvertIconTo32Bit(const IconData: TIconData; out Pixels: T32BitPixels);
var
  x, y, src_idx, dst_idx: integer;
begin
  for y := 0 to TILE_H - 1 do
  begin
    for x := 0 to TILE_W - 1 do
    begin
      src_idx := y * TILE_W + x;
      // Apply a 270-degree clockwise rotation (90-degree counter-clockwise)
      dst_idx := x * TILE_W + (TILE_H - 1 - y);
      Pixels[dst_idx] := Color32(IconData[src_idx]);
    end;
  end;
end;

function LoadMonsterPictures(const FileName: string; R: PSDL_Renderer; out TileSet: TTileSet): Boolean;
var
  pixels: PUInt32;
  count: Integer;
begin
  Result := False;
  if not LoadCON(FileName, pixels, count, False, False) then
  begin
    writeln('Failed to load monster pictures from ', FileName);
    Exit;
  end;

  BuildTileTexture(R, TileSet, pixels, count);
  FreePixels(pixels);
  Result := True;
end;

end.
