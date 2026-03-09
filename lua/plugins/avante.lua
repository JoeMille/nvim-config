-- Avante.nvim: AI chat sidebar supporting Claude, GPT-4, etc.
-- Like Cursor AI / VS Code Claude extension inside Neovim
-- Usage:
--   <leader>aa  = open/toggle AI chat sidebar
--   <leader>ae  = explain selected code
--   <leader>af  = fix selected code
--   <leader>ar  = refactor selected code
return {
  {
    "yetone/avante.nvim",
    enabled = false, -- replaced by codecompanion.nvim
    event = "VeryLazy",
    version = false,
    build = "make",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
      "zbirenbaum/copilot.lua", -- optional: use Copilot as provider
    },
    opts = {
      -- Set provider to Claude (requires ANTHROPIC_API_KEY env var)
      -- Switch to "copilot" if you want to use your Copilot subscription instead
      provider = "claude",

      claude = {
        endpoint = "https://api.anthropic.com",
        model    = "claude-sonnet-4-5",
        timeout  = 30000,
        temperature = 0,
        max_tokens  = 8096,
      },

      -- Sidebar opens on the right (like VS Code)
      windows = {
        position = "right",
        wrap     = true,
        width    = 35,
        sidebar_header = {
          align = "center",
          rounded = true,
        },
      },

      -- Show hints in the editor
      hints = { enabled = true },
    },
    keys = {
      { "<leader>aa", "<cmd>AvanteToggle<cr>",  desc = "AI Chat (Avante)",    mode = { "n", "v" } },
      { "<leader>ae", "<cmd>AvanteAsk<cr>",     desc = "AI Explain",          mode = { "n", "v" } },
      { "<leader>af", "<cmd>AvanteFix<cr>",     desc = "AI Fix",              mode = { "n", "v" } },
      { "<leader>ar", "<cmd>AvanteRefactor<cr>",desc = "AI Refactor",         mode = { "n", "v" } },
    },
  },

  -- Required for better input UI
  {
    "stevearc/dressing.nvim",
    opts = {},
  },
}
