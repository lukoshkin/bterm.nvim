local buf_get_opt = vim.api.nvim_buf_get_option
local M = {}


M.default = {
  opts = {
    insert_on_switch = true,
    focus_on_caller = false,
    hor_height = 8,

    close_if_last = true,
    buflisted = false,
  },

  keys = {
    toggle = '<A-t>',
    orientation = '<C-t>',
    close = '<A-c>',
  },
}


function M.is_buftype_terminal (bufnr)
  return buf_get_opt(bufnr or 0, 'buftype') == 'terminal'
end


function M.only_normal_windows ()
  local normal_windows = vim.tbl_filter(function (key)
    return vim.api.nvim_win_get_config(key).relative == ''
  end, vim.api.nvim_list_wins())

  return normal_windows
end


return M
