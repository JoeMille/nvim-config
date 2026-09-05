-- Keymaps. Cmd+<key> follows VS Code on macOS; each has a Ctrl+<key> twin for
-- terminals that cannot send Cmd (Terminal.app, iTerm2, ssh).
--
-- Cmd reaches nvim only through a terminal that speaks the kitty keyboard
-- protocol; Ghostty does, and ~/.config/ghostty/config releases the Cmd combos
-- Ghostty would otherwise use itself.
local map = vim.keymap.set
local api = vim.api

local function windows()
  return require("ui.windows")
end
local function panel()
  return require("ui.panel")
end
local function dock()
  return require("ui.dock")
end
local function edit()
  return require("ui.edit")
end

---Run an fzf-lua picker from an editor window, so the chosen file opens there.
---@param name string
---@param opts table?
local function picker(name, opts)
  return function()
    edit().normal_mode()
    windows().goto_editor()
    require("fzf-lua")[name](opts)
  end
end

local function explorer_toggle()
  require("neo-tree.command").execute({ action = "show", toggle = true })
end

local function explorer_focus()
  edit().normal_mode()
  require("neo-tree.command").execute({ action = "focus", reveal = true })
end

local function go_to_tab(n)
  return function()
    edit().normal_mode()
    windows().goto_editor()
    require("bufferline").go_to(n, true)
  end
end

local function cycle_tab(dir)
  return function()
    edit().normal_mode()
    windows().goto_editor()
    require("bufferline").cycle(dir)
  end
end

local function split_editor()
  edit().normal_mode()
  windows().goto_editor()
  vim.cmd("vsplit")
end

local all = { "n", "i", "v", "t" }

-- ── Files ────────────────────────────────────────────────────────────────────
map({ "n", "i", "v" }, "<D-s>", edit().save, { desc = "Save" })
map({ "n", "i", "v" }, "<C-s>", edit().save, { desc = "Save" })
map({ "n", "i", "t" }, "<D-w>", windows().close_current, { desc = "Close" })
map("n", "<C-w>", windows().close_current, { desc = "Close" })
map(all, "<D-p>", picker("files"), { desc = "Go to File" })
map(all, "<D-o>", picker("files"), { desc = "Go to File" })
map({ "n", "t" }, "<C-p>", picker("files"), { desc = "Go to File" })
map(all, "<D-S-p>", picker("commands"), { desc = "Command Palette" })
map(all, "<D-S-f>", picker("live_grep"), { desc = "Search in Files" })
map("v", "<D-S-f>", picker("grep_visual"), { desc = "Search Selection in Files" })
map(all, "<C-S-f>", picker("live_grep"), { desc = "Search in Files" })
map(all, "<D-S-o>", picker("lsp_document_symbols"), { desc = "Go to Symbol" })
map({ "n", "i", "t" }, "<D-S-h>", function()
  require("ui.search").open()
end, { desc = "Replace in Files" })
map("v", "<D-S-h>", function()
  require("ui.search").open()
end, { desc = "Replace Selection in Files" })
map(all, "<D-S-m>", function()
  edit().normal_mode()
  panel().toggle_view("problems")
end, { desc = "Problems" })

