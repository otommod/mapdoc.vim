" File:        mapdoc.vim
" Description: Document your mappings
" Authors:     Otto Modinos <ottomodinos@gmail.com>
" Version:     0.0.1

scriptencoding utf-8

if &cp || v:version < 700 || exists('g:loaded_mapdoc')
    finish
endif
let g:loaded_mapdoc = 1

if !exists('g:mapdoc_vertical')
    let g:mapdoc_position = 'down'
endif

if !exists('g:mapdoc_source')
    let g:mapdoc_source = 'mapdoc#source#comments#for'
endif
