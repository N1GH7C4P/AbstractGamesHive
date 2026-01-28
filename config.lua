-- Game configuration file
Config = {}

-- Piece inventory configuration for each player
-- Names correspond to piece classes
Config.pieceInventory = {
    {name = "QueenBee", count = 1},
    {name = "Beetle", count = 2},
    {name = "Grasshopper", count = 3},
    {name = "Spider", count = 2},
    {name = "SoldierAnt", count = 3},
    {name = "Ladybug", count = 1},
    {name = "Mosquito", count = 1},
    {name = "Pillbug", count = 1},
}

-- Game settings
Config.game = {
    windowWidth = 1024,
    windowHeight = 768,
    mapWidth = 100,
    mapHeight = 100,
    hexSize = 35,
    menuOffsetX = 620,
}

-- Queen placement rule
Config.rules = {
    queenMustBePlacedByTurn = 4,  -- Queen bee must be placed by turn 4
}

return Config