map("n", "<D-f>", "/", { desc = "Find" })
map("i", "<D-f>", "<Esc>/", { desc = "Find" })
map("v", "<D-f>", [["zy/\V<C-r>=escape(@z, '/\')<CR><CR>]], { desc = "Find Selection" })
map("n", "<C-f>", "/", { desc = "Find" })
map("n", "<Esc>", function()
  vim.cmd.nohlsearch()
end, { desc = "Clear Search Highlight" })

-- ── Edit ─────────────────────────────────────────────────────────────────────
map("n", "<D-z>", "u", { desc = "Undo" })
map("i", "<D-z>", "<C-o>u", { desc = "Undo" })
map("v", "<D-z>", "<Esc>u", { desc = "Undo" })
map("n", "<D-S-z>", "<C-r>", { desc = "Redo" })
map("i", "<D-S-z>", "<C-o><C-r>", { desc = "Redo" })
map("n", "<C-z>", "u", { desc = "Undo" })
map("i", "<C-z>", "<C-o>u", { desc = "Undo" })
map("n", "<C-y>", "<C-r>", { desc = "Redo" })
map("i", "<C-y>", "<C-o><C-r>", { desc = "Redo" })

map("n", "<D-a>", "ggVG", { desc = "Select All" })
map({ "i", "v" }, "<D-a>", "<Esc>ggVG", { desc = "Select All" })
map("n", "<C-a>", "ggVG", { desc = "Select All" })
map({ "i", "v" }, "<C-a>", "<Esc>ggVG", { desc = "Select All" })

-- Cmd+V is handled by Ghostty as a bracketed paste, which works in every mode.
map("v", "<D-c>", '"+y', { desc = "Copy" })
map("n", "<D-c>", '"+yy', { desc = "Copy Line" })
map("v", "<D-x>", '"+d', { desc = "Cut" })
map("n", "<D-x>", '"+dd', { desc = "Cut Line" })
map("v", "<C-c>", '"+y', { desc = "Copy" })
map("n", "<C-c>", '"+yy', { desc = "Copy Line" })
map("v", "<C-x>", '"+d', { desc = "Cut" })
map("n", "<C-x>", '"+dd', { desc = "Cut Line" })
map("n", "<C-v>", '"+p', { desc = "Paste" })
map("v", "<C-v>", '"+P', { desc = "Paste" })
map("i", "<C-v>", "<C-r><C-o>+", { desc = "Paste" })
map("n", "<C-q>", "<C-v>", { desc = "Visual Block" })

-- Comment toggling uses nvim's built-in gc, so remap stays on.
map("n", "<D-/>", "gcc", { desc = "Toggle Comment", remap = true })
map("v", "<D-/>", "gc", { desc = "Toggle Comment", remap = true })
map("i", "<D-/>", "<C-o>gcc", { desc = "Toggle Comment", remap = true })
-- Terminal.app and iTerm2 send Ctrl+/ as Ctrl+_.
for _, key in ipairs({ "<C-/>", "<C-_>" }) do
  map("n", key, "gcc", { desc = "Toggle Comment", remap = true })
  map("v", key, "gc", { desc = "Toggle Comment", remap = true })
  map("i", key, "<C-o>gcc", { desc = "Toggle Comment", remap = true })
end

map("n", "<M-Up>", "<cmd>move .-2<cr>", { desc = "Move Line Up" })
map("n", "<M-Down>", "<cmd>move .+1<cr>", { desc = "Move Line Down" })
map("i", "<M-Up>", "<cmd>move .-2<cr>", { desc = "Move Line Up" })
map("i", "<M-Down>", "<cmd>move .+1<cr>", { desc = "Move Line Down" })
map("v", "<M-Up>", ":move '<-2<cr>gv", { desc = "Move Selection Up", silent = true })
map("v", "<M-Down>", ":move '>+1<cr>gv", { desc = "Move Selection Down", silent = true })
map("n", "<M-S-Up>", "<cmd>copy .-1<cr>", { desc = "Copy Line Up" })
map("n", "<M-S-Down>", "<cmd>copy .<cr>", { desc = "Copy Line Down" })
map("i", "<M-S-Up>", "<cmd>copy .-1<cr>", { desc = "Copy Line Up" })
map("i", "<M-S-Down>", "<cmd>copy .<cr>", { desc = "Copy Line Down" })
map("v", "<M-S-Up>", ":copy '<-1<cr>gv", { desc = "Copy Selection Up", silent = true })
map("v", "<M-S-Down>", ":copy '><cr>gv", { desc = "Copy Selection Down", silent = true })

map("n", "<D-S-k>", '"_dd', { desc = "Delete Line" })
map("i", "<D-S-k>", '<C-o>"_dd', { desc = "Delete Line" })
map("v", "<D-S-k>", '"_d', { desc = "Delete Selection" })
map("n", "<D-l>", "V", { desc = "Select Line" })
map("v", "<D-l>", "j", { desc = "Extend Selection" })
map("v", "<BS>", '"_d', { desc = "Delete Selection" })

map("n", "<D-]>", ">>", { desc = "Indent" })
map("n", "<D-[>", "<<", { desc = "Outdent" })
map("i", "<D-]>", "<C-t>", { desc = "Indent" })
map("i", "<D-[>", "<C-d>", { desc = "Outdent" })
map("v", "<D-]>", ">gv", { desc = "Indent" })
map("v", "<D-[>", "<gv", { desc = "Outdent" })
map("v", "<Tab>", ">gv", { desc = "Indent" })
map("v", "<S-Tab>", "<gv", { desc = "Outdent" })

map({ "n", "i", "v" }, "<M-F>", edit().format, { desc = "Format Document" })

-- macOS line and word movement
map({ "n", "v" }, "<D-Left>", "^", { desc = "Line Start" })
map({ "n", "v" }, "<D-Right>", "$", { desc = "Line End" })
map({ "n", "v" }, "<D-Up>", "gg", { desc = "File Start" })
map({ "n", "v" }, "<D-Down>", "G", { desc = "File End" })
map("i", "<D-Left>", "<C-o>^", { desc = "Line Start" })
map("i", "<D-Right>", "<C-o>$", { desc = "Line End" })
map("i", "<D-Up>", "<C-o>gg", { desc = "File Start" })
map("i", "<D-Down>", "<C-o>G", { desc = "File End" })
map("i", "<D-BS>", "<C-o>d0", { desc = "Delete to Line Start" })
map("i", "<M-BS>", "<C-w>", { desc = "Delete Word" })
map("i", "<C-BS>", "<C-w>", { desc = "Delete Word" })
map({ "n", "v" }, "<M-Left>", "b", { desc = "Word Left" })
map({ "n", "v" }, "<M-Right>", "w", { desc = "Word Right" })
map("i", "<M-Left>", "<C-o>b", { desc = "Word Left" })
map("i", "<M-Right>", "<C-o>w", { desc = "Word Right" })

-- ── Views ────────────────────────────────────────────────────────────────────
map(all, "<D-b>", explorer_toggle, { desc = "Toggle Explorer" })
map({ "n", "i" }, "<C-b>", explorer_toggle, { desc = "Toggle Explorer" })
map(all, "<D-S-e>", explorer_focus, { desc = "Focus Explorer" })

map(all, "<D-j>", panel().toggle, { desc = "Toggle Panel" })
map(all, "<D-t>", panel().toggle, { desc = "Toggle Panel" })
map({ "n", "t" }, "<C-t>", panel().toggle_focus, { desc = "Focus/Hide Panel" })
map({ "n", "i", "t" }, "<C-`>", panel().toggle_focus, { desc = "Focus/Hide Panel" })
map(all, "<D-d>", panel().new, { desc = "Split Terminal" })
map({ "n", "t" }, "<C-\\>", panel().new, { desc = "Split Terminal" })

-- The AI assistant, docked on the right. With a selection, Cmd+I hands the
-- selected lines over instead of just showing the dock.
map({ "n", "i", "t" }, "<D-i>", dock().toggle_focus, { desc = "AI Assistant" })
map("v", "<D-i>", dock().send_selection, { desc = "Ask the AI about the Selection" })
map({ "n", "i" }, "<D-\\>", split_editor, { desc = "Split Editor" })

for n = 1, 9 do
  map(all, "<D-" .. n .. ">", go_to_tab(n), { desc = "Go to Tab " .. n })
end
map(all, "<D-S-]>", cycle_tab(1), { desc = "Next Tab" })
map(all, "<D-S-[>", cycle_tab(-1), { desc = "Previous Tab" })
map(all, "<D-}>", cycle_tab(1), { desc = "Next Tab" })
map(all, "<D-{>", cycle_tab(-1), { desc = "Previous Tab" })
map({ "n", "i" }, "<C-Tab>", cycle_tab(1), { desc = "Next Tab" })
map({ "n", "i" }, "<C-S-Tab>", cycle_tab(-1), { desc = "Previous Tab" })
map("n", "<S-l>", cycle_tab(1), { desc = "Next Tab" })
map("n", "<S-h>", cycle_tab(-1), { desc = "Previous Tab" })

-- ── Windows ──────────────────────────────────────────────────────────────────
map("n", "<C-h>", "<C-w>h", { desc = "Window Left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window Down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window Up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window Right" })
map("n", "<C-Left>", "<C-w>h", { desc = "Window Left" })
map("n", "<C-Down>", "<C-w>j", { desc = "Window Down" })
map("n", "<C-Up>", "<C-w>k", { desc = "Window Up" })
map("n", "<C-Right>", "<C-w>l", { desc = "Window Right" })
map("t", "<C-Left>", "<C-\\><C-n><C-w>h", { desc = "Window Left" })
map("t", "<C-Down>", "<C-\\><C-n><C-w>j", { desc = "Window Down" })
map("t", "<C-Up>", "<C-\\><C-n><C-w>k", { desc = "Window Up" })
map("t", "<C-Right>", "<C-\\><C-n><C-w>l", { desc = "Window Right" })

-- Double Esc leaves terminal mode; a single Esc still reaches the shell.
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Terminal Normal Mode" })

-- ── Leader (Space): the same things without Cmd, for ssh and other terminals ─
map("n", "<leader>e", explorer_toggle, { desc = "Toggle Explorer" })
map("n", "<leader>E", explorer_focus, { desc = "Focus Explorer" })
map("n", "<leader>t", panel().toggle_focus, { desc = "Terminal" })
map("n", "<leader>T", panel().new, { desc = "Split Terminal" })
map("n", "<leader>f", picker("files"), { desc = "Files" })
map("n", "<leader>g", picker("live_grep"), { desc = "Search in Files" })
map("n", "<leader>r", picker("oldfiles"), { desc = "Recent Files" })
map({ "n", "v" }, "<leader>R", function()
  require("ui.search").open()
end, { desc = "Replace in Files" })
map("n", "<leader>b", picker("buffers"), { desc = "Open Tabs" })
map("n", "<leader>s", picker("lsp_document_symbols"), { desc = "Symbols" })
map("n", "<leader>x", function()
  panel().toggle_view("problems")
end, { desc = "Problems" })
map("n", "<leader>X", picker("diagnostics_workspace"), { desc = "Problems (Search)" })
map("n", "<leader>a", dock().toggle_focus, { desc = "AI Assistant" })
map("v", "<leader>a", dock().send_selection, { desc = "Ask the AI about the Selection" })
map("n", "<leader>A", dock().pick, { desc = "AI Assistant: Switch" })
map("n", "<leader>c", picker("commands"), { desc = "Command Palette" })
map("n", "<leader>k", picker("keymaps"), { desc = "Keyboard Shortcuts" })
map("n", "<leader>h", picker("helptags"), { desc = "Help" })
map("n", "<leader>n", "<cmd>enew<cr>", { desc = "New File" })
map("n", "<leader>w", edit().save, { desc = "Save" })
map("n", "<leader>d", windows().close_current, { desc = "Close" })
map("n", "<leader>q", "<cmd>confirm qall<cr>", { desc = "Quit" })
map("n", "<leader>m", "<cmd>Mason<cr>", { desc = "Language Servers (Mason)" })
map("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Plugins (Lazy)" })
for n = 1, 9 do
  map("n", "<leader>" .. n, go_to_tab(n), { desc = "Go to Tab " .. n })
end

-- ── Right-click menu ─────────────────────────────────────────────────────────
-- Nvim's built-in MenuPopup autocmd greys out its own default PopUp entries
-- (Go to definition, Show Diagnostics, ...). Those entries are gone once we
-- replace the menu below, so the autocmd would error with E329 on every
-- right-click. Drop the whole default group.
pcall(vim.api.nvim_del_augroup_by_name, "nvim.popupmenu")

vim.cmd([[
  silent! aunmenu PopUp
  vnoremenu PopUp.Cut                 "+x
  vnoremenu PopUp.Copy                "+y
  nnoremenu PopUp.Paste               "+p
  vnoremenu PopUp.Paste               "+P
  inoremenu PopUp.Paste               <C-r><C-o>+
  vnoremenu PopUp.Delete              "_x
  anoremenu PopUp.-1-                 <Nop>
  nnoremenu PopUp.Go\ to\ Definition  <cmd>lua vim.lsp.buf.definition()<cr>
  nnoremenu PopUp.Go\ to\ References  <cmd>lua require("fzf-lua").lsp_references({ jump1 = true })<cr>
  nnoremenu PopUp.Rename\ Symbol      <cmd>lua vim.lsp.buf.rename()<cr>
  nnoremenu PopUp.Quick\ Fix          <cmd>lua vim.lsp.buf.code_action()<cr>
  nnoremenu PopUp.Format\ Document    <cmd>lua require("ui.edit").format()<cr>
  anoremenu PopUp.-2-                 <Nop>
  nnoremenu PopUp.Ask\ the\ AI        <cmd>lua require("ui.dock").ask_about_cursor()<cr>
  vnoremenu PopUp.Ask\ the\ AI        <cmd>lua require("ui.dock").send_selection()<cr>
  anoremenu PopUp.-3-                 <Nop>
  nnoremenu PopUp.Select\ All         ggVG
  inoremenu PopUp.Select\ All         <Esc>ggVG
  vnoremenu PopUp.Select\ All         <Esc>ggVG
]])
