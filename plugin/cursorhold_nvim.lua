local uv = vim.loop
local ch_updatetime = vim.g.cursorhold_updatetime ~= nil and vim.g.cursorhold_updatetime or vim.o.updatetime
local fix_ch_nvim_timer
vim.opt.eventignore:append {'CursorHold','CursorHoldI'}

local function hold_cb(event)
  return function()
    vim.opt.eventignore:remove {event}
    vim.api.nvim_exec_autocmds({event},{
      modeline = false,
    })
    vim.opt.eventignore:append {event}
  end
end

CursorHold_Cb = hold_cb('CursorHold')

CursorHoldI_Cb = hold_cb('CursorHoldI')

local function hold_timer(fn)
  return function()
    if fix_ch_nvim_timer ~= nil then
      fix_ch_nvim_timer:close()
    end
    fix_ch_nvim_timer = uv.new_timer()
    fix_ch_nvim_timer:start(0,ch_updatetime,vim.schedule_wrap(function()
      fn()
    end))
  end
end

CursorHoldTimer = hold_timer(CursorHold_Cb)
CursorHoldITimer = hold_timer(CursorHoldI_Cb)

local fix_cursorhold_nvim = vim.api.nvim_create_augroup('FixCursorHoldNvim',{})
vim.api.nvim_create_autocmd({'CursorHold'},{
  group = fix_cursorhold_nvim,
  pattern = '*',
  callback = CursorHoldTimer,
})

vim.api.nvim_create_autocmd({'CursorHoldI'},{
  group = fix_cursorhold_nvim,
  pattern = '*',
  callback = CursorHoldITimer,
})
