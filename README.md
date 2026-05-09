<img width="220" height="90" alt="Group 24" src="https://github.com/user-attachments/assets/be1da57a-3116-4c35-96ea-315681611149" />

### C*ode* U*nder* R*igorous* B*oundary*

Curb provides a floating prompt for replacing the current visual selection.

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
replacement.

## Default Configuration

```lua
require("curb").setup({
  trigger_key = "<leader>ai",
  accept_key = "<C-y>",
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
