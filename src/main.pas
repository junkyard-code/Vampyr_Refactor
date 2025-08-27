program vampyr_world_v7;

{$mode objfpc}{$H+}

uses
  SDL2, SysUtils, Classes, uGameTypes, renderer, uWorldView, data_loaders, uGameLogic;

var
  SearchRec: TSearchRec; // Add this line to declare the SearchRec variable


var
  Window: PSDL_Window;
  GameRenderer: TRenderer;
  Event: TSDL_Event;
  Running: Boolean;
  World: TWorldState;
  info: AnsiString;

function ExeDir: string;
begin
  // Point to the project root directory
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)) + '..');
  writeln('Project directory set to: ', Result);
  
  // Check if data directory exists
  if not DirectoryExists(Result + 'data') then
  begin
    writeln('ERROR: Data directory does not exist: ', Result + 'data');
    writeln('Current directory: ', GetCurrentDir);
  end;
  
  // List files in the data directory for debugging
  if DirectoryExists(Result + 'data') then
  begin
    writeln('Data directory contents:');
    FindFirst(Result + 'data\*.*', faAnyFile, SearchRec);
    repeat
      writeln('  ', SearchRec.Name);
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;
end;

begin
  InitializeTraversalData;
  if SDL_Init(SDL_INIT_VIDEO) <> 0 then
  begin
    writeln('SDL_Init error: ', SDL_GetError);
    halt(1);
  end;

  Window := SDL_CreateWindow('Vampyr World Viewer - Refactored',
    SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 252, 126, SDL_WINDOW_SHOWN); // 7x7 tiles (36x18 px)
  if Window = nil then
  begin
    writeln('SDL_CreateWindow error: ', SDL_GetError);
    halt(1);
  end;

  GameRenderer.FSDLRenderer := SDL_CreateRenderer(Window, -1, SDL_RENDERER_ACCELERATED or SDL_RENDERER_PRESENTVSYNC);
  if GameRenderer.FSDLRenderer = nil then
  begin
    writeln('SDL_CreateRenderer error: ', SDL_GetError);
    halt(1);
  end;

  SetScale(2, 1, 1); // Set initial scaling for the renderer

  InitWorld(World, GameRenderer, ExeDir);

  World.VisibilityEnabled := True;
  World.TileViewerScrollY := 0;


  writeln('Controls: arrows pan | F5 toggle animation | ESC quit');
  writeln('Click on map for tile info.');

  Running := True;
  while Running do
  begin
    while SDL_PollEvent(@Event) = 1 do
    begin
      HandleEvent(World, GameRenderer, Event, Running);
      if Event.type_ = SDL_MOUSEBUTTONDOWN then
      begin
        info := GetMapClickInfo(World, GameRenderer, Event.button.x, Event.button.y);
        if info <> '' then writeln(info);
      end;
    end;

    UpdateWorld(World, Window);

    SDL_SetRenderDrawColor(GameRenderer.FSDLRenderer, 0,0,0,255);
    SDL_RenderClear(GameRenderer.FSDLRenderer);
    RenderWorld(GameRenderer, World);
    SDL_RenderPresent(GameRenderer.FSDLRenderer);
  end;

  // cleanup
  FreeWorld(World, GameRenderer);
  SDL_DestroyRenderer(GameRenderer.FSDLRenderer);
  SDL_DestroyWindow(Window);
  SDL_Quit;
end.

