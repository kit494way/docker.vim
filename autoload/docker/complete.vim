function! docker#complete#containers(arglead, cmdline, cursorpos)
  return system("docker container ls -f name='^".a:arglead."' --format '{{ .Names }}'")
endfunction
