-- C# via easy-dotnet.nvim (built-in Roslyn client, debugger, neotest adapter).
-- LazyVim's lang.dotnet extra is intentionally NOT enabled: it brings OmniSharp, neotest-vstest
-- and its own netcoredbg config, which conflict with easy-dotnet. See docs/adr/0002.
---@type LazySpec
return {
  { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = { "c_sharp", "xml" } } },
  { "mason-org/mason.nvim", opts = { ensure_installed = { "csharpier" } } },
  { "stevearc/conform.nvim", opts = { formatters_by_ft = { cs = { "csharpier" } } } },

  -- Make sure OmniSharp never starts, even if the extra gets enabled later.
  { "neovim/nvim-lspconfig", opts = { servers = { omnisharp = { enabled = false } } } },

  {
    "GustavEikaas/easy-dotnet.nvim",
    ft = { "cs", "fsharp", "xml" },
    cmd = "Dotnet",
    dependencies = { "nvim-lua/plenary.nvim", "mfussenegger/nvim-dap", "folke/snacks.nvim" },
    opts = {
      picker = "snacks",
      lsp = {
        enabled = true,
        preload_roslyn = true,
        roslynator_enabled = true,
        restart_roslyn_on_branch_change = false,
        auto_load_projects = false,
      },
      debugger = {
        engine = "netcoredbg", -- or "dncdbg" / "sharpdbg"
        console = "integratedTerminal",
        auto_register_dap = true,
      },
      test_runner = {
        neotest_integration = true, -- neotest owns signs/keymaps
        viewmode = "float",
      },
    },
    -- <leader>N (not <leader>n, which LazyVim uses for notification history)
    keys = {
      { "<leader>Ns", "<cmd>Dotnet solution select<cr>", desc = "Select solution" },
      { "<leader>Nb", "<cmd>Dotnet build default<cr>", desc = "Build default project" },
      { "<leader>Nd", function() require("easy-dotnet").debug_default() end, desc = "Debug default project" },
      { "<leader>Nr", function() require("easy-dotnet").run_default() end, desc = "Run default project" },
      { "<leader>Nt", function() require("easy-dotnet").testrunner() end, desc = "Test runner" },
    },
  },
  { "folke/which-key.nvim", opts = { spec = { { "<leader>N", group = "dotnet" } } } },

  -- Register easy-dotnet's neotest adapter in LazyVim's adapter table.
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = { "GustavEikaas/easy-dotnet.nvim" },
    opts = { adapters = { ["easy-dotnet.neotest"] = {} } },
  },
}
