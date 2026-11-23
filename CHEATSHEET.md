# Vim Config Cheatsheet

**Leader key = `Space`** (so `<leader>f` means press `Space` then `f`).

Mappings marked **(default)** come from a plugin; the rest are defined in `.vimrc`.

> 💡 Press **`<leader>?`** inside Vim at any time to open this cheatsheet in a new tab.

---

## Quick reference

| Key | Action |
|---|---|
| `<leader>f` | Find a file (fzf) and open it here |
| `<leader>g` | Find a file and open it in a **new tab** |
| `<leader>v` | Find a file and open it in a **vertical split** |
| `<leader>s` | Find a file and open it in a **horizontal split** |
| `<leader>b` | Switch between open buffers |
| `<leader>/` | Search the contents of every file in the project (ripgrep) |
| `<C-t>` | Toggle the file tree (netrw) |
| `<C-h/j/k/l>` | Move to the pane left / below / above / right |
| `<leader>z` | Zoom the current pane to full screen / restore |
| `<F9>` / `<F10>` | Previous / next tab |
| `<leader>t` | New tab |
| `<C-/>` | Toggle comment on the line / selection |
| `<leader>l…` | Language tools (ALE), see below |
| `<leader>G` | Git status (fugitive) |
| `<leader>u` | Undo history tree |
| `<leader>m` | Markdown preview (markdown files only) |
| `<leader>?` | This cheatsheet |

---

## Setup

Run **`./install_dependencies.sh`** from the repo. It installs clangd, clang-format,
ripgrep and glow, links `~/.vimrc`, runs `:PlugInstall` and puts
`project_harness.sh` on your PATH.

**clangd needs a `compile_commands.json`** at or above the file, or types from other
headers show as undeclared. Projects made with `project_harness.sh` already get one
(`build.sh` links it). Otherwise:

| Build system | How to produce `compile_commands.json` |
|---|---|
| CMake | `cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON` then `ln -s build/compile_commands.json .` |
| Make / other | `sudo apt install bear`, then `bear -- make` |
| None | a `compile_flags.txt` at the project root, one flag per line (e.g. `-std=c++20`) |

After generating it, reopen Vim or run `:ALEStopAllLSPs` and `:e`. Check with `:ALEInfo`.

---

## Files & navigation

### fzf (fuzzy finder)
| Key / Command | Action |
|---|---|
| `<leader>f` / `g` / `v` / `s` | Find file → open here / new tab / vsplit / split |
| `<leader>b` | `:Buffers` |
| `<leader>/` | `:Rg` — live ripgrep search across the project |
| `:History` | Recently opened files |
| `:BLines` | Search lines in the current buffer |
| `:Commits` / `:BCommits` | Browse git commits / commits for current file |
| `<C-t>` / `<C-x>` / `<C-v>` | Open selection in tab / split / vsplit **(inside fzf)** |
| `<Tab>` | Multi-select **(inside fzf)** |

### File tree (netrw, built in)
| Key | Action |
|---|---|
| `<C-t>` | Toggle the tree on the left |
| `<CR>` | Open file / expand directory |
| `-` | Go up to the parent directory |
| `%` / `d` | New file / new directory |
| `D` / `R` | Delete / rename |
| `gh` | Toggle hidden files |
| `I` | Show the netrw help banner |

Files open in the window you were in before the tree. To refresh the tree, press `<C-t>` twice.

### Windows, splits & tabs
| Key | Action |
|---|---|
| `<C-h>` / `<C-j>` / `<C-k>` / `<C-l>` | Move to the pane left / below / above / right |
| `<leader>z` | Zoom the current pane to full screen; press again to restore |
| `<F9>` / `<F10>` | Previous / next tab (also works in insert mode) |
| `<leader>t` | New tab |
| `:vsplit` / `:split` | Split the current file vertically / horizontally |
| `<C-w>q` | Close the current pane |
| `<C-w>=` | Equalise pane sizes |
| `<C-w>N` | In a **terminal** pane (e.g. the glow preview): Terminal-Normal mode, to scroll |

Mouse is enabled, so you can also click into a pane, drag borders and scroll.

---

## Code intelligence — ALE (`<leader>l` = "language")

| Key | Action |
|---|---|
| `<leader>ll` | Toggle ALE on / off |
| `<leader>lh` | Hover info (type, docs) |
| `<leader>ld` | Go to definition |
| `<leader>lt` | Go to type definition |
| `<leader>lr` | List references |
| `<leader>lR` | Rename the symbol under the cursor |
| `<leader>ln` / `<leader>lp` | Next / previous problem (error or warning) |
| `<leader>le` | Explain the problem under the cursor (full message) |
| `<leader>lf` | Fix: trim trailing whitespace / blank lines |
| `<C-o>` | Jump back after going to a definition (built in) |
| `<C-x><C-o>` | LSP completion (also pops up automatically as you type) |
| `:ALEInfo` | Show ALE status / which linters ran |

