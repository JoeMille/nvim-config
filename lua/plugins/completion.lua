-- blink.cmp: the VS Code IntelliSense dropdown, and nothing else.
-- No ghost text, no inline AI suggestions — just the LSP/snippet menu you get in
-- VS Code, driven with arrows + Enter/Tab.
return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        preset = "default",
        -- Arrow keys navigate the suggestion menu (in addition to defaults)
        ["<Down>"]    = { "select_next", "fallback" },
        ["<Up>"]      = { "select_prev", "fallback" },
        -- Enter and Tab both accept, like VS Code's acceptSuggestionOnEnter
        ["<CR>"]      = { "accept", "fallback" },
        ["<Tab>"]     = { "accept", "snippet_forward", "fallback" },
        ["<S-Tab>"]   = { "snippet_backward", "fallback" },
        -- Ctrl+Space asks for suggestions on demand (VS Code: Trigger Suggest)
        ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
        -- Escape closes the menu
        ["<Esc>"]     = { "hide", "fallback" },
      },
      completion = {
        menu = {
          -- Show menu automatically while typing
          auto_show = true,
          border = "rounded",
        },
        -- Show documentation popup alongside the suggestion menu
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 150,
          window = { border = "rounded" },
        },
        -- No dimmed inline preview of the completion — the menu is the only hint.
        ghost_text = {
          enabled = false,
        },
        list = {
          selection = {
            preselect = true, -- first item highlighted, like VS Code
            auto_insert = false, -- but nothing lands in the buffer until you accept
          },
        },
      },
      -- Parameter hints while typing a call (VS Code's signature help popup).
      signature = {
        enabled = true,
        window = { border = "rounded" },
      },
    },
  },
}
