-- Startup layout: file tree on the left, terminal panel at the bottom, cursor in
-- the editor. Uses the panel helper so the terminal actually appears (a bare
-- `:ToggleTerm` used to fail silently here when toggleterm was lazy-loaded).

---Windows that make up the tree, so we never try to split one of them.
local sidebar_ft = {
  snacks_layout_box    = true,
  snacks_picker_list   = true,
  snacks_picker_input  = true,
  snacks_picker_preview = true,
}

---First window we can sensibly put the cursor in: a real split (not a popup),
---not part of the tree, not a terminal. The dashboard counts — it is where the
---cursor belongs when nvim opened a directory rather than a file.
---@return integer? win
local function editor_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_win_get_config(win).relative == ""
      and not sidebar_ft[vim.bo[buf].filetype]
      and vim.bo[buf].buftype ~= "terminal"
    then
      return win
    end
  end
end

vim.api.nvim_create_autocmd("User", {
  pattern = "LazyVimStarted",
  callback = function()
    -- Snacks.explorer() is a toggle, not an "open": Snacks.picker.pick() closes an
    -- already-open picker of the same source. With explorer.replace_netrw = true,
    -- `nvim some/dir` has opened the tree before we get here, so calling it
    -- unconditionally used to shut it again — which is why the tree showed up when
    -- opening a file but never when opening a directory.
    if not Snacks.picker.get({ source = "explorer" })[1] then
      Snacks.explorer()
    end

    vim.defer_fn(function()
      -- The tree takes focus while it populates and :ToggleTerm cannot split a
      -- picker window, so the panel has to be built from an editor window. The old
      -- code ran the toggle wherever the cursor happened to land and swallowed the
      -- resulting error in a pcall, so opening a file gave no terminal at all.
      local win = editor_win()
      if not win then
        return
      end
      vim.api.nvim_set_current_win(win)
      require("config.terminal").toggle()
      -- The new terminal grabs the cursor; hand it back to the editor.
      vim.defer_fn(function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_set_current_win(win)
        end
      end, 150)
    end, 500)
  end,
})

-- Show the diagnostic popup when the cursor rests on a problem, the way hovering
-- an error in VS Code does. The float styling lives in config/options.lua;
-- 'updatetime' (200ms, from LazyVim) decides how long "rests" means.
vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    -- Don't stack a float on top of a float (hover, blink docs, lazy UI, ...).
    if vim.api.nvim_win_get_config(0).relative ~= "" then
      return
    end
    if vim.bo.buftype ~= "" then
      return
    end
    pcall(vim.diagnostic.open_float, nil, { focus = false, scope = "cursor" })
  end,
})
