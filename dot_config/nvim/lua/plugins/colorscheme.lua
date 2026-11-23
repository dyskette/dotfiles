-- variant = "auto" follows 'background', which Neovim updates on terminal theme changes (ADR 0003).
---@type LazySpec
return {
  {
    "nuvic/flexoki-nvim",
    name = "flexoki",
    lazy = false,
    priority = 1000,
    opts = {
      variant = "auto",
      -- The port keeps rose-pine's violet float "surface"; use Flexoki bg-2.
      palette = {
        moon = { surface = "#1c1b1a" },
        dawn = { surface = "#f2f0e5" },
      },
    },
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "flexoki" } },
}
