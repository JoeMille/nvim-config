-- Catppuccin Mocha, matching the Ghostty theme, plus the highlight groups the
-- statusline (SL*) and terminal panel (Panel*) draw with.
return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  opts = {
    flavour = "mocha",
    term_colors = true,
    integrations = {
      blink_cmp = true,
      fzf = true,
      gitsigns = true,
      mason = true,
      mini = { enabled = true },
      neotree = true,
      treesitter = true,
      native_lsp = {
        enabled = true,
        underlines = {
          errors = { "undercurl" },
          hints = { "undercurl" },
          warnings = { "undercurl" },
          information = { "undercurl" },
        },
      },
    },
    custom_highlights = function(c)
      return {
        -- chrome
        WinSeparator = { fg = c.surface0, bg = c.base },
        StatusLine = { fg = c.subtext0, bg = c.mantle },
        StatusLineNC = { fg = c.subtext0, bg = c.mantle },
        TabLineFill = { bg = c.mantle },
        FloatBorder = { fg = c.surface1, bg = c.base },
        NormalFloat = { bg = c.base },
        LspReferenceText = { bg = c.surface0 },
        LspReferenceRead = { bg = c.surface0 },
        LspReferenceWrite = { bg = c.surface0 },

        -- statusline
        SLNormal = { fg = c.base, bg = c.blue, bold = true },
        SLInsert = { fg = c.base, bg = c.green, bold = true },
        SLVisual = { fg = c.base, bg = c.mauve, bold = true },
        SLReplace = { fg = c.base, bg = c.red, bold = true },
        SLCommand = { fg = c.base, bg = c.peach, bold = true },
        SLTerminal = { fg = c.base, bg = c.teal, bold = true },
        SLError = { fg = c.red, bg = c.mantle },
        SLWarn = { fg = c.yellow, bg = c.mantle },

        -- terminal panel
        PanelNormal = { fg = c.text, bg = c.base },
        PanelBarActive = { fg = c.text, bg = c.base },
        PanelBar = { fg = c.overlay1, bg = c.base },
        PanelBtn = { fg = c.overlay1, bg = c.base },

        -- the toolbar across the top of the file tree
        SidebarBar = { bg = c.mantle },
        SidebarBtn = { fg = c.subtext0, bg = c.mantle },

        -- panel tabs and the AI dock header
        PanelTabActive = { fg = c.text, bg = c.base, bold = true },
        PanelTab = { fg = c.overlay0, bg = c.base },

        -- problems list
        ProblemsFile = { fg = c.subtext0, bold = true },
        ProblemsCount = { fg = c.overlay0 },
        ProblemsPos = { fg = c.overlay1 },
        ProblemsSource = { fg = c.overlay0, italic = true },

        -- file tree: VS Code colours for git state
        NeoTreeRootName = { fg = c.subtext0, bold = true },
        NeoTreeGitAdded = { fg = c.green },
        NeoTreeGitUntracked = { fg = c.green },
        NeoTreeGitModified = { fg = c.yellow },
        NeoTreeGitDeleted = { fg = c.red },
        NeoTreeGitConflict = { fg = c.red },
        NeoTreeGitIgnored = { fg = c.overlay0 },
        NeoTreeDimText = { fg = c.overlay0 },
        NeoTreeIndentMarker = { fg = c.surface1 },
        NeoTreeWinSeparator = { fg = c.surface0, bg = c.mantle },
      }
    end,
  },
  config = function(_, opts)
    require("catppuccin").setup(opts)

    ---Catppuccin defines 24-bit colours only. In a terminal without truecolor it
    ---renders as flat unhighlighted text, so fall back to habamax, which ships
    ---with nvim and defines cterm colours for every syntax and treesitter group.
    local function apply()
      vim.cmd.colorscheme(vim.o.termguicolors and "catppuccin" or "habamax")
    end

    apply()

    -- nvim asks the terminal about truecolor support during startup and may turn
    -- 'termguicolors' on after this runs. Follow it, so a terminal the check in
    -- core/options.lua does not recognise still ends up on the full palette.
    vim.api.nvim_create_autocmd("OptionSet", {
      group = vim.api.nvim_create_augroup("theme.colordepth", { clear = true }),
      pattern = "termguicolors",
      callback = function()
        vim.schedule(apply)
      end,
    })

    if not vim.o.termguicolors then
      vim.schedule(function()
        vim.notify(
          "This terminal has no 24-bit colour, so the 256-colour theme is in use. Ghostty gives the full palette.",
          vim.log.levels.WARN
        )
      end)
    end
  end,
}
