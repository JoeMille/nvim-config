# nvim-config

A small VS Code, inside Neovim: file tree on the left, a panel of terminals and
a Problems list along the bottom, an AI assistant docked on the right, tabs
across the top, and the keyboard and mouse behaviour you expect from an ordinary
editor. 16 plugins, no framework.

```
┌ EXPLORER ──────────────┬ tabs ───────────────────────────────────┬ Claude · Codex ───┐
│ Files  Search  Replace │ init.lua ×  README.md ×                 │ > explain this    │
│ nvim-config            ├─────────────────────────────────────────┤   function…       │
│  lua/                  │                                         │                   │
│   core/                │            editor                       │ The loop on       │
│   ui/                  │                                         │ line 42 …         │
│  init.lua              ├ ⚠ Problems ───┬ 1: zsh ───────── ⊞ 🗑 ⌄ ┤                   │
│  README.md             │ main.py  2    │ ~/nvim-config $         │                   │
│                        │  ✖ 12:5 …     │                         │                   │
├────────────────────────┴───────────────┴─────────────────────────┴───────────────────┤
│ NORMAL  main  ⊗ 1 ⚠ 0  init.lua        Ln 1, Col 1  Spaces: 4                        │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

## Requirements

- Neovim 0.11+
- [Ghostty](https://ghostty.org) — the only macOS terminal that both renders
  truecolor and delivers Cmd+key presses to nvim. `~/.config/ghostty/config`
  releases the Cmd combos Ghostty would otherwise keep for itself.

  **Run nvim in Ghostty, not Terminal.app.** Terminal.app has no 24-bit colour,
  so the catppuccin palette cannot render there and Cmd shortcuts never arrive.
  The config detects this and falls back to the 256-colour `habamax` theme so
  syntax highlighting still works, but the full palette needs Ghostty.
- A Nerd Font (JetBrainsMono Nerd Font is installed and set in Ghostty)
- `ripgrep`, `fd`, `fzf` (`brew install ripgrep fd fzf`) for the pickers
- `claude` and/or `codex` on your PATH for the AI dock. Neither is required:
  the dock reports a missing command and stays closed.
- `tree-sitter` CLI only when adding a new syntax parser (Mason installs it)
- Language servers install themselves through Mason on first start.
  `clangd` is the exception: `brew install llvm` and put
  `/opt/homebrew/opt/llvm/bin` on your PATH.

Clone to `~/.config/nvim` (or symlink it there) and start `nvim`. Plugins
install on the first launch.

## Keys

Every Cmd shortcut has a Ctrl twin for terminals that cannot send Cmd
(Terminal.app, iTerm2, ssh). Space is the leader for the same actions without
either.

### Files and search

| Action                | Cmd            | Ctrl / other        | Leader      |
| --------------------- | -------------- | ------------------- | ----------- |
| Save                  | `⌘S`           | `^S`                | `␣w`        |
| Close tab / terminal  | `⌘W`           | `^W`                | `␣d`        |
| Go to file            | `⌘P` / `⌘O`    | `^P`                | `␣f`        |
| Search in files       | `⇧⌘F`          | `^⇧F`               | `␣g`        |
| Replace in files      | `⇧⌘H`          |                     | `␣R`        |
| Find in file          | `⌘F`           | `^F` (`/`)          |             |
| Command palette       | `⇧⌘P`          |                     | `␣c`        |
| Go to symbol          | `⇧⌘O`          |                     | `␣s`        |
| Problems              | `⇧⌘M`          |                     | `␣x`        |
| Problems (as a list)  |                |                     | `␣X`        |
| Recent files          |                |                     | `␣r`        |
| Open tabs             |                |                     | `␣b`        |
| New file              |                |                     | `␣n`        |
| Quit                  | `⌘Q` (Ghostty) |                     | `␣q`        |

### Editing

| Action                     | Keys                                          |
| -------------------------- | --------------------------------------------- |
| Undo / redo                | `⌘Z` / `⇧⌘Z`, `^Z` / `^Y`                     |
| Cut / copy / paste         | `⌘X` / `⌘C` / `⌘V`, `^X` / `^C` / `^V`         |
| Select all                 | `⌘A`, `^A`                                    |
| Select with the keyboard   | `⇧←→↑↓`, `⇧Home/End`                          |
| Toggle comment             | `⌘/`, `^/`                                    |
| Move line / selection      | `⌥↑` / `⌥↓`                                   |
| Duplicate line / selection | `⇧⌥↑` / `⇧⌥↓`                                 |
| Delete line                | `⇧⌘K`                                         |
| Select line                | `⌘L`                                          |
| Indent / outdent           | `⌘]` / `⌘[`, `Tab` / `⇧Tab` on a selection    |
| Format document            | `⇧⌥F`                                         |
| Line start / end           | `⌘←` / `⌘→`                                   |
| File start / end           | `⌘↑` / `⌘↓`                                   |
| Word left / right          | `⌥←` / `⌥→`                                   |
| Delete word / to line start| `⌥⌫` / `⌘⌫`                                   |
| Visual block mode          | `^Q` (`^V` is paste)                          |

### Code

| Action              | Keys                              |
| ------------------- | --------------------------------- |
| Go to definition    | `F12`, `gd`, `⌘Click`             |
| Go to references    | `⇧F12`, `gr`                      |
| Rename symbol       | `F2`                              |
| Quick fix           | `⌘.`, `⌥Enter`                    |
| Hover documentation | `K`                               |
| Next / prev problem | `]d` / `[d`                       |
| Next / prev change  | `]c` / `[c`                       |
| Trigger suggestions | `^Space` (Enter/Tab accept)       |

Right-click opens a menu with the same code actions.

### Views

| Action                   | Cmd           | Ctrl / other          | Leader |
| ------------------------ | ------------- | --------------------- | ------ |
| Toggle explorer          | `⌘B`          | `^B`                  | `␣e`   |
| Focus explorer           | `⇧⌘E`         |                       | `␣E`   |
| Toggle panel             | `⌘J` / `⌘T`   |                       |        |
| Focus / hide panel       |               | `^T`, `` ^` ``         | `␣t`   |
| Split terminal           | `⌘D`          | `^\`                  | `␣T`   |
| Problems tab             | `⇧⌘M`         |                       | `␣x`   |
| AI assistant             | `⌘I`          |                       | `␣a`   |
| Ask about the selection  | `⌘I` in visual|                       | `␣a`   |
| Switch assistant         |               |                       | `␣A`   |
| Split editor             | `⌘\`          |                       |        |
| Go to tab 1–9            | `⌘1`–`⌘9`     |                       | `␣1`–`␣9` |
| Next / previous tab      | `⇧⌘]` / `⇧⌘[` | `^Tab`, `L` / `H`     |        |
| Move between windows     |               | `^←↑↓→`, `^hjkl`      |        |
| Leave terminal mode      |               | `Esc Esc`             |        |
| Plugins / language servers |             |                       | `␣l` / `␣m` |

### The explorer toolbar

The top of the file tree carries three buttons — **Files**, **Search**,
**Replace** — that do what `⌘P`, `⇧⌘F` and `⇧⌘H` do from the keyboard. They are
there so the mouse can reach them and so the keys are visible; whatever they
open lands in the editor, never in the sidebar.

### Find and replace

`⇧⌘H` opens the search view as a full-height column between the tree and the
editor, the way VS Code keeps Search in the sidebar. Type a search and a
replacement and the matches appear underneath, grouped by file, updating as you
type; the *Files Filter*, *Flags* and *Paths* inputs narrow it further. With a
selection, `⇧⌘H` starts a fresh search prefilled from it.

Inside the view the leader is the local leader, so `␣r` replaces everywhere,
`␣s` writes the edited results back, `␣q` sends them to the quickfix list and
`g?` lists every key. `⌘W` hides the view and keeps the search for next time.

### In the explorer

Click a file to open it, click a folder to fold it. `n`/`a` new file
(end with `/` for a folder), `r`/`F2` rename, `d`/`Del` move to Trash,
`y`/`x`/`p` copy/cut/paste, `Y` copy path, `O` reveal in Finder, `o` open with
the default app, `H` show/hide hidden files, `R` refresh, `?` all keys.

### In the panel

Each shell has a header with its name and three buttons: split, kill, hide.
Hiding keeps the shells running; closing the last shell closes the panel.
Files never open inside the panel, even when you use a picker from a shell.

### The Problems tab

`⇧⌘M` puts every diagnostic the language servers have reported into the panel,
grouped by file, and follows them as you type. Click a line or press Enter to
jump to it, `q` closes the tab. Pressing `⇧⌘M` again from inside the tab closes
it; from anywhere else it focuses it. `␣X` searches the same problems in fzf
instead.

### The AI dock

`⌘I` opens Claude Code or Codex in a full-height terminal down the right-hand
side, the way the chat sidebar sits in VS Code. The header switches between the
two; both keep running while the dock is hidden, and `⌘W` only hides it — the
trash button is what ends a session.

With a selection, `⌘I` hands the selected lines over instead: they arrive as a
bracketed paste tagged with the file and line numbers, and nothing is submitted
until you press Enter, so you can type the question after the code. The
right-click menu has *Ask the AI*, which sends the current line together with
any problem reported on it. To run a different CLI, add it to `providers` in
`lua/ui/dock.lua`.

## Layout of this repo

```
init.lua                  entry point
lua/core/options.lua      editor options and diagnostics look
lua/core/lazy.lua         plugin manager bootstrap
lua/core/keymaps.lua      every keymap and the right-click menu
lua/core/autocmds.lua     startup layout, yank flash, reload-on-change, …
lua/ui/sidebar.lua        the toolbar across the top of the file tree
lua/ui/search.lua         opens find-and-replace beside the tree
lua/ui/panel.lua          the bottom panel: terminals and the Problems tab
lua/ui/problems.lua       the Problems list
lua/ui/dock.lua           the AI assistant dock (Claude / Codex)
lua/ui/statusline.lua     the status bar
lua/ui/windows.lua        editor-window helpers, close-tab logic
lua/ui/edit.lua           save / format actions
lua/plugins/theme.lua     catppuccin + the highlight groups the UI uses
lua/plugins/explorer.lua  neo-tree
lua/plugins/bufferline.lua tabs
lua/plugins/finder.lua    fzf-lua pickers
lua/plugins/search.lua    grug-far find and replace
lua/plugins/lsp.lua       mason, language servers, blink.cmp completion
lua/plugins/treesitter.lua syntax highlighting
lua/plugins/git.lua       gitsigns gutter
lua/plugins/editing.lua   auto-pairs
```
