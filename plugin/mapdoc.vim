if !exists('g:mapdoc_vertical')
    let g:mapdoc_vertical = 0
endif

if !exists('g:mapdoc_left')
    let g:mapdoc_left = 1
endif

if !exists('g:mapdoc_formatter')
    let g:mapdoc_formatter = 'mapdoc#formatters#from_comments'
endif

" The rest are formatter specific options

if !exists('g:mapdoc_docs')
    let g:mapdoc_docs = {}
endif
