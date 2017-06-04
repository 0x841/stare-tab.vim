" ------------------------------------------------------------------------------
" staretab.vim
" ------------------------------------------------------------------------------

" Minimum "minimum tab length" is 10.
let s:MIN_MIN_TAB_LEN = 10

" Default minimum tab length is 15.
let s:DEF_MIN_TAB_LEN = 15

" This function is set on the setting of tabline.
function! staretab#tabline()
    if exists('g:staretab#min_tab_len')
                              \ && type(g:staretab#min_tab_len) == v:t_number
                              \ && g:staretab#min_tab_len >= s:MIN_MIN_TAB_LEN
        let l:min_tab_len = g:staretab#min_tab_len
    else
        let l:min_tab_len = s:DEF_MIN_TAB_LEN
    endif

    let l:tab_num = tabpagenr('$')
    let l:cur_tab_num = tabpagenr()
    let l:head_tab_num = 1
    let l:foot_tab_num = l:tab_num
    let l:tl_len = &columns
    let l:is_overflow = l:min_tab_len * l:tab_num > l:tl_len ? v:true : v:false
    let l:tabline = ''
    let l:tl_foot = ''

    " Settings when there are many tabs.
    if l:is_overflow
        let l:short_len = (l:tl_len - l:min_tab_len) / 2
        let l:long_len = l:tl_len - l:min_tab_len - l:short_len

        if l:long_len >= l:min_tab_len * (l:tab_num - l:cur_tab_num)
            let l:tl_foot_len = l:min_tab_len * (l:tab_num - l:cur_tab_num)
            let l:tl_head_len = l:tl_len - l:min_tab_len - l:tl_foot_len
        else
            let l:tl_foot = '[' . l:tab_num . ']'
            let l:short_len = (l:tl_len - strwidth(l:tl_foot) - l:min_tab_len)/2
            let l:long_len = l:tl_len - strwidth(l:tl_foot)
                                                \ - l:min_tab_len - l:short_len

            if l:long_len >= l:min_tab_len * (l:cur_tab_num - 1)
                let l:tl_head_len = l:min_tab_len * (l:cur_tab_num - 1)
                let l:tl_foot_len = l:tl_len - strwidth(l:tl_foot)
                                            \ - l:min_tab_len - l:tl_head_len
            else 
                let l:tl_head_len = l:long_len
                let l:tl_foot_len = l:short_len
            endif
        endif

        let l:head_tab_num = l:cur_tab_num
                        \ - (l:tl_head_len + l:min_tab_len - 1) / l:min_tab_len
        let l:foot_tab_num = l:cur_tab_num
                        \ + (l:tl_foot_len + l:min_tab_len - 1) / l:min_tab_len
        let l:head_tab_len = l:tl_head_len % l:min_tab_len
        let l:foot_tab_len = l:tl_foot_len % l:min_tab_len
    endif

    for l:i in range(l:head_tab_num, l:foot_tab_num)
        let l:buflist = tabpagebuflist(l:i)
        let l:bufid = l:buflist[tabpagewinnr(l:i) - 1]
        let l:tab_len = (l:tl_len + l:tab_num - l:i) / l:tab_num
        if l:tab_len < l:min_tab_len
            let l:tab_len = l:min_tab_len
        endif

        " Tab ID.
        let l:tab_id = '(' . l:i . ') '
        let l:tab_len -= strwidth(l:tab_id)

        " Additional information.
        let l:bufnum = len(l:buflist)
        if l:bufnum <= 1
            let l:bufnum = ''
        endif
        let l:modified = ''
        for l:buftemp in l:buflist
            if getbufvar(l:buftemp, '&modified')
                let l:modified = '+'
                break
            endif
        endfor
        let l:addinfo = ''
        if l:bufnum != '' || l:modified != ''
            let l:addinfo = '[' . l:bufnum . l:modified .'] '
        endif
        let l:tab_len -= strwidth(l:addinfo)

        " Filename.
        let l:filename = pathshorten(fnamemodify(bufname(l:bufid), ':t'))
        if l:filename == ''
            let l:filename = '[No Name]'
        endif
        if l:tab_len - strwidth(l:filename) - 1 < 0
            let l:filename = s:hew_str(l:filename, 0, l:tab_len - 3) . '>'
        endif
        let l:filename .= ' '
        for l:j in range(strwidth(l:filename) + 1, l:tab_len)
            let l:addinfo .= ' '
        endfor

        " Hew the string at the verge.
        let l:temp_str = l:tab_id . l:filename . l:addinfo
        if l:is_overflow && l:i != l:cur_tab_num
            if l:i == l:head_tab_num
                let l:temp_str = s:hew_str(l:temp_str, -(l:head_tab_len), -1)
                if strwidth(l:temp_str) < l:head_tab_len
                    let l:temp_str = ' ' . l:temp_str
                endif
            elseif l:i == l:foot_tab_num
                let l:temp_str = s:hew_str(l:temp_str, 0, l:foot_tab_len - 1)
                if strwidth(l:temp_str) < l:foot_tab_len
                    let l:temp_str .= ' '
                endif
            endif
        endif

        " Highlight group label.
        if l:i == l:cur_tab_num
            let l:tabline .= '%#TabLineSel#'
        elseif l:i == l:head_tab_num
            let l:tabline .= '%#TabLine#'
        elseif l:i == l:cur_tab_num + 1
            let l:tabline .= '%#TabLine#'
        endif

        " Set the string with a tab label.
        let l:tabline .= '%' . l:i . 'T' . l:temp_str . '%T'
    endfor

    " Tab number.
    if l:tl_foot != ''
        let l:tabline .= '%#TabLineFill#' . l:tl_foot
    endif

    return l:tabline
endfunction


" This function hews a string.
function! s:hew_str(str, head, foot)
    if strwidth(a:str) == strchars(a:str)
        let l:result =  a:str[a:head : a:foot]
    else
        let l:str_split = split(a:str, '\zs')
        let l:input_len = len(l:str_split)
        let l:head_num = a:head + (a:head < -1 ? strwidth(a:str) : 0)
        let l:foot_num = a:foot + (a:foot < -1 ? strwidth(a:str) : 0)

        let l:result_head_num = 0
        if l:head_num > 0
            for l:i in range(l:input_len - 1)
                if strwidth(join(l:str_split[: l:i], '')) >= l:head_num
                    let l:result_head_num = l:i + 1
                    break
                endif
            endfor
        endif

        let l:result_foot_num = -1
        if l:foot_num > -1
            for l:i in range(l:result_head_num, l:input_len - 1)
                let l:temp_len = strwidth(join(l:str_split[: l:i], ''))
                if l:temp_len >= l:foot_num + 1
                    if l:temp_len > l:foot_num + 1
                        let l:result_foot_num = l:i - 1
                    else
                        let l:result_foot_num = l:i
                    endif
                    break
                endif
            endfor
        endif

        let l:result =
                \ join(l:str_split[l:result_head_num : l:result_foot_num], '')
    endif
    
    return l:result
endfunction

