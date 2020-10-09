" Automatically generated packer.nvim plugin loader code

lua << END
local plugins = {
  ["Dockerfile.vim"] = {
    loaded = false,
    only_sequence = false,
    only_setup = false,
    path = "/Users/stephen/.local/share/nvim/site/pack/packer/opt/Dockerfile.vim"
  },
  ["accelerated-jk"] = {
    keys = { { "", "j" } },
    loaded = false,
    only_sequence = false,
    only_setup = false,
    path = "/Users/stephen/.local/share/nvim/site/pack/packer/opt/accelerated-jk"
  },
  ["context_filetype.vim"] = {
    loaded = false,
    only_sequence = false,
    only_setup = false,
    path = "/Users/stephen/.local/share/nvim/site/pack/packer/opt/context_filetype.vim"
  },
  ["dashboard-nvim"] = {
    loaded = false,
    only_sequence = true,
    only_setup = true,
    path = "/Users/stephen/.local/share/nvim/site/pack/packer/opt/dashboard-nvim"
  },
  ["markdown-preview.nvim"] = {
    commands = { "MarkdownPreview" },
    config = { "\27LJ\1\0021\0\0\2\0\3\0\0054\0\0\0007\0\1\0'\1\0\0:\1\2\0G\0\1\0\20mkdp_auto_start\6g\bvim\0" },
    loaded = false,
    only_sequence = false,
    only_setup = false,
    path = "/Users/stephen/.local/share/nvim/site/pack/packer/opt/markdown-preview.nvim"
  },
  ["nvim-treesitter"] = {
    config = { "\27LJ\1\2à\2\0\0\5\0\f\0\0154\0\0\0%\1\1\0>\0\2\0027\0\2\0003\1\4\0003\2\3\0:\2\5\0013\2\t\0003\3\6\0003\4\a\0:\4\b\3:\3\n\2:\2\v\1>\0\2\1G\0\1\0\16textobjects\vselect\1\0\0\fkeymaps\1\0\4\aif\20@function.inner\aaf\20@function.outer\aac\17@class.outer\aic\17@class.inner\1\0\1\venable\2\14highlight\1\0\1\21ensure_installed\ball\1\0\1\venable\2\nsetup\28nvim-treesitter.configs\frequire\0" },
    loaded = false,
    only_sequence = false,
    only_setup = false,
    path = "/Users/stephen/.local/share/nvim/site/pack/packer/opt/nvim-treesitter"
  },
  ["packer.nvim"] = {
    loaded = false,
    only_sequence = false,
    only_setup = false,
    path = "/Users/stephen/.local/share/nvim/site/pack/packer/opt/packer.nvim"
  },
  ["spaceline.vim"] = {
    loaded = false,
    only_sequence = false,
    only_setup = false,
    path = "/Users/stephen/.local/share/nvim/site/pack/packer/opt/spaceline.vim"
  },
  ["vim-buffet"] = {
    loaded = false,
    only_sequence = false,
    only_setup = false,
    path = "/Users/stephen/.local/share/nvim/site/pack/packer/opt/vim-buffet"
  },
  ["vim-cursorword"] = {
    config = { "\27LJ\1\2ª\3\0\0\2\0\n\0$4\0\0\0007\0\1\0007\0\2\0%\1\3\0>\0\2\0014\0\0\0007\0\1\0007\0\2\0%\1\4\0>\0\2\0014\0\0\0007\0\1\0007\0\2\0%\1\5\0>\0\2\0014\0\0\0007\0\1\0007\0\2\0%\1\6\0>\0\2\0014\0\0\0007\0\1\0007\0\2\0%\1\a\0>\0\2\0014\0\0\0007\0\1\0007\0\2\0%\1\b\0>\0\2\0014\0\0\0007\0\1\0007\0\2\0%\1\t\0>\0\2\1G\0\1\0\16augroup END/autocmd InsertLeave * let b:cursorword = 1/autocmd InsertEnter * let b:cursorword = 0Gautocmd WinEnter * if &diff || &pvw | let b:cursorword = 0 | endifFautocmd FileType defx,denite,fern,clap,vista let b:cursorword = 0\rautocmd!#augroup user_plugin_cursorword\17nvim_command\bapi\bvim\0" },
    loaded = false,
    only_sequence = false,
    only_setup = false,
    path = "/Users/stephen/.local/share/nvim/site/pack/packer/opt/vim-cursorword"
  },
  ["vim-dadbod-ui"] = {
    commands = { "DBUIToggle", "DBUIAddConnection", "DBUI", "DBUIFindBuffer", "DBUIRenameBuffer" },
    config = { "\27LJ\1\2¶\2\0\0\3\1\14\0\0314\0\0\0007\0\1\0'\1\0\0:\1\2\0004\0\0\0007\0\1\0%\1\4\0:\1\3\0004\0\0\0007\0\1\0'\1\1\0:\1\5\0004\0\0\0007\0\6\0'\1#\0:\1\a\0004\0\0\0007\0\1\0+\1\0\0007\1\t\1%\2\n\0$\1\2\1:\1\b\0004\0\0\0007\0\1\0004\1\0\0007\1\f\0017\1\r\1>\1\1\2:\1\v\0G\0\1\0\0¿\30initself#load_db_from_env\afn\bdbs\18db_ui_queries\14cache_dir\24db_ui_save_location\19db_ui_winwidth\6d\25db_ui_use_nerd_fonts\tleft\23db_ui_win_position\20db_ui_show_help\6g\bvim\0" },
    loaded = false,
    only_sequence = false,
    only_setup = false,
    path = "/Users/stephen/.local/share/nvim/site/pack/packer/opt/vim-dadbod-ui"
  },
  ["vim-jsx-pretty"] = {
    loaded = false,
    only_sequence = false,
    only_setup = false,
    path = "/Users/stephen/.local/share/nvim/site/pack/packer/opt/vim-jsx-pretty"
  },
  ["yats.vim"] = {
    loaded = false,
    only_sequence = false,
    only_setup = false,
    path = "/Users/stephen/.local/share/nvim/site/pack/packer/opt/yats.vim"
  },
  ["zig.vim"] = {
    loaded = false,
    only_sequence = false,
    only_setup = false,
    path = "/Users/stephen/.local/share/nvim/site/pack/packer/opt/zig.vim"
  }
}

