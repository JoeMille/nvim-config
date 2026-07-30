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

---Kill the terminal in the current window (VS Code's trash icon).
function M.kill()
  local id = vim.b.toggle_number
  if not id then
    vim.notify("Not inside a terminal", vim.log.levels.WARN)
    return
  end
  local term = terminal().get(id, true)
  if term then
    term:shutdown()
  end
end

return M
