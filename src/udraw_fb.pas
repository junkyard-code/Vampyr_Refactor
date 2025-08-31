unit udraw_fb;
{$mode objfpc}{$H+}

interface
uses ugfx_fb, ulayout_fixed;

procedure FillRect(const R: TRectI; Color: LongWord);
procedure DrawRectBorder(const R: TRectI; Thickness: Integer; Color: LongWord);

implementation

procedure FillRect(const R: TRectI; Color: LongWord);
var x0,y0,x1,y1,x,y: Integer;
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

procedure DrawRectBorder(const R: TRectI; Thickness: Integer; Color: LongWord);
var T: TRectI;
begin
  T := R; T.h := Thickness;                  FillRect(T, Color); // top
  T := R; T.y := R.y + R.h - Thickness;      T.h := Thickness;   FillRect(T, Color); // bottom
  T := R; T.w := Thickness;                  FillRect(T, Color); // left
  T := R; T.x := R.x + R.w - Thickness;      T.w := Thickness;   FillRect(T, Color); // right
end;

end.
