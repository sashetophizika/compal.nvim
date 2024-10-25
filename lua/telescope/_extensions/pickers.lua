local M = {}

local runners = require("compal.runners")
local conf = require("compal.config")
local utils = require("compal.utils")

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local actions = require "telescope.actions"
local themes = require "telescope.themes"
local action_state = require "telescope.actions.state"
local tconf = require("telescope.config").values

local function run_cmd(mode, ft, temp)
    local old_cmd = conf[ft][mode].cmd
    local selection = action_state.get_selected_entry()

    local cmd = action_state.get_current_line()
    if selection and selection[1] then
        cmd = selection[1]
    end

    utils.set_cmd({ "set", mode, "cmd", cmd })
    runners["run_" .. mode]()

    if temp then
        utils.set_cmd({ "set", ft, mode, "cmd", old_cmd })
    end
end

local function attach_mappings(prompt_bufnr, map, mode, ft)
    actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        run_cmd(mode, ft, true)
    end)
    map("i", "<C-s>", function()
        actions.close(prompt_bufnr)
        run_cmd(mode, ft, false)
    end)
    return true
end

M.picker_shell = function()
    local opts = themes.get_dropdown {}
    local ft = vim.bo.filetype
    if conf[ft] == nil then
        error("\nFiletype not supported!! It can be added in init.lua.\n")
    end

    pickers.new(opts, {
        prompt_title = "Compal Shell",
        finder = finders.new_table {
            results = conf[ft].shell.extra
        },
        sorter = tconf.generic_sorter(opts),

        attach_mappings = function(prompt_buffer, map)
            return attach_mappings(prompt_buffer, map, "shell", ft)
        end,
    }):find()
end

M.picker_interactive = function()
    local opts = themes.get_dropdown {}
    local ft = vim.bo.filetype
    if conf[ft] == nil then
        error("\nFiletype not supported!! It can be added in init.lua.\n")
    end

    pickers.new(opts, {
        prompt_title = "Compal Interactive",
        finder = finders.new_table {
            results = conf[ft].interactive.extra
        },
        sorter = tconf.generic_sorter(opts),

        attach_mappings = function(prompt_bufnr, map)
            return attach_mappings(prompt_bufnr, map, "interactive", ft)
        end,
    }):find()
end

M.add_to_pickers = function(args)
    local new_cmd = utils.concat_args(args, 3):sub(2)
    table.insert(conf[vim.bo.filetype][args[2]].extra, new_cmd)
    print(new_cmd)
end

return M