local function handle_bufread(names)
  for _, name in ipairs(names) do
    local path = plugins[name].path
    for _, dir in ipairs({ 'ftdetect', 'ftplugin', 'after/ftdetect', 'after/ftplugin' }) do
      if #vim.fn.finddir(dir, path) > 0 then
        vim.cmd('doautocmd BufRead')
        return
      end
    end
  end
end

_packer_load = nil

local function handle_after(name, before)
  local plugin = plugins[name]
  plugin.load_after[before] = nil
  if next(plugin.load_after) == nil then
    _packer_load({name}, {})
  end
end

_packer_load = function(names, cause)
  local some_unloaded = false
  for _, name in ipairs(names) do
    if not plugins[name].loaded then
      some_unloaded = true
      break
    end
  end

  if not some_unloaded then return end

  local fmt = string.format
  local del_cmds = {}
  local del_maps = {}
  for _, name in ipairs(names) do
    if plugins[name].commands then
      for _, cmd in ipairs(plugins[name].commands) do
        del_cmds[cmd] = true
      end
    end

    if plugins[name].keys then
      for _, key in ipairs(plugins[name].keys) do
        del_maps[key] = true
      end
    end
  end

  for cmd, _ in pairs(del_cmds) do
    vim.cmd('silent! delcommand ' .. cmd)
  end

  for key, _ in pairs(del_maps) do
    vim.cmd(fmt('silent! %sunmap %s', key[1], key[2]))
  end

  for _, name in ipairs(names) do
    if not plugins[name].loaded then
      vim.cmd('packadd ' .. name)
      vim._update_package_paths()
      if plugins[name].config then
        for _i, config_line in ipairs(plugins[name].config) do
          loadstring(config_line)()
        end
      end

      if plugins[name].after then
        for _, after_name in ipairs(plugins[name].after) do
          handle_after(after_name, name)
          vim.cmd('redraw')
        end
      end

      plugins[name].loaded = true
    end
  end

  handle_bufread(names)

  if cause.cmd then
    local lines = cause.l1 == cause.l2 and '' or (cause.l1 .. ',' .. cause.l2)
    vim.cmd(fmt('%s%s%s %s', lines, cause.cmd, cause.bang, cause.args))
  elseif cause.keys then
    local keys = cause.keys
    local extra = ''
    while true do
      local c = vim.fn.getchar(0)
      if c == 0 then break end
      extra = extra .. vim.fn.nr2char(c)
    end

    if cause.prefix then
      local prefix = vim.v.count and vim.v.count or ''
      prefix = prefix .. '"' .. vim.v.register .. cause.prefix
      if vim.fn.mode('full') == 'no' then
        if vim.v.operator == 'c' then
          prefix = '' .. prefix
        end

        prefix = prefix .. vim.v.operator
      end

      vim.fn.feedkeys(prefix, 'n')
    end

    -- NOTE: I'm not sure if the below substitution is correct; it might correspond to the literal
    -- characters \<Plug> rather than the special <Plug> key.
    vim.fn.feedkeys(string.gsub(string.gsub(cause.keys, '^<Plug>', '\\<Plug>') .. extra, '<[cC][rR]>', '\r'))
  elseif cause.event then
    vim.cmd(fmt('doautocmd <nomodeline> %s', cause.event))
  elseif cause.ft then
    vim.cmd(fmt('doautocmd <nomodeline> %s FileType %s', 'filetypeplugin', cause.ft))
    vim.cmd(fmt('doautocmd <nomodeline> %s FileType %s', 'filetypeindent', cause.ft))
  end
