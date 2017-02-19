function! s:add_to_dict(dict, raw, value)
    if !has_key(a:dict, a:raw)
        let a:dict[a:raw] = a:value
    elseif a:dict[a:raw].type !~ a:value.type
        let a:value.type = 'key+group'
        call extend(a:dict[a:raw], a:value)
    endif
endfunction

function! s:add_group_to_dict(dict, raw, key)
    call s:add_to_dict(a:dict, a:raw, {
        \ 'type': 'group',
        \ 'key': a:key,
        \ 'mappings': {},
    \ })
    return a:dict[a:raw].mappings
endfunction

function! s:add_key_to_dict(dict, raw, key, info)
    call s:add_to_dict(a:dict, a:raw, {
        \ 'type': 'key',
        \ 'key': a:key,
        \ 'info': a:info,
    \ })
    return a:dict
endfunction

function! s:add_map_to_dict(dict, map, info)
    let keys = mapdoc#utils#splitmap(a:map)

    " add all the keys up to but excluding the last as 'groups'
    let curlevel = a:dict
    for key in keys[:-2]
        let raw = mapdoc#utils#char2raw(key)
        let curlevel = s:add_group_to_dict(curlevel, raw, key)
    endfor

    if len(keys)
        let lastkey = keys[-1]
        let lastraw = mapdoc#utils#char2raw(lastkey)
        call s:add_key_to_dict(curlevel, lastraw, lastkey, a:info)
    endif
    return a:dict
endfunction

function! s:flatten_dict(dict)
    let mappings = items(a:dict)
    for [r1, k1] in mappings
        if k1.type == 'key+group'
            for [r2, k2] in items(k1.mappings)
                let k2.key = k1.key . k2.key
                let a:dict[r1.r2] = k2
            endfor
            let k1.type = 'key'
            unlet k1.mappings
        elseif k1.type == 'group'
            call s:flatten_dict(k1.mappings)
        endif
    endfor
    return a:dict
endfunction


function! s:all_mappings(prefix, ...)
    let in_modes = get(a:000, 0, '')

    redir => rawmaps
    silent exec 'map' a:prefix
    redir END

    let maps = {}
    let rawmaplines = split(rawmaps, '\n')
    for m in rawmaplines
        " The mode takes at most 3 chars, meaning that there may be no space
        " between the mode and the key itself, meaning `split()` on its own
        " may not separate mode from key.
        let [key; rest] = split(m[3:])
        " maparg() can find the mapping given just one of the modes it's
        " defined in, so the first char (i.e. mode) will suffice.
        let mapinfo = maparg(key, m[0], 0, 1)

        " Skip <Plug> and script-local mappings.
        if mapinfo.lhs =~ '<Plug>.*' || mapinfo.lhs =~ '<SNR>.*'
            continue
        endif

        "if index(in_modes, mapinfo.mode) > -1
        " TODO: implement in_modes
        "endif

        let postfix = substitute(mapinfo.lhs, a:prefix, '', '')
        call s:add_map_to_dict(maps, postfix, mapinfo)
    endfor

    return maps
endfunction




let s:state = {
            \ 'bufnr': -1,
            \ 'winnr': -1,
            \ 'prevwinnr': -1,
            \ 'winview': {},
            \ 'winrest': '',
            \ }

function! s:winopen(vertical, size)
    if a:vertical
        let mode = 'vertical'
        let openpos = g:mapdoc_left ? 'topleft' : 'botright'
    else
        let mode = ''
        let openpos = g:mapdoc_left ? 'leftabove' : 'rightbelow'
    endif
    noautocmd exec 'silent keepalt' openpos mode a:size 'split' 'MapDoc'

    if bufexists(s:state.bufnr)
        " noautocmd exec 'buffer' s:state.bufnr
    else
        let s:state.bufnr = bufnr('%')
        autocmd WinLeave <buffer> call s:winclose()
    endif

    let s:state.winnr = winnr()
    setlocal filetype=mapdoc
    setlocal nonumber norelativenumber nolist nomodeline nowrap nopaste
    setlocal nobuflisted buftype=nofile bufhidden=unload noswapfile
    setlocal nocursorline nocursorcolumn colorcolumn=
    setlocal winfixwidth winfixheight
