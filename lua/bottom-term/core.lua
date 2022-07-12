--- NOTE: `vim.api` is preferable:
--- vim.api : Lua -> C
--- vim.fn  : Lua -> VimL -> C
local fn = vim.fn
local api = vim.api

local is_buftype_terminal = require'bottom-term.utils'.is_buftype_terminal
local bottom_term = {}


local function bottom_term_new ()
  --- '_ephemeral' is like 'bottom_term_session' but hidden from a user.
  --- Moreover, in the current version of Neovim (0.7), it is not possible
  --- to fill up a VimL dict from the Lua side (at least, to my knowledge).
  bottom_term._ephemeral = {}

  --- Let a user change bt config (just two options) for a session.
  for _, key in next, { 'focus_on_caller', 'hor_height' } do
    local reset = bottom_term.bak_opts[key]
    bottom_term.opts[key] = vim.t.bottom_term_session[key] or reset
  end

  local nr = fn.bufnr('BottomTerm')
  local suffix = ''

  if nr >= 0 and not is_buftype_terminal(nr) then
    suffix = '_'
  end

  vim.t.bottom_term_name = 'BottomTerm' .. suffix

  vim.cmd('new | terminal')
  local bh = api.nvim_get_current_buf()

  api.nvim_buf_set_name(bh, vim.t.bottom_term_name)
  api.nvim_buf_set_option(bh, 'modifiable', false)
  api.nvim_buf_set_option(bh, 'bufhidden', 'hide')

  --- Lua note: nil == false is false.
  if bottom_term.opts.buflisted == false then
    api.nvim_buf_set_option(bh, 'buflisted', false)
  end

  vim.t.bottom_term_horizontal = true
  vim.t.bottom_term_channel = api.nvim_buf_get_var(0, 'terminal_job_id')
end


function bottom_term.toggle ()
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
      api.nvim_win_close(wid, false)
      return
    end
  else
    bottom_term_new()
  end

  if vim.t.bottom_term_horizontal then
    --- In future Neovim releases, it may be possible to do resize,
    --- for example, via `api.nvim_win_set_config`.
    vim.cmd('resize' .. bottom_term.opts.hor_height)
    --- resizeN - w/o space is OK.
  end

  vim.cmd 'startinsert'

  if bottom_term.opts.focus_on_caller then
    api.nvim_set_current_win(caller_wid)
    vim.cmd 'stopinsert'
  end
end


function bottom_term.execute (cmd)
  if vim.t.bottom_term_name == nil
      or fn.bufwinid(vim.t.bottom_term_name) < 0 then
    bottom_term.toggle()
  end

  if cmd ~= nil and cmd ~= '' then
    --- Clear the cmd line with \x10.
    --- (NOTE: It may not work for all platforms.)
    cmd = '\x15' .. cmd:match'^%s*(.-)%s*$'
    api.nvim_chan_send(vim.t.bottom_term_channel, cmd .. '\n')
  end
end


function bottom_term.reverse_orientation ()
  if vim.t.bottom_term_name == nil then
    return
  end

  api.nvim_win_call(fn.bufwinid(vim.t.bottom_term_name),
    function ()
      if vim.t.bottom_term_horizontal then
        vim.cmd 'wincmd L'
      else
        vim.cmd 'wincmd J'
        vim.cmd('resize' .. bottom_term.opts.hor_height)
      end

      vim.t.bottom_term_horizontal = not vim.t.bottom_term_horizontal
    end)
end


function bottom_term.terminate ()
  if vim.t.bottom_term_name == nil then
    return
  end

  api.nvim_buf_delete(fn.bufnr(vim.t.bottom_term_name), {force=true})
end


return bottom_term
