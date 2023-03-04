# gpt-commit-msg.vim

gpt-commit-msg is a Vim plugin that generates commit messages automatically using the OpenAI ChatGPT API based on the changes in git diff --cached. 

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

You can configure the gpt-commit-msg plugin by setting the following variables in your Vim configuration file:

```vim
let g:gpt_commit_msg_api_key = "<YOUR_API_KEY>"
```

##  Usage

To use the gpt-commit-msg plugin, simply run the `:GPTCommitMsg` command while in a Git repository. This will generate a commit message based on the changes made in the repository.


