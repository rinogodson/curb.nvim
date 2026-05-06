<img width="220" height="90" alt="CURB" src="https://github.com/user-attachments/assets/4f0941db-7ad6-4b08-a388-c7bc35c8c496" />

<p>
  <span style="color:#FFBD89;">C</span>ode 
  <span style="color:#FFBD89;">U</span>nder 
  <span style="color:#FFBD89;">R</span>igorous 
  <span style="color:#FFBD89;">B</span>oundary
</p>

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
  highlights = {
    normal = "Normal",
    border = "Keyword",
    title_icon = "DiagnosticInfo",
    title_text = "Keyword",
    footer = "Comment",
  },
})
```

## Help

After installation, open the Neovim help with:

```vim
:help curb
```
