function s:find_docs(dict, keys)
    let curdict = a:dict
    for k in a:keys
        if type(curdict) != type({}) || !has_key(curdict, k)
            return [0, '']
        endif
        let curdict = curdict[k]
    endfor
    return !has_key(curdict, 'name') ? [0, ''] : [1, curdict.name]
endfunction

function! mapdoc#formatters#user_docs(keydef)
    let keys = mapdoc#utils#splitmap(a:keydef.info.lhs)
    let [found, doc] = s:find_docs(g:mapdoc_docs, keys)
    if found
        return doc
    elseif a:keydef.type =~ 'group'
        return 'group'
    else
        return substitute(a:keydef.info.rhs, '\c<cr>$', '', '')
    endif
endfunction


function! s:script_sid()
    redir => rawlines
    silent scriptnames
    redir END
    let lines = split(rawlines, '\n')

    let scrpts = []
    for line in lines
        let scrpt = matchstr(line, '\d\+: \zs.*')
        let sfile = fnamemodify(scrpt, ':p')
        call add(scrpts, sfile)
    endfor
endfunction

function! s:all_map_comments(file)
    let lines = readfile(a:file)
    let idx = 0
    let docs = {}
    for line in lines
        let mapcmd = matchstr(line, '\c^\a*map\a*!\?\s*\zs.*')
        if !empty(mapcmd)
            let prev_line = lines[idx - 1]
            let comment = matchstr(prev_line, '^"\s*\zs.*')
            if !empty(comment)
                let docs[mapcmd] = comment
            endif
        endif
        let idx += 1
    endfor
    return docs
endfunction

let s:myvimrc = fnamemodify($MYVIMRC, ':p')
let s:VIMRC_SID = s:script_sid()[s:myvimrc]
let s:VIMRC_MAPS = s:all_map_comments(s:myvimrc)

function! mapdoc#formatters#from_comments(keydef)
    if a:keydef.type =~ 'group'
        return 'group'
    elseif a:keydef.info.sid == s:VIMRC_SID
        let matching_map = match(items(s:VIMRC_MAPS), (a:keydef.info.lhs))
        if matching_map >= 0
            return values(s:VIMRC_MAPS)[matching_map]
        endif
    else
        return substitute(a:keydef.info.rhs, '\c<cr>$', '', '')
    endif
endfunction
