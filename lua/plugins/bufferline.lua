-- Editor tabs along the top, one per open file. Click to switch, click the ×
-- (shown on hover) or middle-click to close.
return {
  "akinsho/bufferline.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons", "catppuccin" },
  opts = function()
    local close = function(buf)
      require("ui.windows").close_buffer(buf)
    end
    local ok, catppuccin = pcall(require, "catppuccin.special.bufferline")
    return {
      options = {
        mode = "buffers",
        themable = true,
        numbers = "none",
        close_command = close,
        middle_mouse_command = close,
        right_mouse_command = function() end,
        indicator = { style = "none" },
        separator_style = "thin",
        show_buffer_close_icons = true,
        show_close_icon = false,
        always_show_bufferline = true,
        sort_by = "insert_after_current",
        hover = { enabled = true, delay = 150, reveal = { "close" } },
        diagnostics = "nvim_lsp",
        diagnostics_indicator = function(count)
          return " " .. count
        end,
        offsets = {
          {
            filetype = "neo-tree",
            text = function()
              return " " .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t"):upper()
            end,
            text_align = "left",
            highlight = "NeoTreeRootName",
            separator = true,
          },
        },
      },
      highlights = ok and catppuccin.get_theme() or nil,
    }
  end,
}
