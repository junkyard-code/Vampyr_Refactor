unit uRenderer;
{$mode objfpc}{$H+}

interface

uses SDL2, uPalette16, uConLoader;

function MakeTileTexture(Renderer: PSDL_Renderer; const Con: TCon; TileIndex: Integer): PSDL_Texture;

implementation

const TILE_W=18; TILE_H=18; TILE_SIZE=TILE_W*TILE_H;

function MakeTileTexture(Renderer: PSDL_Renderer; const Con: TCon; TileIndex: Integer): PSDL_Texture;
var
  surface: PSDL_Surface;
  pixels: PUInt32;
  x,y: Integer;
  idx_base, src_x, src_y, src_idx: Integer;
  pitch: Integer;
  c: Byte;
begin
  Result := nil;
  if (Con.Data=nil) or (TileIndex<0) or (TileIndex>=Con.TileCount) then Exit;

  surface := SDL_CreateRGBSurface(0, TILE_W, TILE_H, 32, $00FF0000, $0000FF00, $000000FF, $FF000000);
  if surface=nil then Exit;
  pixels := PUInt32(surface^.pixels);
  pitch := surface^.pitch div 4;

  { Rotate each 18x18 tile 90 degrees CLOCKWISE when mapping source -> destination }
  idx_base := TileIndex*TILE_SIZE;
  for y:=0 to TILE_H-1 do
    for x:=0 to TILE_W-1 do
    begin
      src_x := y;
      src_y := (TILE_H-1) - x;
      src_idx := idx_base + src_y*TILE_W + src_x;
      c := Con.Data^[src_idx];
      pixels[y*pitch + x] := (Uint32($FF) shl 24)
                           or (Uint32(uPalette16.PALETTE16[c].r) shl 16)
                           or (Uint32(uPalette16.PALETTE16[c].g) shl 8)
                           or (Uint32(uPalette16.PALETTE16[c].b));
    end;

  Result := SDL_CreateTextureFromSurface(Renderer, surface);
  SDL_FreeSurface(surface);
end;

end.
