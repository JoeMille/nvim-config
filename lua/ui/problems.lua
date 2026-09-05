-- The Problems view: every diagnostic the language servers have reported,
-- grouped by file, shown as a slot in the bottom panel (VS Code: Cmd+Shift+M).
-- Click or press Enter on a line to jump to it.
local api = vim.api
local severity = vim.diagnostic.severity
local M = {}

local ns = api.nvim_create_namespace("ui.problems")

local icons = {
  [severity.ERROR] = "\u{ea87}", -- codicon error
  [severity.WARN] = "\u{ea6c}", -- codicon warning
  [severity.INFO] = "\u{ea74}", -- codicon info
  [severity.HINT] = "\u{ea61}", -- codicon lightbulb
}

local hl_of = {
  [severity.ERROR] = "DiagnosticError",
  [severity.WARN] = "DiagnosticWarn",
  [severity.INFO] = "DiagnosticInfo",
  [severity.HINT] = "DiagnosticHint",
}

---The buffer, plus what each of its lines points at.
---@type { buf: integer?, rows: table<integer, { bufnr: integer, lnum: integer, col: integer }> }
local state = { buf = nil, rows = {} }

---@param bufnr integer
---@return string
local function display_name(bufnr)
  local name = api.nvim_buf_is_valid(bufnr) and api.nvim_buf_get_name(bufnr) or ""
  if name == "" then
    return "[No Name]"
  end
  return vim.fn.fnamemodify(name, ":.")
end

---Every diagnostic, grouped into files sorted by name.
---@return { bufnr: integer, name: string, items: vim.Diagnostic[] }[]
local function grouped()
  local by_buf = {}
  for _, d in ipairs(vim.diagnostic.get()) do
    if api.nvim_buf_is_valid(d.bufnr) then
      by_buf[d.bufnr] = by_buf[d.bufnr] or {}
      table.insert(by_buf[d.bufnr], d)
    end
  end
  local files = {}
  for bufnr, items in pairs(by_buf) do
    table.sort(items, function(a, b)
      if a.lnum ~= b.lnum then
        return a.lnum < b.lnum
      end
      return a.col < b.col
    end)
    files[#files + 1] = { bufnr = bufnr, name = display_name(bufnr), items = items }
  end
  table.sort(files, function(a, b)
    return a.name < b.name
  end)
  return files
end

---The panel header for this slot.
---@return string
function M.title()
  local counts = vim.diagnostic.count(nil)
  local errors, warnings = counts[severity.ERROR] or 0, counts[severity.WARN] or 0
  return ("Problems  %%#SLError#%s %d%%* %%#SLWarn#%s %d%%*"):format(
    icons[severity.ERROR],
    errors,
    icons[severity.WARN],
    warnings
  )
end

---@param buf integer
local function render(buf)
  local lines, marks, rows = {}, {}, {}

  ---@param text string
  ---@param hls { [1]: integer, [2]: integer, [3]: string }[] col, end_col, group
  local function add(text, hls)
    lines[#lines + 1] = text
    for _, h in ipairs(hls or {}) do
      marks[#marks + 1] = { #lines - 1, h[1], h[2], h[3] }
    end
    return #lines
  end

  local files = grouped()
  if #files == 0 then
    add("", {})
    add("   No problems have been detected in the workspace.", { { 0, -1, "Comment" } })
  end

  for i, file in ipairs(files) do
    if i > 1 then
      add("", {})
    end
    local head = ("  %s  %d"):format(file.name, #file.items)
    local lnum = add(head, {
      { 2, 2 + #file.name, "ProblemsFile" },
      { 2 + #file.name, -1, "ProblemsCount" },
    })
    local first = file.items[1]
    rows[lnum] = { bufnr = file.bufnr, lnum = first.lnum, col = first.col }

    for _, d in ipairs(file.items) do
      local icon = icons[d.severity] or icons[severity.INFO]
      local pos = ("%d:%d"):format(d.lnum + 1, d.col + 1)
      local message = vim.split(d.message, "\n", { plain = true })[1]
      local source = d.source and (" " .. d.source) or ""
      local text = ("    %s  %s  %s%s"):format(icon, pos, message, source)
      local icon_end = 4 + #icon
      local pos_end = icon_end + 2 + #pos
      lnum = add(text, {
        { 4, icon_end, hl_of[d.severity] or "DiagnosticInfo" },
        { icon_end + 2, pos_end, "ProblemsPos" },
        { pos_end + 2 + #message, -1, "ProblemsSource" },
      })
      rows[lnum] = { bufnr = d.bufnr, lnum = d.lnum, col = d.col }
    end
  end

  state.rows = rows
  vim.bo[buf].modifiable = true
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, m in ipairs(marks) do
    local line, col, end_col, group = m[1], m[2], m[3], m[4]
    pcall(api.nvim_buf_set_extmark, buf, ns, line, col, {
      end_col = end_col == -1 and #lines[line + 1] or math.min(end_col, #lines[line + 1]),
      hl_group = group,
    })
  end
end

---Open the problem on the cursor line in an editor window.
local function jump()
  local row = state.rows[api.nvim_win_get_cursor(0)[1]]
  if not row or not api.nvim_buf_is_valid(row.bufnr) then
    return
  end
  local win = require("ui.windows").goto_editor()
  if api.nvim_win_get_buf(win) ~= row.bufnr then
    api.nvim_win_set_buf(win, row.bufnr)
  end
  pcall(api.nvim_win_set_cursor, win, { row.lnum + 1, row.col })
  vim.cmd("normal! zz")
end

---The Problems buffer, created on first use.
---@return integer buf
function M.create()
  if state.buf and api.nvim_buf_is_valid(state.buf) then
    render(state.buf)
    return state.buf
  end

  local buf = api.nvim_create_buf(false, true)
  state.buf = buf
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].swapfile = false
  vim.bo[buf].buflisted = false
  vim.bo[buf].filetype = "problems"
  api.nvim_buf_set_name(buf, "Problems")

  local function map(lhs, rhs)
    vim.keymap.set("n", lhs, rhs, { buffer = buf, nowait = true })
  end
  map("<CR>", jump)
  map("<2-LeftMouse>", jump)
  map("<LeftRelease>", jump) -- single click, like the file tree
  map("<Esc>", function()
    require("ui.windows").goto_editor()
  end)
  map("q", function()
    require("ui.panel").kill(buf)
  end)

  render(buf)
  return buf
end

-- ── highlights and autocmds ──────────────────────────────────────────────────

---Fallbacks for colorschemes that do not define the Problems* groups.
local function fallback_highlights()
  local links =
    { ProblemsFile = "Directory", ProblemsCount = "Comment", ProblemsPos = "Comment", ProblemsSource = "Comment" }
  for group, target in pairs(links) do
    if vim.fn.hlexists(group) == 0 then
      api.nvim_set_hl(0, group, { link = target })
    end
  end
end

local group = api.nvim_create_augroup("ui.problems", { clear = true })
fallback_highlights()
api.nvim_create_autocmd("ColorScheme", { group = group, callback = fallback_highlights })

api.nvim_create_autocmd("DiagnosticChanged", {
  group = group,
  callback = function()
    if state.buf and api.nvim_buf_is_valid(state.buf) then
      vim.schedule(function()
        if state.buf and api.nvim_buf_is_valid(state.buf) then
          render(state.buf)
        end
      end)
    end
  end,
})

return M
