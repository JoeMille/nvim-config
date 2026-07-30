local map = vim.keymap.set

---Lazily call into the terminal panel helper.
---@param fn string
local function term(fn)
  return function()
    require("config.terminal")[fn]()
  end
end

---Ctrl+B: toggle the tree, revealing the current file when opening it.
local function explorer_toggle()
  local explorer = Snacks.picker.get({ source = "explorer" })[1]
  if explorer and not explorer.closed then
    explorer:close()
    return
  end
  local file = vim.api.nvim_buf_get_name(0)
  if vim.bo.buftype == "" and file ~= "" then
    Snacks.explorer.reveal({ file = file })
  else
    Snacks.explorer()
  end
end

-- Visual Block mode (frees Ctrl+V for paste)
map("n", "<C-q>", "<C-v>", { desc = "Visual Block Mode" })

-- ── macOS Cmd keys (VS Code muscle memory) ───────────────────────────────────
-- These DO fire in a terminal, but only one that speaks the kitty keyboard
-- protocol. Cmd/super cannot be expressed in legacy terminal input encoding at
-- all, so Terminal.app and iTerm2 drop it; a kkp terminal encodes Cmd+S as
-- CSI 115;9u and nvim 0.11 decodes that to <D-s>. Ghostty is set up for this in
-- ~/.config/ghostty/config, which also releases the Cmd combos Ghostty binds to
-- its own actions — a key bound by the terminal never reaches nvim.
-- The Ctrl variants below stay as a fallback for non-kkp terminals and for ssh.
map("v", "<D-c>", '"+y',    { desc = "Copy to clipboard" })
map("v", "<D-x>", '"+d',    { desc = "Cut to clipboard" })
map("n", "<D-v>", '"+p',    { desc = "Paste from clipboard" })
map("i", "<D-v>", "<C-r>+", { desc = "Paste from clipboard" })
map("v", "<D-v>", '"+p',    { desc = "Paste from clipboard" })

map({ "i", "v", "n", "s" }, "<D-s>", "<cmd>w<cr><esc>", { desc = "Save File" })
map({ "n", "v" }, "<D-a>", "ggVG",  { desc = "Select All" })
map("n", "<D-z>", "u",     { desc = "Undo" })
map("i", "<D-z>", "<C-o>u", { desc = "Undo" })
map("n", "<D-S-z>", "<C-r>", { desc = "Redo" })

map("n", "<D-f>", "/",     { desc = "Find in file" })
map("n", "<D-S-f>", "<cmd>lua Snacks.picker.grep()<cr>",     { desc = "Find in Project" })
map("n", "<D-p>", "<cmd>lua Snacks.picker.files()<cr>",      { desc = "Find File" })
map("n", "<D-S-p>", "<cmd>lua Snacks.picker.commands()<cr>", { desc = "Command Palette" })
map("n", "<D-b>", explorer_toggle,    { desc = "Toggle File Explorer" })
map("n", "<D-w>", "<cmd>bdelete<cr>", { desc = "Close Buffer" })

-- Cmd+/ toggles a comment. gcc/gc are LazyVim's own maps, so remap must stay on.
map("n", "<D-/>", "gcc", { desc = "Toggle Comment", remap = true })
map("v", "<D-/>", "gc",  { desc = "Toggle Comment", remap = true })

-- Terminal panel. Cmd+D matches VS Code's "split terminal"; Cmd+\ is the same
-- thing for anyone who reaches for the editor-split binding instead.
map({ "n", "t" }, "<D-t>",  term("toggle"),      { desc = "Terminal: toggle panel" })
map({ "n", "t" }, "<D-d>",  term("split_right"), { desc = "Terminal: split right" })
map({ "n", "t" }, "<D-\\>", term("split_right"), { desc = "Terminal: split right" })

-- Cmd+1..9 jump to a buffer the way they jump to editor tabs in VS Code.
for i = 1, 9 do
  map("n", "<D-" .. i .. ">", "<cmd>BufferLineGoToBuffer " .. i .. "<cr>", { desc = "Go to Buffer " .. i })
end

-- Standard macOS line/document navigation.
map({ "n", "v" }, "<D-Left>",  "^",  { desc = "Start of line" })
map({ "n", "v" }, "<D-Right>", "$",  { desc = "End of line" })
map({ "n", "v" }, "<D-Up>",    "gg", { desc = "Top of file" })
map({ "n", "v" }, "<D-Down>",  "G",  { desc = "Bottom of file" })
map("i", "<D-Left>",  "<C-o>^",  { desc = "Start of line" })
map("i", "<D-Right>", "<C-o>$",  { desc = "End of line" })
map("i", "<D-BS>",    "<C-u>",   { desc = "Delete to line start" })

map("v", "<C-c>", '"+y',   { desc = "Copy to clipboard" })
map("v", "<C-x>", '"+d',   { desc = "Cut to clipboard" })
map("n", "<C-v>", '"+p',   { desc = "Paste from clipboard" })
map("i", "<C-v>", "<C-r>+",{ desc = "Paste from clipboard" })
map("v", "<C-v>", '"+p',   { desc = "Paste from clipboard" })

map({ "i", "v", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })
map("n", "<C-z>", "u",      { desc = "Undo" })
map("n", "<C-y>", "<C-r>",  { desc = "Redo" })
map("n", "<C-a>", "ggVG",   { desc = "Select All" })

