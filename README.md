# B[etter/ottom] Terminal

Sometimes you don't need a floating window, you just want aligned splits  
and to quickly jump between them. For this case, `bterm` might be the choice.

`bterm` is a simple plugin for quicker access to a terminal in Neovim.  
It adds mappings for _opening, hiding, and changing orientation_.  
As well as a couple of auto-commands for a better experience.

---

Note that with the mappings below, you can create at maximum one
`bottom_term` and one `floating_term` instances per tab. `bottom_term` is a
terminal process in a normal window with a lot of associated control mappings.
`floating_term` ─ in a floating window with just two mappings: one for toggling
the window and another for opening it by running a command.

Terminal channel ids are kept in a tab variables:  
`t:bottom_term_channel` and `t:floating_term_channel`.

## Installation

With [**lazy**](https://github.com/folke/lazy.nvim)

```lua
{
  'lukoshkin/bterm.nvim',
  config = true
}
```

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

`<A-t>` ─ toggle a window with `bottom_term` instance.  
`<C-t>` ─ reverse the terminal orientation.  
`<A-c>` ─ terminate the `bottom_term` session.  
`<A-w>` ─ toggle a floating window with a `floating_term` instance.  
`:BottomTerm <cmd>` ─ execute a `<cmd>` in the terminal.

## Customization

One can adjust for their needs by altering some of the defaults below.  
(Configured with [lazy.nvim](https://github.com/folke/lazy.nvim))

```lua
{
  'lukoshkin/bterm.nvim',
  opts = {
    keys = {
      toggle = '<A-t>',
      float_toggle = '<A-w>',
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
      --- Do not show `bottom_term` buffer in the buffer list.
      buflisted = false,
      --- Height of `bottom_term` when it's oriented horizontally.
      hor_height = 8,
      --- Fractional sizes of `floating_term` instance.
      float_term_height = 0.8,
      float_term_width = 0.8,
    },
  }
}
```

## Future Plans

- [x] Clear the terminal cmd line before the execution of a requested command.
- [ ] Allow setting a tmp config before spawning a `bottom_term` instance
      **_from scripts_**.<br> (This might result in the creation of a module
      `ephemeral.lua` or `temporal.lua`)
