"-------------------------------------------------------------------------------
" Starting Point
"-------------------------------------------------------------------------------
" Use Vim settings, rather than Vi settings (much better!). This must be first.
set nocompatible

"-------------------------------------------------------------------------------
" Vundle Plugin Manager
"-------------------------------------------------------------------------------
" Automatically setup Vundle
let has_vundle=1
let vundle_readme=expand('$HOME/.vim/bundle/vundle/README.md')
if !filereadable(vundle_readme)
    echo "Installing Vundle..."
    echo ""
    silent !mkdir -p $HOME/.vim/bundle
    silent !git clone https://github.com/gmarik/vundle.git $HOME/.vim/bundle/vundle
    let has_vundle=0
endif

" Disable file type detection, required
filetype off

" Set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

" Let Vundle manage Vundle, required
Bundle 'gmarik/vundle'

" Plugins
" Show code errors
Bundle 'scrooloose/syntastic'
" Code completion
Bundle 'Shougo/neocomplete'
" Align blocks easy with tabs
Bundle 'godlygeek/tabular'
" Comment code easy
Bundle 'scrooloose/nerdcommenter'
" AutoClose brackets
Bundle 'Townk/vim-autoclose'
" Edit files using sudo/su
Bundle 'chrisbra/SudoEdit.vim'

" Installing plugins the first time
if has_vundle == 0
    echo "Installing Bundles, with tabs please ignore key map error messages"
    echo ""
    :BundleInstall
endif

"-------------------------------------------------------------------------------
" Behaviour
"-------------------------------------------------------------------------------
" Enable file type detection.
filetype plugin on
" Also load indent files, to automatically do language-dependent indenting.
filetype indent on

set encoding=utf-8      " Set utf-8 as standard encoding
set ffs=unix,dos,mac    " Set Unix as standard file type
set mouse=a             " Enable Mouse
set history=100         " Command line history
set autoread            " Watch for file changes

" -- Search -- "
set hlsearch            " Highlight search results
set incsearch           " Do incremental searching
set wrapscan            " Search_next jump to beginning if EOF is reached
set ignorecase          " Ignore case when searching
set smartcase           " Override ignorecase if search pattern has upper case

set magic               " For regular expressions turn magic on

"-------------------------------------------------------------------------------
" View
"-------------------------------------------------------------------------------
syntax on               " Enable syntax highlighting

augroup vim_view
    autocmd!
    " Enable Markdown syntax for .md files, overrides modula highlighting
    autocmd BufRead,BufNewFile *.md set filetype=markdown
augroup END

set splitright          " Puts new vsplit windows to the right
set splitbelow          " Puts new hsplit windows to the bottom

set wildmenu                    " Tab completion menu on command line
set wildmode=list:longest,full  " Command <Tab> completion...
set wildignore=*.o,*~,*.pyc     " Ignore compiled files

set showmode            " Display the current mode on message line
set showcmd             " Display partial commands
set number              " Show line numbers
set ruler               " Show the cursor position all the time
set showmatch           " Show matching brackets when cursor is over them
set nowrap              " Don't wrap text if window is small
set lazyredraw          " Don't redraw when running macros

set scrolljump=5        " Lines to scroll when cursor leaves screen
set scrolloff=3         " Minimun lines to keep above and below cursor

set foldenable          " Auto fold code

" Allow backspacing over autoindent, line breaks and start
set backspace=indent,eol,start
" Backspace and cursor keys wrap too
set whichwrap=b,s,h,l,<,>,[,]

" Highlight problematic whitespace
set list
set listchars=tab:›\ ,trail:•,extends:#,nbsp:.

"-------------------------------------------------------------------------------
" Status Line
"-------------------------------------------------------------------------------
set laststatus=2

set statusline=
set statusline+=[%n]    " Buffer number
set statusline+=%t      " File name
set statusline+=%h      " Help buffer flag
set statusline+=%m      " Modified flag
set statusline+=%r      " Readonly flag
set statusline+=%w      " Preview window flag
set statusline+=%=      " Right align
" Syntastic warnings {
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
" }
set statusline+=%y      " File type
set statusline+=[%l,%c] " Line and column number
set statusline+=%P      " Percentage of file

"-------------------------------------------------------------------------------
" Editing
"-------------------------------------------------------------------------------
set modeline            " Load modeline when available
set hidden              " Allow editing multiple unsaved buffers
set spelllang=es,en     " Define spell languages
set spellsuggest=best   " Spell suggestion match

" -- Tabs -- "
set shiftwidth=4        " Use indents of 4 spaces
set tabstop=4           " An indentation every 4 columns
set softtabstop=4       " Let backspace delete indent
set expandtab           " Tabs are spaces, no tabs
set smarttab            " Be smart when using tabs
set autoindent          " Autoindent enabled

set nojoinspaces        " Prevents two spaces after punctuation on a Join (J)
augroup vim_edit
    autocmd!
    " For all text files set 'textwidth' to 80 characters.
    autocmd FileType text set textwidth=80
    " For all Markdown files set wrap text
    autocmd FileType markdown set  wrap
