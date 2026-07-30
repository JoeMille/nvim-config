return {
  { "nvim-neo-tree/neo-tree.nvim", enabled = false },

  {
    "akinsho/toggleterm.nvim",
    version = "*",
    -- Not lazy: the startup layout in config/autocmds.lua opens the panel, and a
    -- `keys`-only spec means the :ToggleTerm command doesn't exist yet at that
    -- point. Keymaps live in config/keymaps.lua instead.
    lazy = false,
    opts = {
      size = function(term)
        if term.direction == "horizontal" then return 15
        elseif term.direction == "vertical" then return vim.o.columns * 0.4
        end
      end,
      direction       = "horizontal",
      shade_terminals = true,
      env             = { NVIM = "", NVIM_LISTEN_ADDRESS = "" },
      start_in_insert = true,
      persist_size    = true,
      close_on_exit   = true,
      float_opts      = { border = "curved" },
      -- 0 keeps horizontal terminals splitting side by side (VS Code style)
      -- instead of stacking once the window gets narrow.
      responsiveness  = { horizontal_breakpoint = 0 },
      -- toggleterm's winbar draws clickable terminal tabs but no action buttons.
      -- config/terminal.lua replaces it with a VS Code style panel header that
      -- keeps the tabs and adds split / kill / hide, so this stays off to avoid
      -- both of them fighting over the same window option.
      winbar = { enabled = false },
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
        { "<leader>t", group = "terminal" },
      },
    },
  },
}
