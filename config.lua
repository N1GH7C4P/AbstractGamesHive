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
    mapRadius = 10,  -- Initial map radius in hex rings from center
    hexSize = 35,
    menuOffsetX = 620,
}

-- Queen placement rule
Config.rules = {
    queenMustBePlacedByTurn = 4,
}

-- Network settings
Config.network = {
    defaultPort = 12345,
}

-- Visual style and colors
Config.style = {
    -- Board colors
    background = {0.08, 0.1, 0.12, 1},      -- Dark blue-gray
    gridLine = {0.25, 0.28, 0.32, 1},       -- Lighter blue-gray for grid lines

    -- Player piece backgrounds
    player1Piece = {0.2, 0.15, 0.1, 1},     -- Dark brown (dark player)
    player2Piece = {0.95, 0.9, 0.8, 1},     -- Cream/off-white (light player)

    -- Piece selector (slightly different from board pieces)
    player1Selector = {0.25, 0.2, 0.15, 1},
    player1SelectorText = {1, 1, 1, 1},             -- White text on dark background
    player2Selector = {0.9, 0.85, 0.75, 1},
    player2SelectorText = {0.2, 0.15, 0.1, 1},      -- Dark text on light background
    selectorDisabled = {0.3, 0.3, 0.3, 0.5},
    selectorDisabledText = {0.5, 0.5, 0.5, 0.5},

    -- Move highlights
    normalMove = {1, 0.6, 0.2, 0.6},        -- Orange for normal moves
    beetleClimb = {0.6, 0.3, 0.8, 0.6},     -- Purple for beetle climbing
    specialAbility = {0.2, 0.8, 0.9, 0.5},  -- Cyan for pillbug special
    dropLocation = {0.9, 0.3, 0.3, 0.6},    -- Red for drop locations
    selection = {0.3, 0.9, 0.4, 1},         -- Green for selected piece

    -- UI indicators
    selectionHighlight = {1, 0.9, 0.3, 0.5},  -- Yellow for inventory selection
    player1StackIndicator = {1, 0.9, 0.3, 1},     -- Yellow on dark pieces
    player2StackIndicator = {0.2, 0.15, 0.1, 1},  -- Dark brown on light pieces
    stackIndicatorScale = 1.4,                     -- Scale multiplier for stack text
    movedPieceBorder = {0.7, 0.1, 0.2, 1},    -- Dark crimson border for moved pieces
}

return Config
