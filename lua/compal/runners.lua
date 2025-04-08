local M = {}

local conf = require("compal.config")

local multiplexer_commands = {
    window_list_grep = { tmux = "tmux list-windows -F '#{window_index} #{pane_current_command} #{window_panes}' | grep -E '" },
    pane_list_grep = { tmux = "tmux list-panes -F '#{pane_index} #{pane_current_command}' | grep " },
    new_window = { tmux = "tmux new-window" },
    window_select = { tmux = "tmux select-window -t " },
    pane_select = { tmux = "tmux select-pane -t " },
    send_keys = { tmux = "tmux send-key C-u '%s' Enter" },
    pane_index = { tmux = "tmux display-message -p '#{pane_index}'" },
}

local function init()
    local ft = vim.bo.filetype

    local mp
    if os.getenv("TMUX") then
        mp = "tmux"
    elseif os.getenv("ZELLIJ") then
        error("\nZellij not yet supported.\n", vim.log.levels.ERROR)
        mp = "zellij"
    end

    if not conf[ft] then
        error("\nFiletype not supported!! It can be added in init.lua.\n", vim.log.levels.ERROR)
    end

    if conf.save then
        vim.cmd("w")
    end
    return ft, mp
end

local warn = false
local function git_warn()
    if warn == true then
        vim.notify("\nFile is not in a git repository but '%g' was used in the command!!\n", vim.log.levels.WARN)
    end
end

local function parse_wildcards(str)
    local parsed_command = str:gsub("%%f", vim.fn.expand("%:p")):gsub("%%s", vim.fn.expand("%:p:r")):gsub("%%h",
        vim.fn.expand("%:p:h"))
    local git_root = vim.fn.system("git rev-parse --show-toplevel"):sub(0, -2)

    if git_root:gmatch("fatal:")() == nil then
        parsed_command = parsed_command:gsub("%%g", git_root)
    elseif parsed_command:gmatch("%%g")() then
        warn = true
        return ""
    end

    return parsed_command
end

local function auto_append(cmd, ft, mode)
    if conf.telescope.auto_append then
        local dup = false
        for _, v in pairs(conf[ft][mode].extra) do
            if v == cmd then
                dup = true
            end
        end

        if not dup then
            table.insert(conf[ft][mode].extra, 1, cmd)
        end
    end
end

local function full_cmd(cd, cmd)
    if cd:gmatch(";")() or cd:gmatch("&&")() then
        return cd .. " " .. cmd
    elseif cd == "" or cd == " " or cd == nil then
        return cmd
    else
        return cd .. "; " .. cmd
    end
end

local terminal = false
local term_win = 0
local repl_info = nil

local function open_builtin(ft, interactive)
    if interactive and not conf.override_shell then
        repl_info = conf[ft].interactive.title
    end

    if terminal then
        vim.api.nvim_set_current_win(term_win)
    else
        if conf.window then
            vim.cmd("tabnew")
        else
            vim.cmd("split")
        end

        if interactive then
            vim.cmd("terminal " .. conf[ft].interactive.repl)
        else
            vim.cmd("terminal")
        end

        term_win = vim.api.nvim_get_current_win()
    end
end

local function builtin_shell(filetype, args)
    local cd  = parse_wildcards(conf[filetype].shell.cd)
    local cmd = parse_wildcards(conf[filetype].shell.cmd) .. args .. "<Enter>"
    open_builtin(filetype, false)

    if not conf.focus_shell then
        cmd = cmd .. "<C-\\><C-n><C-w><C-w>"
    end

    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("i" .. full_cmd(cd, cmd), true, false, true), "n", true)
    auto_append(conf[filetype].shell.cmd .. args, filetype, "shell")
    git_warn()
end

local function builtin_interactive(filetype, args)
    local cmd = parse_wildcards(conf[filetype].interactive.cmd) .. args .. "<Enter>"
    open_builtin(filetype, true)

    if terminal and conf.override_shell and repl_info ~= conf[filetype].interactive.title then
        cmd = conf[filetype].interactive.repl .. "<Enter>" .. cmd
    end

    if not conf.focus_repl then
        cmd = cmd .. "<C-\\><C-n><C-w><C-w>"
    end

    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("i" .. cmd, true, false, true), "n", true)
    auto_append(conf[filetype].shell.cmd .. args, filetype, "shell")
end

local function multiplexer_list_grep(mp, shell)
    if conf.window then
        return vim.fn.system(
            multiplexer_commands.window_list_grep[mp] ..
            shell .. " 1'")
    else
        return vim.fn.system(multiplexer_commands.pane_list_grep[mp] .. shell)
    end
end

local function multiplexer_select(mp, index)
    if conf.window then
        vim.fn.system(multiplexer_commands.window_select[mp] .. index)
    else
        vim.fn.system(multiplexer_commands.pane_select[mp] .. index)
    end
end

