-- Game configuration file
Config = {}

-- Piece inventory configuration for each player
Config.pieceInventory = {
    {id = 1, name = "Queen bee", initials = "QB", count = 1},
    {id = 2, name = "Beetle", initials = "Be", count = 2},
    {id = 3, name = "Grasshopper", initials = "GH", count = 3},
    {id = 4, name = "Spider", initials = "Sp", count = 2},
    {id = 5, name = "Soldier ant", initials = "SA", count = 3},
    {id = 6, name = "Ladybug", initials = "LB", count = 1},
    {id = 7, name = "Mosquito", initials = "Mo", count = 1},
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
