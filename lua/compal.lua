local M = {}
M.cmd = {
    c = { shell = { cd = "cd %g;", cmd = "make", }, interactive = { repl = nil, title = "", cmd = "", in_shell = false } },
    rust = { shell = { cd = "cd %g;", cmd = "cargo run", extra = { "cargo build --release", "cargo build", "rustc %f" } }, interactive = { repl = nil, title = "", cmd = "", in_shell = false } },
    cpp = { shell = { cd = "cd %g;", cmd = "make" }, interactive = { repl = nil, title = "", cmd = "", in_shell = false } },
    julia = { shell = { cd = "", cmd = "julia %f" }, interactive = { repl = "julia", title = "julia", cmd = 'include("%f")', in_shell = false } },
    python = { shell = { cd = "", cmd = "python %f" }, interactive = { repl = "ipython", title = "python", cmd = "%run %f", in_shell = nil } },
    sh = { shell = { cd = "", cmd = "bash %f" }, interactive = { repl = nil, title = "", cmd = "", in_shell = false } },
    cs = { shell = { cd = "cd %g;", cmd = "dotnet run" }, interactive = { repl = nil, title = "", cmd = "", in_shell = false } },
    php = { shell = { cd = "", cmd = "php %f" }, interactive = { repl = nil, title = "", cmd = "", in_shell = false } },
    haskell = { shell = { cd = "cd %g", cmd = "cabal run" }, interactive = { repl = "ghci", title = "ghc", cmd = ":l %f", in_shell = false } },
    lua = { shell = { cd = "", cmd = "lua %f" }, interactive = { repl = "lua", title = "lua", cmd = "dofile(\"%f\")", in_shell = false } },
    java = { shell = { cd = "", cmd = "javac %f" }, interactive = { repl = nil, title = "", cmd = "", in_shell = false } },
    javascript = { shell = { cd = "", cmd = "node %f" }, interactive = { repl = nil, title = "", cmd = "", in_shell = false } },
    ruby = { shell = { cd = "", cmd = "ruby %f" }, interactive = { repl = "irb", title = "irb", cmd = 'require "%f"', in_shell = false } },
    tex = { shell = { cd = "", cmd = "pdflatex %f" }, interactive = { repl = nil, title = "", cmd = "", in_shell = false } },
    kotlin = { shell = { cd = "", cmd = "kotlinc %f" }, interactive = { repl = nil, title = "", cmd = "", in_shell = false } },
    zig = { shell = { cd = "cd %g;", cmd = "zig build run" }, interactive = { repl = nil, title = "", cmd = "", in_shell = false } },
    typescript = { shell = { cd = "", cmd = "npx tsc %f" }, interactive = { repl = nil, title = "", cmd = "", in_shell = false } },
    elixir = { shell = { cd = "cd %g;", cmd = "mix compile" }, interactive = { repl = "iex -S mix", title = "beam.smp", cmd = "recompile()", in_shell = false } },
    ocaml = { shell = { cd = "cd %g;", cmd = "dune build;dune exec $(basename %g)" }, interactive = { repl = "dune utop", title = "utop", cmd = "", in_shell = true } },
    clojure = { shell = { cd = "", cmd = "clj -M %f" }, interactive = { repl = "clj", title = "rlwrap", cmd = '(load-file "%f")', in_shell = false } },
    go = { shell = { cd = "cd %g;", cmd = "go run ." }, interactive = { repl = nil, title = "", cmd = "", in_shell = false } },
    dart = { shell = { cd = "cd %g;", cmd = "dart run" }, interactive = { repl = nil, title = "", cmd = "", in_shell = false } },
    split = "tmux split -v",
    save = true,
    focus_shell = true,
    focus_repl = true,
    override_shell = true,
    window = false,
    telescope = {
        enabled = false,
        auto_append = true,
    }
}

local multiplexer_commands = {
    window_list_grep = { tmux = "tmux list-windows -F '#{window_index} #{pane_current_command} #{window_panes}' | grep -E '" },
    pane_list_grep = { tmux = "tmux list-panes -F '#{pane_index} #{pane_current_command}' | grep " },
    new_window = { tmux = "tmux new-window" },
    window_select = { tmux = "tmux select-window -t " },
    pane_select = { tmux = "tmux select-pane -t " },
    send_keys = { tmux = "tmux send-key C-u '%s' Enter" },
    pane_index = { tmux = "tmux display-message -p '#{pane_index}'" },
}

local function init(args)
    local ft = vim.bo.filetype

    local mp
    if os.getenv("TMUX") then
        mp = "tmux"
    elseif os.getenv("ZELLIJ") then
        error("\nZellij not yet supported.\n")
        mp = "zellij"
    end

    if M.cmd[ft] == nil then
        error("\nFiletype not supported!! It can be added in init.lua.\n")
    end

    if M.cmd.save then
        vim.cmd("w")
    end
    return ft, mp, args or ""
