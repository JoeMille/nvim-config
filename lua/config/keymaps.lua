local map = vim.keymap.set

-- Visual Block mode (frees Ctrl+V for paste)
map("n", "<C-q>", "<C-v>", { desc = "Visual Block Mode" })

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
map("n", "<C-b>", "<cmd>lua Snacks.explorer()<cr>",       { desc = "Toggle File Explorer" })

map("n", "<C-/>", "gcc", { desc = "Toggle Comment", remap = true })
map("v", "<C-/>", "gc",  { desc = "Toggle Comment", remap = true })

map({ "n", "t" }, "<C-t>", "<cmd>1ToggleTerm direction=horizontal<cr>", { desc = "Terminal 1" })
map({ "n", "t" }, "<C-1>", "<cmd>1ToggleTerm direction=horizontal<cr>", { desc = "Terminal 1" })
map({ "n", "t" }, "<C-2>", "<cmd>2ToggleTerm direction=horizontal<cr>", { desc = "Terminal 2" })
map({ "n", "t" }, "<C-3>", "<cmd>3ToggleTerm direction=horizontal<cr>", { desc = "Terminal 3" })
map({ "n", "t" }, "<C-4>", "<cmd>4ToggleTerm direction=horizontal<cr>", { desc = "Terminal 4" })

map({ "n", "t" }, "<leader>th", function()
  local terms = require("toggleterm.terminal").get_all()
  vim.cmd(#terms + 1 .. "ToggleTerm direction=horizontal")
end, { desc = "New terminal" })

map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit Terminal Mode" })

map("n", "<S-l>", "<cmd>bnext<cr>",   { desc = "Next Buffer" })
map("n", "<S-h>", "<cmd>bprev<cr>",   { desc = "Prev Buffer" })
map("n", "<C-w>", "<cmd>bdelete<cr>", { desc = "Close Buffer" })

map("n", "<leader>X", "<cmd>Mason<cr>",                             { desc = "Extensions (Mason)" })
map("n", "<leader>P", "<cmd>lua Snacks.picker.commands()<cr>",      { desc = "Command Palette" })

map("n", "<C-Left>",  "<C-w>h", { desc = "Move to left split" })
map("n", "<C-Right>", "<C-w>l", { desc = "Move to right split" })
map("n", "<C-Up>",    "<C-w>k", { desc = "Move to upper split" })
map("n", "<C-Down>",  "<C-w>j", { desc = "Move to lower split" })

map("n", "<F12>",   "<cmd>lua vim.lsp.buf.definition()<cr>", { desc = "Go to Definition" })
map("n", "<S-F12>", "<cmd>lua vim.lsp.buf.references()<cr>", { desc = "Go to References" })
map("n", "<F2>",    "<cmd>lua vim.lsp.buf.rename()<cr>",     { desc = "Rename Symbol" })

map({ "n", "v" }, "<leader>Cc", "<cmd>CodeCompanionChat toggle<cr>", { desc = "AI Chat" })
map({ "n", "v" }, "<leader>Ca", "<cmd>CodeCompanionActions<cr>",     { desc = "AI Actions" })
map({ "n", "v" }, "<leader>Ci", "<cmd>CodeCompanion<cr>",            { desc = "AI Inline" })

