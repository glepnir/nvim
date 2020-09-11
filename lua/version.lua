local vim = vim
local api = vim.api

local M = {}

function M.blameVirtualText()
    local fname = vim.fn.expand('%')
    if not vim.fn.filereadable(fname) then return end

    local ns_id = api.nvim_create_namespace("GitLens")
    api.nvim_buf_clear_namespace(0, ns_id, 0, -1)

    local line = api.nvim_win_get_cursor(0)
    local blame = vim.fn.system(string.format("git blame -c -L %d,%d %s", line[1], line[1], fname))
    if vim.v.shell_error > 0 then return end
    local hash = vim.split(blame, '%s')[1]
    if hash == '00000000' then return end

    local cmd = string.format("git show %s ", hash) .. "--format=' : %an | %ar | %s'"
    local text = vim.fn.system(cmd)
    text = vim.split(text, "\n")[1]
    if text:find("fatal") then return end

    api.nvim_buf_set_virtual_text(0, ns_id, line[1]-1, {{ text, "GitLens" }}, {})
end

function M.clearBlameVirtualText()
    local ns_id = api.nvim_create_namespace("GitLens")
    api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
end

return M
