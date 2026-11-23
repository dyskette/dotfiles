-- C# via easy-dotnet.nvim instead of LazyVim's lang.dotnet extra (ADR 0002).
---@type LazySpec
return {
  { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = { "c_sharp", "xml" } } },
  { "mason-org/mason.nvim", opts = { ensure_installed = { "csharpier" } } },
  { "stevearc/conform.nvim", opts = { formatters_by_ft = { cs = { "csharpier" } } } },

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
        engine = "netcoredbg",
        console = "integratedTerminal",
        auto_register_dap = true,
      },
      test_runner = {
        neotest_integration = true,
        viewmode = "float",
      },
    },
    -- <leader>n is LazyVim's notification history.
    keys = {
      { "<leader>Ns", "<cmd>Dotnet solution select<cr>", desc = "Select solution" },
      { "<leader>Nb", "<cmd>Dotnet build default<cr>", desc = "Build default project" },
      { "<leader>Nd", function() require("easy-dotnet").debug_default() end, desc = "Debug default project" },
      { "<leader>Nr", function() require("easy-dotnet").run_default() end, desc = "Run default project" },
      { "<leader>Nt", function() require("easy-dotnet").testrunner() end, desc = "Test runner" },
    },
  },
  { "folke/which-key.nvim", opts = { spec = { { "<leader>N", group = "dotnet" } } } },

  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = { "GustavEikaas/easy-dotnet.nvim" },
    opts = { adapters = { ["easy-dotnet.neotest"] = {} } },
  },
}
