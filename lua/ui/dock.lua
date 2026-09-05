-- The AI dock: a full-height panel down the right-hand side running an AI CLI
-- in a terminal, like VS Code's chat sidebar. Claude and Codex each get their
-- own session; the header switches between them and both keep running while
-- the dock is hidden.
--
-- Selections are handed over as a bracketed paste, so the CLI receives them as
-- pasted text and nothing is submitted until you press Enter yourself.
local api = vim.api
local uv = vim.uv
local M = {}

---@class DockProvider
---@field id string
---@field label string
---@field cmd string[]

---@type DockProvider[] display order in the header
local providers = {
  { id = "claude", label = "Claude", cmd = { "claude" } },
  { id = "codex", label = "Codex", cmd = { "codex" } },
}

local sessions = {} ---@type table<string, integer> provider id -> terminal buffer
local started = {} ---@type table<string, integer> provider id -> uv.now() at launch
local current = providers[1].id
local remembered_width ---@type integer?

local icons = {
  kill = "\u{ea81}", -- codicon trash
  hide = "\u{eab6}", -- codicon chevron-right
}

-- ── bookkeeping ──────────────────────────────────────────────────────────────

---@param id string?
---@return DockProvider?
local function provider(id)
  for _, p in ipairs(providers) do
    if p.id == id then
      return p
    end
  end
end

---@param buf integer
---@return string? id
local function id_of(buf)
  for id, b in pairs(sessions) do
    if b == buf then
      return id
    end
  end
end

---@param buf integer
---@return boolean
function M.is_dock_buf(buf)
  return id_of(buf) ~= nil
end

---The dock window in this tab, if it is open.
---@return integer?
function M.win()
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if api.nvim_win_get_config(win).relative == "" and id_of(api.nvim_win_get_buf(win)) then
      return win
    end
  end
end

function M.is_open()
  return M.win() ~= nil
end

local function default_width()
  return math.min(96, math.max(48, math.floor(vim.o.columns * 0.32)))
end

-- ── windows ──────────────────────────────────────────────────────────────────

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
  wo.winfixwidth = true
  wo.winfixheight = false
  wo.winhighlight = "Normal:PanelNormal,NormalNC:PanelNormal,WinBar:PanelBarActive,WinBarNC:PanelBar"
  wo.winbar = "%{%v:lua.require('ui.dock').winbar()%}"
end

---Show provider `id` in `win`, starting its session the first time.
---@param id string
---@param win integer
---@return boolean started
local function show(id, win)
  local p = provider(id)
  if not p then
    return false
  end
  local buf = sessions[id]
  vim.wo[win].winfixbuf = false

  if buf and api.nvim_buf_is_valid(buf) then
    api.nvim_win_set_buf(win, buf)
  else
    if vim.fn.executable(p.cmd[1]) ~= 1 then
      vim.notify(("%s is not installed: `%s` is not on PATH."):format(p.label, p.cmd[1]), vim.log.levels.WARN)
      return false
    end
    buf = api.nvim_create_buf(false, false)
    api.nvim_win_set_buf(win, buf)
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].buflisted = false
    vim.b[buf].dock_provider = p.label
    api.nvim_win_call(win, function()
      vim.fn.jobstart(p.cmd, { term = true })
    end)
    sessions[id] = buf
    started[id] = uv.now()
  end

  current = id
  vim.wo[win].winfixbuf = true
  return true
end

-- ── public API ───────────────────────────────────────────────────────────────

