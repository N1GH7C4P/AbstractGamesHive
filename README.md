# HIVE Abstract game
* https://love2d.org
* a, s and click to select piece

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

<img src="hive.png" width="500" height="auto"/>

