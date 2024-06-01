local M = {}

local runners = require("compal.runners")
local conf = require("compal.config")
local utils = require("compal.utils")

local has_telescope, _ = pcall(require, "telescope")

if not has_telescope then
    error("\n Telescope is enabled but telescope.nvim is not found!\n")
end

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local actions = require "telescope.actions"
local themes = require "telescope.themes"
local action_state = require "telescope.actions.state"
local tconf = require("telescope.config").values

local function attatch_mappings(prompt_bufnr, map, mode, ft)
    actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()

        if selection[1] ~= nil then
            local old_command = conf[ft][mode].cmd
            utils.set_cmd({ "set", mode, "cmd", selection[1] })
            runners["run_" .. mode]()
            utils.set_cmd({ "set", ft, mode, "cmd", old_command })
        end
    end)
    map("i", "<C-Enter>", function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()

        if selection[1] ~= nil then
            utils.set_cmd({ "set", mode, "cmd", selection[1] })
            runners["run_" .. mode]()
        end
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
            return attatch_mappings(prompt_buffer, map, "shell", ft)
        end,
    }):find()
end

M.picker_interactive = function()
    local opts = themes.get_dropdown {}
    local ft = vim.bo.filetype

    pickers.new(opts, {
        prompt_title = "Compal Interactive",
        finder = finders.new_table {
            results = conf[ft].interactive.extra
        },
        sorter = tconf.generic_sorter(opts),

        attach_mappings = function(prompt_bufnr, map)
            return attatch_mappings(prompt_bufnr, map, "interactive", ft)
        end,
    }):find()
end

return M