---Show the dock.
---@param opts { provider: string?, focus: boolean? }?
function M.open(opts)
  opts = opts or {}
  local id = opts.provider or current
  local win = M.win()

  if win then
    if id ~= id_of(api.nvim_win_get_buf(win)) then
      show(id, win)
    end
    if opts.focus ~= false then
      api.nvim_set_current_win(win)
      vim.cmd("startinsert")
    end
    return
  end

  local prev = api.nvim_get_current_win()
  vim.cmd("botright vsplit")
  win = api.nvim_get_current_win()
  if not show(id, win) then
    pcall(api.nvim_win_close, win, true)
    if api.nvim_win_is_valid(prev) then
      api.nvim_set_current_win(prev)
    end
    return
  end
  style(win)
  api.nvim_win_set_width(win, remembered_width or default_width())
  require("ui.windows").pin_edges()

  if opts.focus == false then
    if api.nvim_win_is_valid(prev) then
      api.nvim_set_current_win(prev)
    end
  else
    api.nvim_set_current_win(win)
    vim.cmd("startinsert")
  end
end

---Hide the dock. The sessions keep running.
function M.close()
  local win = M.win()
  if not win then
    return
  end
  local was_inside = api.nvim_get_current_win() == win
  remembered_width = math.min(api.nvim_win_get_width(win), math.floor(vim.o.columns * 0.6))

  local real = vim.tbl_filter(function(w)
    return api.nvim_win_get_config(w).relative == ""
  end, api.nvim_tabpage_list_wins(0))
  if #real <= 1 then
    vim.cmd("topleft new")
  end
  pcall(api.nvim_win_close, win, true)

  if was_inside then
    local editor = require("ui.windows").find_editor()
    if editor then
      api.nvim_set_current_win(editor)
    end
  end
end

function M.toggle()
  if M.is_open() then
    M.close()
  else
    M.open()
  end
end

---Cmd+I: hide the dock when it has focus, otherwise show and focus it.
function M.toggle_focus()
  local win = M.win()
  if win and api.nvim_get_current_win() == win then
    M.close()
  else
    M.open({ focus = true })
  end
end

---Switch the dock to another provider, starting it if needed.
---@param id string
function M.switch(id)
  M.open({ provider = id, focus = true })
end

---Pick a provider (used by the header tabs and <leader>A).
function M.pick()
  local labels = vim.tbl_map(function(p)
    return p.label
  end, providers)
  vim.ui.select(labels, { prompt = "AI assistant" }, function(_, index)
    if index then
      M.switch(providers[index].id)
    end
  end)
end

---End a session. The dock closes when nothing is left running.
---@param id string?
function M.kill(id)
  id = id or current
  local buf = sessions[id]
  sessions[id] = nil
  started[id] = nil
  if buf and api.nvim_buf_is_valid(buf) then
    local job = vim.bo[buf].channel
    if job and job > 0 then
      pcall(vim.fn.jobstop, job)
    end
  end

  local other
  for _, p in ipairs(providers) do
    if sessions[p.id] and api.nvim_buf_is_valid(sessions[p.id]) then
      other = p.id
      break
    end
  end
  local win = M.win()
  if win and other then
    show(other, win)
  elseif win then
    M.close()
  end
  if buf and api.nvim_buf_is_valid(buf) then
    pcall(api.nvim_buf_delete, buf, { force = true })
  end
end

---Restart the current session in place.
---@param id string?
function M.restart(id)
  id = id or current
  M.kill(id)
  M.open({ provider = id, focus = true })
end

---Type `text` into the assistant as a paste, without submitting it. The prompt
---is left with the cursor after the text so a question can be typed onto it.
---@param text string
---@param opts { provider: string?, submit: boolean? }?
function M.send(text, opts)
  opts = opts or {}
  local id = opts.provider or current
  M.open({ provider = id, focus = true })
  local buf = sessions[id]
  if not buf or not api.nvim_buf_is_valid(buf) then
    return
  end

  local function paste()
    if not api.nvim_buf_is_valid(buf) then
      return
    end
    local chan = vim.bo[buf].channel
    if not chan or chan <= 0 then
      return
    end
    -- Bracketed paste: the CLI takes multi-line text as one block instead of
    -- submitting on every newline.
    vim.fn.chansend(chan, "\27[200~" .. text .. "\27[201~")
    if opts.submit then
      vim.fn.chansend(chan, "\r")
    end
  end

  -- A CLI that has only just launched is still drawing its prompt.
  local age = uv.now() - (started[id] or 0)
  if age < 1500 then
    vim.defer_fn(paste, 1500 - age)
  else
    paste()
  end
