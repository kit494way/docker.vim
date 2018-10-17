"=============================================================================
" FILE: docker.vim
" AUTHOR: KITAGAWA Yasutaka <kit494way@gmail.com>
" License: MIT license
"=============================================================================

function! docker#edit(path) abort
    let tmpfile = tempname()
    silent call docker#cp(a:path, tmpfile)
    execute 'e ' . tmpfile
    let b:docker_edit_path = a:path
    silent autocmd BufWritePost <buffer> call docker#write(b:docker_edit_path)
endfunction

function! docker#write(dst) abort
    silent call docker#cp(expand('%'), a:dst)
    echom 'Written to ' . a:dst
endfunction

function! docker#upload() abort
    let src = expand('%:p')
    let dst = s:container_path(s:path_in_project())
    silent call docker#cp(src, dst)
    echom 'Copied to ' . dst
endfunction

function! docker#download() abort
    let src = s:container_path(s:path_in_project())
    let dst = expand('%:p')
    silent call docker#cp(src, dst)
    silent e!
    echom 'Copied from ' . src
endfunction

function! docker#diff_file() abort
    let path = s:path_in_project()
    let cat_cmd = '0r !docker exec ' . b:docker_container . ' cat ' . s:container_path(path, 0)
    silent diffthis
    silent execute 'bot vnew +setlocal\ buftype=nofile\ bufhidden=hide\ noswapfile ' . s:container_path(path)
    silent autocmd BufDelete <buffer> diffoff!
    silent execute cat_cmd
    silent $d
    silent diffthis
    silent set readonly
endfunction

function! docker#cp(src, dst)
    execute '!docker cp ' . a:src . ' ' . a:dst
endfunction

function! s:container_path(path, ...)
    if a:0 > 0 && !a:1
        return simplify(b:docker_container_dir . '/' . a:path)
    else
        return b:docker_container . ':' . simplify(b:docker_container_dir . '/' . a:path)
    endif
endfunction

function! s:path_in_project()
    let current = expand('%:p')
    let pattern = '^' . simplify(b:docker_local_dir . '/')
    if match(current, pattern) < 0
        return ''
    endif
    return substitute(current, pattern, '', 'g')
endfunction
