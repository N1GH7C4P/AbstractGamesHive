-- Piece types enumeration
-- Centralized definition of all piece IDs and names

local PiecesEnum = {
    QUEEN_BEE = 1,
    BEETLE = 2,
    GRASSHOPPER = 3,
    SPIDER = 4,
    SOLDIER_ANT = 5,
    LADYBUG = 6,
    MOSQUITO = 7,
    PILLBUG = 8
}

-- Reverse mapping: ID to name
PiecesEnum.ID_TO_NAME = {
    [1] = "Queen Bee",
    [2] = "Beetle",
    [3] = "Grasshopper",
    [4] = "Spider",
    [5] = "Soldier Ant",
    [6] = "Ladybug",
    [7] = "Mosquito",
    [8] = "Pillbug"
}

return PiecesEnum