Gutter signs: `E>` = error, `W>` = warning. Wired for **C/C++** (clangd).

---

## Git

| Key / Command | Action |
|---|---|
| `<leader>G` | Git status window (fugitive) |
| `s` / `u` / `=` / `cc` | In the status window: stage / unstage / show diff / commit **(default)** |
| `:Git push` / `:Git log` / `:Git blame` | Any git command, run from inside Vim |
| `:Gdiffsplit` | Diff the current file against the index |
| `]c` / `[c` | Next / previous changed hunk **(default)** |
| `<leader>hp` | Preview hunk under cursor **(default)** |
| `<leader>hs` | Stage hunk **(default)** |
| `<leader>hu` | Undo hunk **(default)** |

---

## Editing

### Comments (vim-commentary)
| Key | Action |
|---|---|
| `<C-/>` | Toggle comment on the current line, or on the selection (visual mode) |
| `gc{motion}` | Comment a motion, e.g. `gcap` (paragraph) **(default)** |

### Multiple cursors (vim-visual-multi)
| Key | Action |
|---|---|
| `<C-n>` | Select the word under the cursor; press again to add the next match **(default)** |
| `<C-Down>` / `<C-Up>` | Add a cursor on the line below / above **(default)** |
| `<leader>a` | Select every match of the word under the cursor |
| `n` / `N` | (in VM mode) next / previous match **(default)** |
| `q` | (in VM mode) skip the current match and go to the next **(default)** |
| `<Esc>` | Exit multi-cursor mode **(default)** |

### auto-pairs
Brackets and quotes close automatically; deleting an opening one deletes its match. **(automatic)**

### vim-surround — surrounding pairs **(default)**
| Key | Action |
|---|---|
| `cs"'` | Change surrounding `"` to `'` |
| `ds(` | Delete surrounding `()` |
| `ysiw)` | Surround the word with `()` (use `(` for inner spaces) |
| `yss)` | Surround the whole line |
| `S)` | (visual mode) surround the selection |

### vim-unimpaired — paired bracket mappings **(default)**
| Key | Action |
|---|---|
| `]q` / `[q` | Next / previous quickfix item |
| `]b` / `[b` | Next / previous buffer |
| `]e` / `[e` | Move the current line down / up |
| `]<Space>` / `[<Space>` | Add a blank line below / above |
| `yos` / `yow` | Toggle spell check / line wrap |

### vim-abolish — case tools **(default)**
| Key / Command | Action |
|---|---|
| `crs` / `crc` / `crm` / `cru` | Change word to snake_case / camelCase / MixedCase / UPPER_CASE |
| `:%S/foo/bar/g` | Case-preserving substitute (Foo→Bar, FOO→BAR, foo→bar) |

### vim-eunuch — file operations
`:Rename <new>` · `:Move <path>` · `:Delete` · `:Mkdir` · `:SudoWrite` · `:Chmod <mode>`

### Undo & repeat
| Key | Action |
|---|---|
| `<leader>u` | Toggle the undo-history tree (persistent across sessions) |
| `.` | Repeat the last change; works for surround/commentary too (vim-repeat) |

---

## Markdown (markdown files only)

| Key / Command | Action |
|---|---|
| `<leader>m` | Toggle a rendered preview (glow) in a split on the right; refreshes on save |
| `<leader>M` | Toggle inline rendering of the markup in the file itself |
| `:Toc` | Table of contents in a split |
| `:TableFormat` | Align the table under the cursor |
| `]]` / `[[` | Next / previous heading **(default)** |

glow keeps the `##` markers on H2+ headings deliberately (a terminal can't change
font size, so the `#` count shows the heading depth).

---

## Clipboard

This Vim is built without clipboard support (`-clipboard`), so `"+y` doesn't reach the
system clipboard. On native Linux, `sudo apt install vim-gtk3` gives a Vim with it.
Under **WSL**, the vim-wsl-copy-paste plugin is loaded instead:

| Key | Action |
|---|---|
| `cy{motion}` | Copy a motion to the Windows clipboard (e.g. `cyy` line) |
| `Y` | (visual) copy the selection to the Windows clipboard |
| `cp` / `cP` | Paste from the Windows clipboard after / before the cursor |

---

## LLM completion — llm-complete (local server on `localhost:5000`)

Insert-mode ghost-text completion; only active when the plugin is installed in
`.vim/pack/llm/` and your LLM server is running.

| Key | Action |
|---|---|
| `<Tab>` | Accept the whole suggestion |
| `<M-Right>` / `<C-Right>` / `<M-w>` | Accept one word |
| `<M-Down>` / `<C-Down>` / `<M-l>` | Accept one line |
| `<C-]>` | Manually trigger a suggestion |
| `<C-e>` | Dismiss the current suggestion |

Commands: `:LLMHealth`, `:LLMEnable` / `:LLMDisable`, `:LLMTrigger`, `:LLMStatus`.
