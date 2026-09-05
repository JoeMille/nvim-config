-- Window helpers: telling editor windows apart from the tree and the terminal
-- panel, and closing a buffer the way an editor closes a tab.
local api = vim.api
local M = {}

M.tree_width = 34

---A real split (not a popup) showing an ordinary file buffer.
---@param win integer?
---@return boolean
function M.is_editor(win)
  win = (win == nil or win == 0) and api.nvim_get_current_win() or win
  if not api.nvim_win_is_valid(win) or api.nvim_win_get_config(win).relative ~= "" then
    return false
  end
  local buf = api.nvim_win_get_buf(win)
  return vim.bo[buf].buftype == "" and vim.bo[buf].filetype ~= "neo-tree"
end

---The file tree window in this tab, if it is open.
---@return integer?
function M.tree_win()
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    local buf = api.nvim_win_get_buf(win)
    if api.nvim_win_get_config(win).relative == "" and vim.bo[buf].filetype == "neo-tree" then
      return win
    end
  end
end

---An editor window: the current one, else the previous one, else any.
---@return integer?
function M.find_editor()
  if M.is_editor(0) then
    return api.nvim_get_current_win()
  end
  local prev = vim.fn.win_getid(vim.fn.winnr("#"))
  if prev ~= 0 and M.is_editor(prev) then
    return prev
  end
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if M.is_editor(win) then
      return win
    end
  end
end

---Keep the sidebar and the AI dock full height at the edges of the screen.
---The panel is created with `botright split`, which otherwise runs underneath
---them, and neo-tree opens to the left of whatever window is current.
function M.pin_edges()
  local tree = M.tree_win()
  if tree then
    local width = api.nvim_win_get_width(tree)
    api.nvim_win_call(tree, function()
      vim.cmd("wincmd H")
    end)
    api.nvim_win_set_width(tree, width)
  end
  local dock = require("ui.dock").win()
  if dock then
    local width = api.nvim_win_get_width(dock)
    api.nvim_win_call(dock, function()
      vim.cmd("wincmd L")
    end)
    api.nvim_win_set_width(dock, width)
  end
end

---Move to an editor window, rebuilding the editor area if it was closed.
---Anything that opens a file (pickers, the tree, "go to definition" from a
---terminal) goes through here so files never land in the tree or the panel.
---@return integer win
function M.goto_editor()
  local win = M.find_editor()
  if not win then
    local panel = require("ui.panel")
    local panel_was_open = panel.is_open()
    panel.close() -- guarantees a non-panel window exists
    win = M.find_editor()
    if not win then
      local tree = M.tree_win()
      if tree then
        api.nvim_win_call(tree, function()
          vim.cmd("rightbelow vnew")
          win = api.nvim_get_current_win()
        end)
        api.nvim_win_set_width(tree, M.tree_width)
      else
        vim.cmd("enew")
        win = api.nvim_get_current_win()
      end
    end
    if panel_was_open then
      panel.open({ focus = false })
    end
  end
  api.nvim_set_current_win(win)
  return win
end

---Buffers that show up as tabs, most recently used first.
---@return integer[]
local function listed_buffers()
  local infos = vim.fn.getbufinfo({ buflisted = 1 })
  table.sort(infos, function(a, b)
    return a.lastused > b.lastused
  end)
  return vim.tbl_map(function(info)
    return info.bufnr
  end, infos)
end

---Close a buffer like closing an editor tab: ask about unsaved changes, then
---show the most recent other tab in every window the buffer occupied. Windows
---are never closed, so the layout stays put.
---@param buf integer?
---@param opts { force: boolean? }?
function M.close_buffer(buf, opts)
  opts = opts or {}
  buf = (buf == nil or buf == 0) and api.nvim_get_current_buf() or buf
  if not api.nvim_buf_is_valid(buf) then
    return
  end

  if vim.bo[buf].modified and not opts.force then
    local name = vim.fn.fnamemodify(api.nvim_buf_get_name(buf), ":t")
    if name == "" then
      name = "Untitled"
    end
    local choice = vim.fn.confirm(("Save changes to %s?"):format(name), "&Save\n&Don't Save\n&Cancel", 1, "Question")
    if choice == 1 then
      if api.nvim_buf_get_name(buf) == "" then
        local path = vim.fn.input({ prompt = "Save as: ", completion = "file" })
        if path == "" then
          return
        end
        api.nvim_buf_call(buf, function()
          vim.cmd.write(vim.fn.fnameescape(path))
        end)
      else
        api.nvim_buf_call(buf, function()
          vim.cmd("silent write")
        end)
      end
      if vim.bo[buf].modified then
        return -- the write failed; the error is already on screen
      end
    elseif choice ~= 2 then
      return
    end
  end

  local fallback
  for _, other in ipairs(listed_buffers()) do
    if other ~= buf then
      fallback = other
      break
    end
  end
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if fallback then
      api.nvim_win_set_buf(win, fallback)
    else
      api.nvim_win_call(win, function()
        vim.cmd("enew")
      end)
    end
  end
  pcall(api.nvim_buf_delete, buf, { force = true })
end

---Close whatever the cursor is in: a panel slot, the assistant, the tree, or
---an editor tab.
function M.close_current()
  local buf = api.nvim_get_current_buf()
  if require("ui.dock").is_dock_buf(buf) then
    require("ui.dock").close() -- hides it; the trash button ends the session
  elseif require("ui.search").is_search_buf(buf) then
    require("ui.search").hide() -- keeps the search and its results for next time
  elseif require("ui.panel").is_panel_win(0) then
    require("ui.panel").kill(buf)
  elseif vim.bo[buf].filetype == "neo-tree" then
    require("neo-tree.command").execute({ action = "close" })
  elseif M.is_editor(0) then
    M.close_buffer(buf)
  else
    pcall(api.nvim_win_close, 0, false)
  end
end

return M
