-- One palette everywhere: Flexoki (Ghostty, tmux, lazygit, bat/delta, Neovim). See docs/adr/0003.
-- variant = "auto" follows 'background'. Neovim 0.12 re-queries the terminal background on a
-- theme-change notification (DEC mode 2031, forwarded by tmux >= 3.6) and updates 'background',
-- which reloads the colorscheme — so light/dark switches live with Ghostty.
---@type LazySpec
return {
  {
    "nuvic/flexoki-nvim",
    name = "flexoki",
    lazy = false,
    priority = 1000,
    opts = {
      variant = "auto",
      -- nuvic's port derives from rose-pine and keeps its "surface" (#1f1d2e, a violet) for floats:
      -- pickers, explorer, which-key, lazygit popup. Use Flexoki bg-2 instead.
      palette = {
        moon = { surface = "#1c1b1a" },
        dawn = { surface = "#f2f0e5" },
      },
    },
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "flexoki" } },
}