end

---@param buf integer
---@return string
local function file_ref(buf)
  local name = api.nvim_buf_get_name(buf)
  return name ~= "" and vim.fn.fnamemodify(name, ":.") or "[No Name]"
end

---Hand the visual selection over, as a fenced block with its file and lines.
function M.send_selection()
  local buf = api.nvim_get_current_buf()
  local anchor = vim.fn.getpos("v")[2]
  local cursor = api.nvim_win_get_cursor(0)[1]
  local first, last = math.min(anchor, cursor), math.max(anchor, cursor)
  api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)

  local lines = api.nvim_buf_get_lines(buf, first - 1, last, false)
  local text = ("%s:%d-%d\n```%s\n%s\n```\n"):format(
    file_ref(buf),
    first,
    last,
    vim.bo[buf].filetype,
    table.concat(lines, "\n")
  )
  M.send(text)
end

---Mention the current file, the way you would type `@path` yourself.
function M.send_file()
  M.send("@" .. file_ref(api.nvim_get_current_buf()) .. " ")
end

---Hand over the line under the cursor and any problems reported on it.
function M.ask_about_cursor()
  local buf = api.nvim_get_current_buf()
  local lnum = api.nvim_win_get_cursor(0)[1]
  local parts = { ("%s:%d"):format(file_ref(buf), lnum) }
  for _, d in ipairs(vim.diagnostic.get(buf, { lnum = lnum - 1 })) do
    local name = vim.diagnostic.severity[d.severity]
    parts[#parts + 1] = ("%s: %s%s"):format(name, d.message, d.source and (" (" .. d.source .. ")") or "")
  end
  local line = api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1] or ""
  parts[#parts + 1] = ("```%s\n%s\n```"):format(vim.bo[buf].filetype, line)
  M.send(table.concat(parts, "\n") .. "\n")
end

-- ── header ───────────────────────────────────────────────────────────────────

function _G.DockTabClick(index)
  local p = providers[index]
  if p then
    M.switch(p.id)
  end
end

function _G.DockKillClick()
  M.kill(current)
end

function _G.DockHideClick()
  M.close()
end

---@return string
function M.winbar()
  local parts = { " " }
  for i, p in ipairs(providers) do
    local live = sessions[p.id] and api.nvim_buf_is_valid(sessions[p.id])
    parts[#parts + 1] = ("%%%d@v:lua.DockTabClick@%%#%s# %s%s %%X"):format(
      i,
      p.id == current and "PanelTabActive" or "PanelTab",
      p.label,
      live and " ●" or ""
    )
  end
  parts[#parts + 1] = "%*%="
  parts[#parts + 1] = ("%%@v:lua.DockKillClick@%%#PanelBtn# %s %%X"):format(icons.kill)
  parts[#parts + 1] = ("%%@v:lua.DockHideClick@%%#PanelBtn# %s %%X"):format(icons.hide)
  parts[#parts + 1] = "%* "
  return table.concat(parts)
end

-- ── autocmds ─────────────────────────────────────────────────────────────────

local group = api.nvim_create_augroup("ui.dock", { clear = true })

-- A session that exits (/exit, Ctrl+C twice) closes its tab.
api.nvim_create_autocmd("TermClose", {
  group = group,
  callback = function(ev)
    local id = id_of(ev.buf)
    if id then
      vim.schedule(function()
        M.kill(id)
      end)
    end
  end,
})

-- Landing in the dock means typing to the assistant.
api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
  group = group,
  callback = function()
    local win = api.nvim_get_current_win()
    if win ~= M.win() then
      return
    end
    vim.schedule(function()
      if api.nvim_get_current_win() == win and win == M.win() and api.nvim_get_mode().mode == "n" then
        vim.cmd("startinsert")
      end
    end)
  end,
})

---The assistants the dock offers. Add to this list to run another CLI.
M.providers = providers

return M
