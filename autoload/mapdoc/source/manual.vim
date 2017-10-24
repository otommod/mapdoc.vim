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

function! mapdoc#source#manual#for(keydef)
    if a:keydef.type =~ 'group'
        let [found, doc] = s:find_docs(g:mapdoc_docs, [a:keydef.key])
        return found ? doc : 'group'
    else
        let keys = mapdoc#utils#splitmap(a:keydef.info.lhs)
        let [found, doc] = s:find_docs(g:mapdoc_docs, keys)
        return found ? doc : substitute(a:keydef.info.rhs, '\c<cr>$', '', '')
    endif
endfunction
