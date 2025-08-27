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
    SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 1280, 400, SDL_WINDOW_SHOWN); // 1280x400 for 2x scaling of 640x200
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

  SetScale(2, 1, 2); // Set 4x horizontal (2*2) and 2x vertical (1*2) scaling

  InitWorld(World, GameRenderer, ExeDir);

  World.VisibilityEnabled := True;
  World.TileViewerScrollY := 0;


  writeln('Controls: arrows pan | F5 toggle animation | Q to quit');
  writeln('Click on map for tile info.');

  Running := True;
  while Running do
  begin
    // Process all pending events
    while SDL_PollEvent(@Event) <> 0 do
    begin
      if Event.type_ = SDL_QUITEV then
        Running := False;
        
      HandleEvent(World, GameRenderer, Event, Running);
      
      if not Running then Break; // Exit early if user pressed Q
      
      if Event.type_ = SDL_MOUSEBUTTONDOWN then
      begin
        info := GetMapClickInfo(World, GameRenderer, Event.button.x, Event.button.y);
        if info <> '' then writeln(info);
      end;
    end;

    if not Running then Break; // Exit before updating/render if we're quitting

    UpdateWorld(World, Window);
    SDL_SetRenderDrawColor(GameRenderer.FSDLRenderer, 0, 0, 0, 255);
    SDL_RenderClear(GameRenderer.FSDLRenderer);
    RenderWorld(GameRenderer, World);
    SDL_RenderPresent(GameRenderer.FSDLRenderer);
  end;

  // Cleanup in reverse order of initialization
  try
    FreeWorld(World, GameRenderer);
    if GameRenderer.FSDLRenderer <> nil then
      SDL_DestroyRenderer(GameRenderer.FSDLRenderer);
    if Window <> nil then
      SDL_DestroyWindow(Window);
  finally
    SDL_Quit;
  end;
end.

