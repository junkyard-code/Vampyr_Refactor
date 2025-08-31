unit ulayout_fixed;
{$mode objfpc}{$H+}

interface
type
  TRectI = record x,y,w,h: Integer; end;
  TLayout = record
    Content, Viewer, Stats, Msg: TRectI;
    Border, Gutter: Integer;
    ScreenW, ScreenH: Integer;
  end;

function MakeLayout1280x400: TLayout;

implementation

function MakeLayout1280x400: TLayout;
const
  W=1280; H=400; M=5; G=5; TOPH=320; RIGHTW=320;
var L: TLayout; cw,ch: Integer;
begin
  L.ScreenW := W; L.ScreenH := H; L.Border := M; L.Gutter := G;
  L.Content.x := M; L.Content.y := M;
  L.Content.w := W-2*M; L.Content.h := H-2*M;
  cw := L.Content.w; ch := L.Content.h;

  L.Viewer.x := L.Content.x;
  L.Viewer.y := L.Content.y;
  L.Viewer.w := cw - G - RIGHTW;
  L.Viewer.h := TOPH;

  L.Stats.x := L.Viewer.x + L.Viewer.w + G;
  L.Stats.y := L.Content.y;
  L.Stats.w := RIGHTW;
  L.Stats.h := TOPH;

  L.Msg.x := L.Content.x;
  L.Msg.y := L.Content.y + TOPH + G;
  L.Msg.w := cw;
  L.Msg.h := ch - TOPH - G;

  Result := L;
end;

end.
