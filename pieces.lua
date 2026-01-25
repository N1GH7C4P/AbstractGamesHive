-- Require all piece classes
Piece = require("pieces.piece")
QueenBee = require("pieces.queenbee")
Beetle = require("pieces.beetle")
Grasshopper = require("pieces.grasshopper")
Spider = require("pieces.spider")
SoldierAnt = require("pieces.soldierant")

-- Legacy functions for compatibility
function init_pieces()
    piecesInventory = {}

    piecesInventory.queenBee = {}
    piecesInventory.beetle = {}
    piecesInventory.grassHopper = {}
    piecesInventory.spider = {}
    piecesInventory.soldierAnt = {}

    piecesInventory.queenBee.name = "Queen bee"
    piecesInventory.beetle.name = "Beetle"
    piecesInventory.grassHopper.name = "Grasshopper"
    piecesInventory.spider.name = "Spider"
    piecesInventory.soldierAnt.name = "Soldier ant"

    piecesInventory.queenBee.initials = "QB"
    piecesInventory.beetle.initials = "Be"
    piecesInventory.grassHopper.initials = "GH"
    piecesInventory.spider.initials = "Sp"
    piecesInventory.soldierAnt.initials = "SA"

    piecesInventory.queenBee.color = {1, 0.78, 0, 1}
    piecesInventory.beetle.color = {0.5, 0.2, 0, 1}
    piecesInventory.grassHopper.color = {0.2, 1, 0.2, 1}
    piecesInventory.spider.color = {0.5, 0, 0, 1}
    piecesInventory.soldierAnt.color = {0.5, 0.5, 0.5, 1}

    piecesInventory.queenBee.id = 1
    piecesInventory.beetle.id = 2
    piecesInventory.grassHopper.id = 3
    piecesInventory.spider.id = 4
    piecesInventory.soldierAnt.id = 5

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
    end
end