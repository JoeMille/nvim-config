-- Git gutter: coloured bars for added/changed lines, a triangle where lines
-- were deleted. Same markers as VS Code.
return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    signs = {
      add = { text = "▎" },
      change = { text = "▎" },
      delete = { text = "▸" },
      topdelete = { text = "▸" },
      changedelete = { text = "▎" },
      untracked = { text = "▎" },
    },
    signs_staged_enable = false,
    current_line_blame = false,
    preview_config = { border = "rounded" },
    on_attach = function(buf)
      local gs = require("gitsigns")
      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
      end
      map("n", "]c", function()
        gs.nav_hunk("next")
      end, "Next Change")
      map("n", "[c", function()
        gs.nav_hunk("prev")
      end, "Previous Change")
      map("n", "<leader>gp", gs.preview_hunk_inline, "Preview Change")
      map("n", "<leader>gr", gs.reset_hunk, "Revert Change")
      map("n", "<leader>gs", gs.stage_hunk, "Stage Change")
      map("n", "<leader>gb", function()
        gs.blame_line({ full = true })
      end, "Blame Line")
      map("n", "<leader>gd", gs.diffthis, "Diff File")
    end,
  },
}
