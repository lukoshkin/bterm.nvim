local api = vim.api
local bt = require "bottom-term.core"
local utils = require "bottom-term.utils"
local M = {}

local aug_bt = api.nvim_create_augroup("BottomTerm", { clear = true })
api.nvim_create_autocmd("TermClose", {
  pattern = "FloatingTerm*",
  callback = function()
    vim.t.floating_term_name = nil
  end,
  group = aug_bt,
})
api.nvim_create_user_command(
  "FloatingTerm", -- not sure how useful this mapping is
  function(cmd)
    bt.float_execute(cmd.args)
  end,
  { nargs = "?" }
)

api.nvim_create_autocmd("TermClose", {
  pattern = "BottomTerm*",
  callback = function()
    --- Assign to a new pointer or just remove it ─
    --- GC handles the memory deallocation.
    vim.t.bottom_term_session = { [vim.type_idx] = vim.types.dictionary }
    bt._ephemeral[api.nvim_get_current_tabpage()] = nil
    vim.t.bottom_term_name = nil
  end,
  group = aug_bt,
})
api.nvim_create_user_command("BottomTerm", function(cmd)
  if not bt.is_visible() then
    bt.toggle()
  end
  bt.execute(cmd.args)
end, { nargs = "?" })

local function toggle_number()
  if vim.opt.number:get() ~= vim.opt.relativenumber:get() then
    vim.opt.number = vim.opt.relativenumber:get()
  end

  vim.opt.number = not vim.opt.number:get()
  vim.opt.relativenumber = not vim.opt.relativenumber:get()
end

api.nvim_create_autocmd({ "TermEnter", "TermLeave" }, {
  pattern = "BottomTerm*",
  callback = toggle_number,
  group = aug_bt,
})

function M.setup(conf)
  conf = vim.tbl_deep_extend("keep", conf or {}, utils.default)
  bt._bak_opts = vim.deepcopy(conf.opts)
  bt.opts = conf.opts
  bt.keys = conf.keys

  --- To make it possible to change 'insert_on_switch' for one bt session,
  --- the option should be checked in the callback fn (not outside of au).
  if bt.opts.insert_on_switch then
    api.nvim_create_autocmd("BufEnter", {
      pattern = "BottomTerm*",
      callback = function()
        --- Fow now, it looks like a pair of crutches:
        --- A developer has to define `insert_on_switch` option as `true`
        --- in the config opts and then assign it to `false` in the code.
        if utils.is_buftype_terminal() and bt.opts.insert_on_switch then
          vim.cmd "startinsert"
        end
      end,
      group = aug_bt,
    })
  end

  if not bt.opts.buflisted and bt.opts.close_if_last then
    api.nvim_create_autocmd("QuitPre", {
      callback = function()
        if utils.ready_to_exit() then
          vim.cmd "quitall"
        end
      end,
      group = aug_bt,
    })
  end

  --- ''  - normal, visual, select, and operator-pending modes.
  --- '!' - insert and command line modes.
  vim.keymap.set({ "", "i", "t" }, conf.keys.float_toggle, bt.float_toggle)
  vim.keymap.set({ "", "i", "t" }, conf.keys.toggle, bt.toggle)
  vim.keymap.set("t", "<C-w>", "<Esc><C-w>", { remap = true })
  vim.keymap.set("t", conf.keys.orientation, bt.reverse_orientation)
  vim.keymap.set({ "", "i", "t" }, conf.keys.close, bt.terminate)
  vim.keymap.set("t", "<Esc>", "<C-\\><C-n>")
end

return M
