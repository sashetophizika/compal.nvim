    local has_telescope, telescope = pcall(require, "telescope")

    if not has_telescope then
        error("\n Telescope is enabled but telescope.nvim is not found!\n")
    end

    return telescope.register_extension({
        exports = {
            shell = require("telescope._extensions.pickers").picker_shell,
            interactive = require("telescope._extensions.pickers").picker_interactive,
        },
    })
