" Author: ktakayama <loiseau@gmail.com>
" License: MIT

let s:gpt_commit_msg_buf = "gpt-commit-msg://gpt-commit-msg-result"
let s:popup_window_id = 0

function! s:echoerr(msg) abort
  echohl ErrorMsg
  echo "[gpt_commit_msg.vim]" a:msg
  echohl None
endfunction

" gpt_commit_msg
function! gpt_commit_msg#gpt_commit_msg(...) abort
  if !executable("curl")
    call s:echoerr("please install curl")
    return
  endif

  echo "Processing..."

  let diff_text = s:get_git_diff()
  let diff_text = s:cut_diff_text(diff_text)
  call s:get_gpt(diff_text)
endfunction

function! s:get_git_diff() abort
  let cmd = ["git", "diff", "--cached", "--",
        \ ":(exclude)*.lock",
        \ ":(exclude)package-lock.json"
        \]
  return system(cmd)
endfunction

function! s:cut_diff_text(text) abort
  let max_lines = g:gpt_commit_msg.max_lines_to_send
  let lines = split(a:text, '\n')
  if len(lines) < max_lines
    return a:text
  endif
  return join(lines[0:max_lines-2], "\n")
endfunction

function! s:get_gpt(diff_text) abort
  let cmd = s:create_gpt_cmd(a:diff_text)
  let s:cmd_gpt_text = []

  if has('nvim')
    call jobstart(cmd, {
          \ 'on_stdout': { id, data -> extend(s:cmd_gpt_text, data) },
          \ 'on_exit': { -> s:get_gpt_result() },
          \ })
  else
    call job_start(cmd, {
          \ "out_cb": function("s:get_gpt_out_cb"),
          \ "err_cb": function("s:get_gpt_out_cb"),
          \ "exit_cb": function("s:get_gpt_exit_cb"),
          \ })
  endif
endfunction

function! s:create_gpt_cmd(text) abort
  let cmd = ["curl", "--location", "--insecure", "--request", "POST", g:gpt_commit_msg.api_end_point]
  let cmd = cmd + ["--header", "Authorization: Bearer " . g:gpt_commit_msg.api_key]
  let cmd = cmd + ["--header", "Content-Type: application/json"]
  let body = json_encode({
        \ "model": "gpt-3.5-turbo",
        \ "temperature": 0.3,
        \ "messages": [
        \ {"role": "system", "content": g:gpt_commit_msg.prompt_header . g:gpt_commit_msg.prompt_multiple},
        \ {"role": "user", "content": a:text}]
        \ })
  let cmd = cmd + ["--data-raw"]
  let cmd = cmd + [body]
  return cmd
endfunction

function! s:get_gpt_out_cb(ch, msg) abort
  call add(s:cmd_gpt_text, a:msg)
endfunction

function! s:get_gpt_exit_cb(job, status) abort
  call s:get_gpt_result()
endfunction

function! s:get_gpt_result() abort
  echo ""

  if has('nvim')
    call remove(s:cmd_gpt_text, -1)
  endif

  if empty(s:cmd_gpt_text)
    call s:echoerr("no diff")
    return
  endif

  let result = s:get_content(join(s:cmd_gpt_text, ""))
  call s:show_result(result)
endfunction

function! s:get_content(json) abort
  return (json_decode(a:json))['choices'][0]['message']['content']
endfunction

function! s:show_result(text) abort
  echo ""
  let result = s:result_text_filter(split(a:text, "\n"))
  let max_height = len(result)
  let max_width = 80

  if exists('*nvim_create_buf')
    call s:close_popup(s:popup_window_id)

    let buffer = nvim_create_buf(v:false, v:true)
    call nvim_buf_set_option(buffer, 'bufhidden', 'wipe')
    call nvim_buf_set_option(buffer, 'swapfile', v:false)
    call setbufvar(buffer, '&filetype', 'gpt-commit-msg-result')

    let opts = {
          \ 'relative': 'win',
          \ 'width': max_width,
          \ 'height': max_height,
          \ 'bufpos': [line("."), 0],
          \ 'row': 0,
          \ 'col': 0,
          \ 'style': 'minimal'
          \ }
    let s:popup_window_id = nvim_open_win(buffer, v:true, opts)
    call nvim_buf_set_lines(buffer, 0, -1, v:true, result)
    call s:setup_map()
  else
    if bufexists(s:gpt_commit_msg_buf)
      let buffer = bufnr(s:gpt_commit_msg_buf)
      let window_id = win_findbuf(buffer)
      if empty(window_id)
        execute str2nr(window_size) . "new | e" s:gpt_commit_msg_buf
      else
        call win_gotoid(window_id[0])
      endif
    else
      execute str2nr(max_height) . "new" s:gpt_commit_msg_buf
      set buftype=nofile
      set ft=gpt-commit-msg-result
      call s:setup_map()
    endif

    silent % d _
    call setline(1, result)
  endif
endfunction

function! s:close_popup(window_id) abort
  if win_getid() == a:window_id
    return
  endif
  if !empty(getwininfo(a:window_id))
    call nvim_win_close(a:window_id, v:true)
  endif
endfunction

function! s:setup_map() abort
  nnoremap <silent> <buffer> <CR> :<C-u>call <SID>yank_result()<CR>
endfunction

function! s:yank_result() abort
  let value = getline('.')
  call setreg(v:register, value . "\n")
  redraw | echo printf("The result text '%s' has yanked.", value)
  execute 'bwipeout!'
endfunction

function! s:result_text_filter(text) abort
  let result = []
  for text in a:text
    let t = substitute(text, "^[0-9][\.:] ", "", "")
    let t = substitute(t, '^"\(.*\)"$', "\\1", "")
    let t = substitute(t, '\.$', "", "")
    let t = g:gpt_commit_msg.result_filter(t)
    call add(result, t)
  endfor
  return result
endfunction
