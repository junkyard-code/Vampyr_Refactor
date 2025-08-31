program TestSDL2;

{$mode objfpc}{$H+}

uses
  SDL2, SysUtils;

var
  window: PSDL_Window;
  renderer: PSDL_Renderer;
  event: TSDL_Event;
  running: Boolean;

begin
  // Initialize SDL2
  if SDL_Init(SDL_INIT_VIDEO) < 0 then
  begin
    WriteLn('SDL_Init failed: ', string(SDL_GetError()));
    Halt(1);
  end;

  // Create a window
  window := SDL_CreateWindow('SDL2 Test',
    SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
    640, 480,
    SDL_WINDOW_SHOWN);

  if window = nil then
  begin
    WriteLn('SDL_CreateWindow failed: ', SDL_GetError());
    SDL_Quit();
    Halt(1);
  end;

  // Create a renderer
  renderer := SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED or SDL_RENDERER_PRESENTVSYNC);
  if renderer = nil then
  begin
    WriteLn('SDL_CreateRenderer failed: ', SDL_GetError());
    SDL_DestroyWindow(window);
    SDL_Quit();
    Halt(1);
  end;

  // Main loop
  running := True;
  while running do
  begin
    // Handle events
    while SDL_PollEvent(@event) = 1 do
    begin
      case event.type_ of
        SDL_QUITEV: running := False;
        SDL_KEYDOWN:
          if event.key.keysym.sym = SDLK_ESCAPE then
            running := False;
      end;
    end;

    // Clear screen
    SDL_SetRenderDrawColor(renderer, 0, 0, 255, 255);  // Blue background
    SDL_RenderClear(renderer);
    
    // Draw a red rectangle
    var rect: TSDL_Rect;
    rect.x := 100;
    rect.y := 100;
    rect.w := 200;
    rect.h := 150;
    SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255);
    SDL_RenderDrawRect(renderer, @rect);
    
    // Update screen
    SDL_RenderPresent(renderer);
  end;

  // Cleanup
  SDL_DestroyRenderer(renderer);
  SDL_DestroyWindow(window);
  SDL_Quit();
end.
