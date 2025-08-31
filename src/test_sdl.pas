program test_sdl;

{$mode objfpc}{$H+}

uses
  SDL2;

var
  window: PSDL_Window;
  renderer: PSDL_Renderer;
  event: TSDL_Event;
  quit: Boolean;
  rect: TSDL_Rect;

begin
  // Initialize SDL2
  if SDL_Init(SDL_INIT_VIDEO) < 0 then
  begin
    WriteLn('SDL could not initialize! SDL_Error: ', SDL_GetError);
    Halt(1);
  end;

  // Create window
  window := SDL_CreateWindow('SDL2 Test',
    SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
    800, 600,
    SDL_WINDOW_SHOWN);
  
  if window = nil then
  begin
    WriteLn('Window could not be created! SDL_Error: ', SDL_GetError);
    SDL_Quit;
    Halt(1);
  end;

  // Create renderer
  renderer := SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED or SDL_RENDERER_PRESENTVSYNC);
  if renderer = nil then
  begin
    WriteLn('Renderer could not be created! SDL Error: ', SDL_GetError);
    SDL_DestroyWindow(window);
    SDL_Quit;
    Halt(1);
  end;

  // Initialize quit flag
  quit := False;

  // Main game loop
  while not quit do
  begin
    // Handle events
    while SDL_PollEvent(@event) <> 0 do
    begin
      if (event.type_ = SDL_QUITEV) or 
         ((event.type_ = SDL_KEYDOWN) and (event.key.keysym.sym = SDLK_ESCAPE)) then
        quit := True;
    end;

    // Clear screen
    SDL_SetRenderDrawColor(renderer, 64, 64, 255, 255);
    SDL_RenderClear(renderer);

    // Draw a red rectangle
    SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255);
    rect.x := 300;
    rect.y := 200;
    rect.w := 200;
    rect.h := 200;
    SDL_RenderFillRect(renderer, @rect);

    // Update screen
    SDL_RenderPresent(renderer);
  end;

  // Cleanup
  SDL_DestroyRenderer(renderer);
  SDL_DestroyWindow(window);
  SDL_Quit;
end.
