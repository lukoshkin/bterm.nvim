# B[etter/ottom] Terminal

Just another plugin for quicker access to a terminal in Neovim.  
Adds mappings for _opening, closing, and changing orientation_.  
As well as a couple of auto-commands for a better experience.


## Installation

With [**packer**](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'lukoshkin/bterm.nvim',
  branch = 'develop',
  config = function ()
    require'bottom-term'.setup()
  end
}
```

## Mappings

`<A-t>` ─ toggle a terminal window.  
`<C-t>` ─ reverse the terminal orientation.

## Customization
```lua
use {
  'lukoshkin/bterm.nvim',
  branch = 'develop',
  config = function ()
    require'bottom-term'.setup {
      toggle = '<A-t>',
      orientation = '<C-t>',
    }
  end

  --- Start typing commands when switching to the terminal.
  vim.g.bottom_term_insert_on_switch = true
  --- Close the terminal window if there are no other windows.
  vim.g.bottom_term_last_close = true
  --- Don't switch to the terminal on its open.
  vim.g.bottom_term_focus_on_win = false
  --- Leave 'buflisted' option set to true.
  vim.g.bottom_term_buflisted = true
}
```
