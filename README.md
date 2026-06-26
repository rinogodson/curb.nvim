<img width="220" height="90" alt="Group 24" src="https://github.com/user-attachments/assets/be1da57a-3116-4c35-96ea-315681611149" />

### C*ode* U*nder* R*igorous* B*oundary*
A Neovim plugin that replaces Vibe Coding with something better.

The core idea is AI snippet generation. You still write your own code, but what about the repetitive or boring parts? Simply select a block of code in Neovim, press a shortcut, and describe the change you want. The AI analyzes your entire project's context and generates a precise snippet edit. Instead of rewriting entire files, it only modifies the selected section, allowing you to review every change before choosing to accept or reject it.

The plugin also includes a Codebase Auditor. With a single command, an AI agent scans your entire project and provides actionable suggestions to improve code quality, maintainability, performance, and security.

This plugin is designed to integrate AI into the development workflow without taking control away from the developer. You remain the one writing, understanding, and owning your codebase, AI simply helps eliminate the tedious parts.

## DEMO:
https://github.com/user-attachments/assets/79999065-d7a7-4f19-aedd-f50a25538ff5

## Installation

Install with your preferred plugin manager, then call:

```lua
require("curb").setup()
```

## Usage

Select text in visual mode and use one of the following:

- Run `:Curb`
- Press the configured trigger mapping

Inside the floating prompt, press the configured accept key to apply the
request. After the replacement is generated, review it in the buffer and use
the configured review keys to accept, reject, or reprompt.

## Default Configuration

```lua
require("curb").setup({
  trigger_key = "<leader>ai",
  accept_key = "<C-y>",
  reject_key = "<C-n>",
  reprompt_key = "<C-p>",
  provider = {
    endpoint = "https://ai.hackclub.com/proxy/v1/chat/completions",
    model = "qwen/qwen3-coder-plus",
    api_key_env = "HACKCLUB_API_KEY",
    api_key_file = nil,
  },
  highlights = {
    normal = "Normal",
    border = "Keyword",
    title_icon = "DiagnosticInfo",
    title_text = "Keyword",
    footer = "Comment",
  },
})
```

`curb` uses `curl` asynchronously through `vim.system(...)`. Set the API key
environment variable named by `provider.api_key_env` before starting Neovim.
You can also save the key from inside Neovim with `:CurbSetApiKey`. By default
it is stored at `stdpath("data") .. "/curb/api_key"`.

## Help

After installation, open the Neovim help with:

```vim
:help curb
```
