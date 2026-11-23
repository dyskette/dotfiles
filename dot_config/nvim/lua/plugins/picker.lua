-- Query, results and preview in separate rounded boxes, matching television's pickers.
-- Overrides snacks' "default" (>= 120 columns) and "vertical" (narrower) presets. A layout
-- with list entries replaces the stock one whole, so its outer border doesn't leak in.
---@type LazySpec
return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        grep = { formatters = { file = { filename_first = true } } },
        grep_word = { formatters = { file = { filename_first = true } } },
      },
      layouts = {
        default = {
          layout = {
            box = "horizontal",
            width = 0.8,
            min_width = 120,
            height = 0.8,
            border = "none",
            {
              box = "vertical",
              { win = "input", height = 1, border = true, title = "{title} {live} {flags}" },
              { win = "list", border = true },
            },
            { win = "preview", title = "{preview}", border = true, width = 0.5 },
          },
        },
        vertical = {
          layout = {
            box = "vertical",
            width = 0.5,
            min_width = 80,
            height = 0.8,
            min_height = 30,
            border = "none",
            { win = "input", height = 1, border = true, title = "{title} {live} {flags}" },
            { win = "list", border = true },
            { win = "preview", title = "{preview}", height = 0.4, border = true },
          },
        },
      },
    },
  },
}