augroup END

"-------------------------------------------------------------------------------
" Syntastic
"-------------------------------------------------------------------------------
let g:syntastic_check_on_open=1
let g:syntastic_enable_signs=1

"-------------------------------------------------------------------------------
" NeoComplete
"-------------------------------------------------------------------------------
" Disable AutoComplPop.
let g:acp_enableAtStartup = 0
" Use neocomplete.
let g:neocomplete#enable_at_startup = 1
" Use smartcase.
let g:neocomplete#enable_smart_case = 1
" Set minimum syntax keyword length.
let g:neocomplete#sources#syntax#min_keyword_length = 3
let g:neocomplete#lock_buffer_name_pattern = '\*ku\*'

" Define dictionary.
let g:neocomplete#sources#dictionary#dictionaries = {
    \ 'default' : '',
    \ 'vimshell' : $HOME.'/.vimshell_hist',
    \ 'scheme' : $HOME.'/.gosh_completions'
        \ }

" Define keyword.
if !exists('g:neocomplete#keyword_patterns')
    let g:neocomplete#keyword_patterns = {}
endif
let g:neocomplete#keyword_patterns['default'] = '\h\w*'

" Plugin key-mappings
inoremap <expr><C-g> neocomplete#undo_completion()
inoremap <expr><C-l> neocomplete#complete_common_string()
inoremap <expr><CR> neocomplete#complete_common_string()

" <TAB>: completion.
inoremap <expr><TAB> pumvisible() ? "\<C-n>" : "\<TAB>"
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<TAB>"

" <CR>: close popup
" <s-CR>: close popup and save indent.
inoremap <expr><s-CR> pumvisible() ? neocomplete#close_popup()"\<CR>" : "\<CR>"
inoremap <expr><CR> pumvisible() ? neocomplete#close_popup() : "\<CR>"

" <C-h>, <BS>: close popup and delete backword char.
inoremap <expr><BS> neocomplete#smart_close_popup()."\<C-h>"
inoremap <expr><C-y> neocomplete#close_popup()

" Enable heavy omni completion.
if !exists('g:neocomplete#sources#omni#input_patterns')
    let g:neocomplete#sources#omni#input_patterns = {}
endif
let g:neocomplete#sources#omni#input_patterns.php = '[^. \t]->\h\w*\|\h\w*::'
let g:neocomplete#sources#omni#input_patterns.c = '[^.[:digit:] *\t]\%(\.\|->\)'
let g:neocomplete#sources#omni#input_patterns.cpp = '[^.[:digit:] *\t]\%(\.\|->\)\|\h\w*::'
let g:neocomplete#sources#omni#input_patterns.perl = '\h\w*->\h\w*\|\h\w*::'
let g:neocomplete#sources#omni#input_patterns.ruby = '[^. *\t]\.\h\w*\|\h\w*::'

"-------------------------------------------------------------------------------
" Mapping
"-------------------------------------------------------------------------------
" Leader
let mapleader = ","

" Pressing ,ss will toggle and untoggle spell checking
map <leader>ss :setlocal spell!<cr>

" Remap VIM 0 to first non-blank character
map 0 ^

" Treat long lines as break lines (when set nowrap)
map j gj
map k gk

" Smart way to move between windows
map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l

" Y yanks from cursor to $, consistent with C and D
map Y y$

" Paste toggle, sane indentation on pastes
set pastetoggle=<F12>

" Tabularize
nmap <Leader>a& :Tabularize /&<CR>
vmap <Leader>a& :Tabularize /&<CR>
nmap <Leader>a= :Tabularize /=<CR>
vmap <Leader>a= :Tabularize /=<CR>
nmap <Leader>a: :Tabularize /:<CR>
vmap <Leader>a: :Tabularize /:<CR>
nmap <Leader>a:: :Tabularize /:\zs<CR>
vmap <Leader>a:: :Tabularize /:\zs<CR>
nmap <Leader>a, :Tabularize /,<CR>
vmap <Leader>a, :Tabularize /,<CR>
nmap <Leader>a,, :Tabularize /,\zs<CR>
vmap <Leader>a,, :Tabularize /,\zs<CR>
nmap <Leader>a<Bar> :Tabularize /<Bar><CR>
vmap <Leader>a<Bar> :Tabularize /<Bar><CR>

"-------------------------------------------------------------------------------
" Saving
"-------------------------------------------------------------------------------
set nobackup            " Do not keep a backup file
set nowb                " Do not write to a backup file
set noswapfile          " Do not create a swap file

" Remember cursor position when opening again
augroup vim_save
    autocmd!
    autocmd BufReadPost *
    \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif
augroup END

" Remember info about open buffers on close
set viminfo^=%

"-------------------------------------------------------------------------------
" I don't know what is this for
"-------------------------------------------------------------------------------
" Don't use Ex mode, use Q for formatting
map Q gq

" CTRL-U in insert mode deletes a lot.  Use CTRL-G u to first break undo,
" so that you can undo CTRL-U after inserting a line break.
inoremap <C-U> <C-G>u<C-U>
