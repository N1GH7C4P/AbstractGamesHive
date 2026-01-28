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

-- Rules text for each piece from the official rules
PiecesEnum.RULES = {
    [1] = "The Queen Bee is the most limited in movement; she can only move one space at a time in any direction. Although restricted in movement, a well-timed movement of the Queen can avoid her being trapped and frustrate an opponent's plans.",
    
    [2] = "The Beetle, like the Bee, can move only one space at a time. However, unlike the Bee, a Beetle can also climb on top of any adjacent piece, and then if the player so wishes can move one space at a time over the top of the layout. The piece under the Beetle cannot move as long as the Beetle remains on top, and for the purpose of placing new tiles, that space is the color of the Beetle's tile, not the underlying tile.",
    
    [3] = "The Grasshopper is, like its namesake, a jumping piece; it moves by jumping over any number of pieces in a straight line to the first adjacent space on the opposite side of the line of pieces. It always jumps in the direction of one of its faces, never one of its corners. Because of this mode of movement, it can quickly traverse from one side of the layout to the other, and like the Beetle it can move into a surrounded space.",
    
    [4] = "The Spider may move exactly three spaces around the edge of the layout. Each space moved must be adjacent to at least one other piece.",
    
    [5] = "The Soldier Ant may move only around the edge of the layout, like the Bee or Spider, but unlike the two, it may move any number of spaces, i.e. as many spaces as the player wishes. This makes the Soldier Ant a very powerful piece, capable of moving from anywhere on the edge of the Hive to anywhere else to trap an opposing piece or free a trapped piece.",
    
    [6] = "The Ladybug is a piece that moves by temporarily climbing on top of the board and climbing back down to the main layer of the board. The Ladybug moves exactly three spaces; first atop an adjacent piece, then onto another piece, and finally down to an empty space next to the second piece it was on.",
    
    [7] = "The Mosquito can mimic the movement of any piece it touches at the start of its turn. When on top of the Hive, the Mosquito can only move like a Beetle.",
    
    [8] = "The Pillbug can move a piece next to itself to a free space that is also next to itself. The Pillbug cannot move a piece if either the Pillbug or that other piece is covered; the Pillbug cannot move a piece if that piece was moved in the most recent turn; the Pillbug cannot move a piece if the Pillbug itself was moved in the most recent turn."
}

return PiecesEnum
