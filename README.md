# B[etter/ottom] Terminal

Sometimes you don't need a floating window, you just want aligned splits  
and to quickly jump between them. For this case, `bterm` might be the choice.

`bterm` is a plugin for quicker access to a terminal in Neovim.  
It adds mappings for _opening, hiding, and changing orientation_.  
As well as a couple of auto-commands for a better experience.

Note that with the mappings, you can create no more than one terminal per tab.  
Terminal channel id is kept in a tab variable (`t:bottom_term_channel`).


## Installation

With [**packer**](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'lukoshkin/bterm.nvim',
  config = function ()
    require'bottom-term'.setup()
  end
}
```


## Mappings

`<A-t>` ─ toggle a terminal window &emsp;_(_`BottomTerm` _instance)._  
`<C-t>` ─ reverse the terminal orientation.  
`<A-c>` ─ terminate the terminal session.  
`:BottomTerm <cmd>` ─ execute a `<cmd>` in the terminal.


## Customization

One can adjust for their needs by altering some of the defaults below.

```lua
use {
  'lukoshkin/bterm.nvim',
  config = function ()
    require'bottom-term'.setup {
      keys = {
        toggle = '<A-t>',
        orientation = '<C-t>',
        close = '<A-c>',
      },
      opts = {
        --- Start typing commands when switching to the terminal.
        insert_on_switch = true,
        --- Close the terminal window if there are no other windows.
        close_if_last = true,
        --- Switch to the terminal window on its open.
        focus_on_caller = false,
        --- Do not show BottomTerm buffer in the buffer list.
        buflisted = false,
      },
    }
  end
}
```


## Future Plans

- [x] Clear the terminal cmd line before the execution of a requested command.
- [ ] Allow setting a tmp config before spawning a BottomTerm instance ***from scripts***.  
  (This might result in the creation of a module `ephemeral.lua` or `temporal.lua`)
