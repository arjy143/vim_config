"init stuff
set nocompatible

"use this repo's .vim directory for plugins (plug.vim, plugged/, pack/).
"~/.vimrc is a symlink into the repo, so resolve it to find the real location;
"that way nothing else needs linking and the repo can live anywhere.
let s:vimdir = fnamemodify(resolve(expand('<sfile>:p')), ':h') . '/.vim'
let &runtimepath = s:vimdir . ',' . &runtimepath . ',' . s:vimdir . '/after'
let &packpath = s:vimdir . ',' . &packpath

filetype plugin indent on
syntax on

"no swap files (undo extension is good enough)
set noswapfile

"leader key: space. (Nop stops a lone space from also moving the cursor.)
let mapleader = " "
nnoremap <Space> <Nop>

"mouse
set mouse=a

"highlight trailing whitespace
"match ErrorMsg '\s\+$'

"code folding
set foldmethod=marker

"setting a nice colour scheme
colorscheme koehler
" if has("termguicolors")
"     set termguicolors
" endif

"line numbers: absolute on the current line, relative everywhere else
set number
set relativenumber

"set the current line to be highlighted
set cursorline
highlight cursorline cterm=NONE ctermbg=236 guibg=#2a2e36
set t_Co=256

"keep context when scrolling
set scrolloff=5
set sidescrolloff=5

"tab and indent stuff
set expandtab
set shiftwidth=4
set tabstop=4
set softtabstop=4
set autoindent
set smartindent

"searching
set incsearch
set hlsearch
set ignorecase
set smartcase

"making undo better
if has('persistent_undo')
	set undofile
endif

"open the cheatsheet from anywhere with <leader>? (read-only, in a new tab).
"path is derived from this vimrc's real location, so it survives moving the repo.
let s:cheatsheet = fnamemodify(resolve(expand('<sfile>:p')), ':h') . '/CHEATSHEET.md'
function! s:OpenCheatsheet() abort
	if filereadable(s:cheatsheet)
		execute 'tabedit ' . fnameescape(s:cheatsheet)
		setlocal readonly nomodifiable
	else
		echohl WarningMsg | echo 'Cheatsheet not found: ' . s:cheatsheet | echohl None
	endif
endfunction
nnoremap <silent> <leader>? :call <SID>OpenCheatsheet()<CR>

"--------------------------------WINDOWS & TABS-------------------------------
"move between panes with ctrl + h/j/k/l
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

"tabs: F9 / F10 = previous / next, <leader>t = new tab
nnoremap <silent> <F9> :tabprevious<CR>
nnoremap <silent> <F10> :tabnext<CR>
inoremap <silent> <F9> <Esc>:tabprevious<CR>
inoremap <silent> <F10> <Esc>:tabnext<CR>
nnoremap <silent> <leader>t :tabnew<CR>

"<leader>z: zoom the current pane to full screen, press again to restore.
"(zooming opens the pane in its own tab; un-zooming closes that tab and goes
"back to the original one.)
function! s:ZoomToggle() abort
	if exists('t:zoom_origin')
		let l:origin = t:zoom_origin
		tabclose
		execute 'tabnext ' . l:origin
	elseif winnr('$') > 1
		let l:origin = tabpagenr()
		tab split
		let t:zoom_origin = l:origin
	endif
endfunction
nnoremap <silent> <leader>z :call <SID>ZoomToggle()<CR>

"--------------------------------FILE TREE (netrw, built in)-------------------------------
"ctrl + t toggles a file tree on the left. Inside it: <CR> open, - parent dir,
"% new file, d new dir, D delete, R rename, gh toggle hidden files.
let g:netrw_banner = 0          "hide the help banner (press I to show it)
let g:netrw_liststyle = 3       "tree view
let g:netrw_winsize = 20        "width, in percent
let g:netrw_browse_split = 4    "open files in the window you came from
nnoremap <silent> <C-t> :Lexplore<CR>
"netrw uses ctrl + l for refresh; make it move to the pane on the right instead,
"like everywhere else (toggle the tree with ctrl + t twice to refresh it).
augroup NetrwMaps
	autocmd!
	autocmd FileType netrw nnoremap <buffer> <C-l> <C-w>l
augroup END

