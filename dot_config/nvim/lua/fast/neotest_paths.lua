--- Windows: let neotest find files whose buffers are named with forward slashes.
---
--- neotest keys its positions by the paths its directory scan returns (C:\x\test_a.py), but looks
--- buffers up by their names. Pickers (snacks) open files as C:/x/test_a.py, so on Windows "run
--- nearest" said "No tests found" and no status signs or counts showed up (nvim-neotest/neotest#563).
--- Renaming such buffers isn't an option: a renamed buffer counts as "not edited" and :write fails
--- with E13. Instead, each place that turns a buffer name into a lookup key retries with backslashes
--- when the name as given finds nothing, so adapters whose ids use forward slashes still match first.
---
--- The same mismatch hits results: adapters that build result ids from their runner's report
--- (neotest-vitest: vitest reports C:/x/a.test.ts) matched no position, and neotest marked every
--- test that had just passed as failed. Results are re-keyed to the position ids they resolve to.
local M = {}

--- The id with backslashes in its path part (before "::"), or nil when that changes nothing.
---@param id any position id: a path, optionally followed by "::" and test names
---@return string?
local function native(id)
  if type(id) ~= "string" then
    return nil
  end
  local path, rest = id:match("^(.-)(::.*)$")
  path = path or id
  if not path:find("/", 1, true) then
    return nil
  end
  return path:gsub("/", "\\") .. (rest or "")
end

--- Wrap `method(self, id, ...)`: call it as given, and again with `native(id)` if it returned nil.
---@param class table
---@param method string
local function retry_native(class, method)
  local orig = class[method]
  class[method] = function(self, id, ...)
    local res = vim.F.pack_len(orig(self, id, ...))
    local fixed = res[1] == nil and native(id)
    if fixed then
      return orig(self, fixed, ...)
    end
    return vim.F.unpack_len(res)
  end
end

--- Patch neotest's lookups and return a wrapper for the client constructor.
---@param new_client fun(...): table neotest.client's module value
---@return fun(...): table
local function patch(new_client)
  -- Real files on disk: native separators are always right.
  local files = require("neotest.lib").files
  local real = files.path.real
  files.path.real = function(path)
    local p, exists = real(path)
    return p and (native(p) or p), exists
  end

  retry_native(require("neotest.types").Tree, "get_key")

  local tracker = require("neotest.consumers.state.tracker")
  local register_buffer = tracker.register_buffer
  ---@param buffer integer
  tracker.register_buffer = function(self, buffer)
    register_buffer(self, buffer)
    local fixed = native(vim.fn.fnamemodify(vim.fn.bufname(buffer), ":p"))
    if fixed then
      self.path_buffers[fixed] = buffer
    end
  end
  local buffer_state = tracker.buffer_state
  ---@param adapter_id string
  ---@param buffer integer
  tracker.buffer_state = function(self, adapter_id, buffer)
    local state = buffer_state(self, adapter_id, buffer)
    local fixed = not state and native(vim.fn.fnamemodify(vim.fn.bufname(buffer), ":p"))
    return fixed and self.adapter_states[adapter_id].buffers[fixed] or state
  end

  --- Results keyed by ids that only resolve through `native` (C:/x/a.ts::t) moved to the
  --- position's own id (C:\x\a.ts::t); the rest are kept as they are.
  ---@param tree neotest.Tree tree of the run the results belong to
  ---@param results table<string, neotest.Result>?
  ---@return table<string, neotest.Result>?
  local function rekey(tree, results)
    if not results then
      return results
    end
    local out = {}
    for id, result in pairs(results) do
      local node = native(id) and tree:get_key(id)
      out[node and node:data().id or id] = result
    end
    return out
  end

  return function(...)
    local client = new_client(...)
    -- The runner is created when the client starts; every adapter result passes through _run_spec.
    local start = client._start
    client._start = function(self, ...)
      local res = vim.F.pack_len(start(self, ...))
      local runner = self._runner
      if runner and not runner._native_results then
        runner._native_results = true
        local run_spec = runner._run_spec
        runner._run_spec = function(r, spec, tree, args, adapter_id, adapter, results_callback)
          return run_spec(r, spec, tree, args, adapter_id, adapter, function(root, results, output)
            return results_callback(root, rekey(tree, results), output)
          end)
        end
      end
      return vim.F.unpack_len(res)
    end
    for _, method in ipairs({ "get_nearest", "get_position", "get_adapter", "_get_adapter", "is_running" }) do
      retry_native(client, method)
    end
    -- These record a file just written or focused: always store the native path.
    for _, method in ipairs({ "_update_positions", "_set_focused_file" }) do
      local orig = client[method]
      client[method] = function(self, path, ...)
        return orig(self, native(path) or path, ...)
      end
    end
    return client
  end
end

--- Install the patch; call from neotest's lazy.nvim `init` (Windows only).
function M.setup()
  -- package.preload runs before lazy.nvim's loader, so this applies before neotest.setup() builds
  -- its client. The real module is loaded from its file: require() can't reenter its own preload.
  package.preload["neotest.client"] = function(name)
    package.preload["neotest.client"] = nil
    local file = vim.api.nvim_get_runtime_file("lua/neotest/client/init.lua", false)[1]
    return patch(assert(loadfile(file))(name))
  end
end

return M
