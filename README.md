# Vampyr Refactor Project

A modern reimplementation of the classic 1989 Turbo Pascal RPG "Vampyr" using Free Pascal and SDL2.

## Project Structure

- `src/` - Source code
- `bin/` - Compiled binaries
- `data/` - Game data files
- `lib/` - SDL2 libraries
- `build/` - Build artifacts
- `resources/` - Original game resources and development tools

## Prerequisites

1. **Free Pascal Compiler (FPC)**
   - Download from: [Free Pascal Downloads](https://www.freepascal.org/download.html)
   - Make sure to add FPC to your system PATH

2. **SDL2 Development Libraries**
   - Download SDL2 development libraries for Windows (32-bit)
   - Place `SDL2.dll` in the `bin/` directory

## Building the Project

1. Clone the repository
2. Copy SDL2.dll to the `bin/` directory
3. Run the build script:
   ```
   .\build.bat
   ```

## Running the Game

1. Ensure all game data files are in the `bin\data\` directory
2. Run the game:
   ```
   .\bin\vampyr_world_viewer.exe
   ```

## Controls

- Arrow Keys: Move player
- F5: Toggle animations
- ESC: Quit game
- Click on map: Show tile information

## Development Notes

- The project uses SDL2 for graphics and input
- Original game data files are preserved in `resources/original_source/`
- Previous implementation is available in `resources/previous_builds/`

## License

This project is for educational purposes only. All original game assets and code are copyright their respective owners.
