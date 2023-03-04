" Author: ktakayama <loiseau@gmail.com>
" License: MIT

let s:endpoint = get(g:, "gpt_commit_msg_endpoint", "https://api.openai.com/v1/chat/completions")

let s:gpt_prompt_header = "You are a master programmer. You are thinking of a title for your Git commit message."
let s:gpt_prompt_single = "Write a concise Git commit message in present tense for the following diff"
let s:gpt_prompt_multiple = "Write three concise Git commit messages in present tense for the following diff."

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

  let s:cmd_diff_text = []
  let s:cmd_gpt_text = []

  call s:git_diff()
endfunction

function! s:git_diff() abort
  let cmd = ["git", "diff", "--cached"]

  if has('nvim')
    call jobstart(cmd, {
          \ 'on_stdout': { id, data -> extend(s:cmd_diff_text, data) },
          \ 'on_exit': { -> s:git_diff_result() },
          \ })
  else
    call job_start(cmd, {
          \ "out_cb": function("s:git_diff_out_cb"),
          \ "err_cb": function("s:git_diff_out_cb"),
          \ "exit_cb": function("s:git_diff_exit_cb"),
          \ })
  endif
endfunction

function! s:git_diff_out_cb(ch, msg) abort
  call add(s:cmd_diff_text, a:msg)
endfunction

function! s:git_diff_exit_cb(job, status) abort
  call s:git_diff_result()
endfunction

function! s:git_diff_result() abort
  if has('nvim')
    call remove(s:cmd_diff_text, -1)
  endif

  if empty(s:cmd_diff_text)
    call s:echoerr("no diff")
    return
  endif

  call s:get_gpt(join(s:cmd_diff_text, "\n"))
endfunction

function! s:get_gpt(diff_text) abort
  let cmd = s:create_gpt_cmd(a:diff_text)

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
  let cmd = ["curl", "--location", "--insecure", "--request", "POST", s:endpoint]
  let cmd = cmd + ["--header", "Authorization: Bearer " . g:gpt_commit_msg_api_key]
  let cmd = cmd + ["--header", "Content-Type: application/json"]
  let body = json_encode({
        \ "model": "gpt-3.5-turbo",
        \ "temperature": 0.3,
        \ "messages": [
        \ {"role": "system", "content": s:gpt_prompt_header . s:gpt_prompt_single},
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

  call s:show_result(join(s:cmd_gpt_text, ""))
endfunction

function! s:show_result(text) abort
  let result = (json_decode(a:text))['choices'][0]['message']['content']
  echo result
endfunction