end

-- Runtimepath customization

-- Pre-load configuration
-- Setup for: spaceline.vim
loadstring('\27LJ\1\2ı\2\0\0\2\0\16\0\0294\0\0\0007\0\1\0%\1\3\0:\1\2\0004\0\0\0007\0\1\0%\1\5\0:\1\4\0004\0\0\0007\0\1\0%\1\a\0:\1\6\0004\0\0\0007\0\1\0003\1\t\0:\1\b\0004\0\0\0007\0\1\0%\1\v\0:\1\n\0004\0\0\0007\0\1\0%\1\r\0:\1\f\0004\0\0\0007\0\1\0%\1\15\0:\1\14\0G\0\1\0\16vim-signify\24spaceline_diff_tool\rnvim_lsp\30spaceline_diagnostic_tool\tÔû∞ \28spaceline_function_icon\1\4\0\0\tÔëó \tÔëò \tÔëô \31spaceline_custom_diff_icon\tÔû° \30spaceline_git_branch_icon\tÔÅ± "spaceline_diagnostic_warnsign\tÔÅó #spaceline_diagnostic_errorsign\6g\bvim\0')()
-- Setup for: dashboard-nvim
loadstring("\27LJ\1\2F\0\0\2\0\4\0\0054\0\0\0007\0\1\0%\1\3\0:\1\2\0G\0\1\0\16commicgirl5\29dashboard_default_header\6g\bvim\0")()
vim.cmd("packadd dashboard-nvim")
-- Post-load configuration
-- Config for: vim-eft
loadstring("\27LJ\1\0020\0\0\2\0\3\0\0054\0\0\0007\0\1\0)\1\2\0:\1\2\0G\0\1\0\19eft_ignorecase\6g\bvim\0")()
-- Conditional loads
-- Load plugins in order defined by `after`
vim._update_package_paths()
END

function! s:load(names, cause) abort
call luaeval('_packer_load(_A[1], _A[2])', [a:names, a:cause])
endfunction


