-- Editor actions that keymaps and the right-click menu share.
local api = vim.api
local M = {}

---Save the current file; ask for a name if it has none.
function M.save()
  if vim.bo.buftype ~= "" then
    return
  end
  if api.nvim_buf_get_name(0) == "" then
    local path = vim.fn.input({ prompt = "Save as: ", completion = "file" })
    if path ~= "" then
      vim.cmd.write(vim.fn.fnameescape(path))
    end
    return
  end
  vim.cmd("update")
end

---Format with the language server, or reindent when there is none.
function M.format()
  if #vim.lsp.get_clients({ bufnr = 0, method = "textDocument/formatting" }) > 0 then
    vim.lsp.buf.format({ async = true })
    return
  end
  local view = vim.fn.winsaveview()
  vim.cmd("silent normal! gg=G")
  vim.fn.winrestview(view)
end

---Leave insert or terminal mode. For actions that switch windows.
function M.normal_mode()
  local mode = api.nvim_get_mode().mode:sub(1, 1)
  if mode == "i" or mode == "t" then
    vim.cmd("stopinsert")
  end
end

return M
