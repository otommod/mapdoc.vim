function! s:scripts()
    redir => lines
        silent! scriptnames
    redir END
    let scripts = split(lines, '\n')
    call map(scripts, 'matchstr(v:val, "\\d\\+: \\zs.*")')
    return map(scripts, 'fnamemodify(v:val, ":p")')
endfunction

function! s:script_sid(file)
    return s:scripts().index(fnamemodify(a:file, ':p'))
endif

function! s:all_map_comments(file)
    let docs = {}
    let prev_line = ''
    for line in readfile(a:file)
        let mapcmd = matchstr(line, '\c^\a*map\a*!\?\s*\zs.*')
        if !empty(mapcmd)
            let comment = matchstr(prev_line, '^"\s*\zs.*')
            if !empty(comment)
                let docs[mapcmd] = comment
            endif
        endif
        let prev_line = line
    endfor
    return docs
endfunction

let s:VIMRC_SID = s:script_sid($MYVIMRC)
let s:VIMRC_MAPS = s:all_map_comments($MYVIMRC)

function! mapdoc#source#comments#for(keydef)
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
