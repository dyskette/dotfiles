-- lualine and bufferline replaced by fast.ui.statusline / fast.ui.tabline: same layout and keys,
-- with their parts cached instead of recomputed on every redraw (ADR 0008). noice stays.
if vim.g.vscode then
  return {}
end

local function tabline()
  return require("fast.ui.tabline")
end

---@type LazySpec
return {
  { "nvim-lualine/lualine.nvim", enabled = false },
  { "akinsho/bufferline.nvim", enabled = false },
  {
    "LazyVim/LazyVim",
    init = function()
      require("fast.ui.statusline").setup()
      tabline().setup()
    end,
    -- bufferline's keys in LazyVim, on the new tabline
    -- stylua: ignore
    keys = {
      { "<S-h>", function() tabline().cycle(-vim.v.count1) end, desc = "Prev Buffer" },
      { "<S-l>", function() tabline().cycle(vim.v.count1) end, desc = "Next Buffer" },
      { "[b", function() tabline().cycle(-vim.v.count1) end, desc = "Prev Buffer" },
      { "]b", function() tabline().cycle(vim.v.count1) end, desc = "Next Buffer" },
      { "[B", function() tabline().move(-1) end, desc = "Move buffer prev" },
      { "]B", function() tabline().move(1) end, desc = "Move buffer next" },
      { "<leader>bp", function() tabline().toggle_pin() end, desc = "Toggle Pin" },
      { "<leader>bP", function() tabline().close_unpinned() end, desc = "Delete Non-Pinned Buffers" },
      { "<leader>br", function() tabline().close_side(1) end, desc = "Delete Buffers to the Right" },
      { "<leader>bl", function() tabline().close_side(-1) end, desc = "Delete Buffers to the Left" },
      { "<leader>bj", function() tabline().pick() end, desc = "Pick Buffer" },
    },
  },
}
