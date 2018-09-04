set nocompatible              " be iMproved, required
filetype off                  " required

"set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'gmarik/Vundle.vim'
"Plugin 'ervandew/supertab'
Plugin 'Valloric/YouCompleteMe'
Plugin 'majutsushi/tagbar'
Plugin 'scrooloose/nerdtree'
Plugin 'Shougo/unite.vim'
Plugin 'devjoe/vim-codequery'
Plugin 'mileszs/ack.vim'
Plugin 'flazz/vim-colorschemes'
Plugin 'BufOnly'
Plugin 'vim-airline/vim-airline'
Plugin 'jreybert/vimagit'
Plugin 'rdnetto/YCM-Generator'
Plugin 'ctrlpvim/ctrlp.vim'
Plugin 'will133/vim-dirdiff'
call vundle#end()
"Disable YCM:
"let g:loaded_youcompleteme = 1
 filetype plugin indent on    " required
 " To ignore plugin indent changes, instead use:
 "filetype plugin on
 "
 " Brief help
 " :PluginList       - lists configured plugins
 " :PluginInstall    - installs plugins; append `!` to update or just
 " :PluginUpdate
 " :PluginSearch foo - searches for foo; append `!` to refresh local cache
 " :PluginClean      - confirms removal of unused plugins; append `!` to
 "
 " see :h vundle for more details or wiki for FAQ
 " Put your non-Plugin stuff after this line
" libclang path for clang_completer
set tags=tags;
"Bind F8 with Tagbar Toggle
nmap <F8> :TagbarToggle<CR>
"Bind F9 to NERDTree
nmap <F9> :NERDTreeToggle<CR>
"Bind F10 to CodeQuery Unite Magic window
nmap <F10> :CodeQueryMenu Unite Magic<CR>

nmap <Leader>x :CodeQuery<CR>
nmap <Leader>T :YcmCompleter GetType<CR>
nmap <Leader>F :YcmCompleter FixIt<CR>
"Autostart NerdTree with Vim
"autocmd vimenter * NERDTree
"Autostart the code completer unite magic
"autocmd vimenter * CodeQueryMenu Unite Magic 
"nnoremap <silent> <F8> :TlistToggle<CR>
filetype plugin indent on
syntax on
autocmd BufRead,BufNewFile *.cl set filetype=c
autocmd BufRead,BufNewFile *.p4 set filetype=c
autocmd BufRead,BufNewFile *.sv set filetype=verilog
autocmd BufRead,BufNewFile *.vh set filetype=verilog
autocmd BufRead,BufNewFile *.cpp.mako set filetype=cpp
autocmd BufRead,BufNewFile *.h.mako set filetype=h
autocmd BufRead,BufNewFile *.v.mako set filetype=verilog
autocmd BufRead,BufNewFile *.sv.mako set filetype=verilog

set t_Co=256
colo Benokai
" YCM options 
" Allow YCM to populate location list with errors in the current file
let g:ycm_always_populate_location_list = 1
"Disable YCM
"let g:loaded_youcompleteme = 1
"let g:ycm_global_ycm_extra_conf = '/home/jehandad/.vim/bundle/YouCompleteMe/.ycm_global_ycm_extra_conf.py'
"set completeopt -=preview
"let g:ycm_add_preview_to_completeopt = 1
let g:ycm_autoclose_preview_window_after_insertion = 1
"let g:ycm_key_list_select_completion = ['<TAB>', '<Down>']
""Turn off the line by line compile error report (set to zero)
let g:ycm_show_diagnostics_ui = 1
""Enable collection of tags from ctags
"let g:ycm_collect_identifiers_from_tags_file = 1

" The following is from my local pc's .vimrc
set foldmethod=syntax 
set foldnestmax=10
set nofoldenable
set foldlevel=1
set nowrap
set autoindent 
set number
set hlsearch
"Set the tabs to four and other goddies
set tabstop=8 softtabstop=0 expandtab shiftwidth=4 smarttab
"Fix the backspace problem
set backspace=2
if &term =~ '256color'
" disable Background Color Erase (BCE) so that color schemes
" render properly when inside 256-color tmux and GNU screen.
"     " see also http://snk.tuxfamily.org/log/vim-256color-bce.html
  set t_ut=
endif
"Highlight column width more than 80
if exists('+colorcolumn')
	set colorcolumn=80
else
	au BufWinEnter * let w:m2=matchadd('ErrorMsg', '\%>80v.\+', -1)
endif
augroup qf
    autocmd!
    autocmd FileType qf set nobuflisted
augroup END
"" Config for clang_complete and clang_indexer
"let g:clang_auto_select=1
"let g:clang_hl_errors=1
"let g:clang_periodic_quickfix=0
"let g:clang_snippets=1
"let g:clang_snippets_engine="clang_complete"
"let g:clang_conceal_snippets=1
"let g:clang_exec="clang"
"let g:clang_user_options=""
"let g:clang_auto_user_options="path, .clang_complete"
"let g:clang_use_library=1
"let g:clang_library_path="/usr/lib/x86_64-linux-gnu/"
"let g:clang_sort_algo="priority"
"let g:clang_complete_macros=1
"let g:clang_complete_patterns=0
"nnoremap <Leader>q :call g:ClangUpdateQuickFix()<CR>
"
"let g:clic_filename="/home/jd/MLOpen/idx/index.db"
"nnoremap <Leader>x :call ClangGetReferences()<CR>
"nnoremap <Leader>d :call ClangGetDeclarations()<CR>
"nnoremap <Leader>s :call ClangGetSubclasses()<CR>
"set completeopt=menu,menuone,longest
"set pumheight=15
"let g:SuperTabDefaultCompletionType="context"
"let g:clang_complete_auto=0
"let g:clang_complete_copen=1
"" end clang_completer and clang_indexer config
