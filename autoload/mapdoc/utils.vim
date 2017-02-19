function! mapdoc#utils#char2raw(char)
    let leader = exists('mapleader') && len(mapleader) ? mapleader : '\'
    let localleader = exists('maplocalleader') && len(maplocalleader) ? maplocalleader : leader

    let char = escape(a:char, '"\')
    let char = substitute(char, '\c<leader>', leader, 'g')
    let char = substitute(char, '\c<localleader>', localleader, 'g')
    let char = substitute(char, '<\(.\{-1,\}\)>', '\\<\1>', 'g')
    return eval('"'.char.'"')
endfun


function! mapdoc#utils#splitmap(map)
    " TODO: write as a regex only, FOR SPEED
    " FIXME: the following almost works; it splits 'foo<Foo>' into ['f', 'o', 'o<Foo>']
    "return split(a:map, '\v(\<.{-1,}\>)?\zs')

    let i = 0
    let splt = []
    while i < strchars(a:map)
        let key = strcharpart(a:map, i, 1)
        let keynr = char2nr(key)
        if keynr > 127 && keynr < 256  " alt + key probably
            let key = '<A-'.nr2char(xor(keynr, 128)).'>'
        elseif key == '<'              " special key, like <F10>
            let mch = matchstr(a:map, '<.\{-1,}>', i)
            if len(mch)
                let key = mch
                let i += strchars(mch) - 1
            endif
        endif
        call add(splt, key)
        let i += 1
    endwhile
    return splt
endfunction


function! mapdoc#utils#getraw()
    let rawkey = getchar()
    if type(rawkey) == type(0)
        " we can just get a character via nr2char
        let rawkey = nr2char(rawkey)
    elseif type(rawkey) == type("")
        " we should also perhaps check what getcharmod says, but we won't have
        " anything to do with anyways and in the terminal I haven't managed to
        " find a case where the modifier can't be 'embedded' in the char
        " itself
    else
        " should never happen
        echoerr 'mapdoc#utils#getraw(): unknown type:' type(rawkey)
    endif

    if rawkey == mapdoc#utils#char2raw('<CursorHold>')
        " keep waiting
        return mapdoc#utils#getraw()
    endif

    return rawkey
endfunction
