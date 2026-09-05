-- The explorer toolbar: the row of buttons across the top of the file tree,
-- the way VS Code puts file and search actions in the sidebar header.
--
-- Every button has a keyboard twin (Cmd+P, Cmd+Shift+F, Cmd+Shift+H); this is
-- the same thing for the mouse, and a reminder that the keys exist.
local api = vim.api
local M = {}

local icons = {
  files = "\u{ea94}", -- codicon go-to-file
  search = "\u{ea6d}", -- codicon search
  replace = "\u{eb3d}", -- codicon replace
}

---Buttons in display order. Winbar click regions carry the index in minwid.
local buttons = {
  {
    icon = icons.files,
    label = "Files",
    action = function()
      require("fzf-lua").files()
    end,
  },
  {
    icon = icons.search,
    label = "Search",
    action = function()
      require("fzf-lua").live_grep()
    end,
  },
  {
    icon = icons.replace,
    label = "Replace",
    action = function()
      require("ui.search").open()
    end,
  },
}

function _G.SidebarButtonClick(index)
  local button = buttons[index]
  if not button then
    return
  end
  -- Run from an editor window, so whatever the action opens lands there
  -- instead of in the tree.
  require("ui.edit").normal_mode()
  require("ui.windows").goto_editor()
  button.action()
end

---@return string
function M.winbar()
  local parts = { "%#SidebarBar#" }
  for i, button in ipairs(buttons) do
    parts[#parts + 1] = ("%%%d@v:lua.SidebarButtonClick@%%#SidebarBtn# %s %s %%X"):format(i, button.icon, button.label)
  end
  parts[#parts + 1] = "%#SidebarBar#%="
  return table.concat(parts)
end

---Put the toolbar on the window showing `buf`, if that is a real sidebar
---window rather than one of neo-tree's popups.
---@param buf integer
function M.attach(buf)
  local win = vim.fn.bufwinid(buf)
  if win == -1 or api.nvim_win_get_config(win).relative ~= "" then
    return
  end
  vim.wo[win].winbar = "%{%v:lua.require('ui.sidebar').winbar()%}"
end

---Fallbacks for colorschemes that do not define the Sidebar* groups.
local function fallback_highlights()
  for group, target in pairs({ SidebarBar = "NeoTreeNormal", SidebarBtn = "NeoTreeRootName" }) do
    if vim.fn.hlexists(group) == 0 then
      api.nvim_set_hl(0, group, { link = target })
    end
  end
end

local group = api.nvim_create_augroup("ui.sidebar", { clear = true })
fallback_highlights()
api.nvim_create_autocmd("ColorScheme", { group = group, callback = fallback_highlights })

return M