"--------------------------------PLUGINS-------------------------------
"ALE: these must be set before ALE loads (full config is further below).
"Turn on LSP-driven autocompletion and auto-import.
let g:ale_completion_enabled = 1
let g:ale_completion_autoimport = 1

"plugins are installed into <repo>/.vim/plugged (git-ignored; run :PlugInstall)
call plug#begin(s:vimdir . '/plugged')

"status line
Plug 'itchyny/lightline.vim'

"fuzzy finding
"(the hook downloads the fzf binary into the plugin dir, so no system fzf is needed)
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

"git
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

"auto close brackets
Plug 'jiangmiao/auto-pairs'

"vscode multi cursor
Plug 'mg979/vim-visual-multi'

"vim comments
Plug 'tpope/vim-commentary'

"--- tier 1 essentials (pure vimscript, no external deps) ---
"surround text objects: cs\"' ds( ysiw)
Plug 'tpope/vim-surround'
"make plugin actions (surround, commentary, ...) repeatable with .
Plug 'tpope/vim-repeat'
"paired bracket mappings: ]q [q quickfix, ]b [b buffers, yos spell, ...
Plug 'tpope/vim-unimpaired'
"case-preserving search/replace + crs crc cru case coercion
Plug 'tpope/vim-abolish'
"file ops from inside vim: :Rename :Delete :Move :SudoWrite :Mkdir
Plug 'tpope/vim-eunuch'
"visualise the persistent undo tree
Plug 'mbbill/undotree'

"Linter / LSP client
Plug 'dense-analysis/ale'

"copy/paste to the Windows clipboard (only useful, and only loaded, under WSL)
if has('wsl')
	Plug 'Konfekt/vim-wsl-copy-paste'
endif

"markdown in-editor rendering (pure vimscript, no external deps)
"(tabular is an optional helper for :TableFormat alignment)
Plug 'godlygeek/tabular'
Plug 'preservim/vim-markdown'
call plug#end()


"--------------------------------PLUGIN CONFIGS-------------------------------

"status line (lightline): default layout, no configuration needed

"fuzzy finder (fzf)
"<leader>f  find a file and open it here
"<leader>g  ... in a new tab
"<leader>v  ... in a vertical split
"<leader>s  ... in a horizontal split
"<leader>b  switch between open buffers
"<leader>/  search the contents of every file in the project (ripgrep)
function! s:FzfFiles(open_cmd) abort
	call fzf#vim#files('', fzf#vim#with_preview({'sink': a:open_cmd}))
endfunction
nnoremap <silent> <leader>f :Files<CR>
nnoremap <silent> <leader>g :call <SID>FzfFiles('tabedit')<CR>
nnoremap <silent> <leader>v :call <SID>FzfFiles('vsplit')<CR>
nnoremap <silent> <leader>s :call <SID>FzfFiles('split')<CR>
nnoremap <silent> <leader>b :Buffers<CR>
nnoremap <silent> <leader>/ :Rg<CR>

"git
"<leader>G opens the fugitive status window (s stage, u unstage, = diff, cc commit).
"gitgutter's own defaults: ]c / [c next/previous change, <leader>hp preview hunk,
"<leader>hs stage hunk, <leader>hu undo hunk.
nnoremap <silent> <leader>G :Git<CR>

"multiple cursors (vim-visual-multi defaults, like vscode):
"ctrl + n select word / add next match, ctrl + down/up add a cursor below/above,
"<leader>a select every match of the word under the cursor.
let g:VM_maps = {}
let g:VM_maps['Select All'] = '<leader>a'

"comments: ctrl + / toggles the current line, or the selection.
"(most terminals send ctrl + / as ctrl + _, so map both.)
nmap <C-_> <Plug>CommentaryLine
xmap <C-_> <Plug>Commentary
nmap <C-/> <Plug>CommentaryLine
xmap <C-/> <Plug>Commentary

