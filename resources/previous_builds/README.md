# Previous AI Viewer Builds

This directory contains the game viewer implementations created by previous AI assistants.

## Current Structure
```
previous_builds/
├── bin/          # Compiled executables and runtime files
├── src/          # Source code from previous builds
├── build.bat     # Build script (to be added)
└── run.bat       # Run script (to be added)
```

## Integration Instructions

1. Copy your existing viewer build files:
   - Source files → `src/`
   - Compiled files → `bin/`
   - `build.bat` and `run.bat` → root of `previous_builds/`

2. We'll analyze the working components and integrate them into the main project

## Expected Components

Based on the development notes, previous builds likely include:
- Map reading functionality
- Basic tile rendering
- Character movement system
- SDL2 integration
- Data file parsers

## Integration Strategy

- Review source code for working components
- Test existing builds using run.bat
- Extract reusable modules
- Merge best components into unified `src/` directory
- Preserve version history in Git commits
