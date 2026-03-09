vim.api.nvim_create_autocmd("User", {
  pattern = "LazyVimStarted",
  callback = function()
    Snacks.explorer()
    vim.defer_fn(function()
      pcall(vim.cmd, "ToggleTerm")
      vim.defer_fn(function() pcall(vim.cmd, "wincmd k") end, 150)
    end, 500)
  end,
})
