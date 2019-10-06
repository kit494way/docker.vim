"=============================================================================
" FILE: docker.vim
" AUTHOR: KITAGAWA Yasutaka <kit494way@gmail.com>
" License: MIT license
"=============================================================================
"

if exists("g:loaded_docker")
    finish
endif
let g:loaded_docker = 1

function! s:init_buffer() abort
    if !filereadable(expand('~/.docker-vim.json'))
        return
    endif

    let config = json_decode(readfile(expand('~/.docker-vim.json')))
    for project in config.projects
        let project.local_dir = simplify(expand(project.local_dir))
    endfor

    let path = expand('%:p')
    let projects = copy(config.projects)
    call filter(projects, {idx, val -> match(path, '^' . val.local_dir) == 0})
    call sort(projects, {x, y -> x.local_dir > y.local_dir})

    if len(projects) == 0
        return
    endif

    let project = projects[0]
    if !has_key(project, 'container')
        echoe 'container is not found.'
        return 0
    endif
    if !has_key(project, 'container_dir')
        echoe 'container_dir is not found.'
        return 0
    endif
    if !has_key(project, 'local_dir')
        echoe 'local_dir is not found.'
        return 0
    endif

    let b:docker_container = project.container
    let b:docker_container_dir = project.container_dir
    let b:docker_local_dir = project.local_dir

    command! -buffer -nargs=0 DockerUpload :call docker#upload()
    command! -buffer -nargs=0 DockerDownload :call docker#download()
    command! -buffer -nargs=0 DockerDiffFile :call docker#diff_file()
endfunction

command! -nargs=1 DockerEdit :call docker#edit(<f-args>)
command! -nargs=1 DockerWrite :call docker#write(<f-args>)
command! -nargs=1 DockerWriteEdit :call docker#write_edit(<f-args>)
command! -nargs=0 DockerPlay :call docker#play()

augroup docker_vim
    autocmd!
    autocmd BufRead,BufNewFile * :call s:init_buffer()
augroup END
