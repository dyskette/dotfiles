--- smart-splits backend for psmux (Windows): moves and resizes in one request on psmux's socket.
---
--- smart-splits-backend-tmux runs `tmux` for each step of a move: zoom check, edge check, pane count,
--- `select-pane`. Under psmux each run costs ~25 ms (process start, Defender scan, an AUTH probe and the
--- command on two connections), and Neovim is blocked meanwhile: 75-100 ms per move into another pane.
--- Here a move is one request that answers and acts at once (~13 ms, the server's timer tick).
---
--- The socket protocol is the one psmux's own CLI speaks (`AUTH <key>`, a command line, then the reply
--- after `OK`), not a documented API: anything unexpected falls back to backend-tmux. Recheck it
--- when the psmux pin in mise/config.toml moves. Everything else (detect, health) is backend-tmux's.
local tmux = require("smart-splits-backend-tmux")

local M = {
  name = "psmux",
  protocol_version = tmux.protocol_version,
  detect = tmux.detect,
  health = tmux.health,
}

local uv = vim.uv
local TIMEOUT_MS = 300 -- backend-tmux's default per call
local DIRECTION_KEYS = { left = "L", right = "R", up = "U", down = "D" }

---@type integer|nil, string|nil
local port, key

--- The server's port from `$TMUX` (`<socket path>,<port>,0`) and the key in the `.key` file next to
--- the `.port` file holding that port, as psmux's CLI finds them.
---@return boolean
local function endpoint()
  if key then
    return true
  end
  port = tonumber((vim.env.TMUX or ""):match("^[^,]*,(%d+),"))
  if not port then
    return false
  end
  local dir = vim.env.PSMUX_DATA_DIR or (vim.env.USERPROFILE .. "\\.psmux")
  for name, kind in vim.fs.dir(dir) do
    local base = kind == "file" and name:match("^(.+)%.port$")
    if base and not base:find("__warm__", 1, true) then
      local f = io.open(dir .. "\\" .. name)
      local text = f and f:read("*a")
      if f then
        f:close()
      end
      if tonumber(vim.trim(text or "")) == port then
        f = io.open(dir .. "\\" .. base .. ".key")
        key = f and vim.trim(f:read("*a"))
        if f then
          f:close()
        end
        return key ~= nil and key ~= ""
      end
    end
  end
  return false
end

--- Send one command line and wait for the reply.
---@param line string psmux command line; `;` chains commands
---@return string|nil reply what the commands printed, nil on any failure (then the caller falls back)
local function request(line)
  if not endpoint() then
    return nil
  end
  local tcp = uv.new_tcp()
  if not tcp then
    return nil
  end
  local chunks, done, failed = {}, false, false
  tcp:connect("127.0.0.1", port, function(err)
    if err then
      failed, done = true, true
      return
    end
    tcp:write("AUTH " .. key .. "\n" .. line .. "\n")
    -- the server closes the connection once the commands have run, so EOF ends the reply
    tcp:read_start(function(read_err, data)
      if read_err then
        failed, done = true, true
      elseif data then
        chunks[#chunks + 1] = data
      else
        done = true
      end
    end)
  end)
  local finished = vim.wait(TIMEOUT_MS, function()
    return done
  end, 1)
  if not tcp:is_closing() then
    tcp:close()
  end
  local reply = table.concat(chunks):gsub("\r\n", "\n")
  if not finished or failed or reply:sub(1, 3) ~= "OK\n" then
    -- a refused key or a restarted server: look both up again next time
    key = nil
    return nil
  end
  reply = reply:sub(4)
  if reply:find("^ERROR") then
    return nil
  end
  return reply
end

--- Neovim's `@pane-is-vim` marker is set and cleared by plugins/navigation.lua without blocking,
--- so backend-tmux's activate (two more blocking `tmux` runs on the first key) is not needed.
function M.activate() end

--- With `at_edge = "wrap"`, backend-tmux moves (`select-pane`, which wraps) unless the pane is zoomed or
--- alone in its window. The same rule as one request: print it, then act on it.
---@param direction SmartSplitsDirection
---@param opts? SmartSplitsBackendMoveOpts
---@return boolean
function M.move(direction, opts)
  local dir_key = DIRECTION_KEYS[direction]
  if opts and opts.at_edge == "wrap" and dir_key then
    -- `!=` rather than `#{e|>:#{window_panes},1}`, which psmux evaluates to 0 even for 2 panes
    local moves = "#{&&:#{!=:#{window_zoomed_flag},1},#{!=:#{window_panes},1}}"
    local reply = request(('display-message -p -- "%s" ; if -F "%s" "select-pane -%s"'):format(moves, moves, dir_key))
    if reply then
      return vim.trim(reply) == "1"
    end
  end
  return tmux.move(direction, opts)
end

---@param direction SmartSplitsDirection
---@param opts? SmartSplitsBackendResizeOpts
---@return boolean
function M.resize(direction, opts)
  local dir_key = DIRECTION_KEYS[direction]
  local amount = opts and opts.amount
  if dir_key and amount and request(("resize-pane -%s %d"):format(dir_key, amount)) then
    return true
  end
  return tmux.resize(direction, opts)
end

return M
