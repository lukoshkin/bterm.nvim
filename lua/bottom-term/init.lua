local api = vim.api
local bt = require'bottom-term.core'
local M = {}


if vim.g.bottom_term_insert_on_switch == nil then
  vim.g.bottom_term_insert_on_switch = true
end

if vim.g.bottom_term_last_close == nil then
  vim.g.bottom_term_last_close = true
end

if vim.g.bottom_term_focus_on_win == nil then
  vim.g.bottom_term_focus_on_win = false
end


local aug_bt = api.nvim_create_augroup('BottomTerm', {clear=true})

if vim.g.bottom_term_insert_on_switch then
  api.nvim_create_autocmd('BufEnter', {
    pattern = 'BottomTerm',
    command = 'norm i<CR>',
    group = aug_bt
  })
end

if vim.g.bottom_term_buflisted
    and vim.g.bottom_term_last_close then
  api.nvim_create_autocmd('BufEnter', {
    pattern = 'BottomTerm',
    callback = function ()
      if #api.nvim_list_wins() == 1
          and api.nvim_buf_get_name(0) == 'BottomTerm' then
        vim.cmd 'quit'
      end
    end,
    group = aug_bt
  })
end


function M.setup(conf)
  local toggle = conf.toggle or '<A-t>'
  local orient = conf.orientation or '<C-t>'

  vim.keymap.set('n', toggle, bt.toggle_term)
  vim.keymap.set('t', '<Esc>', '<C-\\><C-n>')
  vim.keymap.set('t', toggle, '<Esc>:q<Bar>echo<CR>', {remap=true})
  vim.keymap.set('t', '<C-w>', '<Esc><C-w>', {remap=true})
  vim.keymap.set('t', orient, bt.reverse_orient)
end

return M