" Command lazy-loads
command! -nargs=* -range -bang -complete=file MarkdownPreview call s:load(['markdown-preview.nvim'], { "cmd": "MarkdownPreview", "l1": <line1>, "l2": <line2>, "bang": <q-bang>, "args": <q-args> })
command! -nargs=* -range -bang -complete=file DBUIAddConnection call s:load(['vim-dadbod-ui'], { "cmd": "DBUIAddConnection", "l1": <line1>, "l2": <line2>, "bang": <q-bang>, "args": <q-args> })
command! -nargs=* -range -bang -complete=file DBUIRenameBuffer call s:load(['vim-dadbod-ui'], { "cmd": "DBUIRenameBuffer", "l1": <line1>, "l2": <line2>, "bang": <q-bang>, "args": <q-args> })
command! -nargs=* -range -bang -complete=file DBUIFindBuffer call s:load(['vim-dadbod-ui'], { "cmd": "DBUIFindBuffer", "l1": <line1>, "l2": <line2>, "bang": <q-bang>, "args": <q-args> })
command! -nargs=* -range -bang -complete=file DBUI call s:load(['vim-dadbod-ui'], { "cmd": "DBUI", "l1": <line1>, "l2": <line2>, "bang": <q-bang>, "args": <q-args> })
command! -nargs=* -range -bang -complete=file DBUIToggle call s:load(['vim-dadbod-ui'], { "cmd": "DBUIToggle", "l1": <line1>, "l2": <line2>, "bang": <q-bang>, "args": <q-args> })

" Keymap lazy-loads
noremap <silent> j <cmd>call <SID>load(['accelerated-jk'], { "keys": "j", "prefix": "" })<cr>

augroup packer_load_aucmds
  au!
  " Filetype lazy-loads
  au FileType lua ++once call s:load(['nvim-treesitter'], { "ft": "lua" })
  au FileType html ++once call s:load(['nvim-treesitter'], { "ft": "html" })
  au FileType typescript ++once call s:load(['nvim-treesitter', 'yats.vim'], { "ft": "typescript" })
  au FileType go ++once call s:load(['nvim-treesitter'], { "ft": "go" })
  au FileType rmd ++once call s:load(['markdown-preview.nvim'], { "ft": "rmd" })
  au FileType Dockerfile ++once call s:load(['Dockerfile.vim'], { "ft": "Dockerfile" })
  au FileType javascriptreact ++once call s:load(['vim-jsx-pretty'], { "ft": "javascriptreact" })
  au FileType rust ++once call s:load(['nvim-treesitter'], { "ft": "rust" })
  au FileType markdown ++once call s:load(['markdown-preview.nvim'], { "ft": "markdown" })
  au FileType pandoc.markdown ++once call s:load(['markdown-preview.nvim'], { "ft": "pandoc.markdown" })
  au FileType css ++once call s:load(['nvim-treesitter'], { "ft": "css" })
  au FileType zig ++once call s:load(['zig.vim'], { "ft": "zig" })
  au FileType typescriptreact ++once call s:load(['vim-jsx-pretty', 'yats.vim'], { "ft": "typescriptreact" })
  au FileType zir ++once call s:load(['zig.vim'], { "ft": "zir" })
  au FileType docker-compose ++once call s:load(['Dockerfile.vim'], { "ft": "docker-compose" })
  au FileType toml ++once call s:load(['nvim-treesitter'], { "ft": "toml" })
  " Event lazy-loads
  au BufNewFile * ++once call s:load(['spaceline.vim', 'vim-buffet'], { "event": "BufNewFile *" })
  au BufReadPre * ++once call s:load(['spaceline.vim', 'vim-buffet'], { "event": "BufReadPre *" })
  au BufReadPost ++once call s:load(['vim-cursorword'], { "event": "BufReadPost" })
  au BufReadPost * ++once call s:load(['context_filetype.vim'], { "event": "BufReadPost *" })
  au BufNewFile ++once call s:load(['vim-cursorword'], { "event": "BufNewFile" })
augroup END
