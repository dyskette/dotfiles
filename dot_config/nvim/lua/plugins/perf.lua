-- Startup and typing latency (ADR 0008).
-- LazyVim loads LSP, gitsigns, nvim-lint and todo-comments on "LazyFile", i.e. before a file
-- opened from the command line is first drawn. Here they load on VeryLazy, right after the
-- first screen: lspconfig and gitsigns attach to the open buffers themselves, nvim-lint is run
-- once below. Treesitter stays on LazyFile so the first screen is highlighted.
if vim.g.vscode then
  return {}
end

local function after_first_screen()
  return { "VeryLazy" }
end

-- gitsigns runs `git --version` (a process spawn) on every start. Its plugin/ file calls
-- setup() before LazyVim's opts arrive, so `_git_version` in opts comes too late: instead the
-- version module is handed back with last session's answer, refreshed in the background.
local git_version_cache = vim.fn.stdpath("state") .. "/git-version"

local function gitsigns_version_cache()
  local f = io.open(git_version_cache, "r")
  local cached = f and f:read("*l")
  if f then
    f:close()
  end
  local major, minor, patch = (cached or ""):match("^(%d+)%.(%d+)%.(%d+)")
  if major then
    package.preload["gitsigns.git.version"] = function(name)
      package.preload[name] = nil
      local file = vim.api.nvim_get_runtime_file("lua/gitsigns/git/version.lua", false)[1]
      local mod = assert(loadfile(file))(name)
      mod.version = mod.version or { major = tonumber(major), minor = tonumber(minor), patch = tonumber(patch) }
      return mod
    end
  end
  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    once = true,
    callback = function()
      vim.defer_fn(function()
        vim.system({ "git", "--version" }, { text = true }, function(res)
          local v = res.code == 0 and (res.stdout or ""):match("git version (%d+%.%d+%.%d+)")
          if v and v ~= cached then
            local out = io.open(git_version_cache, "w")
            if out then
              out:write(v)
              out:close()
            end
          end
        end)
      end, 5000)
    end,
  })
end

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    vim.schedule(function()
      -- nvim-lint's own autocmds fire on later reads/writes; lint the buffer already open.
      if package.loaded.lint and vim.bo.buftype == "" then
        require("lint").try_lint()
      end
    end)
    -- blink.cmp takes ~80 ms to load (Rust matcher, snippets). Load it while idle instead of on
    -- the first `i` or `:`.
    local function prewarm()
      local blink = require("lazy.core.config").plugins["blink.cmp"]
      if not blink or blink._.loaded then
        return
      end
      if vim.fn.getchar(1) ~= 0 or vim.api.nvim_get_mode().blocking then
        return vim.defer_fn(prewarm, 200) -- typing: try again later
      end
      require("lazy").load({ plugins = { "blink.cmp" } })
    end
    vim.defer_fn(prewarm, 1000)
  end,
})

return {
  { "neovim/nvim-lspconfig", event = after_first_screen },
  { "lewis6991/gitsigns.nvim", event = after_first_screen, init = gitsigns_version_cache },
  { "mfussenegger/nvim-lint", event = after_first_screen },
  { "folke/todo-comments.nvim", event = after_first_screen },
}
