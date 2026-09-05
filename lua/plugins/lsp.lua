-- Language servers (installed by Mason, wired up with nvim 0.11's built-in
-- vim.lsp.config/enable) and the IntelliSense dropdown (blink.cmp).
--
-- clangd is not on the Mason list: `brew install llvm` and put
-- /opt/homebrew/opt/llvm/bin on PATH, and it is picked up automatically.

local servers = {
  "lua_ls",
  "pyright",
  "ts_ls",
  "html",
  "cssls",
  "jsonls",
  "yamlls",
  "bashls",
  "dockerls",
}

return {
  {
    "mason-org/mason.nvim",
    opts = { ui = { border = "rounded", width = 0.8, height = 0.8 } },
  },

  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    -- Every installed server is enabled automatically. stylua is excluded: it is
    -- a formatter, and as a server it complains on every exit.
    opts = { ensure_installed = servers, automatic_enable = { exclude = { "stylua" } } },
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = { "saghen/blink.cmp" },
    config = function()
      vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            workspace = {
              checkThirdParty = false,
              library = { vim.env.VIMRUNTIME, "${3rd}/luv/library" },
            },
            diagnostics = { globals = { "vim" } },
            completion = { callSnippet = "Replace" },
          },
        },
      })

      vim.lsp.config("pyright", {
        settings = {
          python = {
            analysis = { autoSearchPaths = true, useLibraryCodeForTypes = true, diagnosticMode = "openFilesOnly" },
          },
        },
      })

      vim.lsp.config("yamlls", {
        settings = {
          yaml = {
            schemas = {
              ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = {
                "docker-compose*.yml",
                "docker-compose*.yaml",
                "compose*.yml",
                "compose*.yaml",
              },
              ["https://json.schemastore.org/github-workflow.json"] = ".github/workflows/*.yml",
            },
          },
        },
      })

      if vim.fn.executable("clangd") == 1 then
        vim.lsp.config("clangd", { cmd = { "clangd", "--background-index", "--clang-tidy" } })
        vim.lsp.enable("clangd")
      end

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp.attach", { clear = true }),
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
          end
          local fzf = function(name)
            return function()
              require("fzf-lua")[name]({ jump1 = true })
            end
          end

          map("n", "K", vim.lsp.buf.hover, "Hover")
          map("n", "gd", fzf("lsp_definitions"), "Go to Definition")
          map("n", "gD", vim.lsp.buf.declaration, "Go to Declaration")
          map("n", "gr", fzf("lsp_references"), "Go to References")
          map("n", "gi", fzf("lsp_implementations"), "Go to Implementation")
          map("n", "gy", fzf("lsp_typedefs"), "Go to Type Definition")
          map("n", "<F12>", fzf("lsp_definitions"), "Go to Definition")
          map("n", "<S-F12>", fzf("lsp_references"), "Go to References")
          map("n", "<F2>", vim.lsp.buf.rename, "Rename Symbol")
          map({ "n", "v" }, "<D-.>", vim.lsp.buf.code_action, "Quick Fix")
          map({ "n", "v" }, "<M-CR>", vim.lsp.buf.code_action, "Quick Fix")
          map({ "n", "i" }, "<D-LeftMouse>", "<LeftMouse><cmd>lua vim.lsp.buf.definition()<cr>", "Go to Definition")

          -- highlight other uses of the symbol under the cursor, like VS Code
          if client and client:supports_method("textDocument/documentHighlight") then
            local group = vim.api.nvim_create_augroup("lsp.highlight." .. ev.buf, { clear = true })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              group = group,
              buffer = ev.buf,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufLeave" }, {
              group = group,
              buffer = ev.buf,
              callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })
    end,
  },

  {
    "saghen/blink.cmp",
    version = "1.*",
    opts = {
      keymap = {
        preset = "none",
        ["<Down>"] = { "select_next", "fallback" },
        ["<Up>"] = { "select_prev", "fallback" },
        ["<C-n>"] = { "select_next", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
        ["<Tab>"] = { "accept", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
        ["<Esc>"] = { "hide", "fallback" },
        ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-d>"] = { "scroll_documentation_down", "fallback" },
        ["<C-u>"] = { "scroll_documentation_up", "fallback" },
      },
      appearance = { nerd_font_variant = "mono" },
      completion = {
        menu = { border = "rounded" },
        documentation = { auto_show = true, auto_show_delay_ms = 200, window = { border = "rounded" } },
        ghost_text = { enabled = false },
        list = { selection = { preselect = true, auto_insert = false } },
      },
      signature = { enabled = true, window = { border = "rounded" } },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
  },
}
