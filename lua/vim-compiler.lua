local M = {}

local commands = {
        c = { normal = {cd = "cd %g;", cmd = "make"}, interactive = { repl = nil, title = "", cmd = ""}},
        rust = { normal = {cd = "cd %g;", cmd = "cargo run"}, interactive = { repl = nil, title = "", cmd = ""}},
        cpp = { normal = {cd = "cd %g;", cmd = "make"}, interactive = { repl = nil, title = "", cmd = ""}},
        julia = { normal = {cd = "", cmd = "julia %f"}, interactive = { repl = "julia", title = "julia", cmd = 'include("%f")'}},
        python = { normal = {cd = "", cmd = "python %f"}, interactive = { repl = "ipython", title = "python", cmd = "%run %f"}},
        bash = { normal = {cd = "", cmd = "bash %f"}, interactive = { repl = nil, title = "", cmd = ""}},
        cs = { normal = {cd = "cd %g;", cmd = "dotnet run"}, interactive = { repl = nil, title = "", cmd = ""}},
        php = { normal = {cd = "", cmd = "php %f"}, interactive = { repl = nil, title = "", cmd = ""}},
        haskell = { normal = {cd = "cd %g", cmd = "cabal run"}, interactive = { repl = "ghci", title = "ghc", cmd = ":l %f"}},
        lua = { normal = {cd = "", cmd = "lua %f"}, interactive = { repl = "lua", title = "lua", cmd = "require('%f')"}},
        java = { normal = {cd = "", cmd = "javac %f"}, interactive = { repl = nil, title = "", cmd = ""}},
        javascript = { normal = {cd = "", cmd = "node %f"}, interactive = { repl = nil, title = "", cmd = ""}},
        ruby = { normal = {cd = "", cmd = "ruby %f"}, interactive = { repl = "irb", title = "irb", cmd = 'require "%f"'}},
        tex = { normal = {cd = "", cmd = "pdflatex %f"}, interactive = { repl = nil, title = "", cmd = ""}},
        kotlin = { normal = {cd = "", cmd = "kotlinc %f"}, interactive = { repl = nil, title = "", cmd = ""}},
        zig = { normal = {cd = "cd %g;", cmd = "zig build run"}, interactive = { repl = nil, title = "", cmd = ""}},
        typescript = { normal = {cd = "", cmd = "npx tsc %f"}, interactive = { repl = nil, title = "", cmd = ""}},
        elixir = { normal = {cd = "cd %g;", cmd = "mix compile"}, interactive = { repl = "iex -S mix", title = "beam.smp", cmd = "recompile()"}},
        clojure = { normal = {cd = "", cmd = "clj -M %f"}, interactive = { repl = "clj", title = "rlwrap", cmd = '(load-file "%f")'}},
        go = { normal = {cd = "cd %g;", cmd = "go run ."}, interactive = { repl = nil, title = "", cmd = ""}},
        dart = { normal = {cd = "cd %g;", cmd = "dart run"}, interactive = { repl = nil, title = "", cmd = ""}},
    split = "tmux split -v",
    save = true,
    focus_shell = true,
    focus_repl = true,
    override_shell = true
}

local function parse_wildcards(str)
    local pre_git = str:gsub("%%f", vim.fn.expand("%:p")):gsub("%%s", vim.fn.expand("%:p:r")):gsub("%%h", vim.fn.expand("%:p:h"))
    local git_root = vim.fn.system("git rev-parse --show-toplevel")

    local no_git = ""
    if git_root:gmatch("fatal:")() == nil then
        pre_git = pre_git:gsub("%%g", git_root:sub(0, -2))
    else if pre_git:gmatch("%g") then
        pre_git = no_git
    end

    return pre_git
end

M.compile_vim = function(args)
    args = args or ""

    if M.save then
        vim.cmd("w")
    end

    vim.fn.system(parse_wildcards(M.cmd[vim.bo.filetype].normal.cmd) .. args)
end

M.compile_normal = function(args)
    args = args or ""

    if M.save then
        vim.cmd("w")
    end

    if os.getenv("TMUX") then
        local sh_pane = vim.fn.system("tmux list-panes -F '#{pane_index} #{pane_current_command}' | rg sh")
        local pane_index

        if sh_pane == "" then
            pane_index = tonumber(vim.fn.system("tmux display-message -p '#{pane_index}'")) + 1
            vim.fn.system(M.cmd.split)
        else
            pane_index = sh_pane:gmatch("%w+")()
            vim.fn.system("tmux select-pane -t " .. pane_index)
        end

        vim.fn.system(string.format("tmux send-keys C-z '%s' Enter", parse_wildcards(M.cmd[vim.bo.filetype].normal.cd .. M.cmd[vim.bo.filetype].normal.cmd) .. args))

        if M.cmd.focus_shell == false then
            vim.fn.system("tmux select-pane -t " .. tonumber(pane_index) - 1)
    	end
    end
end

M.compile_interactive = function(args)
    args = args or ""

    if M.save then
        vim.cmd("w")
    end

    if os.getenv("TMUX") then
        local ft = vim.bo.filetype
        local sh_pane = vim.fn.system("tmux list-panes -F '#{pane_index} #{pane_current_command}' | rg " .. M.cmd[ft].interactive.title)
        local pane_index

        if sh_pane ~= "" then
            pane_index = sh_pane:gmatch("%w+")()
            vim.fn.system("tmux select-pane -t " .. pane_index)
        else
            if M.cmd.override_shell then
                local sh_present = vim.fn.system("tmux list-panes -F '#{pane_index} #{pane_current_command}' | rg sh")

                if sh_present ~= "" then
                    pane_index = sh_present:gmatch("%w+")()
                    vim.fn.system("tmux select-pane -t " .. pane_index)
                    vim.fn.system(string.format("tmux send-keys C-z '%s' Enter", M.cmd[ft].interactive.repl))
                else
                    pane_index = tonumber(vim.fn.system("tmux display-message -p '#{pane_index}'")) + 1
                    vim.fn.system(M.cmd.split .. " " .. M.cmd[ft].interactive.repl)
                end
            else
                pane_index = tonumber(vim.fn.system("tmux display-message -p '#{pane_index}'")) + 1
                vim.fn.system(M.cmd.split .. " " .. M.cmd[ft].interactive.repl)
            end
        end

        vim.fn.system(string.format("tmux send-keys '%s' Enter", parse_wildcards(M.cmd[ft].interactive.cmd) .. args))

        if M.cmd.focus_repl == false then
            vim.fn.system("tmux select-pane -t" .. tonumber(pane_index) - 1)
    	end
    end
end

M.compile_smart = function(args)
    if os.getenv("TMUX") then
        if M.cmd[vim.bo.filetype].interactive.repl then
            M.compile_interactive(args)
        else
            M.compile_normal(args)
        end
    else
        M.compile_vim(args)
    end
end

M.cmd = commands

M.setup = function(opts)
    if opts then M.cmd = vim.tbl_deep_extend("force", commands, opts) end

    local function concat_args(argv)
        local res = " "
        for i=2,#argv do
            res = res .. argv[i] .. " "
        end
        return res
    end

    vim.api.nvim_create_user_command("VimCompiler", function(opts)
        M["compile_" .. opts.fargs[1]](concat_args(opts.fargs))
    end,
        {nargs = "*",
        complete = function()
      -- return completion candidates as a list-like table
      return { "smart", "interactive", "vim", "normal" }
    end,
    })

    return M
end

return M