local function multiplexer_new_pane(ft, mp, interactive)
    local new_pane
    if conf.window then
        new_pane = multiplexer_commands.new_window[mp]
    else
        new_pane = conf.split or conf.tmux_split
    end

    if interactive and conf[ft] then
        local repl = ""
        repl = conf[ft].interactive.repl or ""
        if conf[ft].interactive.in_shell then
            vim.fn.system(new_pane)
            vim.fn.system(string.format(multiplexer_commands.send_keys[mp], repl))
        else
            vim.fn.system(new_pane .. " " .. repl)
        end
    else
        vim.fn.system(new_pane)
    end
end

local function open_multiplexer(ft, mp, pane_cmd, interactive)
    local pane_index

    if pane_cmd ~= "" then
        pane_index = pane_cmd:gmatch("%w+")()
        multiplexer_select(mp, pane_index)
        return pane_index
    end

    if interactive and conf.override_shell then
        pane_cmd = multiplexer_list_grep(mp, "sh")

        if pane_cmd ~= "" then
            pane_index = pane_cmd:gmatch("%w+")()
            multiplexer_select(mp, pane_index)
            vim.fn.system(string.format(multiplexer_commands.send_keys[mp], parse_wildcards(conf[ft].interactive.repl)))
            return pane_index
        end
    end

    pane_index = tonumber(vim.fn.system(multiplexer_commands.pane_index[mp])) + 1
    multiplexer_new_pane(ft, mp, interactive)
    return pane_index
end

local function multiplexer_shell(filetype, multiplexer, args)
    local sh_pane    = multiplexer_list_grep(multiplexer, "sh")
    local pane_index = open_multiplexer(filetype, multiplexer, sh_pane, false)

    local cd         = parse_wildcards(conf[filetype].shell.cd)
    local cmd        = parse_wildcards(conf[filetype].shell.cmd)

    vim.fn.system(string.format(multiplexer_commands.send_keys[multiplexer],
        full_cmd(cd, cmd) .. args))

    if conf.focus_shell == false then
        vim.fn.system(multiplexer_commands.pane_select[multiplexer] .. tonumber(pane_index) - 1)
    end
    auto_append(conf[filetype].shell.cmd .. args, filetype, "shell")
    git_warn()
end

local function multiplexer_interactive(filetype, multiplexer, args)
    local repl_pane = multiplexer_list_grep(multiplexer, conf[filetype].interactive.title)
    local pane_index = open_multiplexer(filetype, multiplexer, repl_pane, true)

    vim.fn.system(string.format(multiplexer_commands.send_keys[multiplexer],
        parse_wildcards(conf[filetype].interactive.cmd) .. args))

    if conf.focus_repl == false then
        vim.fn.system(multiplexer_commands.pane_select[multiplexer] .. tonumber(pane_index) - 1)
    end

    auto_append(conf[filetype].interactive.cmd .. args, filetype, "interactive")

    if conf[filetype].interactive.cmd == nil then
        vim.notify("Filetype '" .. filetype .. "' has no interactive command!!\nAdd it in init.lua.", vim.log.levels
            .WARN)
    end
end

M.open_shell = function()
    if conf.prefer_tmux and os.getenv("TMUX") then
        local mp = "tmux"
        local sh_pane = multiplexer_list_grep(mp, "sh")
        open_multiplexer(nil, mp, sh_pane, false)
    else
        open_builtin(nil, false)
    end
end

M.open_repl = function()
    local ft, mp = init()

    if conf.prefer_tmux and os.getenv("TMUX") then
        local repl_pane = multiplexer_list_grep(mp, conf[ft].interactive.title)
        open_multiplexer(ft, mp, repl_pane, true)
    else
        open_builtin(ft, true)
    end
end

M.run_shell = function(args)
    args = args or ""
    local ft, mp = init()

    if conf[ft].shell.cmd == nil then
        vim.notify("Filetype '" .. ft .. "' has no shell command!!\nAdd it in init.lua.", vim.log.levels.ERROR)
        return
    end

    if conf.prefer_tmux and mp then
        multiplexer_shell(ft, mp, args)
    else
        builtin_shell(ft, args)
    end
end

M.run_interactive = function(args)
    args = args or ""
    local ft, mp = init()

    if conf[ft].interactive.repl == nil then
        vim.notify("Filetype '" .. ft .. "' has no repl!!\nIf it should, add it in init.lua.", vim.log.levels
            .ERROR)
        return
    end

    if conf.prefer_tmux and mp then
        multiplexer_interactive(ft, mp, args)
    else
        builtin_interactive(ft, args)
    end
end

M.run_smart = function(args)
    if conf[vim.bo.filetype] and conf[vim.bo.filetype].interactive.repl then
        M.run_interactive(args)
    else
        M.run_shell(args)
    end
end

M.create_autocmds = function()
    vim.api.nvim_create_autocmd({ "TermOpen" }, {
        callback = function()
            terminal = true
        end
    })

    vim.api.nvim_create_autocmd({ "TermClose" }, {
        callback = function()
            terminal = false
            repl_info = nil
        end
    })
end

return M