"surround: <leader> + " ' ( [ { wraps the word under the cursor, or the selection.
"(the closing character goes in first, so the start position doesn't shift.)
nnoremap <leader>" viw<Esc>`>a"<Esc>`<i"<Esc>
xnoremap <leader>" <Esc>`>a"<Esc>`<i"<Esc>
nnoremap <leader>' viw<Esc>`>a'<Esc>`<i'<Esc>
xnoremap <leader>' <Esc>`>a'<Esc>`<i'<Esc>
nnoremap <leader>( viw<Esc>`>a)<Esc>`<i(<Esc>
xnoremap <leader>( <Esc>`>a)<Esc>`<i(<Esc>
nnoremap <leader>[ viw<Esc>`>a]<Esc>`<i[<Esc>
xnoremap <leader>[ <Esc>`>a]<Esc>`<i[<Esc>
nnoremap <leader>{ viw<Esc>`>a}<Esc>`<i{<Esc>
xnoremap <leader>{ <Esc>`>a}<Esc>`<i{<Esc>

"undotree: toggle the undo-history panel (focuses it so you can navigate)
nnoremap <silent> <leader>u :UndotreeToggle<CR>:UndotreeFocus<CR>
"(surround / repeat / unimpaired / abolish / eunuch work out of the box)

"wsl copy paste: the plugin provides `cy` (operator) and `Y` (visual) to copy
"to the Windows clipboard, and `cp` to paste. No custom mapping needed.

"markdown (markdown buffers only)
"<leader>m  toggle a rendered preview (glow) in a split on the right
"<leader>M  toggle inline rendering of the markup in the file itself
"conceal raw markup so **bold**, _italics_, [links](url) etc. render inline.
"markup on the line under the cursor stays visible so editing is easy.
let g:vim_markdown_conceal = 1
"keep fenced code blocks (```) shown as-is rather than concealing the fences
let g:vim_markdown_conceal_code_blocks = 0
"don't auto-collapse the whole document into folds when a file opens
let g:vim_markdown_folding_disabled = 1
"conceallevel 2 = hide concealed text entirely; only active in markdown buffers
autocmd FileType markdown setlocal conceallevel=2
"toggle the inline rendering on/off (handy while writing raw markup)
function! s:ToggleMarkdownConceal() abort
	let &l:conceallevel = &conceallevel == 0 ? 2 : 0
	echo "conceallevel=" . &conceallevel
endfunction
"(provided by vim-markdown when concealment is on)
" :Toc        - open a table of contents in a split
" :TableFormat - align the current markdown table (uses tabular)

"--- side-by-side rendered preview (glow in a terminal split) ---
"the preview also auto-refreshes whenever you save the markdown file.
let s:md_preview_buf = -1

"window id of the live preview, or -1 if it isn't open
function! s:MdPreviewWinId() abort
	if s:md_preview_buf != -1 && bufexists(s:md_preview_buf)
		return bufwinid(s:md_preview_buf)
	endif
	return -1
endfunction

"render the given file with glow in a fresh vertical split on the right
function! s:MdRenderInNewSplit(file) abort
	rightbelow vertical new
	"the new buffer is empty/unmodified, so ++curwin is safe here
	execute 'terminal ++curwin ++noclose glow ' . fnameescape(a:file)
	let s:md_preview_buf = bufnr('%')
	setlocal nonumber norelativenumber nocursorline nobuflisted nospell
endfunction

"close the preview window/buffer if it exists
function! s:MdPreviewClose() abort
	let l:win = s:MdPreviewWinId()
	if l:win != -1
		call win_gotoid(l:win)
		close!
	endif
	if s:md_preview_buf != -1 && bufexists(s:md_preview_buf)
		execute 'bwipeout!' s:md_preview_buf
	endif
	let s:md_preview_buf = -1
endfunction

"(re)build the preview for the current buffer; never writes, so it's safe
"to call from BufWritePost without recursing
function! s:MdPreviewShow() abort
	let l:file = expand('%:p')
	let l:srcwin = win_getid()
	call s:MdPreviewClose()
	call s:MdRenderInNewSplit(l:file)
	call win_gotoid(l:srcwin)
endfunction

"save, show the preview, and keep it fresh on save
function! s:MdPreviewOpen() abort
	if &filetype !=# 'markdown'
		echohl WarningMsg | echo 'Not a markdown buffer' | echohl None | return
	endif
	if empty(expand('%'))
		echohl WarningMsg | echo 'Save the file first' | echohl None | return
	endif
	if !executable('glow')
		echohl WarningMsg | echo 'glow is not installed (apt install glow)' | echohl None | return
	endif
	silent update
	call s:MdPreviewShow()
	augroup MdPreviewRefresh
		autocmd! * <buffer>
		autocmd BufWritePost <buffer> call s:MdPreviewShow()
	augroup END
endfunction

"entry point for <leader>m: open the preview, or close it if it's already open
function! s:MdPreviewToggle() abort
	if s:MdPreviewWinId() != -1
		call s:MdPreviewClose()
		augroup MdPreviewRefresh
			autocmd! * <buffer>
		augroup END
	else
		call s:MdPreviewOpen()
	endif
endfunction

augroup MarkdownMaps
	autocmd!
	autocmd FileType markdown nnoremap <buffer> <silent> <leader>m :call <SID>MdPreviewToggle()<CR>
	autocmd FileType markdown nnoremap <buffer> <silent> <leader>M :call <SID>ToggleMarkdownConceal()<CR>
augroup END

"--------------------------------ALE (linter + LSP client)-------------------------------
"clangd is the C/C++ language server: diagnostics, completion, go-to-def, hover.
let g:ale_linters = {
\   'c':   ['clangd'],
\   'cpp': ['clangd'],
\}
"only run the linters listed above; don't auto-enable every linter ALE knows
let g:ale_linters_explicit = 1

"clangd options:
" --background-index : index the whole project so symbols/types from other
"                      headers resolve and cross-file references work.
" --clang-tidy       : surface clang-tidy lint warnings inline.
" --header-insertion=never : don't auto-add #include lines on completion.
" (clangd still needs a compilation database -- compile_commands.json -- in the
"  project; for CMake: cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON, see notes.)
let g:ale_c_clangd_options = '--background-index --clang-tidy --header-insertion=never'
let g:ale_cpp_clangd_options = '--background-index --clang-tidy --header-insertion=never'

"feed ALE's LSP completions into omni-complete too (<C-x><C-o>).
"must be per-filetype: Vim's built-in c/cpp ftplugin otherwise forces ccomplete.
autocmd FileType c,cpp setlocal omnifunc=ale#completion#OmniFunc

"fixers: these two are built into ALE and need no external tool.
"(add 'clang-format' for c/cpp once it's installed.)
let g:ale_fixers = {
\   '*': ['remove_trailing_lines', 'trim_whitespace'],
\}
"run fixers manually with <leader>lf (not on save, to avoid surprises)

"lint as you edit, but gently
let g:ale_lint_on_text_changed = 'normal'
let g:ale_lint_on_insert_leave = 1
let g:ale_lint_delay = 300

"gutter: keep the sign column open so text doesn't jump around
let g:ale_sign_column_always = 1
let g:ale_sign_error = 'E>'
let g:ale_sign_warning = 'W>'
"show the current line's message in a floating popup
let g:ale_hover_to_floating_preview = 1
let g:ale_detail_to_floating_preview = 1

"IDE shortcuts, all under <leader>l ("language"):
"  l  toggle ALE on/off           h  hover info
"  d  go to definition            t  go to type definition
"  r  list references             R  rename symbol
"  n  next problem                p  previous problem
"  e  explain problem (full msg)  f  fix (trim whitespace etc.)
nnoremap <silent> <leader>ll :ALEToggle<CR>:echo 'ALE ' . (g:ale_enabled ? 'on' : 'off')<CR>
nnoremap <silent> <leader>lh :ALEHover<CR>
nnoremap <silent> <leader>ld :ALEGoToDefinition<CR>
nnoremap <silent> <leader>lt :ALEGoToTypeDefinition<CR>
nnoremap <silent> <leader>lr :ALEFindReferences<CR>
nnoremap <silent> <leader>lR :ALERename<CR>
nnoremap <silent> <leader>ln :ALENextWrap<CR>
nnoremap <silent> <leader>lp :ALEPreviousWrap<CR>
nnoremap <silent> <leader>le :ALEDetail<CR>
nnoremap <silent> <leader>lf :ALEFix<CR>
"<C-x><C-o> = omni-complete (LSP-backed in c/cpp buffers)


"llm completion mappings
let g:llm_complete_context_lines = 50
let g:llm_complete_suffix_lines = 20
let g:llm_complete_max_tokens = 128
let g:llm_complete_debounce = 80
let g:llm_complete_project_file = 'MODEL.md'
