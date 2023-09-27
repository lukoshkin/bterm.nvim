--- NOTE: `vim.api` is preferable:
--- vim.api : Lua -> C
--- vim.fn  : Lua -> VimL -> C
local fn = vim.fn
local api = vim.api
local bt_utils = require 'bottom-term.utils'
local M = {}


local function bottom_term_new()
  --- The code in the curly braces below is responsible
  --- for the correct 'Lua → Vim' dict conversion.
  vim.t.bottom_term_session = { [vim.type_idx] = vim.types.dictionary }
  --- '_ephemeral' is like 'bottom_term_session' but hidden from a user.
  --- Moreover, in the current version of Neovim (0.7), it is not possible
  --- to fill up a VimL dict from the Lua side (at least, to my knowledge).
  M._ephemeral = {}

  --- Let a user change bt config (just two options) for a session.
  for _, key in next, { 'focus_on_caller', 'hor_height' } do
    local reset = M.bak_opts[key]
    M.opts[key] = vim.t.bottom_term_session[key] or reset
  end

  vim.t.bottom_term_associated_buf = api.nvim_get_current_buf()
  local name = 'BottomTerm' .. api.nvim_get_current_tabpage()
  local suffix = nil

  while fn.bufnr(table.concat({ name, suffix }, '_')) >= 0 do
    suffix = (suffix or 0) + 1
  end

  --- To shadow non-terminal buffer with the same name.
  vim.t.bottom_term_name = table.concat({ name, suffix }, '_')

  vim.cmd('new | terminal')
  local bh = api.nvim_get_current_buf()

  api.nvim_buf_set_name(bh, vim.t.bottom_term_name)
  api.nvim_buf_set_option(bh, 'modifiable', false)
  api.nvim_buf_set_option(bh, 'bufhidden', 'hide')
  api.nvim_buf_set_option(bh, 'buflisted', M.opts.buflisted or false)

  vim.t.bottom_term_horizontal = true
  vim.t.bottom_term_channel = api.nvim_buf_get_var(0, 'terminal_job_id')
end


function M.toggle()
  local caller_wid = api.nvim_get_current_win()

  if vim.t.bottom_term_name then
    local wid = fn.bufwinid(vim.t.bottom_term_name)
    if wid < 0 then
      if vim.t.bottom_term_horizontal then
        vim.cmd('sb ' .. vim.t.bottom_term_name)
      else
        --- 'vs' "re-opens" a file, while 'vert sb'
        --- puts an existing buffer in rightmost window.
        vim.cmd('vert sb ' .. vim.t.bottom_term_name)
      end
    else
      bt_utils.term_safe_close(wid)
      return
    end
  else
    bottom_term_new()
  end

  if vim.t.bottom_term_horizontal then
    --- In future Neovim releases, it may be possible to do resize,
    --- for example, via `api.nvim_win_set_config`.
    vim.cmd('resize' .. M.opts.hor_height)
    --- resizeN - w/o space is OK.
  end

  vim.cmd 'startinsert'

  if M.opts.focus_on_caller then
    api.nvim_set_current_win(caller_wid)
    vim.cmd 'stopinsert'
  end
end


function M.is_visible()
  if vim.t.bottom_term_name == nil
      or fn.bufwinid(vim.t.bottom_term_name) < 0 then
    return false
  end
  return true
end


function M.execute(cmd)
  if not M.is_visible() then
    return
  end

  if cmd ~= nil and cmd ~= '' then
    --- Clear the cmd line with \x10.
    --- (NOTE: It may not work for all platforms.)
    cmd = '\x15' .. cmd:match '^%s*(.-)%s*$'
    api.nvim_chan_send(vim.t.bottom_term_channel, cmd .. '\n')
  end
end


function M.copy_line_and_run()
  local line = api.nvim_get_current_line()
  M.execute(line .. '\n')
end


function M.copy_cell_and_run(pat)
  local top = fn.search(pat, 'bnW')  -- either <some> or zero (beg)
  local bot = fn.search(pat, 'cnW') - 1  -- either <some> - 1 or -1 (end)
  local lines = table.concat(api.nvim_buf_get_lines(0, top, bot, false), '\n')
  M.execute(lines .. '\n')
end


function M.reverse_orientation()
  if vim.t.bottom_term_name == nil then
    return
  end

  api.nvim_win_call(fn.bufwinid(vim.t.bottom_term_name),
    function()
      if vim.t.bottom_term_horizontal then
        vim.cmd 'wincmd L'
      else
        vim.cmd 'wincmd J'
        vim.cmd('resize' .. M.opts.hor_height)
      end

      vim.t.bottom_term_horizontal = not vim.t.bottom_term_horizontal
    end)
end


function M.terminate()
  if vim.t.bottom_term_name == nil then
    return
  end

  api.nvim_buf_delete(fn.bufnr(vim.t.bottom_term_name), { force = true })
end

return M
