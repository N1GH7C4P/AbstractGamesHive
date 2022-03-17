require "pieces"

function init_players()
    player = {}

    for i = 1, 2 do
        player[i] = {}
        player[i].pieces = {}
        player[i].pieces[1] = piecesInventory.queenBee
        player[i].pieces[1].inStock = 1
        player[i].pieces[2] = piecesInventory.spider
        player[i].pieces[2].inStock = 2
        player[i].pieces[3] = piecesInventory.beetle
        player[i].pieces[3].inStock = 2
        player[i].pieces[4] = piecesInventory.grassHopper
        player[i].pieces[4].inStock = 3
        player[i].pieces[5] = piecesInventory.soldierAnt
        player[i].pieces[5].inStock = 3
    end

    return player
end

function removePieceFromStock(player_nb, id)
    if player[player_nb].pieces[id].inStock > 0 then
        player[player_nb].pieces[id].inStock = player.pieces[id].inStock - 1
    end
end

function getPiecesInStock(player_nb, id)
    return (player[player_nb].pieces[id].inStock)
end