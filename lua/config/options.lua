vim.opt.clipboard = "unnamedplus"
if vim.fn.has("mac") == 1 then
  vim.g.clipboard = {
    name = "macOS",
    copy = { ["+"] = "pbcopy", ["*"] = "pbcopy" },
    paste = { ["+"] = "pbpaste", ["*"] = "pbpaste" },
    cache_enabled = 0,
  }
end
vim.opt.mouse        = "a"
vim.opt.cursorline   = true
vim.opt.scrolloff    = 8
vim.opt.sidescrolloff = 8
vim.opt.undofile     = true
vim.opt.splitbelow   = true
vim.opt.splitright   = true
vim.opt.mousefocus   = true

vim.api.nvim_create_autocmd("BufEnter", {
  callback = function() vim.opt_local.mouse = "a" end,
})

vim.diagnostic.config({
  virtual_text = {
    enabled  = true,
    spacing  = 4,
    prefix   = "■",
    severity = { min = vim.diagnostic.severity.HINT },
  },
  underline = {
    severity = { min = vim.diagnostic.severity.HINT },
  },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN]  = " ",
      [vim.diagnostic.severity.INFO]  = " ",
      [vim.diagnostic.severity.HINT]  = "󰌵 ",
    },
  },
  update_in_insert = true,
  severity_sort    = true,
  -- Float popup when cursor rests on an error
  float = {
    border  = "rounded",
    source  = true,   -- show which LSP raised the error
    header  = "",
    prefix  = "",
  },
})
