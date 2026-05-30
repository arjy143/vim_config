

"init stuff
set nocompatible
filetype plugin indent on
syntax on

"no swap files (undo extension is good enough)
set noswapfile

"leader key
let mapleader = ","

"mouse
set mouse=a

"highlight trailing whitespace
"match ErrorMsg '\s\+$'

"clipboard: this Vim is built with -clipboard, so unnamedplus does nothing here.
"System clipboard is handled by the vim-wsl-copy-paste plugin (cy / visual Y).

"code folding
set foldmethod=marker

"setting a nice colour scheme
colorscheme koehler 
" if has("termguicolors")
"     set termguicolors
" endif

"set line numbers
set number

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

"ctags (need to have ctags installed: apt install exuberant-ctags)
set tags=./tags;,tags;

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

"--------------------------------PLUGINS-------------------------------
"ALE: these must be set before ALE loads (full config is further below).
"Turn on LSP-driven autocompletion and auto-import.
let g:ale_completion_enabled = 1
let g:ale_completion_autoimport = 1

call plug#begin('~/.vim/plugged')

"status line
Plug 'itchyny/lightline.vim'

"file tree
Plug 'preservim/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'

"fuzzy finding
Plug 'junegunn/fzf'
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

"auto-(re)generate the ctags 'tags' file in the background
Plug 'ludovicchabant/vim-gutentags'

"Linter / LSP client
Plug 'dense-analysis/ale'

"debugger integration
Plug 'puremourning/vimspector'

"wsl copy paste
Plug 'Konfekt/vim-wsl-copy-paste'

"markdown in-editor rendering (pure vimscript, no external deps)
"(tabular is an optional helper for :TableFormat alignment)
Plug 'godlygeek/tabular'
Plug 'preservim/vim-markdown'
call plug#end()


"--------------------------------PLUGIN CONFIGS-------------------------------
"mappings for some of the plugins

"status line (lightline)
"show 'TAGS...' in the statusline while gutentags is generating tags in the
"background; the component is empty (invisible) when nothing is happening.
function! LightlineGutentags() abort
	return exists('*gutentags#statusline') ? gutentags#statusline('', '', 'TAGS...') : ''
endfunction
let g:lightline = {
\   'active': {
\     'left':  [ [ 'mode', 'paste' ],
\                [ 'readonly', 'filename', 'modified' ] ],
\     'right': [ [ 'lineinfo' ],
\                [ 'percent' ],
\                [ 'fileformat', 'fileencoding', 'filetype' ],
\                [ 'gutentags' ] ],
\   },
\   'component_function': {
\     'gutentags': 'LightlineGutentags',
\   },
\ }
"lightline already initialised (at plug#end) before g:lightline was set above,
"so re-init now to pick up our layout.
if exists('*lightline#init')
	call lightline#init()
	call lightline#colorscheme()
	call lightline#update()
endif
"redraw the statusline when gutentags starts/finishes so the indicator toggles
augroup LightlineGutentags
	autocmd!
	autocmd User GutentagsUpdating call lightline#update()
	autocmd User GutentagsUpdated  call lightline#update()
augroup END

"file tree
"(control n) toggles the panel on the left
"(shift i) shows hidden files
nnoremap <C-n> :NERDTreeToggle<CR>

"below will automatically open file tree with every new vim opening
"autocmd VimEnter * NERDTree | wincmd p

"fuzzy finder
"(C f) brings it up
nnoremap <C-f> :Files<CR>
nnoremap <C-g> :Rg<CR>

"git
nnoremap <leader>gs :Git status<CR>
nnoremap <leader>gd :Gdiffsplit<CR>
nnoremap <leader>ga :Gwrite<CR>
nnoremap <leader>gc :Git commit<CR>
nnoremap <leader>gp :Git push<CR>
nnoremap <leader>gl :Git log --oneline<CR>


"vim visual multi
let g:VM_maps = {}
let g:VM_maps['Find Under']             = '<leader>n'
let g:VM_maps['Find Subword Under']     = '<leader>n'
let g:VM_maps['Select All']             = '<leader>a'
let g:VM_maps['Add Cursor Down']        = '<leader>j'
let g:VM_maps['Add Cursor Up']          = '<leader>k'
let g:VM_maps['Exit']                   = '<leader>q'

