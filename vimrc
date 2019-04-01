" Use Vim settings, rather then Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible
filetype off

call plug#begin('~/.vim/plugged')

Plug 'altercation/vim-colors-solarized'
Plug 'tomasr/molokai'
Plug 'Yggdroot/indentLine'
Plug 'kien/ctrlp.vim'
Plug 'tpope/vim-surround'
Plug 'scrooloose/nerdtree'
Plug 'scrooloose/nerdcommenter'
Plug 'jistr/vim-nerdtree-tabs'
Plug 'tpope/vim-endwise'
Plug 'jiangmiao/auto-pairs'
Plug 'junegunn/vim-easy-align'
"Plug 'vim-airline/vim-airline'
"Plug 'vim-airline/vim-airline-themes'
"Plug 'Valloric/YouCompleteMe'
Plug 'Shougo/deoplete.nvim'
Plug 'rking/ag.vim'
Plug 'w0rp/ale'
Plug 'itchyny/lightline.vim'
Plug 'majutsushi/tagbar'

"lang
Plug 'tpope/vim-rails', { 'for': ['ruby', 'haml'] }
Plug 'plasticboy/vim-markdown', { 'for': 'markdown' }
Plug 'suan/vim-instant-markdown', { 'for': 'markdown' }
Plug 'tpope/vim-fugitive'
Plug 'Shougo/echodoc.vim'
Plug 'SirVer/ultisnips'
Plug 'vim-ruby/vim-ruby'
Plug 'hashivim/vim-terraform'
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'nsf/gocode', { 'rtp': 'nvim', 'do': '~/.config/nvim/plugged/gocode/nvim/symlink.sh' }
Plug 'jodosha/vim-godebug'

"Plug 'vim-syntastic/syntastic'

call plug#end()

"set autowrite
set textwidth=120
set fo=mbtcrolq
set backspace=indent,eol,start  " backspace for dummies
set linespace=0                 " No extra spaces between rows
set number                      " Line numbers on
set showmatch                   " show matching brackets/parenthesis
set incsearch                   " find as you type search
set hlsearch                    " highlight search terms
set winminheight=0              " windows can be 0 line high
set ignorecase                  " case insensitive search
set smartcase                   " case sensitive when uc present
set wildmenu                    " show list instead of just completing
set wildmode=list:longest,full  " command <Tab> completion, list matches, then longest common part, then all
set whichwrap=b,s,h,l,<,>,[,]   " backspace and cursor keys wrap to
set scrolljump=5                " lines to scroll when cursor leaves screen
set scrolloff=3                 " minimum lines to keep above and below cursor
set spell
"folding settings
set foldmethod=indent
set foldenable
set foldlevel=1
set foldlevelstart=99
nnoremap <space> @=((foldclosed(line('.')) < 0) ? 'zc' : 'zo')<CR> " 用空格键来开关折叠
set nobackup                    "don't create backup file
set fileformat=unix             "set file format
set shortmess=atI               "set don't show the hint at startup
set list
set listchars=tab:,.,trail:.,extends:#,nbsp:. " Highlight problematic whitespace
set visualbell                  "no sounds
set autoread                    "reload files changed outside
set showmode                    "display the current mode
set cursorline cursorcolumn     "highlight current line
set hidden                      "buffers can exist in the background
set linebreak                   "wrap lines at convenient points
set autoindent                  " indent at the same level of the previous line
set smartindent
set noswapfile
set shiftwidth=2                " use indents of 2 spaces
set expandtab                   " tabs are spaces, not tabs
set tabstop=2                   " an indentation every four columns
set softtabstop=2               " let backspace delete indent
set smarttab                    "insert tabs on the start of a line according to shiftwidth, not tabstop"
set wildignore+=*/tmp/*,*.so*,*.swp,*.zip,._*,*DS_Store*,log/**,*.png,*.jpg,*.gif "MacOSX or Linux
syntax on                       "syntax highlighting
set noshowmode
"set matchpairs+=<:>                " match, to be used with %

filetype plugin indent on       "Automatically detect file types
set mouse=a                     "enable mouse usage
scriptencoding utf-8
set shortmess+=filmnrxoOtT      "abbrev. of messages (avoids 'hit enter')
set viewoptions=folds,options,cursor,unix,slash " better unix / windows compatibility
set virtualedit=onemore         "allow for cursor beyond last character
set tags+=tags             "set tags
set tags+=~/.rvm/gems/tags

"Disable netrw to generate file
let g:netrw_dirhistmax = 0
" ================================= Vim Theme ==================================
syntax enable                   "syntax highlighting
set background=dark             "Color theme
colorscheme molokai           "railscasts solarized

" ================================= Status Line ==================================
"let g:airline#extensions#tabline#enabled = 1
"set laststatus=2
"let g:airline_powerline_fonts = 1
"let g:airline_theme='molokai'

if has('cmdline_info')
  set ruler                   " show the ruler
  set rulerformat=%30(%=\:b%n%y%m%r%w\ %l,%c%V\ %P%) " a ruler on steroids
  set showcmd                 " show partial commands in status line and
endif

set comments=sl:/*,mb:*,elx:*/  " auto format comment blocks
" }

