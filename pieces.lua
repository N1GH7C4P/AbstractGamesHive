function init_pieces()
    piecesInventory = {}

    piecesInventory.queenBee = {}
    piecesInventory.beetle = {}
    piecesInventory.grassHopper = {}
    piecesInventory.spider = {}
    piecesInventory.soldierAnt = {}

    piecesInventory.queenBee.color = {1, 0, 0, 1}
    piecesInventory.beetle.color = {0, 1, 0, 1}
    piecesInventory.grassHopper.color = {0, 0, 1, 1}
    piecesInventory.spider.color = {1, 1, 0, 1}
    piecesInventory.soldierAnt.color = {0, 1, 1, 1}

    piecesInventory.queenBee.color = {1, 0, 0, 1}
    piecesInventory.beetle.color = {0, 1, 0, 1}
    piecesInventory.grassHopper.color = {0, 0, 1, 1}
    piecesInventory.spider.color = {1, 1, 0, 1}
    piecesInventory.soldierAnt.color = {0, 1, 1, 1}

    piecesInventory.queenBee.id = 1
    piecesInventory.beetle.id = 2
    piecesInventory.grassHopper.id =3
    piecesInventory.spider.id = 4
    piecesInventory.soldierAnt.id = 5

    return (piecesInventory)
end

function getPieceFromInventoryById(id)
    if id == 1 then
        return (piecesInventory.queenBee)
    elseif id == 2 then
        return (piecesInventory.beetle)
    elseif id == 3 then
        return (piecesInventory.grassHopper)
    elseif id == 4 then
        return (piecesInventory.spider)
    elseif id == 5 then
        return (piecesInventory.soldierAnt)
    else
        print ("piece id error!")
    end
end