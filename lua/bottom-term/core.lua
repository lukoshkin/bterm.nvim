--- TODO: get rid of `vim.fn`, `vim.api` is preferable:
--- vim.api : Lua -> C
--- vim.fn  : Lua -> VimL -> C
local fn = vim.fn
local api = vim.api
local bottom_term = {}

function bottom_term.toggle_term (cmd)
  cmd = cmd or ''
  local caller_wid = api.nvim_get_current_win()

  if fn.bufnr'BottomTerm' >= 0 then
    local wid = fn.bufwinid('BottomTerm')
    if wid < 0 then
      if vim.t.bottom_term_horizontal then
        vim.cmd 'sb BottomTerm'
      else
        vim.cmd 'vs BottomTerm'
      end
    else
      -- api.nvim_set_current_win(wid)
      api.nvim_win_close(wid)
      return
    end
  else
    vim.cmd('terminal' .. cmd)
    local bh = api.nvim_get_current_buf()

    api.nvim_buf_set_name(bh, 'BottomTerm')
    api.nvim_buf_set_option(bh, 'modifiable', false)
    api.nvim_buf_set_option(bh, 'bufhidden', 'hide')

    --- Lua note: nil == false is false.
    if vim.g.bottom_term_buflisted == false then
      api.nvim_buf_set_option(bh, 'buflisted', false)
    end

    vim.t.bottom_term_horizontal = true
    vim.t.bottom_term_channel = vim.opt.channel
  end

  if vim.t.bottom_term_horizontal then
    --- In future Neovim releases, it may be possible to do resize,
    --- for example, via `api.nvim_win_set_config`.
    vim.cmd('resize' .. (vim.g.bottom_term_height or 8))
  end

  vim.cmd 'startinsert'

  if vim.g.bottom_term_focus_on_win then
    api.nvim_set_current_win(caller_wid)
    vim.cmd 'stopinsert'
  end
end


function bottom_term.reverse_orient ()
  if api.nvim_buf_get_name(0) ~= 'BottomTerm' then
    return
  end

  if vim.t.bottom_term_horizontal then
    vim.cmd 'wincmd L'
  else
    vim.cmd 'wincmd J'
    vim.cmd('resize' .. (vim.g.bottom_term_height or 8))
  end

  vim.t.bottom_term_horizontal = not vim.t.bottom_term_horizontal
end


return bottom_term
