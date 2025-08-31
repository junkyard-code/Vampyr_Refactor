unit uDraw;
{$mode objfpc}{$H+}

interface
uses uGfx, uLayout;

procedure FillRect(const R: TRectI; Color: UInt32);
procedure DrawRectBorder(const R: TRectI; Thickness: Integer; Color: UInt32);
procedure BlitARGB32(const Src: PUInt32; SrcW, SrcH, SrcPitchPx: Integer;
                     const DstR: TRectI; const Clip: TRectI; Opaque: Boolean = True);

implementation

procedure FillRect(const R: TRectI; Color: UInt32);
var
  x0,y0,x1,y1,x,y: Integer;
begin
  x0 := R.x; y0 := R.y; x1 := R.x + R.w - 1; y1 := R.y + R.h - 1;
  if x0 < 0 then x0 := 0;
  if y0 < 0 then y0 := 0;
  if x1 >= ScreenW then x1 := ScreenW-1;
  if y1 >= ScreenH then y1 := ScreenH-1;
  for y := y0 to y1 do
    for x := x0 to x1 do
      FB[y*ScreenW + x] := Color;
end;

procedure DrawRectBorder(const R: TRectI; Thickness: Integer; Color: UInt32);
var T: TRectI;
begin
  // top
  T := R; T.h := Thickness; FillRect(T, Color);
  // bottom
  T := R; T.y := R.y + R.h - Thickness; T.h := Thickness; FillRect(T, Color);
  // left
  T := R; T.w := Thickness; FillRect(T, Color);
  // right
  T := R; T.x := R.x + R.w - Thickness; T.w := Thickness; FillRect(T, Color);
end;

procedure BlitARGB32(const Src: PUInt32; SrcW, SrcH, SrcPitchPx: Integer;
                     const DstR: TRectI; const Clip: TRectI; Opaque: Boolean);
var
  x,y, dstX, dstY: Integer;
  rowSrc, rowDst: PUInt32;
  clipX0, clipY0, clipX1, clipY1: Integer;
begin
  clipX0 := Clip.x; clipY0 := Clip.y;
  clipX1 := Clip.x + Clip.w - 1;
  clipY1 := Clip.y + Clip.h - 1;

  for y := 0 to SrcH-1 do
  begin
    dstY := DstR.y + y;
    if (dstY < clipY0) or (dstY > clipY1) or (dstY < 0) or (dstY >= ScreenH) then continue;

    rowSrc := Src;
    Inc(rowSrc, y*SrcPitchPx);
    rowDst := @FB[dstY*ScreenW];

    for x := 0 to SrcW-1 do
    begin
      dstX := DstR.x + x;
      if (dstX < clipX0) or (dstX > clipX1) or (dstX < 0) or (dstX >= ScreenW) then continue;

      if Opaque then
        rowDst[dstX] := rowSrc[x]
      else
      begin
        if (rowSrc[x] shr 24) <> 0 then rowDst[dstX] := rowSrc[x];
      end;
    end;
  end;
end;

end.
