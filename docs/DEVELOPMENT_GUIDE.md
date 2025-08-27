# Vampyr Refactor - Development Guide

This guide provides information for developers working on the Vampyr Refactor project.

## Code Organization

- `src/main.pas` - Entry point and main game loop
- `src/uWorldView.pas` - World rendering and game state management
- `src/renderer.pas` - SDL2 rendering abstraction
- `src/data_loaders.pas` - Game data loading and parsing
- `src/uGameTypes.pas` - Core type definitions
- `src/uGameLogic.pas` - Game mechanics implementation

## Building from Source

1. Install Free Pascal Compiler (FPC)
2. Run `build.bat` to compile the project
3. Place SDL2.dll in the `bin/` directory
4. Copy game data files to `bin/data/`

## Code Style Guidelines

- Use PascalCase for types, classes, and methods
- Use camelCase for variables and parameters
- Prefix class member variables with 'F' (e.g., `FPlayerX`)
- Use meaningful names for all identifiers
- Add comments for non-obvious code sections
- Keep methods focused and reasonably sized

## Debugging

- Use `writeln()` for simple debug output
- The game can be run from the command line to see debug messages
- Press F5 to toggle animations for debugging

## Version Control

- Create feature branches for new development
- Write descriptive commit messages
- Keep commits focused and atomic
- Rebase feature branches before merging to main

## Testing

- Test map loading and rendering
- Verify player movement and collision detection
- Check that all game mechanics work as expected
- Test on different screen resolutions

## Performance Considerations

- Minimize memory allocations during gameplay
- Use efficient data structures for game state
- Profile performance with large maps
- Optimize rendering for smooth frame rates
