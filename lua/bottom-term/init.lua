local api = vim.api
local bt = require'bottom-term.core'
local bt_utils = require'bottom-term.utils'
local M = {}


local aug_bt = api.nvim_create_augroup('BottomTerm', {clear=true})

api.nvim_create_autocmd('TermClose', {
  pattern = 'BottomTerm*',
  callback = function ()
    --- Assign to a new pointer or just remove it ─
    --- GC handles the memory deallocation.
    vim.t.bottom_term_session = {[vim.type_idx]=vim.types.dictionary}
    bt._ephemeral = nil

    vim.t.bottom_term_name = nil
  end,
  group = aug_bt
})

api.nvim_create_user_command(
  'BottomTerm',
  function (cmd) bt.execute(cmd.args) end,
  { nargs='?' }
)


function M.setup(conf)
  conf = conf or {}
  conf.keys = conf.keys or {}
  conf.opts = conf.opts or {}


  bt.opts, bt.bak_opts = {}, {}
  for key, value in pairs(bt_utils.default.opts) do
    bt.opts[key] = conf.opts[key] or value
    bt.bak_opts[key] = bt.opts[key]
  end

  --- To make it possible to change 'insert_on_switch' for one bt session,
  --- the option should be checked in the callback fn (not outside of au).
  if bt.opts.insert_on_switch then
    api.nvim_create_autocmd('BufEnter', {
      pattern = 'BottomTerm*',
      callback = function ()
        if bt_utils.is_buftype_terminal() then
          vim.cmd 'startinsert'
        end
      end,
      group = aug_bt
    })
  end

  if not bt.opts.buflisted
      and bt.opts.close_if_last then
    api.nvim_create_autocmd('BufEnter', {
      pattern = 'BottomTerm*',
      callback = function ()
        if #bt_utils.only_normal_windows() == 1
            and bt_utils.is_buftype_terminal() then
          vim.cmd 'quit'
        end
      end,
      group = aug_bt
    })
  end


  local toggle = conf.keys.toggle or bt_utils.default.keys.toggle
  local orient = conf.keys.orientation or bt_utils.default.keys.orientation
  local close = conf.keys.close or bt_utils.default.keys.close

  vim.keymap.set('n', toggle, bt.toggle)
  vim.keymap.set('t', '<Esc>', '<C-\\><C-n>')
  vim.keymap.set('t', toggle, '<Esc>:q<Bar>echo<CR>', {remap=true})
  vim.keymap.set('t', '<C-w>', '<Esc><C-w>', {remap=true})
  vim.keymap.set('t', orient, bt.reverse_orientation)
  vim.keymap.set('n', close, bt.terminate)

  --- The code in the curly braces below is responsible
  --- for the correct 'Lua → Vim' dict conversion.
  vim.t.bottom_term_session = {[vim.type_idx]=vim.types.dictionary}
end


return M