endfunction

function! s:winclose()
    noautocmd exec s:state.winnr 'wincmd w'
    if s:state.bufnr == bufnr('%')
        close
        exec s:state.winrest
        call winrestview(s:state.winview)
    endif
endfunction


function! s:map_display(keydef)
    let desc = call(g:mapdoc_formatter, [a:keydef])
    return printf('[%s] %s', a:keydef.key, desc)
endfunction

function! s:layout_for(mapdict)
    let items = len(a:mapdict)
    let lens = map(values(a:mapdict), 'strdisplaywidth(s:map_display(v:val))')
    let maxlen = max(lens) + 5  " TODO: make this configurable

    if g:mapdoc_vertical
        let rows = winheight(0) - 2
        let cols = items / rows + (items != rows)
        let col_size = maxlen
        let win_size = cols * col_size
    else
        let cols = winwidth(0) / maxlen
        let rows = items / cols + (fmod(items, cols) > 0)
        let col_size = winwidth(0) / cols
        let win_size = rows
    endif

    return {'rows': rows - 1,
          \ 'cols': cols,
          \ 'col_size': col_size,
          \ 'win_size': win_size}
endfunction


function! s:compare_keydef(a, b)
    return a:a.key == a:b.key ? 0 : a:a.key > a:b.key ? 1 : -1
endfunction

function! s:render_doc(mapdict, layout)
    let col = 0
    let row = []
    let rows = [row]
    let maps = sort(values(a:mapdict), 's:compare_keydef')
    for m in maps
        let dispstr = s:map_display(m)
        let fillspace = a:layout.col_size - strdisplaywidth(dispstr)
        call add(row, dispstr)

        if col >= a:layout.cols - 1
            let col = 0
            let row = []
            call add(rows, row)
        else
            let col += 1
            call add(row, repeat(' ', fillspace))
        endif
    endfor

    silent! unlet row[-1]      " remove trailing whitespace if row did not end
    return map(rows, 'join(v:val, "")')  " join all the row lists into strings
endfunction


function! s:bufcreate(mapdict, keys_typed)
    let s:state.winview = winsaveview()
    let s:state.winrest = winrestcmd()
    let layout = s:layout_for(a:mapdict)
    let lines = s:render_doc(a:mapdict, layout)

    " if g:leaderGuide_max_size
    "     let layout.win_size = min([g:leaderGuide_max_size, layout.win_size])
    " endif

    " FIXME: when there is only a single line in the buffer it is not shown
    let layout.win_size += 1
    call s:winopen(g:mapdoc_vertical, layout.win_size)

    setlocal modifiable
    call append(0, lines)
    setlocal nomodifiable

    call s:main_loop(a:mapdict, a:keys_typed)
endfunction

function! s:main_loop(mapdict, keys_typed)
    redraw

    let rawkey = mapdoc#utils#getraw()
    call s:winclose()

    if len(rawkey)
        let fsel = get(a:mapdict, rawkey)
        if !has_key(a:mapdict, rawkey)
            echoerr 'No such mapping:' rawkey
        elseif fsel.type =~ 'group'
            call s:bufcreate(fsel.mappings, a:keys_typed.rawkey)
        elseif fsel.type == 'key'
            redraw
            call feedkeys(v:register.v:count.a:keys_typed.rawkey, 'mt')
        endif
    endif
endfunction


function! mapdoc#(...)
    let prefix = get(a:000, 0, '')
    let flatten = get(a:000, 1, 0)
    let mappings = s:all_mappings(prefix)
    return flatten ? s:flatten_dict(mappings) : mappings
endfunction

function! mapdoc#display(...)
    let prefix = get(a:000, 0, '')
    let flatten = get(a:000, 1, 0)
    call s:bufcreate(mapdoc#(prefix, flatten), mapdoc#utils#char2raw(prefix))
endfunction
