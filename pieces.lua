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
    end
end