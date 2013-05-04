set nocompatible

colorscheme torte

" enable pathogen
call pathogen#infect()

" show line/column at bottom
set ruler

" 80 char wrapping
set tw=80

" allow backspace across lines
set backspace=2

" 4 space tabs
set expandtab
set tabstop=4
set sw=4

" Auto-indent
set autoindent
set smartindent
"set cindent
au BufNewFile,BufReadPost *.c setl cindent
au BufNewFile,BufReadPost *.C setl cindent
au BufNewFile,BufReadPost *.cpp setl cindent

" Don't abandon hidden buffers
set hidden

" Highlight the current line.
"Note: totally busted on dark themes
"set cursorline

" Show context when searching.
set scrolloff=8

" Highlight whitespace at ends of lines
:highlight ExtraWhitespace ctermbg=red guibg=red
:match ExtraWhitespace /\s\+\%#\@<!$/
:match
:au InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
:au InsertLeave * match ExtraWhitespace /\s\+$/

" Enable conceal
set conceallevel=2

" Tab complete filenames
set wildmode=longest,list,full
set wildmenu

" Mouse hiding frenquently doesn't unhide.
set nomh
