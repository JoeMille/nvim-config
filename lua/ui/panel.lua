-- The bottom panel: a row of slots along the bottom of the editor area, built
-- on nvim's own :terminal. No plugin.
--
-- A slot is either a shell or a view (Problems). Every slot is a split in that
-- row. "Split" adds a shell to the right of the current one, the trash button
-- closes a slot, the chevron hides the whole panel (shells keep running). Each
-- slot has a header with its name and the buttons, like the panel in VS Code.
local api = vim.api
local M = {}

---@class PanelSlot
---@field buf integer
---@field kind "shell"|"view"
---@field view string? for kind == "view": the key in `views`

---@type PanelSlot[] display order, left to right
local slots = {}
local remembered_height ---@type integer?
local last_shell ---@type integer?

---Views the panel can host. A view module provides `create()`, which returns a
---buffer, and `title(buf)`, the text for its header.
local views = { problems = "ui.problems" }

local icons = {
  terminal = "\u{ea85}", -- codicon terminal
  split = "\u{eb56}", -- codicon split-horizontal
  kill = "\u{ea81}", -- codicon trash
  hide = "\u{eab4}", -- codicon chevron-down
}

-- ── bookkeeping ──────────────────────────────────────────────────────────────

local function prune()
  slots = vim.tbl_filter(function(s)
    return api.nvim_buf_is_valid(s.buf)
  end, slots)
end

---@param buf integer
---@return PanelSlot?, integer? index
local function slot_of(buf)
  for i, s in ipairs(slots) do
    if s.buf == buf then
      return s, i
    end
  end
end

---@param name string
---@return PanelSlot?
local function slot_of_view(name)
  for _, s in ipairs(slots) do
    if s.view == name then
      return s
    end
  end
end

---Shells are numbered in their own sequence, so a Problems slot does not shift
---"Terminal 1" along.
---@param buf integer
---@return integer
local function shell_number(buf)
  local n = 0
  for _, s in ipairs(slots) do
    if s.kind == "shell" then
      n = n + 1
      if s.buf == buf then
        return n
      end
    end
  end
  return n
end

---Any slot: a shell or a view.
---@param win integer?
---@return boolean
function M.is_panel_win(win)
  win = (win == nil or win == 0) and api.nvim_get_current_win() or win
  return api.nvim_win_is_valid(win) and slot_of(api.nvim_win_get_buf(win)) ~= nil
end

---@param win integer?
---@return boolean
function M.is_shell_win(win)
  win = (win == nil or win == 0) and api.nvim_get_current_win() or win
  if not api.nvim_win_is_valid(win) then
    return false
  end
  local slot = slot_of(api.nvim_win_get_buf(win))
  return slot ~= nil and slot.kind == "shell"
end

---Panel windows in this tab, left to right.
---@return integer[]
function M.wins()
  prune()
  local out = {}
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if api.nvim_win_get_config(win).relative == "" and slot_of(api.nvim_win_get_buf(win)) then
      out[#out + 1] = win
    end
  end
  table.sort(out, function(a, b)
    return api.nvim_win_get_position(a)[2] < api.nvim_win_get_position(b)[2]
  end)
  return out
end

function M.is_open()
  return #M.wins() > 0
end

---@return integer?
function M.any_win()
  return M.wins()[1]
end

---@param buf integer
---@return integer?
local function win_of(buf)
  for _, win in ipairs(M.wins()) do
    if api.nvim_win_get_buf(win) == buf then
      return win
    end
  end
end

local function default_height()
  return math.max(8, math.floor(vim.o.lines * 0.3))
end

-- ── windows ──────────────────────────────────────────────────────────────────

---Make a window look like a panel slot and pin its buffer to it, so a file
---opened while the cursor is in the panel cannot take its place.
---@param win integer
local function style(win)
  local wo = vim.wo[win]
  wo.number = false
  wo.relativenumber = false
  wo.signcolumn = "no"
  wo.foldcolumn = "0"
  wo.statuscolumn = ""
  wo.cursorline = false
  wo.list = false
  wo.spell = false
  wo.wrap = false
  wo.scrolloff = 0
  wo.sidescrolloff = 0
  wo.winfixheight = true
  wo.winfixwidth = false
  wo.winhighlight = "Normal:PanelNormal,NormalNC:PanelNormal,WinBar:PanelBarActive,WinBarNC:PanelBar"
  wo.winbar = "%{%v:lua.require('ui.panel').winbar()%}"
  wo.winfixbuf = true
end

---Start a shell in `buf`, which must be displayed in `win`.
---@param buf integer
---@param win integer
local function start_shell(buf, win)
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].buflisted = false
  api.nvim_win_call(win, function()
    vim.fn.jobstart({ vim.o.shell }, { term = true })
  end)
