local api = vim.api
local group = api.nvim_create_augroup("core.autocmds", { clear = true })

local function autocmd(event, opts)
  opts.group = group
  api.nvim_create_autocmd(event, opts)
end

-- ── Startup layout: tree on the left, terminal panel below, cursor in the editor
local reading_stdin = false
autocmd("StdinReadPre", {
  callback = function()
    reading_stdin = true
  end,
})

autocmd("VimEnter", {
  once = true,
  callback = function()
    local first = vim.fn.argv(0) --[[@as string]]
    -- git commit messages, diffs and piped input want a plain editor
    if reading_stdin or vim.o.diff or first:match("COMMIT_EDITMSG$") or first:match("git%-rebase%-todo$") then
      return
    end

    local file
    if first ~= "" then
      if vim.fn.isdirectory(first) == 1 then
        -- `nvim some/dir`: work there, and drop the buffer nvim made for the directory
        vim.cmd.cd(vim.fn.fnameescape(vim.fn.fnamemodify(first, ":p")))
        local buf = api.nvim_get_current_buf()
        if vim.fn.isdirectory(api.nvim_buf_get_name(buf)) == 1 then
          vim.cmd("enew")
          pcall(api.nvim_buf_delete, buf, { force = true })
        end
      else
        file = vim.fn.fnamemodify(first, ":p")
      end
    end

    vim.schedule(function()
      local cwd = vim.fn.getcwd()
      local inside = file and vim.startswith(file, cwd .. "/") or nil
      require("neo-tree.command").execute({
        action = "show",
        position = "left",
        reveal_file = inside and file or nil,
        reveal_force_cwd = false,
      })
      require("ui.panel").open({ focus = false })
      local editor = require("ui.windows").find_editor()
      if editor then
        api.nvim_set_current_win(editor)
      end
    end)
  end,
})

-- ── Editing niceties ─────────────────────────────────────────────────────────
autocmd("TextYankPost", {
  callback = function()
    vim.hl.on_yank({ timeout = 150 })
  end,
})

-- reopen a file where you left it
autocmd("BufReadPost", {
  callback = function(ev)
    if vim.bo[ev.buf].filetype == "gitcommit" then
      return
    end
    local mark = api.nvim_buf_get_mark(ev.buf, '"')
    if mark[1] > 0 and mark[1] <= api.nvim_buf_line_count(ev.buf) then
      pcall(api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- create missing folders on save
autocmd("BufWritePre", {
  callback = function(ev)
    if ev.match:match("^%w+://") then
      return
    end
    local dir = vim.fn.fnamemodify(ev.match, ":p:h")
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end
  end,
})

-- reload files changed outside nvim
autocmd({ "FocusGained", "BufEnter", "CursorHold", "TermLeave" }, {
  callback = function()
    if vim.fn.getcmdwintype() == "" and vim.bo.buftype == "" then
      vim.cmd("checktime")
    end
  end,
})

-- the problem under the cursor, shown when the cursor rests on it
autocmd("CursorHold", {
  callback = function()
    if vim.bo.buftype ~= "" or api.nvim_win_get_config(0).relative ~= "" then
      return
    end
    pcall(vim.diagnostic.open_float, nil, { focus = false, scope = "cursor" })
  end,
})

autocmd("VimResized", {
  callback = function()
    vim.cmd("wincmd =")
  end,
})

-- the toolbar across the top of the file tree (Files / Search / Replace)
autocmd("BufWinEnter", {
  callback = function(ev)
    if vim.bo[ev.buf].filetype == "neo-tree" then
      require("ui.sidebar").attach(ev.buf)
    end
  end,
})

-- ── Helper windows: not tabs, and q closes them ──────────────────────────────
autocmd("FileType", {
  pattern = { "help", "man", "qf", "checkhealth", "query", "lspinfo", "gitsigns-blame" },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = ev.buf, desc = "Close" })
  end,
})

autocmd("TermOpen", {
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
  end,
})
