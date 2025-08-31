program TestSDL2;

{$mode objfpc}{$H+}

uses
  SDL2;

const
  SCREEN_WIDTH = 800;
  SCREEN_HEIGHT = 600;
  WINDOW_TITLE = 'SDL2 Test';

var
  window: PSDL_Window = nil;
  renderer: PSDL_Renderer = nil;
  quit: Boolean = False;
  event: TSDL_Event;

begin
  // Initialize SDL2
  if SDL_Init(SDL_INIT_VIDEO) < 0 then
  begin
    WriteLn('SDL_Init failed: ', SDL_GetError);
    Halt(1);
  end;

  try
    // Create window
    window := SDL_CreateWindow(
      PAnsiChar(AnsiString(WINDOW_TITLE)),
      SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
      SCREEN_WIDTH, SCREEN_HEIGHT,
      SDL_WINDOW_SHOWN or SDL_WINDOW_RESIZABLE
    );

    if window = nil then
    begin
      WriteLn('Window could not be created! SDL_Error: ', SDL_GetError);
      Halt(1);
    end;

    // Create renderer
    renderer := SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED or SDL_RENDERER_PRESENTVSYNC);
    if renderer = nil then
    begin
      WriteLn('Renderer could not be created! SDL_Error: ', SDL_GetError);
      Halt(1);
    end;

    // Set renderer color
    SDL_SetRenderDrawColor(renderer, 100, 149, 237, 255); // Cornflower blue

    // Main loop
    while not quit do
    begin
      // Handle events
      while SDL_PollEvent(@event) <> 0 do
      begin
        if event.type_ = SDL_QUITEV then
          quit := True;
      end;

      // Clear screen
      SDL_RenderClear(renderer);
      
      // Update screen
      SDL_RenderPresent(renderer);
    end;

  finally
    // Cleanup
    if renderer <> nil then
      SDL_DestroyRenderer(renderer);
    if window <> nil then
      SDL_DestroyWindow(window);
    
    // Quit SDL
    SDL_Quit;
  end;
end.
