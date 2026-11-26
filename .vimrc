"init stuff
set nocompatible

"load plugins from the repo's .vim dir (~/.vimrc is a symlink into the repo)
let s:vimdir = fnamemodify(resolve(expand('<sfile>:p')), ':h') . '/.vim'
let &runtimepath = s:vimdir . ',' . &runtimepath . ',' . s:vimdir . '/after'
let &packpath = s:vimdir . ',' . &packpath
"filetype and syntax are enabled by plug#end()

"no swap files (undo extension is good enough)
set noswapfile

"leader key
let mapleader = " "
nnoremap <Space> <Nop>

"mouse
set mouse=a

"highlight trailing whitespace
"match ErrorMsg '\s\+$'

"code folding
set foldmethod=marker

"line numbers
set number
set relativenumber

"highlight the current line
set cursorline
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

"files over 10 MB: no marker folding, undo file or ALE
"foldmethod is window-local, so restore it when another buffer enters the window
function! s:LargeFileFolds() abort
	if get(b:, 'large_file', 0)
		setlocal foldmethod=manual
		let w:large_file_folds = 1
	elseif get(w:, 'large_file_folds', 0)
		let &l:foldmethod = &g:foldmethod
		unlet w:large_file_folds
	endif
endfunction
augroup LargeFile
	autocmd!
	autocmd BufReadPre * if getfsize(expand('<afile>')) > 10 * 1024 * 1024
		\ | let b:large_file = 1 | setlocal foldmethod=manual noundofile | let b:ale_enabled = 0 | endif
	autocmd BufWinEnter * call s:LargeFileFolds()
augroup END

"<leader>? opens the cheatsheet, read-only, in a new tab
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
"pane navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

"tabs
nnoremap <silent> <F9> :tabprevious<CR>
nnoremap <silent> <F10> :tabnext<CR>
inoremap <silent> <F9> <Esc>:tabprevious<CR>
inoremap <silent> <F10> <Esc>:tabnext<CR>
nnoremap <silent> <leader>t :tabnew<CR>

"zoom: show the current pane in its own tab, close it to restore
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
let g:netrw_banner = 0
let g:netrw_liststyle = 3       "tree view
let g:netrw_winsize = 20        "width (%)
let g:netrw_browse_split = 4    "open files in the previous window
nnoremap <silent> <C-t> :Lexplore<CR>
"netrw maps ctrl-l to refresh; keep it for pane navigation
augroup NetrwMaps
	autocmd!
	autocmd FileType netrw nnoremap <buffer> <C-l> <C-w>l
augroup END

"--------------------------------YANK HISTORY-------------------------------
"yanks are stored newest first in ~/.vim_yank_history (JSON, shared between
"instances). <leader>p opens a picker: j/k and <CR>, or 1-9. <Esc> cancels.
"yanks larger than s:yank_max_bytes are skipped, capping the file at ~2 MB.
let s:yank_file = expand('~/.vim_yank_history')
let s:yank_max = 20
let s:yank_max_bytes = 100 * 1024

function! s:YankHistoryRead() abort
	"ignore a missing or oversized file
	if !filereadable(s:yank_file) || getfsize(s:yank_file) > 2 * s:yank_max * s:yank_max_bytes
		return []
	endif
	try
		let l:history = json_decode(join(readfile(s:yank_file), ''))
		return type(l:history) == v:t_list ? l:history : []
	catch
		return []    "invalid JSON
	endtry
endfunction

function! s:YankHistorySave(event) abort
	if a:event.operator !=# 'y' || join(a:event.regcontents, '') =~# '^\s*$'
		return
	endif
	let entry = {'text': a:event.regcontents, 'type': a:event.regtype}
	if strlen(json_encode(entry)) > s:yank_max_bytes
		echo 'Yank too big for the yank history (over 100 KB), not saved'
		return
	endif
	"a repeated yank moves to the top
	let history = [entry] + filter(s:YankHistoryRead(), {_, old -> old != entry})
	call writefile([json_encode(history[: s:yank_max - 1])], s:yank_file)
	call setfperm(s:yank_file, 'rw-------')
endfunction

