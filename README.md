# gpt-commit-msg.vim

gpt-commit-msg is a Vim plugin that automatically generates Git commit messages using the OpenAI ChatGPT API based on the changes in `git diff --cached.`

https://user-images.githubusercontent.com/42468/223039319-a55fefcc-a23a-4973-bdc9-973614b4be16.mov

## Requirement
- curl

## Installation
You can use the plugin manager or Vim8 package manager.
eg: dein.vim

```toml
[[plugins]]
repo = 'ktakayama/gpt-commit-msg.vim'
```

Once you have installed the plugin, you will need to set up an API key from OpenAI. You can do this by following the instructions on the [OpenAI website](https://platform.openai.com/docs/api-reference/introduction).

## Configuration

You can configure this plugin by setting the following variables in your .vimrc:

### Required

```vim
let g:gpt_commit_msg = {}
let g:gpt_commit_msg.api_key = "<YOUR_API_KEY>"
```

### Optional

```vim
" The maximum number of lines of Git diff text to send to the ChatGPT API
let g:gpt_commit_msg.max_lines_to_send = 2000

" A function to filter the generated commit message
function! g:gpt_commit_msg.result_filter(text) abort
  return substitute(a:text, '^\(.\)', '\L\1', '')
endfunction

" Example for Custom mapping in result window
augroup GPTCommitMsg
  autocmd!
  autocmd FileType gpt-commit-msg-result nnoremap <silent><buffer>q :<C-u>bwipeout!<CR>
augroup END
```

##  Usage

To use this plugin, simply run the `:GPTCommitMsg` command while in a Git repository. This will generate a commit message based on the changes made in the repository.

After running `:GPTCommitMsg` you will see a results window with the commit messages generated. Move the cursor over the message you like and `<CR>` to yank it.

