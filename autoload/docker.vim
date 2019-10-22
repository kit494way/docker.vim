"=============================================================================
" FILE: docker.vim
" AUTHOR: KITAGAWA Yasutaka <kit494way@gmail.com>
" License: MIT license
"=============================================================================

function! docker#edit(path) abort
    let ext = fnamemodify(a:path, ':e')
    if len(ext) > 0
        let tmpfile = tempname() . '.' . ext
    else
        let tmpfile = tempname()
    endif
    silent call docker#cp(a:path, tmpfile)
    execute 'e ' . tmpfile
    let b:docker_edit_path = a:path
    silent autocmd BufWritePost <buffer> call docker#write(b:docker_edit_path)
endfunction

function! docker#write_edit(dst) abort
    call docker#write(a:dst)
    let b:docker_edit_path = a:dst
    silent autocmd BufWritePost <buffer> call docker#write(b:docker_edit_path)
endfunction

function! docker#write(dst) abort
    silent call docker#cp(expand('%'), a:dst)
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
    call system('docker cp ' . a:src . ' ' . a:dst)
endfunction

function! s:container_path(path, ...)
    if a:0 > 0 && !a:1
        return simplify(b:docker_container_dir . '/' . a:path)
    else
        return b:docker_container . ':' . simplify(b:docker_container_dir . '/' . a:path)
    endif
endfunction

function! docker#exec(...) abort
    let cmd = 'docker container exec ' . join(a:000)
    if exists(':AsyncRun') == 2
        execute 'AsyncRun -raw ' . cmd
    else
        copen
        cgetexpr system(cmd)
    endif
endfunction

function! docker#play() abort
    let ext = expand('%:e')

    if len(ext) == 0
        echohl WarningMsg
        echomsg "No extension"
        return
    endif

    let params = s:docker_play_params(ext)
    if len(params) == 0
        return
    endif

    if exists('b:docker_play_container_tmpfile') == 0
python3 << EOF
import vim
import random
import string
seed = string.ascii_letters + string.digits
fname = ''.join([random.choice(seed) for _ in range(10)])
ext = vim.eval('ext')
vim.command('let b:docker_play_container_tmpfile = "{}.{}"'.format(fname, ext))
EOF
    endif

    if exists('b:docker_play_tmpfile') == 0
      let b:docker_play_tmpfile = tempname()
    endif

python3 << EOF
import vim
lines = '\n'.join(vim.current.buffer)
with open(vim.eval('b:docker_play_tmpfile'), 'w') as f:
    f.writelines(lines)
EOF

    let dst = params['container'] . ':' . b:docker_play_container_tmpfile
    silent call docker#cp(b:docker_play_tmpfile, dst)
    call docker#exec(params['container'], join(params['cmd']), b:docker_play_container_tmpfile)
endfunction

let s:docker_play_containers = {
\ 'py': {'container': 'python', 'cmd': ['python']},
\ 'rb': {'container': 'ruby', 'cmd': ['ruby']},
\ 'swift': {'container': 'swift', 'cmd': ['swift']},
\}

function! s:docker_play_params(ext) abort
    if exists('g:docker_play_containers') && has_key(g:docker_play_containers, a:ext)
      return g:docker_play_containers[a:ext]
    endif

    if !has_key(s:docker_play_containers, a:ext)
        echohl WarningMsg
        echomsg "Not found extension in docker_play_containers"
        return {}
    endif

    return s:docker_play_containers[a:ext]
endfunction

function! s:path_in_project()
    let current = expand('%:p')
    let pattern = '^' . simplify(b:docker_local_dir . '/')
    if match(current, pattern) < 0
        return ''
    endif
    return substitute(current, pattern, '', 'g')
endfunction
