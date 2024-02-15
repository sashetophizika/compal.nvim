local M = {}
M.cmd = {
    c = { shell = { cd = "cd %g;", cmd = "make" }, interactive = { repl = nil, title = "", cmd = "", in_shell = false } },
    rust = { shell = { cd = "cd %g;", cmd = "cargo run" }, interactive = { repl = nil, title = "", cmd = "", in_shell = false } },
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
    window = false
}

local function init(args)
    local ft = vim.bo.filetype
    if not M.cmd[ft] then
        error("\nFiletype not supported!! It can be added in init.lua.\n")
    end

    if M.cmd.save then
        vim.cmd("w")
    end
    return ft, args or ""
end

local function parse_wildcards(str)
    local parsed_command = str:gsub("%%f", vim.fn.expand("%:p")):gsub("%%s", vim.fn.expand("%:p:r")):gsub("%%h",
        vim.fn.expand("%:p:h"))
    local git_root = vim.fn.system("git rev-parse --show-toplevel"):sub(0, -2)

    if git_root:gmatch("fatal:")() == nil then
        parsed_command = parsed_command:gsub("%%g", git_root)
    else
        if parsed_command:gmatch("%%g")() then
            error("\nFile is not in a git repository but '%g' was used in the command!!\n")
        end
    end

    return parsed_command
end

M.run_vim = function(args)
    local ft
    ft, args = init(args)

    vim.cmd("!" .. parse_wildcards(M.cmd[ft].shell.cd .. M.cmd[ft].shell.cmd) .. args)
end

local function tmux_list_grep(shell)
    if M.cmd.window then
        return vim.fn.system(
            "tmux list-windows -F '#{window_index} #{pane_current_command} #{window_panes}' | grep -E '" ..
            shell .. " 1'")
    else
        return vim.fn.system("tmux list-panes -F '#{pane_index} #{pane_current_command}' | grep " .. shell)
    end
end

local function tmux_select(index)
    if M.cmd.window then
        vim.fn.system("tmux select-window -t " .. index)
    else
        vim.fn.system("tmux select-pane -t " .. index)
    end
end

local function tmux_new_pane(ft, interactive)
    local new_pane = M.cmd.split
    if M.cmd.window then
        new_pane = "tmux new-window"
    end

    local repl = ""
    if interactive then
        repl = M.cmd[ft].interactive.repl
    end

    if M.cmd[ft].interactive.in_shell then
        vim.fn.system(new_pane)
        vim.fn.system(string.format("tmux send-key '%s' Enter", repl))
    else
        vim.fn.system(new_pane .. " " .. repl)
    end
end

M.run_shell = function(args)
    local ft
    ft, args = init(args)

    if os.getenv("TMUX") then
        local sh_pane = tmux_list_grep("sh")
        local pane_index

        if sh_pane == "" then
            pane_index = tonumber(vim.fn.system("tmux display-message -p '#{pane_index}'")) + 1
            tmux_new_pane(ft, false)
        else
            pane_index = sh_pane:gmatch("%w+")()
            tmux_select(pane_index)
        end

        vim.fn.system(string.format("tmux send-keys C-z C-u '%s' Enter",
            parse_wildcards(M.cmd[ft].shell.cd .. M.cmd[ft].shell.cmd) .. args))

        if M.cmd.focus_shell == false then
            vim.fn.system("tmux select-pane -t " .. tonumber(pane_index) - 1)
        end
    else
        error("\nNo active tmux session!!\n")
    end
end

M.run_interactive = function(args)
    local ft
    ft, args = init(args)

    if os.getenv("TMUX") then
        local repl_pane = tmux_list_grep(M.cmd[ft].interactive.title)
        local pane_index

        if repl_pane ~= "" then
            pane_index = repl_pane:gmatch("%w+")()
            tmux_select(pane_index)
        else
            if M.cmd.override_shell then
                local sh_pane = tmux_list_grep("sh")

                if sh_pane ~= "" then
                    pane_index = sh_pane:gmatch("%w+")()
                    tmux_select(pane_index)
                    vim.fn.system(string.format("tmux send-keys C-z C-u '%s' Enter", M.cmd[ft].interactive.repl))
                else
                    pane_index = tonumber(vim.fn.system("tmux display-message -p '#{pane_index}'")) + 1
                    tmux_new_pane(ft, true)
                end
            else
                pane_index = tonumber(vim.fn.system("tmux display-message -p '#{pane_index}'")) + 1
                tmux_new_pane(ft, true)
            end
        end

        vim.fn.system(string.format("tmux send-keys C-u '%s' Enter", parse_wildcards(M.cmd[ft].interactive.cmd) .. args))

        if M.cmd.focus_repl == false then
            vim.fn.system("tmux select-pane -t" .. tonumber(pane_index) - 1)
        end
    else
        error("\nNo active tmux session!!\n")
    end
end

M.run_smart = function(args)
    if os.getenv("TMUX") then
        if M.cmd[vim.bo.filetype].interactive.repl then
            M.run_interactive(args)
        else
            M.run_shell(args)
        end
    else
        M.run_vim(args)
    end
end

local function concat_args(argv, first, last)
    local res = " "
    for i = first or 1, last or #argv do
        res = res .. argv[i] .. " "
    end
    return res
end

M.set_cmd = function(args)
    local new_cmd = concat_args(args, 4)
    M.cmd[vim.bo.filetype][args[2]][args[3]] = new_cmd
    print(new_cmd)
end

M.setup = function(opts)
    if opts then M.cmd = vim.tbl_deep_extend("force", M.cmd, opts) end

    vim.api.nvim_create_user_command("Compal", function(opt)
            if opt.fargs[1] == "set" then
                M.set_cmd(opt.fargs)
            else
                M["run_" .. opt.fargs[1]](concat_args(opt.fargs, 2))
            end
        end,
        {
            nargs = "*",
            complete = function()
                return { "smart", "interactive", "vim", "shell", "set" }
            end,
        })

    return M
end

return M
