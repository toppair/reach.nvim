if exists('g:loaded_reach') | finish | endif

function! s:complete(...)
  return "buffers\nmarks\ntabpages"
endfunction

command! -nargs=1 -complete=custom,s:complete ReachOpen lua require'reach'.<args>()

let g:loaded_reach = 1
