-- Syntax highlighting. The `main` branch installs parsers with the tree-sitter
-- CLI (Mason has it; mason.nvim puts its bin dir on PATH first).
local languages = {
  "bash",
  "c",
  "cpp",
  "css",
  "diff",
  "dockerfile",
  "html",
  "javascript",
  "jsdoc",
  "json",
  "lua",
  "luadoc",
  "markdown",
  "markdown_inline",
  "python",
  "query",
  "regex",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "xml",
  "yaml",
}

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  -- Pinned: `main` dropped nvim 0.11 in April 2026 (c82bf96f). This is the last
  -- commit the parsers in ~/.local/share/nvim/site/parser were built with.
  -- Drop the pin once nvim is on 0.12.
  commit = "493890b87a81dfe6a7e577dbc364ae33fa482da9",
  build = ":TSUpdate",
  dependencies = { "mason-org/mason.nvim" },
  config = function()
    local ts = require("nvim-treesitter")
    ts.setup({})
    vim.schedule(function()
      ts.install(languages)
    end)

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("treesitter.start", { clear = true }),
      callback = function(ev)
        -- skip huge files; regex highlighting is fine there
        local size = vim.fn.getfsize(vim.api.nvim_buf_get_name(ev.buf))
        if size > 2 * 1024 * 1024 then
          return
        end
        local lang = vim.treesitter.language.get_lang(ev.match) or ev.match
        pcall(vim.treesitter.start, ev.buf, lang)
      end,
    })
  end,
}