end

local function parse_wildcards(str)
    local parsed_command = str:gsub("%%f", vim.fn.expand("%:p")):gsub("%%s", vim.fn.expand("%:p:r")):gsub("%%h",
        vim.fn.expand("%:p:h"))
    local git_root = vim.fn.system("git rev-parse --show-toplevel"):sub(0, -2)

    if git_root:gmatch("fatal:")() == nil then
        parsed_command = parsed_command:gsub("%%g", git_root)
    elseif parsed_command:gmatch("%%g")() then
        error("\nFile is not in a git repository but '%g' was used in the command!!\n")
    end

    return parsed_command
end

local function auto_append(cmd, ft, mode)
    if M.cmd.telescope.auto_append then
        local dup = false
        for _, v in pairs(M.cmd[ft][mode].extra) do
            if v == cmd then
                dup = true
            end
        end

        if not dup then
            table.insert(M.cmd[ft][mode].extra, 1, cmd)
        end
    end
end

M.run_vim = function(args)
    local ft
    ft, _, args = init(args)

    vim.cmd("!" .. parse_wildcards(M.cmd[ft].shell.cd .. M.cmd[ft].shell.cmd) .. args)
    auto_append(M.cmd[ft].shell.cmd .. args, ft, "shell")
end

local function multiplexer_list_grep(mp, shell)
    if M.cmd.window then
        return vim.fn.system(
            multiplexer_commands.window_list_grep[mp] ..
            shell .. " 1'")
    else
        return vim.fn.system(multiplexer_commands.pane_list_grep[mp] .. shell)
    end
end

local function multiplexer_select(mp, index)
    if M.cmd.window then
        vim.fn.system(multiplexer_commands.window_select[mp] .. index)
    else
        vim.fn.system(multiplexer_commands.pane_select[mp] .. index)
    end
end

local function multiplexer_new_pane(ft, mp, interactive)
    local new_pane = M.cmd.split
    if M.cmd.window then
        new_pane = multiplexer_commands.new_window[mp]
    end

    local repl = ""
    if interactive then
        repl = M.cmd[ft].interactive.repl
    end

    if M.cmd[ft].interactive.in_shell then
        vim.fn.system(new_pane)
        vim.fn.system(string.format(multiplexer_commands.send_keys[mp], repl))
    else
        vim.fn.system(new_pane .. " " .. repl)
    end
end

M.run_shell = function(args)
    local ft
    local mp
    ft, mp, args = init(args)

    if mp then
        local sh_pane = multiplexer_list_grep(mp, "sh")
        local pane_index

        if sh_pane == "" then
            pane_index = tonumber(vim.fn.system(multiplexer_commands.pane_index[mp])) + 1
            multiplexer_new_pane(ft, mp, false)
        else
            pane_index = sh_pane:gmatch("%w+")()
            multiplexer_select(mp, pane_index)
        end

        vim.fn.system(string.format(multiplexer_commands.send_keys[mp],
            parse_wildcards(M.cmd[ft].shell.cd .. M.cmd[ft].shell.cmd) .. args))

        if M.cmd.focus_shell == false then
            vim.fn.system(multiplexer_commands.pane_select[mp] .. tonumber(pane_index) - 1)
        end
        auto_append(M.cmd[ft].shell.cmd .. args, ft, "shell")
    else
        error("\nNo active multiplexer session!!\n")
    end
end

M.run_interactive = function(args)
    local ft
    local mp
    ft, mp, args = init(args)

    if mp then
        local repl_pane = multiplexer_list_grep(mp, M.cmd[ft].interactive.title)
        local pane_index

        if repl_pane ~= "" then
            pane_index = repl_pane:gmatch("%w+")()
            multiplexer_select(mp, pane_index)
        else
            if M.cmd.override_shell then
                local sh_pane = multiplexer_list_grep(mp, "sh")

                if sh_pane ~= "" then
                    pane_index = sh_pane:gmatch("%w+")()
                    multiplexer_select(mp, pane_index)
                    vim.fn.system(string.format(multiplexer_commands.send_keys[mp], M.cmd[ft].interactive.repl))
                else
                    pane_index = tonumber(vim.fn.system(multiplexer_commands.pane_index[mp])) + 1
                    multiplexer_new_pane(ft, mp, true)
                end
            else
                pane_index = tonumber(vim.fn.system(multiplexer_commands.pane_index[mp])) + 1
                multiplexer_new_pane(ft, mp, true)
            end
        end

        vim.fn.system(string.format(multiplexer_commands.send_keys[mp],
            parse_wildcards(M.cmd[ft].interactive.cmd) .. args))
        if M.cmd.focus_repl == false then
            vim.fn.system(multiplexer_commands.pane_select[mp] .. tonumber(pane_index) - 1)
        end

        auto_append(M.cmd[ft].interactive.cmd .. args, ft, "interactive")
    else
        error("\nNo active multiplexer session!!\n")
    end
