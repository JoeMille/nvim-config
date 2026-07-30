return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "stylua", "prettier", "black", "isort", "clang-format",
        "eslint_d", "pylint", "flake8", "shellcheck", "hadolint",
      },
    },
  },

  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      -- clangd installed via: brew install llvm (add /opt/homebrew/opt/llvm/bin to PATH)
      skip_install = { "clangd" },
    },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          settings = {
            python = {
              analysis = {
                autoSearchPaths        = true,
                useLibraryCodeForTypes = true,
                diagnosticMode         = "workspace",
              },
            },
          },
        },
        ts_ls  = {},
        eslint = {},
        clangd = {
          cmd   = { "clangd", "--background-index", "--clang-tidy" },
          mason = false,
        },
        yamlls = {
          settings = {
            yaml = {
              schemas = {
                ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = {
                  "docker-compose*.yml", "docker-compose*.yaml",
                  "compose*.yml", "compose*.yaml",
                },
                ["https://json.schemastore.org/github-workflow.json"] = ".github/workflows/*.yml",
              },
              validate   = true,
              hover      = true,
              completion = true,
            },
          },
        },
        dockerls                       = {},
        docker_compose_language_service = {},
        html   = {},
        cssls  = {},
        jsonls = {},
        lua_ls = {
          settings = {
            Lua = { diagnostics = { globals = { "vim", "Snacks" } } },
          },
        },
        bashls = {},
      },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      -- LazyVim declares opts_extend for this key, so these are added to its own
      -- default list rather than replacing it.
      -- No "jsonc": it is not a parser on the nvim-treesitter main branch (there
      -- are no jsonc queries and it isn't in the registry) — the json parser
      -- covers jsonc, which is why it never appeared in site/parser.
      ensure_installed = {
        "bash", "c", "cpp", "css", "dockerfile",
        "html", "javascript", "json",
        "lua", "markdown", "markdown_inline",
        "python", "regex", "toml",
        "tsx", "typescript",
        "vim", "vimdoc", "xml", "yaml",
      },
      -- lazyvim.TSFeat shape; LazyVim reads these to decide whether to call
      -- vim.treesitter.start() and set indentexpr per filetype.
      -- auto_install is deliberately absent: neither LazyVim's spec nor the
      -- main branch reads it, so it was inert.
      highlight = { enable = true },
      indent    = { enable = true },
    },
  },

  {
    "stevearc/conform.nvim",
    opts = {
      format_on_save = { timeout_ms = 1000, lsp_fallback = true },
      formatters_by_ft = {
        python          = { "black", "isort" },
        javascript      = { "prettier" },
        typescript      = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        html            = { "prettier" },
        css             = { "prettier" },
        json            = { "prettier" },
        yaml            = { "prettier" },
        markdown        = { "prettier" },
        lua             = { "stylua" },
        c               = { "clang_format" },
        cpp             = { "clang_format" },
      },
    },
  },

  {
    "folke/trouble.nvim",
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>",              desc = "Problems Panel" },
      { "<leader>xf", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "File Problems" },
    },
  },

  {
    "windwp/nvim-ts-autotag",
    event = "LazyFile",
    opts  = {},
  },
}
