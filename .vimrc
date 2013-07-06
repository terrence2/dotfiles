" += M
set nocompatible

" Default to a sane encoding.
set encoding=utf-8

" Set dark colorscheme
colorscheme torte

" Vundle Configuration
filetype off
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()
Bundle 'gmarik/vundle'
  " My Bundles here:
Bundle 'scrooloose/nerdtree'
Bundle 'klen/python-mode'
"Bundle 'wesleyche/SrcExpl'
filetype plugin indent on

" enable pathogen
call pathogen#infect()

" Configure NERD Tree
nmap <F7> :NERDTreeToggle<CR>

" Configure SrcExpl
"nmap <F8> :SrcExplToggle<CR>
"let g:SrcExpl_pluginList = [
"        \ "__Tag_List__",
"        \ "_NERD_tree_",
"        \ "Source_Explorer"
"    \ ]
"let g:SrcExpl_searchLocalDef = 0
"let g:SrcExpl_isUpdateTags = 0
"let g:SrcExpl_updateTagsCmd = "ctags --sort=foldcase **/*.cpp **/*.h"
"let g:SrcExpl_updateTagsKey = "<F12>"

" Configure SrcExpl
"map <C-S-O> :SrcExplToggle<CR>

" show line/column at bottom
set ruler

" Line wrapping.
set tw=99
set cc=+1

" allow backspace across lines
set backspace=2

" 4 space tabs
set expandtab
set tabstop=4
set sw=4

" Auto/Smart-indent everywhere.
set autoindent
set smartindent

" Set cindent, but only for C(++) files.
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

" Enable conceal -- used for our C(++) replacement chars.
set conceallevel=2

" Tab complete filenames
set wildmode=longest,list,full
set wildmenu

" Mouse hiding frenquently doesn't unhide in qtile.
set nomh

