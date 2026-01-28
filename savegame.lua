-- Hive Game Save File
-- Generated: 2026-01-28 14:34:07

return {
  ["map"] = {
    ["current_radius"] = 10,
  },
  ["game_state"] = {
    ["active_player_id"] = 2,
    ["active_piece_id"] = 1,
    ["turn_number"] = {
      [1] = 4,
      [2] = 3,
    },
    ["highlight"] = 0,
    ["move_mode"] = 0,
    ["game_over"] = false,
    ["selected_piece_x"] = 1,
    ["selected_piece_y"] = 1,
    ["who_won"] = {
      [1] = 0,
      [2] = 0,
    },
  },
  ["camera"] = {
    ["zoom"] = 0.8,
    ["x"] = 512,
    ["y"] = 384,
  },
  ["players"] = {
    [1] = {
      ["pieces"] = {
        [1] = {
          ["inStock"] = 0,
          ["id"] = 1,
          ["name"] = "Queen bee",
        },
        [2] = {
          ["inStock"] = 2,
          ["id"] = 2,
          ["name"] = "Beetle",
        },
        [3] = {
          ["inStock"] = 3,
          ["id"] = 3,
          ["name"] = "Grasshopper",
        },
        [4] = {
          ["inStock"] = 2,
          ["id"] = 4,
          ["name"] = "Spider",
        },
        [5] = {
          ["inStock"] = 2,
          ["id"] = 5,
          ["name"] = "Soldier ant",
        },
        [6] = {
          ["inStock"] = 1,
          ["id"] = 6,
          ["name"] = "Ladybug",
        },
        [7] = {
          ["inStock"] = 1,
          ["id"] = 7,
          ["name"] = "Mosquito",
        },
        [8] = {
          ["inStock"] = 0,
          ["id"] = 8,
          ["name"] = "Pillbug",
        },
      },
      ["id"] = 1,
    },
    [2] = {
      ["pieces"] = {
        [1] = {
          ["inStock"] = 0,
          ["id"] = 1,
          ["name"] = "Queen bee",
        },
        [2] = {
          ["inStock"] = 2,
          ["id"] = 2,
          ["name"] = "Beetle",
        },
        [3] = {
          ["inStock"] = 3,
          ["id"] = 3,
          ["name"] = "Grasshopper",
        },
        [4] = {
          ["inStock"] = 2,
          ["id"] = 4,
          ["name"] = "Spider",
        },
        [5] = {
          ["inStock"] = 3,
          ["id"] = 5,
          ["name"] = "Soldier ant",
        },
        [6] = {
          ["inStock"] = 1,
          ["id"] = 6,
          ["name"] = "Ladybug",
        },
        [7] = {
          ["inStock"] = 1,
          ["id"] = 7,
          ["name"] = "Mosquito",
        },
        [8] = {
          ["inStock"] = 0,
          ["id"] = 8,
          ["name"] = "Pillbug",
        },
      },
      ["id"] = 2,
    },
  },
  ["board"] = {
    [1] = {
      ["player_id"] = 1,
      ["cube"] = {
        ["z"] = 0,
        ["x"] = 0,
        ["y"] = 0,
      },
      ["piece_id"] = 5,
      ["has_under_piece"] = false,
    },
    [2] = {
      ["player_id"] = 2,
      ["cube"] = {
        ["z"] = 0,
        ["x"] = 1,
        ["y"] = -1,
      },
      ["piece_id"] = 8,
      ["has_under_piece"] = false,
    },
    [3] = {
      ["player_id"] = 1,
      ["cube"] = {
        ["z"] = -1,
        ["x"] = 0,
        ["y"] = 1,
      },
      ["piece_id"] = 1,
      ["has_under_piece"] = false,
    },
    [4] = {
      ["player_id"] = 1,
      ["cube"] = {
        ["z"] = 0,
        ["x"] = -1,
        ["y"] = 1,
      },
      ["piece_id"] = 8,
      ["has_under_piece"] = false,
    },
    [5] = {
      ["player_id"] = 2,
      ["cube"] = {
        ["z"] = 1,
        ["x"] = 1,
        ["y"] = -2,
      },
      ["piece_id"] = 1,
      ["has_under_piece"] = false,
    },
  },
}
