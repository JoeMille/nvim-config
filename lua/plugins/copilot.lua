return {
  {
    "zbirenbaum/copilot.lua",
    cmd   = "Copilot",
    event = "InsertEnter",
    opts  = {
      suggestion = {
        enabled      = true,
        auto_trigger = true,
        keymap = {
          accept      = "<Tab>",
          accept_word = "<C-Right>",
          next        = "<M-]>",
          prev        = "<M-[>",
          dismiss     = "<C-]>",
        },
      },
      panel     = { enabled = false },
      filetypes = { ["*"] = true },
    },
  },

  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      { "stevearc/dressing.nvim", opts = {} },
    },
    opts = {
      strategies = {
        chat   = { adapter = "copilot" },
        inline = { adapter = "copilot" },
        agent  = { adapter = "copilot" },
      },
      adapters = {
        copilot = function()
          return require("codecompanion.adapters").extend("copilot", {
            schema = { model = { default = "claude-sonnet-4-5" } },
          })
        end,
      },
      display = {
        chat = {
          window = { layout = "vertical", position = "right", width = 0.30 },
        },
        inline        = { diff = { enabled = true } },
        action_palette = { width = 95, height = 10 },
      },
    },
    cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
    keys = {
      { "<leader>Cc", "<cmd>CodeCompanionChat toggle<cr>", desc = "AI Chat",       mode = { "n", "v" } },
      { "<leader>Ca", "<cmd>CodeCompanionActions<cr>",     desc = "AI Actions",    mode = { "n", "v" } },
      { "<leader>Ci", "<cmd>CodeCompanion<cr>",            desc = "AI Inline",     mode = { "n", "v" } },
      { "<leader>Cf", "<cmd>CodeCompanionChat Add<cr>",    desc = "Add to chat",   mode = { "n", "v" } },
    },
  },
}