"one line per entry, truncated to 70 characters
function! s:YankPreview(index, entry) abort
	let l:text = substitute(trim(join(a:entry.text, ' ⏎ ')), '\s\+', ' ', 'g')
	let l:text = strchars(l:text) > 70 ? strcharpart(l:text, 0, 69) . '…' : l:text
	return printf('%2d  %s', a:index + 1, l:text)
endfunction

"1-9 select directly; other keys go to the default menu filter
function! s:YankHistoryFilter(id, key) abort
	if a:key =~# '^[1-9]$'
		call popup_close(a:id, str2nr(a:key))
		return 1
	endif
	return popup_filter_menu(a:id, a:key)
endfunction

function! s:YankHistoryPut(history, choice) abort
	if a:choice < 1 || a:choice > len(a:history)
		return
	endif
	let l:entry = a:history[a:choice - 1]
	call setreg('"', l:entry.text, l:entry.type)
	normal! ""p
endfunction

function! s:YankHistoryPaste() abort
	let history = s:YankHistoryRead()
	if empty(history)
		echo 'Yank history is empty'
		return
	endif
	call popup_menu(map(copy(history), function('s:YankPreview')), {
	\   'title': ' Yank history ',
	\   'filter': function('s:YankHistoryFilter'),
	\   'callback': {_, choice -> s:YankHistoryPut(history, choice)},
	\ })
endfunction

augroup YankHistory
	autocmd!
	autocmd TextYankPost * call s:YankHistorySave(v:event)
augroup END
nnoremap <silent> <leader>p :call <SID>YankHistoryPaste()<CR>

"--------------------------------PLUGINS-------------------------------
"ALE options that must be set before it loads
let g:ale_completion_enabled = 1
let g:ale_completion_autoimport = 1

"installed into .vim/plugged (git-ignored)
call plug#begin(s:vimdir . '/plugged')

"status line
Plug 'itchyny/lightline.vim'

"fuzzy finding (the hook installs the fzf binary)
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

"surround: cs, ds, ys
Plug 'tpope/vim-surround'
"repeat plugin maps with .
Plug 'tpope/vim-repeat'
"case-preserving substitution, case coercion
Plug 'tpope/vim-abolish'
":Rename, :Move, :Delete, :Mkdir, :SudoWrite
Plug 'tpope/vim-eunuch'
"undo tree
Plug 'mbbill/undotree'

"linter / LSP client
Plug 'dense-analysis/ale'

"windows clipboard (WSL only)
if has('wsl')
	Plug 'Konfekt/vim-wsl-copy-paste'
endif

"markdown (tabular is only used by :TableFormat)
Plug 'godlygeek/tabular', { 'for': 'markdown' }
Plug 'preservim/vim-markdown'
call plug#end()

"colour scheme: after plug#end(), which enables syntax and would reset highlights
colorscheme koehler
" if has("termguicolors")
"     set termguicolors
" endif
highlight cursorline cterm=NONE ctermbg=236 guibg=#2a2e36


"--------------------------------PLUGIN CONFIGS-------------------------------

"fzf: <leader>f open, g new tab, v vsplit, s split; b buffers; / ripgrep
function! s:FzfFiles(open_cmd) abort
	call fzf#vim#files('', fzf#vim#with_preview({'sink': a:open_cmd}))
endfunction
nnoremap <silent> <leader>f :Files<CR>
nnoremap <silent> <leader>g :call <SID>FzfFiles('tabedit')<CR>
nnoremap <silent> <leader>v :call <SID>FzfFiles('vsplit')<CR>
nnoremap <silent> <leader>s :call <SID>FzfFiles('split')<CR>
nnoremap <silent> <leader>b :Buffers<CR>
nnoremap <silent> <leader>/ :Rg<CR>

"git: fugitive status. gitgutter defaults: ]c [c, <leader>hp/hs/hu
nnoremap <silent> <leader>G :Git<CR>

"multiple cursors: ctrl-n, ctrl-up/down (defaults); <leader>a selects all
let g:VM_maps = {}
let g:VM_maps['Select All'] = '<leader>a'

