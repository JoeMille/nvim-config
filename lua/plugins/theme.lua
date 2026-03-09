return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = false,
      term_colors = true,
      integrations = {
        blink_cmp = true,
        bufferline = true,
        gitsigns = true,
        lsp_trouble = true,
        mason = true,
        noice = true,
        snacks = true,
        treesitter = true,
        which_key = true,
        copilot_vim = true,
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "catppuccin" },
  },
}
    },
  },
}
