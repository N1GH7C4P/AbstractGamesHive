-- Require all piece classes
Piece = require("pieces.piece")
QueenBee = require("pieces.queenbee")
Beetle = require("pieces.beetle")
Grasshopper = require("pieces.grasshopper")
Spider = require("pieces.spider")
SoldierAnt = require("pieces.soldierant")
Ladybug = require("pieces.ladybug")

-- Legacy functions for compatibility
function init_pieces()
    piecesInventory = {}

    -- Initialize from config-like structure for backward compatibility
    piecesInventory[1] = {name = "Queen bee", initials = "QB", id = 1}
    piecesInventory[2] = {name = "Beetle", initials = "Be", id = 2}
    piecesInventory[3] = {name = "Grasshopper", initials = "GH", id = 3}
    piecesInventory[4] = {name = "Spider", initials = "Sp", id = 4}
    piecesInventory[5] = {name = "Soldier ant", initials = "SA", id = 5}
    piecesInventory[6] = {name = "Ladybug", initials = "LB", id = 6}
    
    -- Old named access for backward compatibility
    piecesInventory.queenBee = piecesInventory[1]
    piecesInventory.beetle = piecesInventory[2]
    piecesInventory.grassHopper = piecesInventory[3]
    piecesInventory.spider = piecesInventory[4]
    piecesInventory.soldierAnt = piecesInventory[5]
    piecesInventory.ladybug = piecesInventory[6]

    piecesInventory.queenBee.color = {1, 0.78, 0, 1}
    piecesInventory.beetle.color = {0.5, 0.2, 0, 1}
    piecesInventory.grassHopper.color = {0.2, 1, 0.2, 1}
    piecesInventory.spider.color = {0.5, 0, 0, 1}
    piecesInventory.soldierAnt.color = {0.5, 0.5, 0.5, 1}
    piecesInventory.ladybug.color = {1, 0, 0, 1}

    return (piecesInventory)
end

function getPieceFromInventoryById(id)
    -- Return a new instance of the appropriate piece class
    -- This ensures each placed piece has all the methods available
    if id == 1 then
        return QueenBee:new(active_player_id)
    elseif id == 2 then
        return Beetle:new(active_player_id)
    elseif id == 3 then
        return Grasshopper:new(active_player_id)
    elseif id == 4 then
        return Spider:new(active_player_id)
    elseif id == 5 then
        return SoldierAnt:new(active_player_id)
    elseif id == 6 then
        return Ladybug:new(active_player_id)
    end
end

-- Create a new piece instance by type
function createPieceByType(pieceType, owner)
    if pieceType == "queenBee" or pieceType == 1 then
        return QueenBee:new(owner)
    elseif pieceType == "beetle" or pieceType == 2 then
        return Beetle:new(owner)
    elseif pieceType == "grasshopper" or pieceType == 3 then
        return Grasshopper:new(owner)
    elseif pieceType == "spider" or pieceType == 4 then
        return Spider:new(owner)
    elseif pieceType == "soldierAnt" or pieceType == 5 then
        return SoldierAnt:new(owner)
    elseif pieceType == "ladybug" or pieceType == 6 then
        return Ladybug:new(owner)
    end
end