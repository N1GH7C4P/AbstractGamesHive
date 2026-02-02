# AbstractGameHive (Hive Helsinki Rush project)
* https://love2d.org

https://en.wikipedia.org/wiki/Hive_(game)#Movement_and_pieces

## Architecture

The codebase is organized into a modular structure with clear separation of concerns.

### Module Hierarchy

```
main.lua (Entry Point)
├── config.lua                    # Game configuration
├── animation.lua                 # Animation system
├── console.lua                   # Debug console
│
├── game.lua                      # Core game logic
│   ├── player.lua                # Player management
│   ├── globals.lua               # Global state management
│   ├── hexagon.lua               # Hexagon drawing/math
│   ├── map.lua                   # Game board/map
│   ├── pieces.lua                # Piece initialization
│   │   ├── config.lua
│   │   └── pieces/               # Individual piece types
│   │       ├── pieces_enum.lua   # Piece type constants
│   │       ├── piece.lua         # Base piece class
│   │       ├── movement_utils.lua # Shared movement logic
│   │       ├── queenbee.lua
│   │       ├── beetle.lua
│   │       ├── grasshopper.lua
│   │       ├── spider.lua
│   │       ├── soldierant.lua
│   │       ├── ladybug.lua
│   │       ├── mosquito.lua
│   │       └── pillbug.lua
│   └── cubecoords.lua            # Cube coordinate system
│
├── graphics.lua                  # Rendering system
│   ├── hexagon.lua
│   ├── map.lua
│   ├── cubecoords.lua
│   └── animation.lua
│
├── ui.lua                        # User interface
│   ├── cubecoords.lua
│   ├── map.lua
│   ├── network.lua               # (lazy loaded)
│   └── pieces/pieces_enum.lua    # (lazy loaded)
│
├── input.lua                     # Input handling
│   ├── actions.lua               # Game action execution
│   ├── pieces/pieces_enum.lua
│   ├── cubecoords.lua
│   ├── gamestate.lua             # Save/load system
│   ├── console.lua
│   ├── network.lua
│   ├── globals.lua
│   ├── game.lua
│   ├── map.lua
│   └── camera.lua                # Camera controls
│
├── actions.lua                   # Game actions (placement, movement, special abilities)
│
├── camera.lua                    # Camera zoom & pan
│
└── network.lua                   # Multiplayer networking
    └── game.lua

Utility Modules:
├── cubecoords.lua               # Hexagonal coordinate math
├── hexagon.lua                  # Hexagon geometry
├── map.lua                      # Board state management
├── globals.lua                  # Global state helpers
├── gamestate.lua                # Serialization
├── camera.lua                   # Camera controls (zoom & pan)
└── json.lua                     # JSON parser
```

### Core Systems

1. **Game Loop** ([main.lua](main.lua))
   - Entry point and LÖVE2D callbacks
   - Coordinates update/draw cycles

2. **Game Logic** ([game.lua](game.lua))
   - Game initialization and state
   - Win condition checking
   - Turn management

3. **Rendering** ([graphics.lua](graphics.lua))
   - Board rendering
   - Piece visualization
   - Animation display

4. **User Interface** ([ui.lua](ui.lua))
   - Piece selector
   - Tooltips and overlays
   - Game over screen

5. **Input System** ([input.lua](input.lua))
   - Mouse and keyboard handling
   - Delegates camera controls to [camera.lua](camera.lua)
   - Delegates game actions to [actions.lua](actions.lua)

6. **Actions** ([actions.lua](actions.lua))
   - Piece placement and movement execution
   - Inventory navigation
   - Special abilities (pillbug, mosquito)

7. **Camera** ([camera.lua](camera.lua))
   - Zoom in/out (mouse wheel, +/- keys)
   - Pan (drag with right/middle click)
   - Screen ↔ world coordinate conversion

8. **Network** ([network.lua](network.lua))
   - LAN multiplayer via LuaSocket
   - Server/client architecture
   - Move synchronization

9. **Coordinate System** ([cubecoords.lua](cubecoords.lua))
   - Hexagonal grid mathematics
   - Pixel ↔ cube coordinate conversion

## Controls
- **a/s**: Cycle through piece types to place
- **Left click**: Place piece or select/move piece
- **Right/Middle click + drag**: Pan camera
- **Mouse wheel** or **+/-**: Zoom in/out
- **0**: Reset zoom to 1.0x
- **h**: Toggle hex coordinate display
- **c**: Toggle console
- **x**: Clear console
- **d**: Export game state to file
- **l**: Load game state from file

## Multiplayer (LAN)
- **n**: Host a network game (becomes Player 1)
- **m**: Join a network game (becomes Player 2)
- **q**: Quit network game

### How to Play Multiplayer
1. **Host:** Press `n` on one computer to host a game (default port 12345)
2. **Join:** Press `m` on another computer on the same network to join
3. The host (Player 1) goes first, then players alternate turns
4. Moves are automatically synchronized over the network

**Note:** Requires LuaSocket. Install with: `luarocks install luasocket`

## Development

### Setup

```bash
# Install Lua and luarocks (if not already installed)
brew install lua luarocks

# Install development tools
luarocks install --local busted      # Test framework
luarocks install --local luacheck    # Static analyzer
```

### Running Tests

```bash
# Run all tests
busted tests/

# Run tests with verbose output
busted tests/ --verbose

# Run specific test file
busted tests/camera_spec.lua
```

### Static Analysis

```bash
# Run luacheck on all files
luacheck .
```

A pre-commit hook runs both luacheck and tests automatically before each commit.

### Test Coverage

**238 tests** covering core modules including:
- Piece movement logic (all 8 piece types)
- Game state management
- Coordinate systems
- Camera controls

All tests pass with 0 failures.

<img src="/img/screenshot.png" width="500" height="auto"/>

