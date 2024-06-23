local M = {}

local runners = require("compal.runners")
local utils = require("compal.utils")
local conf = require("compal.config")

M.run_smart = runners.run_smart
M.run_shell = runners.run_shell
M.run_interactive = runners.run_interactive
M.open_shell = runners.open_shell
M.open_repl = runners.open_repl
M.add_to_pickers = utils.add_to_pickers
M.conf = conf

M.run_vim = function()
    vim.notify("compal.run_vim is deprecated, remove the keybinding to avoid breaking when it is removed.",
        vim.log.levels.WARN)
end

M.picker_shell = function()
    vim.notify(
        "compal.picker_shell is deprecated, remove the keybinding to avoid breaking when it is removed.\nSee the documentation for how to load the telescope extension",
        vim.log.levels.WARN)
end

M.picker_interactive = function()
    vim.notify(
        "compal.picker_interactive is deprecated, remove the keybinding to avoid breaking when it is removed.\nSee the documentation for how to load the telescope extension",
        vim.log.levels.WARN)
end

M.setup = function(opts)
    for key, val in pairs(conf) do
        if type(val) == "table" and key ~= "telescope" then
            val.shell.extra = { val.shell.cmd }
            val.interactive.extra = { val.interactive.cmd }
        end
    end

    if opts then utils.extend_conf(conf, opts) end

    vim.api.nvim_create_user_command("Compal", function(opt)
            if opt.fargs[1] == "set" or opt.fargs[1] == "get" then
                utils[opt.fargs[1] .. "_cmd"](opt.fargs)
            elseif opt.fargs[1] == "add" then
                M.add_to_pickers(opt.fargs)
            else
                runners["run_" .. opt.fargs[1]](utils.concat_args(opt.fargs, 2, #opt.fargs))
            end
        end,
        {
            nargs = "*",
            complete = function()
                return { "smart", "interactive", "shell", "set", "get", "add" }
            end,
        })

    runners.create_autocmds()
    return M
end

return M