" ================================= Key Mappings ==================================
"The default leader is '\', but many people prefer ',' as it's in a standard location
let mapleader = ','

"Jump into tag if there is noly one match and present a list if there are multiple matches
nnoremap <C-]> g<C-]>

" ctrl + a
noremap <C-a> ggVG
inoremap <C-a> <C-O>ggVG

"set system clipboard as default clipboard for vim
set clipboard=unnamed

map <C-H> <C-W>h
map <C-J> <C-W>j
map <C-K> <C-W>k
map <C-L> <C-W>l

" Quickly close the current window
nnoremap <leader>q :q<CR>
nnoremap <leader>Q :q!<CR>

" Quickly save the current file
nnoremap <leader>w :w<CR>

" Qickly copy path of current file
nmap ,ps :let @*=expand("%")<CR>
nmap ,pl :let @*=expand("%:p")<CR>

" Remap H and L (top, bottom of screen to left and right end of line)
nnoremap H ^
nnoremap L $

" Start substitute on current word under the cursor
nnoremap ,s :%s///gc<Left><Left><Left>

" 设置可以高亮的关键字
if has("autocmd")
  " Highlight TODO, FIXME, NOTE, etc.
  if v:version > 701
    autocmd Syntax * call matchadd('Todo',  '\W\zs\(TODO\|FIXME\|CHANGED\|DONE\|XXX\|BUG\|HACK\)')
    autocmd Syntax * call matchadd('Debug', '\W\zs\(NOTE\|INFO\|IDEA\|NOTICE\)')
  endif
endif

" ********************************* indentLine ********************************
let g:indentLine_color_term = 239

" ********************************* Ctrlp ********************************
let g:ctrlp_map = '<C-p>'
let g:ctrlp_working_path_mode = 'ra'
let g:ctrlp_show_hidden = 1
let g:ctrlp_root_markers = ['.git','Gemfile','.vimrc','.bashrc', '.zshrc']
let g:ctrlp_custom_ignore = {
     \'dir':  '\v[\/](\.(git|hg|svn)|node_modules|bower_components)$',
     \'file': '\v\.(exe|so|dll)$',
     \ }

"********************************* Fugitive ********************************
nnoremap <silent> <leader>gs :Gstatus<CR>
nnoremap <silent> <leader>gd :Gdiff<CR>
nnoremap <silent> <leader>gc :Gcommit<CR>
nnoremap <silent> <leader>gb :Gblame<CR>
nnoremap <silent> <leader>gl :Glog<CR>
nnoremap <silent> <leader>gp :Git push<CR>

" ********************************* Nerd Commenter ********************************
let NERDSpaceDelims = 1

" ********************************* lightline ********************************
set laststatus=2
let g:lightline = {
      \ 'colorscheme': 'solarized',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'fugitive', 'readonly', 'filename', 'modified' ] ]
      \ },
      \ 'component_function': {
      \   'fugitive': 'MyFugitive',
      \   'readonly': 'MyReadonly',
      \   'filename': 'MyFilename',
      \ },
      \ 'separator': { 'left': '>', 'right': '<' },
      \ 'subseparator': { 'left': '>', 'right': '<' }
      \ }
