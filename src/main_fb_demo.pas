program vampyr_layout_demo;
{$mode objfpc}{$H+}

uses SDL2, uGfx, uLayout, uDraw;

const
  W = 1280; H = 400; SCALE = 1;
  COL_BG     : LongWord = $FF0E0E10;
  COL_BORDER : LongWord = $FF808080;
  COL_VIEW   : LongWord = $FF202838;
  COL_STATS  : LongWord = $FF283020;
  COL_MSG    : LongWord = $FF202020;
  COL_TEST   : LongWord = $FF00FFFF;

type
  TRectIHelper = record end;

function RectI(ax,ay,aw,ah: Integer): TRectI;
begin
  Result.x := ax; Result.y := ay; Result.w := aw; Result.h := ah;
end;

var
  running: Boolean = True;
  e: TSDL_Event;
  L: TLayout;
  i: Integer;
  vGutter, hGutter: TRectI;
  outer: TRectI;

begin
  if not GfxInit(W,H,SCALE) then Halt(1);
  L := MakeLayout1280x400;

  outer := RectI(0,0,W,H);
  vGutter := RectI(L.Viewer.x + L.Viewer.w, L.Viewer.y, 5, L.Viewer.h);
  hGutter := RectI(L.Content.x, L.Viewer.y + L.Viewer.h, L.Content.w, 5);

  while running do
  begin
    while SDL_PollEvent(@e) <> 0 do
    begin
      if e.type_ = SDL_QUIT then
        running := False
      else if e.type_ = SDL_KEYDOWN then
      begin
        if e.key.keysym.sym = SDLK_ESCAPE then running := False;
        // Removed F12 save to avoid any string/AnsiString issues for now
      end;
    end;

    ClearFB(COL_BG);

    DrawRectBorder(outer, 5, COL_BORDER);
    FillRect(L.Viewer, COL_VIEW);
    FillRect(L.Stats,  COL_STATS);
    FillRect(L.Msg,    COL_MSG);

    FillRect(vGutter, COL_BORDER);
    FillRect(hGutter, COL_BORDER);

    for i := 0 to 200 do
      PutPixel(L.Viewer.x + 10 + (i mod (L.Viewer.w-20)),
               L.Viewer.y + 10 + (i div 2 mod (L.Viewer.h-20)),
               COL_TEST);

    Present;
    SDL_Delay(16);
  end;

  GfxQuit;
end.
