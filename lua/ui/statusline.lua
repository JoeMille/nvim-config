-- One global statusline, laid out like VS Code's status bar:
--   mode · branch · errors/warnings · file            Ln, Col · Spaces · encoding · language
local api = vim.api
local M = {}

local modes = {
  n = { "NORMAL", "SLNormal" },
  no = { "PENDING", "SLNormal" },
  i = { "INSERT", "SLInsert" },
  v = { "VISUAL", "SLVisual" },
  V = { "V-LINE", "SLVisual" },
  ["\22"] = { "V-BLOCK", "SLVisual" },
  s = { "SELECT", "SLVisual" },
  S = { "S-LINE", "SLVisual" },
  ["\19"] = { "S-BLOCK", "SLVisual" },
  R = { "REPLACE", "SLReplace" },
  c = { "COMMAND", "SLCommand" },
  r = { "PROMPT", "SLCommand" },
  ["!"] = { "SHELL", "SLCommand" },
  t = { "TERMINAL", "SLTerminal" },
}

local function mode_segment()
  local m = api.nvim_get_mode().mode
  local info = modes[m] or modes[m:sub(1, 2)] or modes[m:sub(1, 1)] or { m:upper(), "SLNormal" }
  return ("%%#%s# %s %%*"):format(info[2], info[1])
end

local function branch_segment()
  local head = vim.b.gitsigns_head or vim.g.gitsigns_head
  if not head or head == "" then
    return ""
  end
  return " \u{ea68} " .. head .. " "
end

local function diagnostics_segment()
  local counts = vim.diagnostic.count(nil)
  local errors = counts[vim.diagnostic.severity.ERROR] or 0
  local warnings = counts[vim.diagnostic.severity.WARN] or 0
  return ("%%#SLError# \u{ea87} %d %%#SLWarn# \u{ea6c} %d %%*"):format(errors, warnings)
end

local function file_segment()
  local buf = api.nvim_get_current_buf()
  if vim.b[buf].dock_provider then
    return " \u{ea85} " .. vim.b[buf].dock_provider
  end
  if vim.bo[buf].buftype == "terminal" then
    return " \u{ea85} Terminal"
  end
  if vim.bo[buf].filetype == "neo-tree" then
    return " \u{ea83} Explorer"
  end
  if vim.bo[buf].filetype == "problems" then
    return " \u{ea6c} Problems"
  end
  local name = api.nvim_buf_get_name(buf)
  name = name == "" and "Untitled" or vim.fn.fnamemodify(name, ":~:.")
  local flags = (vim.bo[buf].modified and " ●" or "") .. (vim.bo[buf].readonly and " \u{ea75}" or "")
  return " " .. name .. flags
end

local function right_segments()
  local buf = api.nvim_get_current_buf()
  if vim.bo[buf].buftype ~= "" then
    return ""
  end
  local parts = {}
  local clients = vim.tbl_map(function(c)
    return c.name
  end, vim.lsp.get_clients({ bufnr = buf }))
  if #clients > 0 then
    parts[#parts + 1] = " " .. table.concat(clients, ", ")
  end
  parts[#parts + 1] = " Ln %l, Col %v"
  parts[#parts + 1] = vim.bo[buf].expandtab and (" Spaces: " .. vim.bo[buf].shiftwidth)
    or (" Tab Size: " .. vim.bo[buf].tabstop)
  local enc = vim.bo[buf].fileencoding
  parts[#parts + 1] = " " .. (enc ~= "" and enc or vim.o.encoding):upper()
  local ft = vim.bo[buf].filetype
  parts[#parts + 1] = " " .. (ft ~= "" and ft or "plain text") .. " "
  return table.concat(parts, " ")
end

function M.render()
  return table.concat({
    mode_segment(),
    branch_segment(),
    diagnostics_segment(),
    file_segment(),
    "%=",
    right_segments(),
  })
end

---Fallbacks for colorschemes that do not define the SL* groups (theme.lua does).
local function fallback_highlights()
  local links = {
    SLNormal = "ModeMsg",
    SLInsert = "ModeMsg",
    SLVisual = "ModeMsg",
    SLReplace = "ModeMsg",
    SLCommand = "ModeMsg",
    SLTerminal = "ModeMsg",
    SLError = "DiagnosticError",
    SLWarn = "DiagnosticWarn",
  }
  for group, target in pairs(links) do
    if vim.fn.hlexists(group) == 0 then
      api.nvim_set_hl(0, group, { link = target })
    end
  end
end

local group = api.nvim_create_augroup("ui.statusline", { clear = true })
fallback_highlights()
api.nvim_create_autocmd("ColorScheme", { group = group, callback = fallback_highlights })
api.nvim_create_autocmd({ "ModeChanged", "DiagnosticChanged", "LspAttach", "LspDetach" }, {
  group = group,
  callback = function()
    vim.cmd("redrawstatus")
  end,
})

vim.o.statusline = "%!v:lua.require('ui.statusline').render()"

return M
