-- Picker layout matching the shell's television pickers (~/.config/television/config.toml):
-- the query and the results get rounded boxes of their own, the preview a third on the right
-- at half width. tv can't put query and results in one shared box (snacks' stock "default"
-- layout), so Neovim follows the terminal instead.
--
-- This replaces snacks' "default" preset (120+ columns) and "vertical" preset (narrower),
-- which LazyVim's files/grep/buffers pickers use.
-- Pickers with a layout of their own (explorer sidebar, vim.ui.select, ...) are unchanged.
-- A layout table with list entries replaces the stock one whole (Snacks.config.merge), so the
-- stock outer border and title don't leak in.
---@type LazySpec
return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      -- Grep results show the file name first, then its folder (fzf-lua's
      -- path.filename_first): long paths can't push the file name off the row. File pickers
      -- keep snacks' path-first view; add `filename_first = true` to `formatters.file` to use
      -- it everywhere.
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
        -- snacks switches to "vertical" below 120 columns (picker/config/defaults.lua,
        -- layout.preset). Same three boxes, stacked.
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
