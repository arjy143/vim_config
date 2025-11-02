"init stuff
set nocompatible
filetype plugin indent on
syntax on

"leader key
let mapleader = ","

"mouse
set mouse=a

"highlight trailing whitespace
match ErrorMsg '\s\+$'

"clipboard
set clipboard=unnamedplus

"code folding
set foldmethod=marker

"setting a nice colour scheme
:colorscheme murphy

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

"--------------------------------PLUGINS-------------------------------
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


call plug#end()


"--------------------------------PLUGIN CONFIGS-------------------------------
"mappings for some of the plugins

"file tree
"(control n) toggles the panel on the left
"(shift i) shows hidden files
nnoremap <C-n> :NERDTreeToggle<CR>

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





