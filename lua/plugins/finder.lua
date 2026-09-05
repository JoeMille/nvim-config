-- Quick open (Cmd+P), search in files (Cmd+Shift+F), command palette
-- (Cmd+Shift+P) and the picker behind every "choose one" prompt.
return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    winopts = {
      height = 0.6,
      width = 0.65,
      row = 0.3,
      col = 0.5,
      border = "rounded",
      backdrop = 100,
      preview = {
        border = "rounded",
        layout = "flex",
        flip_columns = 140,
        scrollbar = false,
      },
    },
    fzf_colors = true,
    fzf_opts = { ["--layout"] = "reverse", ["--info"] = "inline-right" },
    keymap = {
      builtin = {
        ["<F1>"] = "toggle-help",
        ["<C-d>"] = "preview-page-down",
        ["<C-u>"] = "preview-page-up",
      },
      fzf = {
        ["ctrl-q"] = "select-all+accept",
        ["ctrl-a"] = "toggle-all",
      },
    },
    files = {
      prompt = "Files  ",
      previewer = false,
      cwd_prompt = false,
      git_icons = false,
      formatter = "path.filename_first",
    },
    oldfiles = { prompt = "Recent  ", previewer = false, cwd_only = true, include_current_session = true },
    buffers = { prompt = "Open  ", previewer = false },
    grep = { prompt = "Search  ", rg_glob = true },
    commands = { prompt = "Command  " },
    keymaps = { prompt = "Keys  " },
    lsp = { symbols = { symbol_style = 3 } },
    diagnostics = { prompt = "Problems  " },
  },
  config = function(_, opts)
    local fzf = require("fzf-lua")
    fzf.setup(opts)
    fzf.register_ui_select()
  end,
}
