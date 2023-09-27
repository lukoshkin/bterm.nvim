local api = vim.api
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


function M.is_buftype_terminal(bufnr)
  return api.nvim_buf_get_option(bufnr or 0, 'buftype') == 'terminal'
end

function M.tabpage_normal_windows()
  local normal_windows = vim.tbl_filter(function(key)
    return api.nvim_win_get_config(key).relative == ''
  end, api.nvim_tabpage_list_wins(0))

  return normal_windows
end

function M.term_safe_close(wid)
  if #M.tabpage_normal_windows() > 1 then
    api.nvim_win_close(wid, false)
  else
    if api.nvim_buf_is_valid(vim.t.bottom_term_associated_buf) then
      api.nvim_win_set_buf(0, vim.t.bottom_term_associated_buf)
    else
      local msg = " bterm: broken layout :(\n"
      msg = msg .. " Associated buffer is no longer valid"
      vim.notify(msg)
    end
  end
end

local function is_essential_buffer(bufnr)
  return api.nvim_buf_get_option(bufnr or 0, 'buftype') == ''
end

function M.ready_to_exit()
  if not is_essential_buffer() then
    return false
  end

  local essential_win_cnt = 0
  local wins = M.tabpage_normal_windows()
  for _, wnr in ipairs(wins) do
    local bnr = api.nvim_win_get_buf(wnr)
    if is_essential_buffer(bnr) then
      essential_win_cnt = essential_win_cnt + 1
    end
  end
  return essential_win_cnt <= 1
end

return M
