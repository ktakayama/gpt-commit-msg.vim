" Author: ktakayama <loiseau@gmail.com>
" License: MIT

scriptencoding utf-8

if exists('g:loaded_gpt_commit_msg')
  finish
endif

let g:loaded_gpt_commit_msg = 1

let g:gpt_commit_msg = get(g:, "gpt_commit_msg", {})

let g:gpt_commit_msg.api_end_point = get(g:gpt_commit_msg, "api_end_point", "https://api.openai.com/v1/chat/completions")
let g:gpt_commit_msg.prompt_header = get(g:gpt_commit_msg, "prompt_header", "You are a master programmer. You are considering the contents of a Git commit message. The commit message is a single-line commit message of less than 50 characters. Do not include file names or class names.\n")
let g:gpt_commit_msg.prompt_body = get(g:gpt_commit_msg, "prompt_body", "Write three concise Git commit messages in present tense for the following diff:")
let g:gpt_commit_msg.result_filter = get(g:gpt_commit_msg, "result_filter", { input -> input })
let g:gpt_commit_msg.max_lines_to_send = get(g:gpt_commit_msg, "max_lines_to_send", 2000)

command! -nargs=? GPTCommitMsg call gpt_commit_msg#gpt_commit_msg(<f-args>)

nnoremap <silent> <Plug>(GPTCommitMsg) :<C-u>GPTCommitMsg<CR>