end

---Give every slot in the row the same width.
local function equalize()
  local wins = M.wins()
  if #wins < 2 then
    return
  end
  local total = 0
  for _, win in ipairs(wins) do
    total = total + api.nvim_win_get_width(win)
  end
  local each = math.floor(total / #wins)
  for i = 1, #wins - 1 do
    api.nvim_win_set_width(wins[i], each)
  end
end
M.equalize = equalize

---Close panel windows without ever closing the last window of the tab.
---@param wins integer[]
local function close_wins(wins)
  if #wins == 0 then
    return
  end
  -- Remember a dragged height, but not the full-screen height the panel gets
  -- when the last editor window was closed out from above it.
  if require("ui.windows").find_editor() then
    remembered_height = math.min(api.nvim_win_get_height(wins[1]), math.floor(vim.o.lines * 0.6))
  end
  local real = vim.tbl_filter(function(win)
    return api.nvim_win_get_config(win).relative == ""
  end, api.nvim_tabpage_list_wins(0))
  if #real <= #wins then
    vim.cmd("topleft new")
  end
  for _, win in ipairs(wins) do
    pcall(api.nvim_win_close, win, true)
  end
end

-- ── public API ───────────────────────────────────────────────────────────────

---Focus a slot (default: the last shell used), opening the panel if needed.
---@param buf integer?
function M.focus(buf)
  prune()
  if #slots == 0 then
    M.open()
    return
  end
  if not (buf and slot_of(buf)) then
    buf = (last_shell and slot_of(last_shell)) and last_shell or slots[1].buf
  end
  if not M.is_open() then
    M.open({ focus = false })
  end
  local win = win_of(buf)
  if win then
    api.nvim_set_current_win(win)
    if M.is_shell_win(win) then
      last_shell = buf
      vim.cmd("startinsert")
    end
  end
end

---Show the panel. Creates the first shell on demand.
---@param opts { focus: boolean? }?
function M.open(opts)
  opts = opts or {}
  prune()
  if M.is_open() then
    if opts.focus ~= false then
      M.focus()
    end
    return
  end

  local prev = api.nvim_get_current_win()
  vim.cmd("botright " .. (remembered_height or default_height()) .. "split")
  local first = api.nvim_get_current_win()
  vim.wo[first].winfixbuf = false

  if #slots == 0 then
    local buf = api.nvim_create_buf(false, false)
    api.nvim_win_set_buf(first, buf)
    start_shell(buf, first)
    slots[1] = { buf = buf, kind = "shell" }
    style(first)
  else
    api.nvim_win_set_buf(first, slots[1].buf)
    style(first)
    local anchor = first
    for i = 2, #slots do
      anchor = api.nvim_open_win(slots[i].buf, false, { split = "right", win = anchor })
      style(anchor)
    end
  end

  require("ui.windows").pin_edges()
  equalize()

  if opts.focus == false then
    if api.nvim_win_is_valid(prev) then
      api.nvim_set_current_win(prev)
    end
  else
    M.focus()
  end
end

---Hide the panel. Shells keep running.
function M.close()
  local wins = M.wins()
  if #wins == 0 then
    return
  end
  local cur = api.nvim_get_current_win()
  local was_inside = M.is_panel_win(cur)
  if was_inside and M.is_shell_win(cur) then
    last_shell = api.nvim_win_get_buf(cur)
  end
  close_wins(wins)
  if was_inside then
    local editor = require("ui.windows").find_editor()
    if editor then
      api.nvim_set_current_win(editor)
    end
  end
end

---Show/hide the panel (VS Code: Cmd+J).
function M.toggle()
  if M.is_open() then
    M.close()
  else
    M.open()
  end
end

---VS Code's Ctrl+`: hide the panel when a slot has focus, otherwise focus one.
function M.toggle_focus()
  if M.is_open() and M.is_panel_win(0) then
    M.close()
  else
    M.focus()
  end
end

---Add a shell to the right of the current one (VS Code: split terminal).
---@param opts { after: integer? }? buffer to split next to; defaults to the current slot
function M.new(opts)
  opts = opts or {}
  prune()
  if #slots == 0 then
    M.open()
    return
  end
  if not M.is_open() then
    M.open({ focus = false })
  end

  local wins = M.wins()
  local anchor = wins[#wins]
  if opts.after and win_of(opts.after) then
    anchor = win_of(opts.after)
  elseif M.is_shell_win(0) then
    anchor = api.nvim_get_current_win()
  end

  local buf = api.nvim_create_buf(false, false)
  local win = api.nvim_open_win(buf, true, { split = "right", win = anchor })
  start_shell(buf, win)
  local _, at = slot_of(api.nvim_win_get_buf(anchor))
  table.insert(slots, (at or #slots) + 1, { buf = buf, kind = "shell" })
  style(win)
  equalize()
  last_shell = buf
  vim.cmd("startinsert")
end

---Show a view (Problems) as a slot at the left end of the row.
---@param name string key in `views`
function M.show_view(name)
  prune()
  local slot = slot_of_view(name)
  if not slot then
    local ok, view = pcall(require, views[name] or "")
    if not ok then
      vim.notify("No such panel view: " .. name, vim.log.levels.ERROR)
      return
    end
    slot = { buf = view.create(), kind = "view", view = name }
    table.insert(slots, 1, slot)
  end

  if not M.is_open() then
    M.open({ focus = false })
  end
  local win = win_of(slot.buf)
  if not win then
    win = api.nvim_open_win(slot.buf, false, { split = "left", win = M.wins()[1] })
    style(win)
    equalize()
  end
  api.nvim_set_current_win(win)
end

---Open a view, or close it when it already has focus (VS Code: Cmd+Shift+M).
---@param name string
function M.toggle_view(name)
  local slot = slot_of_view(name)
  if slot and win_of(slot.buf) and api.nvim_get_current_win() == win_of(slot.buf) then
    M.kill(slot.buf)
    return
  end
  M.show_view(name)
end

---@param name string
---@return boolean
function M.view_is_open(name)
  local slot = slot_of_view(name)
  return slot ~= nil and win_of(slot.buf) ~= nil
end

---Close a slot: kill the shell, or drop the view (VS Code: the trash button).
---@param buf integer? defaults to the current buffer
function M.kill(buf)
  buf = (buf == nil or buf == 0) and api.nvim_get_current_buf() or buf
  local slot, i = slot_of(buf)
  if not slot then
    return
  end
  local was_current = api.nvim_get_current_buf() == buf
  table.remove(slots, i)

  -- Stop the shell first: once its window closes, nvim wipes a finished
  -- terminal buffer on its own, and the buffer id is no longer valid.
  if slot.kind == "shell" then
    local job = api.nvim_buf_is_valid(buf) and vim.bo[buf].channel or 0
    if job and job > 0 then
      pcall(vim.fn.jobstop, job)
    end
  end

  local wins = vim.tbl_filter(function(win)
    return api.nvim_win_get_config(win).relative == ""
  end, vim.fn.win_findbuf(buf))
  close_wins(wins)

  if api.nvim_buf_is_valid(buf) then
    pcall(api.nvim_buf_delete, buf, { force = true })
  end
  if last_shell == buf then
    last_shell = nil
  end
  equalize()

  if was_current then
    if #slots > 0 and M.is_open() then
      M.focus(slots[math.min(i, #slots)].buf)
    else
      local editor = require("ui.windows").find_editor()
      if editor then
        api.nvim_set_current_win(editor)
      end
    end
  end
end

-- ── header ───────────────────────────────────────────────────────────────────
-- Click regions in a winbar can only call global functions, as
-- fn(minwid, clicks, button, modifiers); minwid carries the buffer number.

function _G.PanelSplitClick(buf)
  M.new({ after = buf })
end

function _G.PanelKillClick(buf)
  M.kill(buf)
end

function _G.PanelHideClick()
  M.close()
end

---What the shell is doing, in a few characters.
---@param buf integer
---@return string
local function shell_label(buf)
  local shell = vim.fn.fnamemodify(vim.o.shell, ":t")
  local title = vim.b[buf].term_title or ""
  -- Until the shell sets a title, nvim uses the term://... buffer name.
  if title == "" or title:find("^term://") then
    return shell
  end
  if title:find("/") then
    -- a path (the shell's cwd): keep its last component
    title = vim.fn.fnamemodify(title:gsub("/+$", ""), ":t")
  end
  if #title > 28 then
    title = title:sub(1, 27) .. "…"
  end
  return title
end

---Evaluated per window, with that window current.
---@return string
function M.winbar()
  local buf = api.nvim_get_current_buf()
  local slot = slot_of(buf)
  if not slot then
    return ""
  end

  local parts = {}
  if slot.kind == "shell" then
    parts[1] = (" %s %d: %s"):format(icons.terminal, shell_number(buf), shell_label(buf))
  else
    parts[1] = " " .. require(views[slot.view]).title(buf)
  end
  parts[#parts + 1] = "%="
  if slot.kind == "shell" then
    parts[#parts + 1] = ("%%%d@v:lua.PanelSplitClick@%%#PanelBtn# %s %%X"):format(buf, icons.split)
  end
  parts[#parts + 1] = ("%%%d@v:lua.PanelKillClick@%%#PanelBtn# %s %%X"):format(buf, icons.kill)
  parts[#parts + 1] = ("%%@v:lua.PanelHideClick@%%#PanelBtn# %s %%X"):format(icons.hide)
  parts[#parts + 1] = "%* "
  return table.concat(parts)
end

-- ── highlights and autocmds ──────────────────────────────────────────────────

---Fallbacks for colorschemes that do not define the Panel* groups (theme.lua does).
local function fallback_highlights()
  local links = {
    PanelNormal = "Normal",
    PanelBarActive = "WinBar",
    PanelBar = "WinBarNC",
    PanelBtn = "WinBarNC",
    PanelTabActive = "WinBar",
    PanelTab = "WinBarNC",
  }
  for group, target in pairs(links) do
    if vim.fn.hlexists(group) == 0 then
      api.nvim_set_hl(0, group, { link = target })
    end
  end
end

local group = api.nvim_create_augroup("ui.panel", { clear = true })
fallback_highlights()
api.nvim_create_autocmd("ColorScheme", { group = group, callback = fallback_highlights })

-- A shell that exits (Ctrl+D, `exit`) takes its slot with it.
api.nvim_create_autocmd("TermClose", {
  group = group,
  callback = function(ev)
    local slot = slot_of(ev.buf)
    if slot and slot.kind == "shell" then
      vim.schedule(function()
        M.kill(ev.buf)
      end)
    end
  end,
})

-- Landing in a shell means typing into it, like clicking a terminal in VS Code.
-- Deferred so a window switch that merely passes through the panel (the
-- startup layout, `goto_editor`) does not leave the editor in insert mode.
api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
  group = group,
  callback = function()
    if not M.is_shell_win(0) then
      return
    end
    local win = api.nvim_get_current_win()
    vim.schedule(function()
      if api.nvim_get_current_win() == win and M.is_shell_win(win) and api.nvim_get_mode().mode == "n" then
        vim.cmd("startinsert")
      end
    end)
  end,
})

api.nvim_create_autocmd("VimResized", {
  group = group,
  callback = function()
    vim.schedule(equalize)
  end,
})

return M