end

M.run_smart = function(args)
    if os.getenv("TMUX") or os.getenv("ZELLIJ") then
        if M.cmd[vim.bo.filetype] and M.cmd[vim.bo.filetype].interactive.repl then
            M.run_interactive(args)
        else
            M.run_shell(args)
        end
    else
        M.run_vim(args)
    end
end

local function concat_args(argv, first, last)
    local res = ""
    for i = first or 1, last or #argv do
        res = res .. " " .. argv[i]
    end
    return res
end

M.get_cmd = function(args)
    local ft = vim.bo.filetype
    if args[2] == nil then
        print(vim.inspect(M.cmd[ft]))
    elseif args[3] == nil then
        print(vim.inspect(M.cmd[ft][args[2]]))
    else
        print(M.cmd[ft][args[2]][args[3]])
    end
end

M.set_cmd = function(args)
    local new_cmd = concat_args(args, 4):sub(2)
    M.cmd[vim.bo.filetype][args[2]][args[3]] = new_cmd
    print(new_cmd)
end

local function enable_telescope()
    local pickers = require "telescope.pickers"
    local finders = require "telescope.finders"
    local actions = require "telescope.actions"
    local themes = require("telescope.themes")
    local action_state = require "telescope.actions.state"
    local conf = require("telescope.config").values

    M.picker_shell = function()
        local opts = themes.get_dropdown {}
        local ft = vim.bo.filetype
        if M.cmd[ft] == nil then
            error("\nFiletype not supported!! It can be added in init.lua.\n")
        end

        pickers.new(opts, {
            prompt_title = "Compal Shell",
            finder = finders.new_table {
                results = M.cmd[ft].shell.extra
            },
            sorter = conf.generic_sorter(opts),

            attach_mappings = function(prompt_bufnr, map)
                actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()

                    if selection[1] ~= nil then
                        local old_command = M.cmd[ft].shell.cmd
                        M.set_cmd({ "set", "shell", "cmd", selection[1] })
                        M.run_shell()
                        M.set_cmd({ "set", "shell", "cmd", old_command })
                    end
                end)
                map("i", "<C-Enter>",function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()

                    if selection[1] ~= nil then
                        M.set_cmd({ "set", "shell", "cmd", selection[1] })
                        M.run_shell()
                    end
                end)
                return true
            end,
        }):find()
    end

    M.picker_interactive = function()
        local opts = themes.get_dropdown {}
        local ft = vim.bo.filetype

        pickers.new(opts, {
            prompt_title = "Compal Interactive",
            finder = finders.new_table {
                results = M.cmd[ft].interactive.extra
            },
            sorter = conf.generic_sorter(opts),

            attach_mappings = function(prompt_bufnr, map)
                actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()

                    if selection[1] ~= nil then
                        local old_command = M.cmd[ft].interactive.cmd
                        M.set_cmd({ "set", "interactive", "cmd", selection[1] })
                        M.run_interactive()
                        M.set_cmd({ "set", "interactive", "cmd", old_command })
                    end
                end)
                map("i", "<C-Enter>",function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()

                    if selection[1] ~= nil then
                        M.set_cmd({ "set", "shell", "cmd", selection[1] })
                        M.run_interactive()
                    end
                end)
                return true
            end,
        }):find()
    end

    M.add_to_pickers = function(args)
        local new_cmd = concat_args(args, 3):sub(2)
        table.insert(M.cmd[vim.bo.filetype][args[2]].extra, new_cmd)
        print(new_cmd)
    end
end

M.setup = function(opts)
    for key, val in pairs(M.cmd) do
        if type(val) == "table" and key ~= "telescope" then
            val.shell.extra = { val.shell.cmd }
            val.interactive.extra = { val.interactive.cmd }
        end
    end

    if opts then M.cmd = vim.tbl_deep_extend("force", M.cmd, opts) end

    if M.cmd.telescope.enabled then
        enable_telescope()

        vim.api.nvim_create_user_command("CompalPicker", function(opt)
                if opt.fargs[1] == "add" then
                    M.add_to_pickers(opt.fargs)
                else
                    M["picker_" .. opt.fargs[1]]()
                end
            end,
            {
                nargs = "*",
                complete = function()
                    return { "shell", "interactive", "add" }
                end,
            })
    end

    vim.api.nvim_create_user_command("Compal", function(opt)
            if opt.fargs[1] == "set" or opt.fargs[1] == "get" then
                M[opt.fargs[1] .. "_cmd"](opt.fargs)
            else
                M["run_" .. opt.fargs[1]](concat_args(opt.fargs, 2, #opt.fargs))
            end
        end,
        {
            nargs = "*",
            complete = function()
                return { "smart", "interactive", "vim", "shell", "set", "get" }
            end,
        })
    return M
end

return M
