" Author: ktakayama <loiseau@gmail.com>
" License: MIT

scriptencoding utf-8

if exists('g:loaded_gpt_commit_msg')
  finish
endif

let g:loaded_gpt_commit_msg = 1

command! -nargs=? GPTCommitMsg call gpt_commit_msg#gpt_commit_msg(<f-args>)

nnoremap <silent> <Plug>(GPTCommitMsg) :<C-u>GPTCommitMsg<CR>
