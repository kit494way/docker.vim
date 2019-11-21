"=============================================================================
" FILE: complete.vim
" AUTHOR: KITAGAWA Yasutaka <kit494way@gmail.com>
" License: MIT license
"=============================================================================

function! docker#complete#containers(arglead, cmdline, cursorpos)
  return system("docker container ls -f name='^".a:arglead."' --format '{{ .Names }}'")
endfunction

function! docker#complete#path(arglead, cmdline, cursorpos)
  let container_path = split(a:arglead, ':', 1)
  if len(container_path) == 1
    return
  endif

  let [container, path] = container_path
  let dir = fnamemodify(path, ':h')
  let file = fnamemodify(path, ':t')
  let paths = split(system("docker container exec ".container." find ".dir." -maxdepth 1 -name '".file."*'"))
  return join(map(paths, 'l:container.":".v:val'), "\n")
endfunction

function! docker#complete#container_path(arglead, cmdline, cursorpos)
  let container_path = split(a:arglead, ':', 1)
  if len(container_path) == 1
    return docker#complete#containers(a:arglead, a:cmdline, a:cursorpos)
  endif

  let containers = split(docker#complete#containers(container_path[0], a:cmdline, a:cursorpos))
  if len(containers) == 1
    return docker#complete#path(a:arglead, a:cmdline, a:cursorpos)
  else
    return
  endif
endfunction
