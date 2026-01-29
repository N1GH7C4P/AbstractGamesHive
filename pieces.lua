-- Require all piece classes
Piece = require("pieces.piece")
QueenBee = require("pieces.queenbee")
Beetle = require("pieces.beetle")
Grasshopper = require("pieces.grasshopper")
Spider = require("pieces.spider")
SoldierAnt = require("pieces.soldierant")
Ladybug = require("pieces.ladybug")
Mosquito = require("pieces.mosquito")
Pillbug = require("pieces.pillbug")

-- Map of class names to constructors
local pieceClasses = {
    QueenBee = QueenBee,
    Beetle = Beetle,
    Grasshopper = Grasshopper,
    Spider = Spider,
    SoldierAnt = SoldierAnt,
    Ladybug = Ladybug,
    Mosquito = Mosquito,
    Pillbug = Pillbug
}

-- Initialize piece templates from config
function init_pieces()
    local Config = require("config")
    piecesInventory = {}
    
    -- Create template pieces (owner 1 for template)
    for index, pieceConfig in ipairs(Config.pieceInventory) do
        local className = pieceConfig.name
        local pieceClass = pieceClasses[className]
        
        if pieceClass then
            -- Create a template instance to get properties
            local template = pieceClass:new(1)
            
            piecesInventory[index] = {
                id = template.id,
                name = template.name,
                initials = template.initials,
                color = template.color,
                image_path = template.image_path,
                image = nil,
                class = pieceClass
            }
        else
            print("Warning: Unknown piece class: " .. className)
        end
    end
    
    return piecesInventory
end