map("n", "<C-f>", "/",      { desc = "Find in file" })
map("n", "<C-p>", "<cmd>lua Snacks.picker.files()<cr>",   { desc = "Find File" })
map("n", "<leader>fg", "<cmd>lua Snacks.picker.grep()<cr>", { desc = "Find in Project" })
map("n", "<C-b>", explorer_toggle,                        { desc = "Toggle File Explorer" })

-- Terminal.app and iTerm2 send Ctrl+/ as 0x1F, which nvim reads as <C-_>, so both
-- have to be mapped or LazyVim's own <C-_> binding (a floating terminal) wins.
for _, key in ipairs({ "<C-/>", "<C-_>" }) do
  map("n", key, "gcc", { desc = "Toggle Comment", remap = true })
  map("v", key, "gc",  { desc = "Toggle Comment", remap = true })
end

-- ── Terminal panel ───────────────────────────────────────────────────────────
-- Ctrl+T toggles the whole panel, Ctrl+\ adds a terminal to the right of the
-- current one. Both work from inside a terminal, so no Esc dance first.
-- Ctrl+1..4 are deliberately gone: no terminal emulator can send Ctrl+digit
-- (Ctrl+3 arrives as Esc), so those bindings never fired. <leader>t1..t4 instead.
map({ "n", "t" }, "<C-t>",  term("toggle"),      { desc = "Terminal: toggle panel" })
map({ "n", "t" }, "<C-\\>", term("split_right"), { desc = "Terminal: split right" })
map("n", "<leader>ts", term("split_right"), { desc = "Split terminal right" })
map("n", "<leader>tt", term("toggle"),      { desc = "Toggle terminal panel" })
-- Leader is Space, so leader maps stay out of terminal mode — otherwise the
-- spacebar would start a chord inside your shell.
map("n", "<leader>tq", term("kill"), { desc = "Kill this terminal" })
map("n", "<leader>tv", "<cmd>ToggleTerm direction=vertical<cr>", { desc = "Terminal (full height right)" })
map("n", "<leader>tf", "<cmd>ToggleTerm direction=float<cr>",    { desc = "Terminal (floating)" })
map("n", "<leader>tl", "<cmd>ToggleTermToggleAll<cr>",           { desc = "Toggle all terminals" })
for i = 1, 4 do
  map("n", "<leader>t" .. i, function()
    require("config.terminal").focus(i)
  end, { desc = "Terminal " .. i })
end

-- Esc leaves terminal mode. Ctrl+\ is taken by split-right above, so this is the
-- way out of a terminal.
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit Terminal Mode" })

map("n", "<S-l>", "<cmd>bnext<cr>",   { desc = "Next Buffer" })
map("n", "<S-h>", "<cmd>bprev<cr>",   { desc = "Prev Buffer" })

-- Ctrl+W closes the buffer like VS Code closes a tab. That shadows nvim's window
-- prefix, which silently broke every LazyVim keymap whose right-hand side is
-- <C-w>... with remap=true — <C-h/j/k/l> deleted the buffer instead of moving,
-- and <leader>- / <leader>| / <leader>wd ran `s` / `v` / `c` on the buffer after
-- closing it. They're redefined below without remap, so the builtin runs.
map("n", "<C-w>", "<cmd>bdelete<cr>", { desc = "Close Buffer" })

map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window" })
map("n", "<leader>-",  "<C-w>s", { desc = "Split Window Below" })
map("n", "<leader>|",  "<C-w>v", { desc = "Split Window Right" })
map("n", "<leader>wd", "<C-w>c", { desc = "Delete Window" })

map("n", "<leader>X", "<cmd>Mason<cr>",                             { desc = "Extensions (Mason)" })
map("n", "<leader>P", "<cmd>lua Snacks.picker.commands()<cr>",      { desc = "Command Palette" })

-- Split navigation, also from inside a terminal.
map("n", "<C-Left>",  "<C-w>h", { desc = "Move to left split" })
map("n", "<C-Right>", "<C-w>l", { desc = "Move to right split" })
map("n", "<C-Up>",    "<C-w>k", { desc = "Move to upper split" })
map("n", "<C-Down>",  "<C-w>j", { desc = "Move to lower split" })
map("t", "<C-Left>",  "<C-\\><C-n><C-w>h", { desc = "Move to left split" })
map("t", "<C-Right>", "<C-\\><C-n><C-w>l", { desc = "Move to right split" })
map("t", "<C-Up>",    "<C-\\><C-n><C-w>k", { desc = "Move to upper split" })
map("t", "<C-Down>",  "<C-\\><C-n><C-w>j", { desc = "Move to lower split" })

map("n", "<F12>",   "<cmd>lua vim.lsp.buf.definition()<cr>", { desc = "Go to Definition" })
map("n", "<S-F12>", "<cmd>lua vim.lsp.buf.references()<cr>", { desc = "Go to References" })
map("n", "<F2>",    "<cmd>lua vim.lsp.buf.rename()<cr>",     { desc = "Rename Symbol" })

map({ "n", "v" }, "<leader>Cc", "<cmd>CodeCompanionChat toggle<cr>", { desc = "AI Chat" })
map({ "n", "v" }, "<leader>Ca", "<cmd>CodeCompanionActions<cr>",     { desc = "AI Actions" })
map({ "n", "v" }, "<leader>Ci", "<cmd>CodeCompanion<cr>",            { desc = "AI Inline" })
