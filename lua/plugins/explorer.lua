-- File tree (neo-tree), set up to behave like the VS Code explorer: single
-- click opens, files are coloured by git state, ignored files are dimmed,
-- deletes go to the Trash.

---Move a path to the macOS Trash. Returns false if that failed.
---@param path string
---@return boolean
local function trash(path)
  local cmd
  if vim.fn.executable("trash") == 1 then
    cmd = { "trash", path } -- ships with macOS 14+, no permission prompt
  elseif vim.fn.executable("osascript") == 1 then
    cmd = {
      "osascript",
      "-e",
      "on run argv",
      "-e",
      'tell application "Finder" to delete POSIX file (item 1 of argv)',
      "-e",
      "end run",
      path,
    }
  else
    return false
  end
  local result = vim.system(cmd, { text = true }):wait(10000)
  return result.code == 0
end

local commands = {
  ---Single click: files open, folders fold. The root line is left alone.
  click = function(state)
    local node = state.tree:get_node()
    if not node then
      return
    end
    local fs = require("neo-tree.sources.filesystem.commands")
    if node.type == "directory" then
      if node:get_depth() > 1 then
        fs.toggle_node(state)
      end
    else
      fs.open(state)
    end
  end,

  ---Delete to the Trash, with a confirmation like VS Code's.
  delete = function(state)
    local node = state.tree:get_node()
    if not node or node.type == "message" then
      return
    end
    if vim.fn.confirm(("Move '%s' to the Trash?"):format(node.name), "&Move to Trash\n&Cancel", 2, "Question") ~= 1 then
      return
    end
    if not trash(node.path) then
      -- no Finder (ssh, Linux): fall back to neo-tree's permanent delete
      require("neo-tree.sources.filesystem.commands").delete(state)
      return
    end
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local name = vim.api.nvim_buf_get_name(buf)
      if name == node.path or vim.startswith(name, node.path .. "/") then
        require("ui.windows").close_buffer(buf, { force = true })
      end
    end
    require("neo-tree.sources.manager").refresh("filesystem")
  end,

  copy_path = function(state)
    local node = state.tree:get_node()
    if node then
      vim.fn.setreg("+", node.path)
      vim.notify("Copied " .. node.path)
    end
  end,

  copy_relative_path = function(state)
    local node = state.tree:get_node()
    if node then
      local rel = vim.fn.fnamemodify(node.path, ":.")
      vim.fn.setreg("+", rel)
      vim.notify("Copied " .. rel)
    end
  end,

  reveal_in_finder = function(state)
    local node = state.tree:get_node()
    if node then
      vim.fn.jobstart({ "open", "-R", node.path }, { detach = true })
    end
  end,

  open_with_system = function(state)
    local node = state.tree:get_node()
    if node then
      vim.ui.open(node.path)
    end
  end,

  focus_editor = function()
    require("ui.windows").goto_editor()
  end,
}

return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    close_if_last_window = false,
    popup_border_style = "rounded",
    enable_git_status = true,
    enable_diagnostics = true,
    sort_case_insensitive = true,
    -- never open a file into the terminal panel or a help/quickfix window
    open_files_do_not_replace_types = { "terminal", "qf", "help", "problems" },
    default_component_configs = {
      container = { enable_character_fade = true },
      indent = {
        indent_size = 2,
        padding = 1,
        with_markers = false,
        with_expanders = true,
        expander_collapsed = "\u{eab6}", -- codicon chevron-right
        expander_expanded = "\u{eab4}", -- codicon chevron-down
        expander_highlight = "NeoTreeExpander",
      },
      icon = {
        folder_closed = "\u{ea83}", -- codicon folder
        folder_open = "\u{eaf7}", -- codicon folder-opened
        folder_empty = "\u{ea83}",
        default = "\u{ea7b}", -- codicon file
      },
      modified = { symbol = "●" },
      name = { trailing_slash = false, use_git_status_colors = true },
      git_status = {
        symbols = {
          added = "A",
          modified = "M",
          deleted = "D",
          renamed = "R",
          untracked = "U",
          ignored = "",
          unstaged = "",
          staged = "",
          conflict = "!",
        },
      },
    },
    window = {
      position = "left",
      width = require("ui.windows").tree_width,
      mappings = {
        ["<LeftRelease>"] = "click",
        ["<2-LeftMouse>"] = "open",
        ["<cr>"] = "open",
        ["<Right>"] = "open",
        ["<Left>"] = "close_node",
        ["<Esc>"] = "focus_editor",
        ["<F2>"] = "rename",
        ["<Del>"] = "delete",
        ["d"] = "delete",
        ["n"] = { "add", config = { show_path = "relative" } },
        ["a"] = { "add", config = { show_path = "relative" } },
        ["A"] = { "add_directory", config = { show_path = "relative" } },
        ["r"] = "rename",
        ["y"] = "copy_to_clipboard",
        ["x"] = "cut_to_clipboard",
        ["p"] = "paste_from_clipboard",
        ["c"] = { "copy", config = { show_path = "relative" } },
        ["m"] = { "move", config = { show_path = "relative" } },
        ["Y"] = "copy_path",
        ["gy"] = "copy_relative_path",
        ["O"] = "reveal_in_finder",
        ["o"] = "open_with_system",
        ["R"] = "refresh",
        ["H"] = "toggle_hidden",
        ["Z"] = "close_all_nodes",
        ["q"] = "close_window",
        ["<C-b>"] = "close_window",
        ["<D-b>"] = "close_window",
        ["?"] = "show_help",
        ["<C-t>"] = "none",
        ["t"] = "none",
      },
    },
    filesystem = {
      commands = commands,
      filtered_items = {
        visible = true, -- show hidden and ignored files, dimmed
        hide_dotfiles = false,
        hide_gitignored = true,
        never_show = { ".git", ".DS_Store" },
        -- Editor debris: swap files, `:recover` output, merge and patch leftovers.
        -- `never_show_*` wins over `visible = true`, so these stay out of the tree
        -- even with hidden files shown.
        never_show_by_pattern = {
          "*.recovered",
          "*.sw[a-p]",
          "*.un~",
          "*~",
          "*.orig",
          "*.rej",
        },
      },
      follow_current_file = { enabled = true, leave_dirs_open = false },
      group_empty_dirs = true, -- VS Code's "compact folders"
      hijack_netrw_behavior = "disabled",
      use_libuv_file_watcher = true,
      bind_to_cwd = true,
    },
  },
}