function! MyReadonly()
  if &filetype == "help"
    return ""
  elseif &readonly
    return "l "
  else
    return ""
  endif
endfunction
function! MyFugitive()
  if exists("*fugitive#head")
    let _ = fugitive#head()
    return strlen(_) ? '| '._ : ''
  endif
  return ''
endfunction
function! MyFilename()
  return ('' != MyReadonly() ? MyReadonly() . ' ' : '') .
       \ ('' != expand('%') ? expand('%') : '[NoName]')
endfunction

" ********************************* NerdTree ********************************
nnoremap <leader>t :NERDTreeToggle<cr>
function! OpenNerdTree()
  if &modifiable && strlen(expand('%')) > 0 && !&diff
    NERDTreeFind
  else
    NERDTreeToggle
  endif
endfunction
nnoremap <silent> <C-\> :call OpenNerdTree()<CR>
"autocmd VimEnter * NERDTree | wincmd p
"autocmd vimenter * if !argc() | NERDTree | endif "Open nerdtree when no files specific"
let NERDTreeChDirMode = 2
let NERDTreeIgnore=['\~$', '\.git$', '.jpg$', '.png$', 'node_modules$', 'bower_components$', 'tags', '.DS_Store']
let g:nerdtree_tabs_open_on_gui_startup = 0
let NERDTreeWinSize = 30
let NERDTreeQuitOnOpen = 0
let NERDTreeShowHidden = 1

" *********************************** Vim Instant Markdown *******************************
let g:instant_markdown_slow = 1
let g:instant_markdown_autostart = 0
let g:instant_markdown_open_to_the_world = 1
map <Leader>m :InstantMarkdownPreview<CR>
autocmd BufNewFile,BufReadPost *.md set filetype=markdown

" *********************************** Vim Easy Align *******************************
vmap <Leader>a <Plug>(EasyAlign)
nmap <Leader>a <Plug>(EasyAlign)
if !exists('g:easy_align_delimeters')
  let g:easy_align_delimeters = {}
endif
let g:easy_align_delimeters['#'] = { 'pattern': '#', 'ignore_groups': ['String'] }

" *********************************** Ultisnips *******************************
" Trigger configuration. Do not use <tab> if you use https://github.com/Valloric/YouCompleteMe.
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<tab>"
let g:UltiSnipsJumpBackwardTrigger="<c-b>"
" If you want :UltiSnipsEdit to split your window.
let g:UltiSnipsEditSplit="vertical"

" *********************************** syntastic *******************************
"set statusline+=%#warningmsg#
"set statusline+=%{SyntasticStatuslineFlag()}
"set statusline+=%*

"let g:syntastic_always_populate_loc_list = 1
"let g:syntastic_auto_loc_list = 1
"let g:syntastic_check_on_open = 1
"let g:syntastic_check_on_wq = 0

" *********************************** tagbar *******************************
map <Leader>b :TagbarToggle<CR>
let g:tagbar_type_go = {
	\ 'ctagstype' : 'go',
	\ 'kinds'     : [
		\ 'p:package',
		\ 'i:imports:1',
		\ 'c:constants',
		\ 'v:variables',
		\ 't:types',
		\ 'n:interfaces',
		\ 'w:fields',
		\ 'e:embedded',
		\ 'm:methods',
		\ 'r:constructor',
		\ 'f:functions'
	\ ],
	\ 'sro' : '.',
	\ 'kind2scope' : {
		\ 't' : 'ctype',
		\ 'n' : 'ntype'
	\ },
	\ 'scope2kind' : {
		\ 'ctype' : 't',
		\ 'ntype' : 'n'
	\ },
	\ 'ctagsbin'  : 'gotags',
	\ 'ctagsargs' : '-sort -silent'
\ }

" *********************************** ale *******************************
"let g:ale_sign_column_always = 1
let g:ale_sign_error = '>>'
let g:ale_sign_warning = '--'
let g:ale_set_highlights = 0
nmap <silent> <C-k> <Plug>(ale_previous_wrap)
nmap <silent> <C-j> <Plug>(ale_next_wrap)
map <Leader>a :ALEToggle<CR>

" *********************************** deoplete *******************************
let g:deoplete#enable_at_startup = 1

let g:go_fmt_command = "goimports"
