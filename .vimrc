set nocompatible              " be iMproved, required
filetype off                  " required

set rtp+=~/.vim/bundle/nerdtree
"set the runtime path to include Vundle and initialize
"set rtp+=~/.vim/bundle/Vundle.vim
"call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
 "call vundle#begin('~/some/path/here')

 " let Vundle manage Vundle, required
 "Plugin 'gmarik/Vundle.vim'
 " Plugin 'Valloric/YouCompleteMe'
 " The following are examples of different formats supported.
 " Keep Plugin commands between vundle#begin/end.
 " plugin on GitHub repo
 "Plugin 'tpope/vim-fugitive'
 " plugin from http://vim-scripts.org/vim/scripts.html
 "Plugin 'L9'
 " Git plugin not hosted on GitHub
 "Plugin 'git://git.wincent.com/command-t.git'
 " git repos on your local machine (i.e. when working on your own plugin)
 "Plugin 'file:///home/gmarik/path/to/plugin'
 " The sparkup vim script is in a subdirectory of this repo called vim.
 " Pass the path to set the runtimepath properly.
 "Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
 " Avoid a name conflict with L9
 "Plugin 'user/L9', {'name': 'newL9'}

 " All of your Plugins must be added before the following line
 "call vundle#end()            " required
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

set tags=tags;
"Enable Tlist toggle with F8
nnoremap <silent> <F8> :TlistToggle<CR>
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
colo blue
" YCM options 
"Disable YCM
"let g:loaded_youcompleteme = 1
let g:ycm_global_ycm_extra_conf = '/home/jehandad/.vim/bundle/YouCompleteMe/.ycm_global_ycm_extra_conf.py'
"set completeopt -=preview
"let g:ycm_add_preview_to_completeopt = 1
let g:ycm_autoclose_preview_window_after_insertion = 1
"let g:ycm_key_list_select_completion = ['<TAB>', '<Down>']
""Turn off the annoying line by line compile error report
"let g:ycm_show_diagnostics_ui = 0
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
