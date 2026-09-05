-- Project-wide find and replace (grug-far), opened as a full-height column
-- between the file tree and the editor, where VS Code keeps its Search view.
-- fzf-lua finds matches; this is the view that writes changes back to disk.
local api = vim.api
local M = {}

local NAME = "search"

local function width()
  return math.min(84, math.max(52, math.floor(vim.o.columns * 0.32)))
end

---@return table
local function options()
  return {
    instanceName = NAME,
    staticTitle = "Search",
    windowCreationCommand = "topleft vsplit",
  }
end

---Size and place the view once grug-far has made its window.
local function fit()
  local win = api.nvim_get_current_win()
  if api.nvim_win_get_config(win).relative ~= "" then
    return
  end
  vim.wo[win].winfixwidth = true
  api.nvim_win_set_width(win, width())
  require("ui.windows").pin_edges()
end

---@return boolean
local function in_visual_mode()
  return vim.fn.mode():find("[vV\22]") ~= nil
end

---Open the search view (VS Code: Cmd+Shift+H). From visual mode the selection
---is prefilled as the search, so a fresh search replaces the old one.
function M.open()
  local grug = require("grug-far")
  if in_visual_mode() and grug.has_instance(NAME) then
    grug.kill_instance(NAME)
  end
  if grug.has_instance(NAME) then
    grug.toggle_instance(options())
  else
    grug.open(options())
  end
  if grug.is_instance_open(NAME) then
    fit()
  end
end

---Hide the view, keeping the search and its results for next time.
function M.hide()
  local grug = require("grug-far")
  if grug.has_instance(NAME) then
    grug.hide_instance(NAME)
  end
end

---@param buf integer
---@return boolean
function M.is_search_buf(buf)
  return vim.bo[buf].filetype == "grug-far"
end

return M
