
if !exists('g:gounit_bin')
    let g:gounit_bin = 'gounit'
endif

function! s:Tests() range
    let bin = g:gounit_bin
    if !executable(bin)
        echom 'gounit-vim: gounit binary not found.'
        return
    endif

    let funcLine = 0
    for lineno in range(a:firstline, a:lastline)
        let funcName = matchstr(getline(lineno), '^func\s*\(([^)]\+)\)\=\s*\zs\w\+\ze(')
        if funcName != ''
            let funcLine = lineno
        endif
    endfor
    if funcLine == 0
        echom 'gounit-vim: No function selected!'
        return
    endif


    let file = expand('%')
    let out = system(bin . ' -l ' . shellescape(funcLine) . ' -i ' . shellescape(file))
    if out != ''
      echom 'gounit-vim: ' . out
    else
      echom 'gounit-vim: test successfully generated'
    endif
endfunction

command! -range GoUnit <line1>,<line2>call s:Tests()
