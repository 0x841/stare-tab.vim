" ------------------------------------------------------------------------------
" staretab.vim
" ------------------------------------------------------------------------------

" Minimum "minimum tab length" is 10.
let s:MIN_MIN_TAB_LEN = 10

" Default minimum tab length is 15.
let s:DEF_MIN_TAB_LEN = 15

function! staretab#tabline()
    let l:tab_num = tabpagenr('$')
    let l:cur_tab_id = tabpagenr()
    let l:tabline_len = &columns
    let l:min_tab_len = s:load_min_tab_len()
    let l:is_overflow = (l:min_tab_len * l:tab_num > l:tabline_len)

    let l:edge_tab_info = s:create_edge_tab_info(l:tab_num, l:cur_tab_id, l:tabline_len, l:min_tab_len, l:is_overflow)
    let l:tabline = s:create_tabline(l:tab_num, l:cur_tab_id, l:tabline_len, l:min_tab_len, l:is_overflow, l:edge_tab_info)

    return l:tabline
endfunction

function! s:load_min_tab_len() abort
    if exists('g:staretab#min_tab_len') && (type(g:staretab#min_tab_len) == type(0))
                \ && (g:staretab#min_tab_len >= s:MIN_MIN_TAB_LEN)
        return g:staretab#min_tab_len
    else
        return s:DEF_MIN_TAB_LEN
    endif
endfunction

function! s:create_edge_tab_info(tab_num, cur_tab_id, tabline_len, tab_len, is_overflow) abort
    if !a:is_overflow
        return {
        \   'head_tab_id'  : 1,
        \   'foot_tab_id'  : a:tab_num,
        \   'head_tab_len' : -1,
        \   'foot_tab_len' : -1,
        \   'tabline_foot' : ''
        \}
    endif

    " l:shorter_len and l:longer_len are the length of the left or right side of the current tab.
    let l:exclude_cur_tab_len = a:tabline_len - a:tab_len
    let l:shorter_len = l:exclude_cur_tab_len / 2
    let l:longer_len  = l:exclude_cur_tab_len - l:shorter_len

    if l:longer_len >= a:tab_len * (a:tab_num - a:cur_tab_id)
        let l:tabline_foot = ''
        let l:right_than_cur_tab_len = a:tab_len * (a:tab_num - a:cur_tab_id)
        let l:left_than_cur_tab_len  = l:exclude_cur_tab_len - l:right_than_cur_tab_len
    else
        let l:tabline_foot = '[' . a:tab_num . ']'
        let l:exclude_cur_tab_len -= strwidth(l:tabline_foot)
        let l:shorter_len = l:exclude_cur_tab_len / 2
        let l:longer_len  = l:exclude_cur_tab_len - l:shorter_len

        if l:longer_len >= a:tab_len * (a:cur_tab_id - 1)
            let l:left_than_cur_tab_len  = a:tab_len * (a:cur_tab_id - 1)
            let l:right_than_cur_tab_len = l:exclude_cur_tab_len - l:left_than_cur_tab_len
        else
            let l:left_than_cur_tab_len  = l:longer_len
            let l:right_than_cur_tab_len = l:shorter_len
        endif
    endif

    return {
    \   'head_tab_id'  : a:cur_tab_id - (l:left_than_cur_tab_len  + a:tab_len - 1) / a:tab_len,
    \   'foot_tab_id'  : a:cur_tab_id + (l:right_than_cur_tab_len + a:tab_len - 1) / a:tab_len,
    \   'head_tab_len' : l:left_than_cur_tab_len  % a:tab_len,
    \   'foot_tab_len' : l:right_than_cur_tab_len % a:tab_len,
    \   'tabline_foot' : l:tabline_foot
    \}
endfunction

function! s:create_tabline(tab_num, cur_tab_id, tabline_len, min_tab_len, is_overflow, edge_tab_info) abort
    let l:tabline = ''

    for l:i in range(a:edge_tab_info.head_tab_id, a:edge_tab_info.foot_tab_id)
        let l:buf_list = tabpagebuflist(l:i)
        let l:buf_id = l:buf_list[tabpagewinnr(l:i) - 1]
        let l:tab_len = (a:tabline_len + a:tab_num - l:i) / a:tab_num
        if l:tab_len < a:min_tab_len
            let l:tab_len = a:min_tab_len
        endif

        let l:tab_id = s:format_id(l:i)
        let l:tab_len -= strwidth(l:tab_id)

        let l:add_info = s:create_add_info(l:buf_list)
        let l:tab_len -= strwidth(l:add_info)

        let l:filename = s:load_filename(l:buf_id, l:tab_len)
        let l:tab_len -= strwidth(l:filename)

        let l:tab_string = l:tab_id . l:filename . l:add_info . repeat(' ', l:tab_len)

        if a:is_overflow
            let l:tab_string = s:hew_edge_str(l:tab_string, a:edge_tab_info, l:i)
        endif

        let l:tab_string = s:load_highlight_label(l:i, a:edge_tab_info.head_tab_id, a:cur_tab_id) . l:tab_string
        let l:tabline .= s:create_tab_label(l:tab_string, l:i)
    endfor

    let l:tabline .= s:format_footer(a:edge_tab_info.tabline_foot)

    return l:tabline
endfunction

function! s:format_id(id) abort
    return '(' . a:id . ') '
endfunction

function! s:create_add_info(buf_list) abort
    let l:buf_num = len(a:buf_list)
    if l:buf_num <= 1
        let l:buf_num = ''
    endif

    let l:modified = ''
    for l:buf in a:buf_list
        if getbufvar(l:buf, '&modified')
            let l:modified = '+'
            break
        endif
    endfor

    let l:add_info = ''
    if l:buf_num != '' || l:modified != ''
        let l:add_info = '[' . l:buf_num . l:modified . '] '
    endif

    return l:add_info
endfunction

function! s:load_filename(buf_id, tab_len) abort
    let l:filename = fnamemodify(bufname(a:buf_id) , ':t')
    if l:filename == ''
        let l:filename = '[No Name]'
    endif

    if a:tab_len - strwidth(l:filename) - 1 < 0
        let l:filename = s:hew_str(l:filename , 0, a:tab_len - 3) . '>'
    endif

    let l:filename .= ' '
    return l:filename
endfunction

function! s:hew_edge_str(tab_string, edge_tab_info, id) abort
    if a:id == a:edge_tab_info.head_tab_id
        let l:hewed_str = s:hew_str(a:tab_string, -a:edge_tab_info.head_tab_len, -1)
        if strwidth(l:hewed_str) < a:edge_tab_info.head_tab_len
            let l:hewed_str = ' ' . l:hewed_str
        endif
    elseif a:id == a:edge_tab_info.foot_tab_id
        let l:hewed_str = s:hew_str(a:tab_string, 0, a:edge_tab_info.foot_tab_len - 1)
        if strwidth(l:hewed_str) < a:edge_tab_info.foot_tab_len
            let l:hewed_str .= ' '
        endif
    else
        let l:hewed_str = a:tab_string
    endif

    return l:hewed_str
endfunction

function! s:load_highlight_label(id, head_tab_id, current_tab_id) abort
    if a:id == a:current_tab_id
        return '%#TabLineSel#'
    elseif (a:id == a:head_tab_id) || (a:id == a:current_tab_id + 1)
        return '%#TabLine#'
    else
        return ''
    endif
endfunction

function! s:create_tab_label(tab_string, id) abort
    return '%' . a:id . 'T' . a:tab_string . '%T'
endfunction

function! s:format_footer(footer_str) abort
    if a:footer_str != ''
        return '%#TabLineFill#' . a:footer_str
    else
        return ''
    endif
endfunction

function! s:hew_str(str, head, foot)
    let l:str_width = strwidth(a:str)
    if l:str_width == strchars(a:str)
        return a:str[a:head : a:foot]
    else

    let l:splited_str = split(a:str, '\zs')
    let l:head_pos = a:head + (a:head < -1 ? l:str_width : 0)
    let l:foot_pos = a:foot + (a:foot < -1 ? l:str_width : 0)

    let l:head_index = 0
    for l:i in range(len(l:splited_str))
        if strwidth(join(l:splited_str[l:i :], '')) <= l:str_width - l:head_pos
            let l:head_index = l:i
            break
        endif
    endfor

    let l:foot_index = -1
    for l:i in range(len(l:splited_str) - 1, -1, -1)
        if strwidth(join(l:splited_str[: l:i], '')) <= l:foot_pos + 1
            let l:foot_index = l:i
            break
        endif
    endfor

    return join(l:splited_str[l:head_index : l:foot_index], '')
endfunction

