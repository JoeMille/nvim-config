-- VS Code style terminal panel, built on toggleterm.
--
-- "The panel" is every terminal with direction = "horizontal". They sit at the
-- bottom of the screen and new ones split to the right of the existing ones,
-- which is what toggleterm's `rightbelow vsplit` does for a second horizontal
-- terminal. Floats and full-height verticals are left alone.
local M = {}

local function terminal()
  return require("toggleterm.terminal")
end

---Terminals that belong to the bottom panel.
---@return table[]
local function panel()
  return vim.tbl_filter(function(term)
    return term.direction == "horizontal"
  end, terminal().get_all(true))
end

---Lowest terminal id that isn't taken yet, so we always get a *new* terminal.
---@return integer
local function free_id()
  local used = {}
  for _, term in ipairs(terminal().get_all(true)) do
    used[term.id] = true
  end
  local id = 1
  while used[id] do
    id = id + 1
  end
  return id
end

---True while any terminal window is on screen.
---@return boolean
local function visible()
  return (require("toggleterm.ui").find_open_windows())
end

---Show/hide the whole panel, splits included. Creates the first terminal on demand,
---because toggleterm's own toggle_all() does nothing when no terminal exists yet.
function M.toggle()
  if #panel() == 0 then
    vim.cmd("1ToggleTerm direction=horizontal")
  else
    require("toggleterm").toggle_all()
  end
end

---Open a new terminal to the right of the current one (VS Code "split terminal").
function M.split_right()
  if not visible() then
    -- bring the panel back first so the new terminal splits it instead of
    -- replacing it with a fresh full-width one
    M.toggle()
  end
  vim.cmd(free_id() .. "ToggleTerm direction=horizontal")
end

---Focus terminal `id` without toggling it shut when it is already open.
---@param id integer
function M.focus(id)
  local term = terminal().get(id, true)
  if term and term:is_open() then
    term:focus()
  else
    vim.cmd(id .. "ToggleTerm direction=horizontal")
  end
end

---Kill a terminal (VS Code's trash icon). Defaults to the one in the current
---window; the winbar passes an explicit id, because clicking a button does not
---necessarily move the cursor into that window first.
---@param id integer?
function M.kill(id)
  id = id or vim.b.toggle_number
  if not id or id == 0 then
    vim.notify("Not inside a terminal", vim.log.levels.WARN)
    return
  end
  local term = terminal().get(id, true)
  if term then
    term:shutdown()
  end
end

-- ── Panel header ─────────────────────────────────────────────────────────────
-- toggleterm's own winbar renders labels only, so it is disabled in
-- plugins/editor.lua and the header is built here instead: the same clickable
-- terminal tabs, plus the action buttons VS Code puts at the right of its panel.
--
-- Escapes rather than literal glyphs so the codepoints are reviewable. These are
-- VS Code's own codicons, all present in JetBrainsMono Nerd Font:
--   EB56 split-horizontal, EA81 trash, EAB4 chevron-down.
local icons = {
  split = "\u{eb56}",
  kill  = "\u{ea81}",
  hide  = "\u{eab4}",
}

---Panel terminals in stable id order, so the tabs don't reshuffle on redraw.
local function ordered_panel()
  local terms = panel()
  table.sort(terms, function(a, b)
    return a.id < b.id
  end)
  return terms
end

---Short display name: the shell basename, not the full command line.
local function label(term)
  local name = term.name or ""
  name = name:gsub(";#toggleterm#%d+$", "")
  return vim.fn.fnamemodify(name, ":t")
end

-- Click targets. Winbar click regions can only reach global functions, and each
-- is called as fn(minwid, clicks, button, modifiers) — minwid is how the region
-- tells us which terminal was clicked.
function _G.ToggleTermTabClick(id)
  M.focus(id)
end

function _G.ToggleTermSplitClick()
  M.split_right()
end

function _G.ToggleTermKillClick(id)
  M.kill(id)
end

function _G.ToggleTermHideClick()
  M.toggle()
end

---Winbar string. Evaluated per window, so vim.b.toggle_number inside it is the
---terminal currently being drawn, and that id gets baked into the kill button.
---@return string
function M.winbar()
  local current = vim.b.toggle_number or 0
  local out = {}

  for _, term in ipairs(ordered_panel()) do
    local group = term.id == current and "ToggleTermTabSel" or "ToggleTermTab"
    out[#out + 1] = string.format(
      "%%%d@v:lua.ToggleTermTabClick@%%#%s# %d: %s %%X",
      term.id,
      group,
      term.id,
      label(term)
    )
  end

  out[#out + 1] = "%#ToggleTermBar#%="
  out[#out + 1] = string.format(
    "%%@v:lua.ToggleTermSplitClick@%%#ToggleTermBtn# %s %%X",
    icons.split
  )
  out[#out + 1] = string.format(
    "%%%d@v:lua.ToggleTermKillClick@%%#ToggleTermBtn# %s %%X",
    current,
    icons.kill
  )
  out[#out + 1] = string.format(
    "%%@v:lua.ToggleTermHideClick@%%#ToggleTermBtn# %s %%X",
    icons.hide
  )

  return table.concat(out)
end

---Linked rather than hard-coded so the header follows whatever colorscheme is
---active instead of pinning catppuccin's hex values in a second place.
local function apply_highlights()
  vim.api.nvim_set_hl(0, "ToggleTermBar", { link = "StatusLine" })
  vim.api.nvim_set_hl(0, "ToggleTermTab", { link = "StatusLineNC" })
  vim.api.nvim_set_hl(0, "ToggleTermTabSel", { link = "Normal" })
  vim.api.nvim_set_hl(0, "ToggleTermBtn", { link = "StatusLine" })
end

local group = vim.api.nvim_create_augroup("ToggleTermPanelHeader", { clear = true })
apply_highlights()
vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = apply_highlights })

-- Painted on entry rather than only on TermOpen: the tab list shows every panel
-- terminal, so an existing terminal's header goes stale when a new one is split
-- off beside it and has to be re-evaluated.
vim.api.nvim_create_autocmd({ "TermOpen", "BufWinEnter", "WinEnter" }, {
  group = group,
  callback = function()
    local id = vim.b.toggle_number
    if not id then
      return
    end
    local term = terminal().get(id, true)
    if term and term.direction == "horizontal" then
      vim.opt_local.winbar = "%{%v:lua.require('config.terminal').winbar()%}"
      -- Pin the buffer to this window. Opening a file into a terminal window is
      -- what scrambles the layout: the file takes the panel slot, toggleterm
      -- notices its terminal is no longer displayed and re-opens it in a fresh
      -- split up top, and the two end up swapped. winfixbuf makes nvim refuse
      -- the swap at the source instead of trying to undo it afterwards.
      vim.opt_local.winfixbuf = true
      vim.opt_local.winfixheight = true
    end
  end,
})

return M
