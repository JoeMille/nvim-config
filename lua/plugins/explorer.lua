-- File tree: snacks.nvim explorer, tuned to behave like the VS Code sidebar.
-- neo-tree stays disabled (see editor.lua) — this is one picker engine instead
-- of a second tree plugin, so it costs nothing extra at startup.
return {
  {
    "folke/snacks.nvim",
    opts = {
      explorer = {
        replace_netrw = true, -- `nvim .` / `:e some/dir` opens the tree
        trash = true, -- deletes go to macOS Trash, not oblivion
      },
      picker = {
        sources = {
          explorer = {
            -- VS Code shows dotfiles and greys out gitignored files rather than
            -- hiding them. `ignored` is what was hiding your .gitignore'd files;
            -- they now render with the NonText highlight (dimmed), same as VS Code.
            hidden = true,
            ignored = true,

            -- Stuff VS Code hides via files.exclude anyway.
            exclude = { ".git", ".DS_Store" },

            -- Decorations: git state, untracked files, LSP errors/warnings, and
            -- roll both up onto collapsed parent folders like VS Code badges do.
            git_status = true,
            git_status_open = true,
            git_untracked = true,
            diagnostics = true,
            diagnostics_open = true,

            follow_file = true, -- auto-reveal the file you're editing
            watch = true, -- pick up changes made outside nvim
            auto_close = false, -- stays open when you jump to a file
            jump = { close = false },
            focus = "list", -- land on the tree, not the filter box
            layout = {
              preset = "sidebar",
              preview = false,
              layout = { position = "left", width = 34, min_width = 34 },
            },
            win = {
              list = {
                keys = {
                  -- VS Code muscle memory on top of the snacks defaults
                  -- (a=add, d=delete, r=rename, c=copy, m=move, y=yank, p=paste,
                  --  o=open in Finder, Z=collapse all, ]g/[g=next/prev git change)
                  ["<Right>"] = "confirm", -- expand dir / open file
                  ["<Left>"] = "explorer_close", -- collapse dir
                  ["<F2>"] = "explorer_rename",
                  ["<Del>"] = "explorer_del",
                  ["n"] = "explorer_add", -- new file, trailing / makes a folder
                  ["<C-r>"] = "explorer_update", -- refresh
                  ["<C-b>"] = "close", -- Ctrl+B closes the tree again
                  ["<C-t>"] = false, -- don't shadow the terminal panel toggle
                },
              },
            },
          },
        },
      },
    },
  },
}
