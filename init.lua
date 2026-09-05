-- A small VS Code: file tree on the left, terminals at the bottom, tabs on top,
-- and the keyboard/mouse behaviour you expect from a normal editor.
--
--   lua/core/     options, plugin manager, keymaps, autocmds
--   lua/ui/       the terminal panel, statusline and window helpers (no plugins)
--   lua/plugins/  one file per plugin
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("core.options")
require("core.lazy")
require("core.keymaps")
require("core.autocmds")
