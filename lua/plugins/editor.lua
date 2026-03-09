return {
  { "nvim-neo-tree/neo-tree.nvim", enabled = false },

  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      size = function(term)
        if term.direction == "horizontal" then return 15
        elseif term.direction == "vertical" then return vim.o.columns * 0.4
        end
      end,
      direction       = "horizontal",
      shade_terminals = true,
      start_in_insert = true,
      persist_size    = true,
      close_on_exit   = true,
      float_opts      = { border = "curved" },
      winbar = {
        enabled = true,
        name_formatter = function(term)
          return string.format(" %d: %s", term.id, term.name)
        end,
      },
    },
    keys = {
      { "<leader>tv", "<cmd>ToggleTerm direction=vertical<cr>",  desc = "Terminal vertical",   mode = { "n", "t" } },
      { "<leader>th", "<cmd>exe (bufnr('%') + 1) . 'ToggleTerm direction=horizontal'<cr>", desc = "New terminal", mode = { "n", "t" } },
      { "<leader>tf", "<cmd>ToggleTerm direction=float<cr>",     desc = "Terminal float",      mode = { "n", "t" } },
      { "<leader>tl", "<cmd>ToggleTermToggleAll<cr>",            desc = "Toggle all terminals",mode = { "n", "t" } },
    },
  },

  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        mode              = "buffers",
        numbers           = "none",
        close_command     = "bdelete! %d",
        separator_style   = "slant",
        show_buffer_icons = true,
        show_close_icon   = true,
        show_tab_indicators = true,
        diagnostics       = "nvim_lsp",
        diagnostics_indicator = function(count, level)
          local icon = level:match("error") and " " or " "
          return " " .. icon .. count
        end,
        offsets = {
          {
            filetype   = "snacks_layout_box",
            text       = " File Explorer",
            highlight  = "Directory",
            separator  = true,
          },
        },
      },
    },
  },

  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      table.insert(opts.sections.lualine_x, {
        function()
          local ok, copilot = pcall(require, "copilot.api")
          if not ok then return "" end
          local status = copilot.status and copilot.status.data
          if status and status.status == "InProgress" then return " " end
          if status and status.status == "Normal" then return " " end
          return ""
        end,
        color = { fg = "#6CC644" },
      })
    end,
  },

  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>C", group = "copilot" },
      },
    },
  },
}