"comments: ctrl-/ (most terminals send it as ctrl-_)
nmap <C-_> <Plug>CommentaryLine
xmap <C-_> <Plug>Commentary
nmap <C-/> <Plug>CommentaryLine
xmap <C-/> <Plug>Commentary

"surround the word or selection; the closing character goes in first
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

"undo tree
nnoremap <silent> <leader>u :UndotreeToggle<CR>:UndotreeFocus<CR>

"blank line above / below, with optional count
nnoremap <silent> [<Space> :<C-u>call append(line('.') - 1, repeat([''], v:count1))<CR>
nnoremap <silent> ]<Space> :<C-u>call append(line('.'), repeat([''], v:count1))<CR>

"wsl-copy-paste: cy{motion} and visual Y copy, cp pastes

"markdown: <leader>m glow preview, <leader>M toggle concealment
let g:vim_markdown_conceal = 1
let g:vim_markdown_conceal_code_blocks = 0
let g:vim_markdown_folding_disabled = 1
autocmd FileType markdown setlocal conceallevel=2
function! s:ToggleMarkdownConceal() abort
	let &l:conceallevel = &conceallevel == 0 ? 2 : 0
	echo "conceallevel=" . &conceallevel
endfunction

"glow preview in a terminal split, refreshed on save
let s:md_preview_buf = -1

"preview window id, or -1
function! s:MdPreviewWinId() abort
	if s:md_preview_buf != -1 && bufexists(s:md_preview_buf)
		return bufwinid(s:md_preview_buf)
	endif
	return -1
endfunction

function! s:MdRenderInNewSplit(file) abort
	rightbelow vertical new
	execute 'terminal ++curwin ++noclose glow ' . fnameescape(a:file)
	let s:md_preview_buf = bufnr('%')
	setlocal nonumber norelativenumber nocursorline nobuflisted nospell
endfunction

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

"doesn't write, so it's safe to call from BufWritePost
function! s:MdPreviewShow() abort
	let l:file = expand('%:p')
	let l:srcwin = win_getid()
	call s:MdPreviewClose()
	call s:MdRenderInNewSplit(l:file)
	call win_gotoid(l:srcwin)
endfunction

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
let g:ale_linters = {
\   'c':   ['clangd'],
\   'cpp': ['clangd'],
\}
let g:ale_linters_explicit = 1

"clangd needs a compile_commands.json in the project
let g:ale_c_clangd_options = '--background-index --clang-tidy --header-insertion=never'
let g:ale_cpp_clangd_options = '--background-index --clang-tidy --header-insertion=never'

"LSP completion for <C-x><C-o> (the c/cpp ftplugins would set ccomplete)
autocmd FileType c,cpp setlocal omnifunc=ale#completion#OmniFunc

"fixers run manually with <leader>lf
let g:ale_fixers = {
\   '*': ['remove_trailing_lines', 'trim_whitespace'],
\}

"lint after normal-mode changes. lint_on_insert_leave is off: ALE implements it
"with ModeChanged, which auto-pairs and the completion menu trigger constantly.
let g:ale_lint_on_text_changed = 'normal'
let g:ale_lint_on_insert_leave = 0
let g:ale_lint_delay = 300

let g:ale_sign_column_always = 1
let g:ale_sign_error = 'E>'
let g:ale_sign_warning = 'W>'
let g:ale_hover_to_floating_preview = 1
let g:ale_detail_to_floating_preview = 1

"<leader>l:
"  l  toggle ALE           h  hover
"  d  definition           t  type definition
"  r  references           R  rename
"  n  next problem         p  previous problem
"  e  problem detail       f  fix
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

"completion menu: <Tab>/<S-Tab> cycle, <CR> accepts (newline if nothing selected).
"auto-pairs wraps this <CR> mapping.
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <CR> pumvisible() ? (complete_info(['selected']).selected >= 0 ? "\<C-y>" : "\<C-e>\<CR>") : "\<CR>"


"llm completion mappings
let g:llm_complete_context_lines = 50
let g:llm_complete_suffix_lines = 20
let g:llm_complete_max_tokens = 128
let g:llm_complete_debounce = 80
let g:llm_complete_project_file = 'MODEL.md'
