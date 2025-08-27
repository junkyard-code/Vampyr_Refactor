# Vampyr RPG - Modernization Project

A refactoring effort to modernize the classic 1989 Turbo Pascal RPG "Vampyr" using modern Pascal and SDL2.

## Project Overview

This project aims to preserve the original gameplay and data files while modernizing the codebase for contemporary development practices and cross-platform compatibility.

## Project Structure

```
vampyr-refactoring/
├── original_source/          # Original 1989 Turbo Pascal source code (preserved)
├── src/                      # Modern refactored source code
├── data/                     # Game data files (maps, tiles, etc.)
├── assets/                   # Graphics, sounds, and other assets
├── docs/                     # Documentation and development notes
├── tools/                    # Utilities and helper programs
├── tests/                    # Unit tests and validation
└── SDL2-for-Pascal-2.3-stable/ # SDL2 Pascal headers
```

## Original Game Files

The original source includes:
- **VAMPYR.PAS** - Main game engine (60KB)
- **VCOMBAT.PAS** - Combat system (63KB)
- **DISPLAY.PAS** - Graphics and display routines
- **SHOP.PAS** - Shop and trading system
- **TALK.PAS** - NPC dialogue system
- **TITLE.PAS** - Title screen and intro
- **INITVAM.PAS** - Game initialization
- **MUSIC.PAS** - Sound and music system
- Various map files (.MAP), configuration files (.CON), and data files (.DAT)

## Development Status

- ✅ Original source code preserved
- 🔄 Game viewer with basic movement (previous work)
- 📋 Project organization and version control setup
- ⏳ Modern Pascal refactoring (planned)
- ⏳ SDL2 integration (planned)
- ⏳ Cross-platform compatibility (planned)

## Dependencies

- Free Pascal Compiler (FPC) or Delphi
- SDL2 for Pascal (included in project)
- SDL2 runtime libraries

## Getting Started

1. Ensure you have Free Pascal or Delphi installed
2. Install SDL2 development libraries
3. Clone this repository
4. Review the original source code in `original_source/`
5. Begin development in the `src/` directory

## License

Original game code from 1989. Refactoring efforts are open source.
