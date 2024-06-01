local M = {}

local runners = require("compal.runners")
local utils = require("compal.utils")
local conf = require("compal.config")

M.run_smart = runners.run_smart
M.run_shell = runners.run_shell
M.run_interactive = runners.run_interactive
M.run_vim = runners.run_vim
M.add_to_pickers = utils.add_to_pickers

M.setup = function(opts)
    for key, val in pairs(conf) do
        if type(val) == "table" and key ~= "telescope" then
            val.shell.extra = { val.shell.cmd }
            val.interactive.extra = { val.interactive.cmd }
        end
    end

    if opts then utils.extend_conf(conf, opts) end

    if conf.telescope.enabled then
        local telescope = require("compal.telecompal")
        M.picker_shell = telescope.picker_shell
        M.picker_interactive = telescope.picker_interactive

        vim.api.nvim_create_user_command("CompalPicker", function(opt)
                M["picker_" .. opt.fargs[1]]()
            end,
            {
                nargs = "*",
                complete = function()
                    return { "shell", "interactive" }
                end,
            })
    end

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
