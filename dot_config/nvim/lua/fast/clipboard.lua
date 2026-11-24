--- Windows clipboard through the Win32 API (LuaJIT FFI) instead of a process per yank/put.
---
--- The default provider runs win32yank.exe for every `y` and `p` with 'clipboard=unnamedplus':
--- 15-50 ms each on Windows (process start + Defender scan). These calls take microseconds.
--- Falls back to win32yank when the clipboard can't be opened (another app holds it).
local M = {}

local ffi = require("ffi")

ffi.cdef([[
  typedef void* HANDLE;
  typedef void* HWND;
  typedef unsigned int UINT;
  typedef int BOOL;
  BOOL OpenClipboard(HWND hWndNewOwner);
  BOOL CloseClipboard(void);
  BOOL EmptyClipboard(void);
  HANDLE GetClipboardData(UINT uFormat);
  HANDLE SetClipboardData(UINT uFormat, HANDLE hMem);
  HANDLE GlobalAlloc(UINT uFlags, size_t dwBytes);
  void* GlobalLock(HANDLE hMem);
  BOOL GlobalUnlock(HANDLE hMem);
  HANDLE GlobalFree(HANDLE hMem);
  int MultiByteToWideChar(UINT CodePage, unsigned long dwFlags, const char* lpMultiByteStr, int cbMultiByte, wchar_t* lpWideCharStr, int cchWideChar);
  int WideCharToMultiByte(UINT CodePage, unsigned long dwFlags, const wchar_t* lpWideCharStr, int cchWideChar, char* lpMultiByteStr, int cbMultiByte, const char* lpDefaultChar, int* lpUsedDefaultChar);
]])

local user32, kernel32 = ffi.load("user32"), ffi.C
local CF_UNICODETEXT, GMEM_MOVEABLE, CP_UTF8 = 13, 0x0002, 65001

--- Last copy, so a put of our own linewise/blockwise yank keeps its register type.
local last = { text = nil, regtype = "v" }

local function open()
  for _ = 1, 10 do
    if user32.OpenClipboard(nil) ~= 0 then
      return true
    end
    vim.uv.sleep(2)
  end
  return false
end

---@param text string
---@return boolean
local function set_text(text)
  local wlen = kernel32.MultiByteToWideChar(CP_UTF8, 0, text, #text, nil, 0)
  local mem = kernel32.GlobalAlloc(GMEM_MOVEABLE, (wlen + 1) * 2)
  if mem == nil then
    return false
  end
  local ptr = ffi.cast("wchar_t*", kernel32.GlobalLock(mem))
  kernel32.MultiByteToWideChar(CP_UTF8, 0, text, #text, ptr, wlen)
  ptr[wlen] = 0
  kernel32.GlobalUnlock(mem)
  if not open() then
    kernel32.GlobalFree(mem)
    return false
  end
  user32.EmptyClipboard()
  local ok = user32.SetClipboardData(CF_UNICODETEXT, mem) ~= nil
  user32.CloseClipboard()
  if not ok then
    kernel32.GlobalFree(mem)
  end
  return ok
end

---@return string?
local function get_text()
  if not open() then
    return nil
  end
  local text = ""
  local mem = user32.GetClipboardData(CF_UNICODETEXT)
  if mem ~= nil then
    local ptr = ffi.cast("const wchar_t*", kernel32.GlobalLock(mem))
    if ptr ~= nil then
      local len = kernel32.WideCharToMultiByte(CP_UTF8, 0, ptr, -1, nil, 0, nil, nil)
      if len > 1 then
        local buf = ffi.new("char[?]", len)
        kernel32.WideCharToMultiByte(CP_UTF8, 0, ptr, -1, buf, len, nil, nil)
        text = ffi.string(buf, len - 1)
      end
      kernel32.GlobalUnlock(mem)
    end
  end
  user32.CloseClipboard()
  return text
end

local function fallback()
  local yank = vim.fs.joinpath(vim.fs.dirname(vim.v.progpath), "win32yank.exe")
  yank = vim.uv.fs_stat(yank) and yank or "win32yank.exe"
  return {
    copy = { yank, "-i", "--crlf" },
    paste = { yank, "-o", "--lf" },
  }
end

---@param lines string[]
---@param regtype string
local function copy(lines, regtype)
  local text = table.concat(lines, "\r\n") .. (regtype == "V" and "\r\n" or "")
  last.text, last.regtype = text, regtype
  if not set_text(text) then
    vim.system(fallback().copy, { stdin = text })
  end
end

---@return table
local function paste()
  local text = get_text()
  if not text then
    text = vim.system(fallback().paste, { text = true }):wait().stdout or ""
  end
  local regtype = "v"
  if text == last.text then
    regtype = last.regtype
  elseif text:find("\n$") then
    regtype = "V"
  end
  text = text:gsub("\r\n", "\n")
  local lines = vim.split(text, "\n", { plain = true })
  if regtype == "V" and lines[#lines] == "" then
    lines[#lines] = nil
  end
  return { lines, regtype }
end

function M.setup()
  vim.g.clipboard = {
    name = "win32-ffi",
    copy = { ["+"] = copy, ["*"] = copy },
    paste = { ["+"] = paste, ["*"] = paste },
    cache_enabled = 0,
  }
end

return M
