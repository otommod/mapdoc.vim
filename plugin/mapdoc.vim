if !exists('g:mapdoc_vertical')
    let g:mapdoc_vertical = 0
endif

if !exists('g:mapdoc_left')
    let g:mapdoc_left = 1
endif

if !exists('g:mapdoc_source')
    let g:mapdoc_source = 'mapdoc#source#comments#for'
endif

" The rest are source-specific options

if !exists('g:mapdoc_docs')
    let g:mapdoc_docs = {}
endif
