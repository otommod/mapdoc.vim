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
    return s:find_docs(g:mapdoc_docs, a:keydef.type =~ 'group'
                \ ? [a:keydef.key]
                \ : mapdoc#utils#splitmap(a:keydef.info.lhs))
endfunction
