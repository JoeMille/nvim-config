-- blink.cmp: autocomplete with arrow key navigation (like VS Code IntelliSense)
return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        preset = "default",
        -- Arrow keys navigate the suggestion menu (in addition to defaults)
        ["<Down>"]  = { "select_next", "fallback" },
        ["<Up>"]    = { "select_prev", "fallback" },
        -- Enter confirms the selection
        ["<CR>"]    = { "accept", "fallback" },
        -- Tab also accepts
        ["<Tab>"]   = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
        -- Escape closes the menu
        ["<Esc>"]   = { "hide", "fallback" },
      },
      completion = {
        menu = {
          -- Show menu automatically while typing
          auto_show = true,
        },
        -- Show documentation popup alongside the suggestion menu
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
        },
        -- Ghost text preview (like VS Code inline suggestion dimmed text)
        ghost_text = {
          enabled = true,
        },
      },
    },
  },
}