"working with tabs
nnoremap <leader>[ :tabprevious<CR>
nnoremap <leader>] :tabnext<CR>
nnoremap <leader>t :tabnew<CR>

"comments
nnoremap <leader>/ : Commentary<CR>
vnoremap <leader>/ : Commentary<CR>

"tier 1 essentials
"undotree: toggle the undo-history panel (focuses it so you can navigate)
nnoremap <leader>u :UndotreeToggle<CR>:UndotreeFocus<CR>
"(surround / repeat / unimpaired / abolish / eunuch work out of the box)

"gutentags: keep the ctags 'tags' file generated/updated automatically.
"store generated tag files in a cache dir so they never clutter your projects
"(gutentags adds this file to 'tags' itself, alongside the ./tags;,tags; above).
let g:gutentags_cache_dir = expand('~/.cache/vim/gutentags')
"only run inside a real project, identified by one of these root markers
let g:gutentags_project_root = ['.git', 'CMakeLists.txt', 'Makefile', 'package.json']
"use the ctags backend only
let g:gutentags_modules = ['ctags']
"don't index build artefacts / vendored code
let g:gutentags_ctags_exclude = ['build', '.git', 'node_modules', '*.min.js', 'tags']
":GutentagsToggleEnabled turns background generation on/off if you ever need to

"wsl copy paste: the plugin provides `cy` (operator) and `Y` (visual) to copy
"to the Windows clipboard, and `cp` to paste. No custom mapping needed.

"markdown
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
autocmd FileType markdown nnoremap <buffer> <silent> <leader>mc :call <SID>ToggleMarkdownConceal()<CR>
"(provided by vim-markdown when concealment is on)
" :Toc        - open a table of contents in a split
" :TableFormat - align the current markdown table (uses tabular)

"--- side-by-side rendered preview (glow in a terminal split) ---
",mp  open/refresh a rendered view of the current file in a right-hand split
",mq  close the preview
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
	setlocal nonumber nocursorline nobuflisted nospell
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

"entry point for ,mp : save, show the preview, and keep it fresh on save
function! s:MdPreviewOpen() abort
	if &filetype !=# 'markdown'
		echohl WarningMsg | echo 'Not a markdown buffer' | echohl None | return
	endif
	if empty(expand('%'))
		echohl WarningMsg | echo 'Save the file first' | echohl None | return
	endif
	silent update
	call s:MdPreviewShow()
	augroup MdPreviewRefresh
		autocmd! * <buffer>
		autocmd BufWritePost <buffer> call s:MdPreviewShow()
	augroup END
endfunction

autocmd FileType markdown nnoremap <buffer> <silent> <leader>mp :call <SID>MdPreviewOpen()<CR>
autocmd FileType markdown nnoremap <buffer> <silent> <leader>mq :call <SID>MdPreviewClose()<CR>
"--------------------------------ALE (linter + LSP client)-------------------------------
"clangd is the C/C++ language server: diagnostics, completion, go-to-def, hover.
"(install per language: clangd=installed; clang-format / pyright not yet present.)
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
"run fixers manually with :ALEFix (not on save, to avoid surprises)

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

"IDE navigation (LSP via ALE)
nnoremap <leader>ld :ALEGoToDefinition<CR>
nnoremap <leader>lr :ALEFindReferences<CR>
nnoremap <leader>lh :ALEHover<CR>
nnoremap <leader>lt :ALEGoToTypeDefinition<CR>
nnoremap <leader>lf :ALEFix<CR>
nnoremap <leader>ln :ALENextWrap<CR>
nnoremap <leader>lp :ALEPreviousWrap<CR>
"<C-x><C-o> = omni-complete (LSP-backed in c/cpp buffers)



"llm completion mappings
let g:llm_complete_context_lines = 50
let g:llm_complete_suffix_lines = 20
let g:llm_complete_max_tokens = 128
let g:llm_complete_debounce = 80
let g:llm_complete_project_file = 'MODEL.md'


