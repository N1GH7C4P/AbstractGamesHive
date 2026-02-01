-- Luacheck configuration for LÖVE2D game

-- Standard globals
std = "lua51+love"

-- Project-wide globals
globals = {
    -- Game state (intentionally global)
    "G",
    "Config",
    "Console",

    -- Piece classes (OOP pattern)
    "Piece",
    "QueenBee",
    "Beetle",
    "Grasshopper",
    "Spider",
    "SoldierAnt",
    "Ladybug",
    "Mosquito",
    "Pillbug",

    -- Player class
    "Player",

    -- Piece inventory
    "piecesInventory",

    -- Graphics functions (exposed globally for main.lua)
    "drawAddedPieces",
    "drawGridHexes",
    "drawBackground",
    "drawSelected",
    "drawPieceSelector",
    "getPieceSelectorHover",
    "clickPieceSelector",
    "drawMosquitoChoicePopup",
    "checkMosquitoChoicePopupClick",
    "printPlayerStock",
    "setupCanvases",
    "drawGameBoard",

    -- Player functions (exposed globally)
    "removePieceFromStock",
    "getPiecesInStock",

    -- Network function
    "tryAddPieceToMap",

    -- Cube coordinates (used across modules without require)
    "cubecoords",

    -- GameState module
    "GameState",
}

-- Ignore specific warnings
ignore = {
    "611", -- line contains only whitespace
    "612", -- line contains trailing whitespace
    "614", -- trailing whitespace in a comment
    "121/print", -- setting read-only global 'print' (intentional in console.lua)
    "631", -- line is too long (style preference)
}

-- Maximum line length (informational only since 631 is ignored)
max_line_length = 150

-- Allow unused arguments/variables prefixed with _
unused_args = false
unused_secondaries = false

-- Files to exclude
exclude_files = {
    "tests/**",
    ".luarocks/**",
}
