-- LazyVim's keys inside VS Code (vscode-neovim, ADR 0007). LazyVim loads its vscode extra on its own
-- when vim.g.vscode is set; this remaps the keys whose LazyVim versions open Neovim UI (snacks
-- pickers, explorer, lazygit) or need an LSP to the matching VS Code commands.
if not vim.g.vscode then
  return {}
end

local vscode = require("vscode")

---@param cmd string VS Code command id
---@param args? table
local function act(cmd, args)
  return function()
    vscode.action(cmd, args and { args = args } or nil)
  end
end

-- No wl-copy/xclip inside the Flatpak sandbox: yank and put through VS Code's clipboard
-- (vscode-neovim's own provider when it defines one, otherwise the same through its eval API).
local function copy(lines)
  vscode.eval("await vscode.env.clipboard.writeText(args)", { args = table.concat(lines, "\n") })
end
local function paste()
  return vim.split(vscode.eval("return await vscode.env.clipboard.readText()"), "\n")
end
vim.g.clipboard = vim.g.vscode_clipboard
  or { name = "vscode", copy = { ["+"] = copy, ["*"] = copy }, paste = { ["+"] = paste, ["*"] = paste } }

local function lazygit()
  vscode.call("workbench.action.createTerminalEditor")
  vscode.action("workbench.action.terminal.sendSequence", { args = { text = "lazygit && exit\r" } })
end

local function debug_continue()
  local running = vscode.eval("return vscode.debug.activeDebugSession !== undefined")
  vscode.action(running and "workbench.action.debug.continue" or "workbench.action.debug.start")
end

local keys = {
  { "<leader>ff", act("workbench.action.quickOpen"), desc = "Find Files" },
  { "<leader>fF", act("workbench.action.quickOpen"), desc = "Find Files" },
  { "<leader>fr", act("workbench.action.openRecent"), desc = "Recent" },
  { "<leader>fb", act("workbench.action.showAllEditorsByMostRecentlyUsed"), desc = "Buffers" },
  { "<leader>,", act("workbench.action.showAllEditorsByMostRecentlyUsed"), desc = "Buffers" },
  { "<leader>sg", act("workbench.action.findInFiles"), desc = "Grep" },
  { "<leader>sG", act("workbench.action.findInFiles"), desc = "Grep" },
  { "<leader>sw", act("workbench.action.findInFiles"), mode = { "n", "x" }, desc = "Word or Selection" },
  { "<leader>sS", act("workbench.action.showAllSymbols"), desc = "Workspace Symbols" },
  { "<leader>sk", act("workbench.action.openGlobalKeybindings"), desc = "Keymaps" },
  { "<leader>sC", act("workbench.action.showCommands"), desc = "Commands" },
  { "<leader>sd", act("workbench.actions.view.problems"), desc = "Diagnostics" },
  { "<leader>xx", act("workbench.actions.view.problems"), desc = "Diagnostics" },
  { "<leader>e", act("workbench.view.explorer"), desc = "Explorer" },
  { "<leader>E", act("workbench.files.action.showActiveFileInExplorer"), desc = "Explorer (current file)" },
  { "<leader>gg", lazygit, desc = "Lazygit" },
  { "<leader>gb", act("git.blame.toggleEditorDecoration"), desc = "Git Blame" },
  { "<leader>gf", act("timeline.focus"), desc = "Git File History" },
  { "<leader>gs", act("workbench.view.scm"), desc = "Git Status" },
  { "<leader>gd", act("git.openChange"), desc = "Git Diff" },
  -- LSP (VS Code's language features)
  { "gr", act("editor.action.goToReferences"), desc = "References" },
  { "gI", act("editor.action.goToImplementation"), desc = "Goto Implementation" },
  { "gy", act("editor.action.goToTypeDefinition"), desc = "Goto Type Definition" },
  { "gD", act("editor.action.revealDeclaration"), desc = "Goto Declaration" },
  { "gK", act("editor.action.triggerParameterHints"), desc = "Signature Help" },
  { "<leader>ca", act("editor.action.quickFix"), mode = { "n", "x" }, desc = "Code Action" },
  { "<leader>cA", act("editor.action.sourceAction"), desc = "Source Action" },
  { "<leader>cr", act("editor.action.rename"), desc = "Rename" },
  { "<leader>cf", act("editor.action.formatDocument"), desc = "Format" },
  { "<leader>cf", act("editor.action.formatSelection"), mode = "x", desc = "Format" },
  { "<leader>cs", act("outline.focus"), desc = "Symbols" },
  { "<leader>cd", act("editor.action.showHover"), desc = "Line Diagnostics" },
  -- Diagnostics: VS Code doesn't filter by severity, so ]e/[e behave like ]d/[d.
  { "]d", act("editor.action.marker.next"), desc = "Next Diagnostic" },
  { "[d", act("editor.action.marker.prev"), desc = "Prev Diagnostic" },
  { "]e", act("editor.action.marker.next"), desc = "Next Error" },
  { "[e", act("editor.action.marker.prev"), desc = "Prev Error" },
  -- Git hunks
  { "]h", act("workbench.action.editor.nextChange"), desc = "Next Hunk" },
  { "[h", act("workbench.action.editor.previousChange"), desc = "Prev Hunk" },
  { "<leader>ghs", act("git.stageSelectedRanges"), mode = { "n", "x" }, desc = "Stage Hunk" },
  { "<leader>ghr", act("git.revertSelectedRanges"), mode = { "n", "x" }, desc = "Reset Hunk" },
  { "<leader>ghp", act("editor.action.dirtydiff.next"), desc = "Preview Hunk" },
  { "<leader>ghd", act("git.openChange"), desc = "Diff This" },
  -- Buffers and windows: VS Code editors and editor groups
  { "<leader>bd", act("workbench.action.closeActiveEditor"), desc = "Delete Buffer" },
  { "<leader>bo", act("workbench.action.closeOtherEditors"), desc = "Delete Other Buffers" },
  { "<leader>-", act("workbench.action.splitEditorDown"), desc = "Split Window Below" },
  { "<leader>|", act("workbench.action.splitEditorRight"), desc = "Split Window Right" },
  { "<leader>wd", act("workbench.action.closeEditorsAndGroup"), desc = "Delete Window" },
  { "<leader>wm", act("workbench.action.toggleMaximizeEditorGroup"), desc = "Maximize Window" },
  { "<C-h>", act("workbench.action.navigateLeft"), desc = "Go to Left Window" },
  { "<C-j>", act("workbench.action.navigateDown"), desc = "Go to Lower Window" },
  { "<C-k>", act("workbench.action.navigateUp"), desc = "Go to Upper Window" },
  { "<C-l>", act("workbench.action.navigateRight"), desc = "Go to Right Window" },
  { "<leader>qq", act("workbench.action.closeWindow"), desc = "Quit" },
  { "<leader>uw", act("editor.action.toggleWordWrap"), desc = "Toggle Wrap" },
  { "<leader>uz", act("workbench.action.toggleZenMode"), desc = "Toggle Zen Mode" },
  -- Debug (dap.core) and tests (test.core)
  { "<leader>db", act("editor.debug.action.toggleBreakpoint"), desc = "Toggle Breakpoint" },
  { "<leader>dB", act("editor.debug.action.conditionalBreakpoint"), desc = "Breakpoint Condition" },
  { "<leader>dc", debug_continue, desc = "Run/Continue" },
  { "<leader>dC", act("editor.debug.action.runToCursor"), desc = "Run to Cursor" },
  { "<leader>di", act("workbench.action.debug.stepInto"), desc = "Step Into" },
  { "<leader>dO", act("workbench.action.debug.stepOver"), desc = "Step Over" },
  { "<leader>do", act("workbench.action.debug.stepOut"), desc = "Step Out" },
  { "<leader>dP", act("workbench.action.debug.pause"), desc = "Pause" },
  { "<leader>dt", act("workbench.action.debug.stop"), desc = "Terminate" },
  { "<leader>dr", act("workbench.debug.action.toggleRepl"), desc = "Toggle REPL" },
  { "<leader>du", act("workbench.view.debug"), desc = "Debug View" },
  { "<leader>tr", act("testing.runAtCursor"), desc = "Run Nearest" },
  { "<leader>tt", act("testing.runCurrentFile"), desc = "Run File" },
  { "<leader>tT", act("testing.runAll"), desc = "Run All Tests" },
  { "<leader>tl", act("testing.reRunLastRun"), desc = "Run Last" },
  { "<leader>td", act("testing.debugAtCursor"), desc = "Debug Nearest" },
  { "<leader>ts", act("workbench.view.testing.focus"), desc = "Toggle Summary" },
  { "<leader>tO", act("testing.showMostRecentOutput"), desc = "Toggle Output Panel" },
  { "<leader>tS", act("testing.cancelRun"), desc = "Stop" },
}

-- Set where the extra sets its own: after LazyVim's core keymaps and plugin keys, so these win.
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyVimKeymapsDefaults",
  callback = function()
    for _, k in ipairs(keys) do
      vim.keymap.set(k.mode or "n", k[1], k[2], { desc = k.desc })
    end
  end,
})

return {}
