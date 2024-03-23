--- NOTE: `vim.api` is preferable:
--- vim.api : Lua -> C
--- vim.fn  : Lua -> VimL -> C

local fn = vim.fn
local api = vim.api
local bt_utils = require "bottom-term.utils"

local M = {}
M._ephemeral = {}

local function tabpage_unique_name(name)
  local tnr = api.nvim_get_current_tabpage()
  local name = name .. tnr
  local suffix = nil

  while fn.bufnr(table.concat({ name, suffix }, "_")) >= 0 do
    suffix = (suffix or 0) + 1
  end

  name = table.concat({ name, suffix }, "_")
  return name, tnr
end

local function execute(cmd, channel)
  if cmd ~= nil and cmd ~= "" then
    --- Clear the cmd line with '\x15'.
    --- (21st code of ASCII table - NAK: negative acknowledge).
    --- (NOTE: It may not work for all platforms.)
    -- cmd = '\x15' .. cmd:match '^%s*(.-)%s*$' -- is also valid
    cmd = string.char(21) .. cmd:match "^%s*(.-)%s*$"
    api.nvim_chan_send(channel, cmd .. "\n")
  end
end

function M.bottom_term_new(start_cmd)
  vim.t.bottom_term_name, tnr = tabpage_unique_name "BottomTerm"
  vim.t.bottom_term_session = { [vim.type_idx] = vim.types.dictionary }
  --- 1. The code in the curly braces above is responsible
  --- for the correct 'Lua → Vim' dict conversion.
  --- 2. '_ephemeral' is like 'bottom_term_session' but hidden from a user.
  --- Moreover, in the current version of Neovim (0.7), it is not possible
  --- to fill up a VimL dict from the Lua side (at least, to my knowledge).
  --- 3. Neither modifying vim dicts is available in 0.9 version.
  M._ephemeral[tnr] = {}

  --- Let a user change bt config (just two options) for a session.
  for _, key in next, { "focus_on_caller", "hor_height" } do
    M.opts[key] = vim.t.bottom_term_session[key] or M._bak_opts[key]
  end

  vim.t.bottom_term_associated_buf = api.nvim_get_current_buf()

  local scratch = true
  local bh = api.nvim_create_buf(M.opts.buflisted or false, scratch)
  api.nvim_buf_set_name(bh, vim.t.bottom_term_name)

  api.nvim_command "bot split"
  local wh = vim.api.nvim_get_current_win()

  api.nvim_win_set_buf(wh, bh)
  vim.t.bottom_term_channel = api.nvim_open_term(bh, {
    on_input = function(_, _, _, data)
      if vim.t.bt_jobid then
        pcall(api.nvim_chan_send, vim.t.bt_jobid, data)
      end
    end,
  })
  local opts = {
    pty = true,  -- haven't explore whether it gives any benefits
    height = M.opts.hor_height,
    on_stdout = function(_, data)
      api.nvim_chan_send(vim.t.bottom_term_channel, table.concat(data, "\n"))
    end,
    on_exit = M.terminate,
  }
  vim.t.bt_jobid = vim.fn.jobstart(start_cmd or vim.o.shell, opts)
  vim.cmd("resize" .. M.opts.hor_height)
  vim.t.bottom_term_horizontal = true
end

local function floating_term_new()
  local buflisted = false
  local scratch = true

  local enter_on_open = true
  local bh = vim.api.nvim_create_buf(buflisted, scratch)
  vim.api.nvim_open_win(bh, enter_on_open, bt_utils.floating_win_opts)
  vim.t.floating_term_channel = fn.termopen(vim.o.shell:match "^.+/(.+)$")

  vim.t.floating_term_name = tabpage_unique_name "FloatingTerm"
  api.nvim_buf_set_name(bh, vim.t.floating_term_name)
end

function M.toggle()
  local caller_wid = api.nvim_get_current_win()

  if vim.t.bottom_term_name then
    local wid = fn.bufwinid(vim.t.bottom_term_name)
    if wid < 0 then
      if vim.t.bottom_term_horizontal then
        vim.cmd("sb " .. vim.t.bottom_term_name)
        vim.cmd "wincmd J"
      else
        --- 'vs' "re-opens" a file, while 'vert sb'
        --- puts an existing buffer in rightmost window.
        vim.cmd("vert sb " .. vim.t.bottom_term_name)
        vim.cmd "wincmd L"
      end
    else
      bt_utils.term_safe_close(wid)
      return
    end
  else
    M.bottom_term_new()
  end

  if vim.t.bottom_term_horizontal then
    --- In future Neovim releases, it may be possible to do resize,
    --- for example, via `api.nvim_win_set_config`.
    vim.cmd("resize" .. M.opts.hor_height)
    --- resizeN - w/o space is OK.
  end

  vim.cmd "startinsert"

  if M.opts.focus_on_caller then
    api.nvim_set_current_win(caller_wid)
    vim.cmd "stopinsert"
  end
end

function M.float_toggle()
  if vim.t.floating_term_name then
    local wid = fn.bufwinid(vim.t.floating_term_name)
    if wid < 0 then
      local enter_on_open = true
      api.nvim_open_win(
        fn.bufnr(vim.t.floating_term_name),
        enter_on_open,
        bt_utils.floating_win_opts
      )
      vim.cmd "startinsert"
    else
      api.nvim_win_close(wid, false)
    end
  else
    floating_term_new()
    vim.cmd "startinsert"
  end
end

function M.is_visible()
  if
    vim.t.bottom_term_name == nil or fn.bufwinid(vim.t.bottom_term_name) < 0
  then
    return false
  end
  return true
end

function M.execute(cmd)
  if not M.is_visible() then
    return
  end

  execute(cmd, vim.t.bt_jobid)
end

function M.float_execute(cmd)
  if
    vim.t.floating_term_name == nil
    or fn.bufwinid(vim.t.floating_term_name) < 0
  then
    M.float_toggle()
  end

  execute(cmd, vim.t.floating_term_channel)
end

function M.reverse_orientation()
  if vim.t.bottom_term_name == nil then
    return
  end

  api.nvim_win_call(fn.bufwinid(vim.t.bottom_term_name), function()
    if vim.t.bottom_term_horizontal then
      vim.cmd "wincmd L"
    else
      vim.cmd "wincmd J"
      vim.cmd("resize" .. M.opts.hor_height)
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
