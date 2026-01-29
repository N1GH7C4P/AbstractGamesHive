-- Player class
Player = {}
Player.__index = Player

function Player:new(playerId, pieceConfig)
    local instance = setmetatable({}, Player)
    instance.id = playerId
    instance.pieces = {}
    
    -- Initialize pieces from configuration with templates from piecesInventory
    for pieceIndex, pieceInfo in ipairs(pieceConfig) do
        local template = piecesInventory[pieceIndex]
        table.insert(instance.pieces, {
            id = template.id,
            name = template.name,
            initials = template.initials,
            inStock = pieceInfo.count,
            template = template
        })
    end
    
    return instance
end

function Player:getPieceStock(pieceId)
    if self.pieces[pieceId] then
        return self.pieces[pieceId].inStock
    end
    return 0
end

function Player:removePieceFromStock(pieceId)
    if self.pieces[pieceId] and self.pieces[pieceId].inStock > 0 then
        self.pieces[pieceId].inStock = self.pieces[pieceId].inStock - 1
        return true
    end
    return false
end

function Player:addPieceToStock(pieceId)
    if self.pieces[pieceId] then
        self.pieces[pieceId].inStock = self.pieces[pieceId].inStock + 1
        return true
    end
    return false
end

function Player:getPieceInfo(pieceId)
    return self.pieces[pieceId]
end

function Player:getAllPieces()
    return self.pieces
end

-- Legacy global functions for backward compatibility
function removePieceFromStock(player_nb, id)
    if G.player[player_nb] then
        G.player[player_nb]:removePieceFromStock(id)
    end
end

function getPiecesInStock(player_nb, id)
    if G.player[player_nb] then
        return G.player[player_nb]:getPieceStock(id)
    end
    return 0
end

return Player
