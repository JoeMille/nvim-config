local o = vim.opt

-- netrw is replaced by the file tree.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- ── Colour depth ─────────────────────────────────────────────────────────────
-- Only claim 24-bit colour when the terminal can actually render it. Terminal.app
-- cannot: it silently drops the escape sequences, so every buffer renders in the
-- default foreground and looks like unhighlighted plain text. Where truecolor is
-- missing we stay in 256-colour mode and theme.lua picks a colorscheme that
-- defines cterm colours, so syntax highlighting still works.
---@return boolean
local function supports_truecolor()
  local colorterm = vim.env.COLORTERM
  if colorterm == "truecolor" or colorterm == "24bit" then
    return true
  end
  local term = vim.env.TERM or ""
  for _, known in ipairs({ "direct", "ghostty", "kitty", "wezterm", "alacritty" }) do
    if term:find(known, 1, true) then
      return true
    end
  end
  -- Backstop: terminals that advertise RGB/Tc in terminfo without setting COLORTERM.
  if term ~= "" and vim.fn.executable("infocmp") == 1 then
    local caps = vim.fn.system({ "infocmp", "-x", term })
    if vim.v.shell_error == 0 and (caps:find("RGB", 1, true) or caps:find("Tc", 1, true)) then
      return true
    end
  end
  return false
end

vim.g.have_truecolor = supports_truecolor()

-- ── Look ─────────────────────────────────────────────────────────────────────
o.termguicolors = vim.g.have_truecolor
o.number = true
o.relativenumber = false
o.signcolumn = "yes"
o.cursorline = true
o.laststatus = 3 -- one statusline for the whole screen
o.showtabline = 2 -- always show editor tabs
o.showmode = false -- the statusline shows the mode
o.showcmd = false
o.ruler = false
o.cmdheight = 1
o.wrap = false
o.linebreak = true
o.scrolloff = 4
o.sidescrolloff = 8
o.pumheight = 12
o.winborder = "rounded"
o.fillchars = {
  eob = " ",
  vert = "│",
  horiz = "─",
  horizup = "┴",
  horizdown = "┬",
  vertleft = "┤",
  vertright = "├",
  verthoriz = "┼",
}
o.shortmess:append("IcC") -- no intro screen, no completion chatter
o.title = true
o.titlestring = "%t%( %M%) - nvim"

-- ── Editing ──────────────────────────────────────────────────────────────────
o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.softtabstop = 4
o.shiftround = true
o.ignorecase = true
o.smartcase = true
o.undofile = true
o.swapfile = false -- no "swap file exists" prompts; undo history is on disk instead
o.autoread = true -- pick up files changed outside the editor
o.confirm = true -- ask to save instead of failing with E37
o.updatetime = 300
o.timeoutlen = 300
o.splitbelow = true
o.splitright = true
o.startofline = false

-- ── Standard keyboard and mouse ──────────────────────────────────────────────
o.mouse = "a"
o.mousemodel = "popup_setpos" -- right-click menu
o.mousemoveevent = true -- hover effects in the tab bar
o.mousescroll = "ver:3,hor:0"
o.clipboard = "unnamedplus" -- y/p use the system clipboard
o.keymodel = "startsel,stopsel" -- Shift+Arrow selects, plain Arrow stops selecting
o.whichwrap:append("<,>,[,]") -- arrows wrap onto the next line

-- ── Diagnostics: squiggles, a coloured line number, hover for details ───────
vim.diagnostic.config({
  virtual_text = false,
  underline = true,
  severity_sort = true,
  update_in_insert = false,
  signs = {
    priority = 5, -- lower than gitsigns, so the git gutter stays visible
    text = {
      [vim.diagnostic.severity.ERROR] = "\u{ea87}", -- codicon error
      [vim.diagnostic.severity.WARN] = "\u{ea6c}", -- codicon warning
      [vim.diagnostic.severity.INFO] = "\u{ea74}", -- codicon info
      [vim.diagnostic.severity.HINT] = "\u{ea61}", -- codicon lightbulb
    },
    numhl = {
      [vim.diagnostic.severity.ERROR] = "DiagnosticError",
      [vim.diagnostic.severity.WARN] = "DiagnosticWarn",
      [vim.diagnostic.severity.INFO] = "DiagnosticInfo",
      [vim.diagnostic.severity.HINT] = "DiagnosticHint",
    },
  },
  float = { border = "rounded", source = true, header = "", prefix = "" },
  jump = { float = true },
})
