local M = {}

local commands = {
    normal = {
        c = "",
        rust = "",
        cpp = "",
        julia = "",
        python = "python %f",
        bash = "",
        cs = "",
        php = "",
        haskell = "",
        lua = "",
        java = "",
        javascript = "",
        ruby = "",
        tex = "",
        markdown = "",
        kotlin = "",
        zig = "",
        typescript = "",
        elixir = "",
        clojure = "",
        go = "",
        dart = "",
        swift = ""
    },
    interactive = {
        julia = "",
        elixir = "",
        python = "python %f",
        haskell = "",
        lua = "",
        ruby = ""
    }
}

M.vim_normal = function()
    vim.fn.system(commands.normal[vim.bo.filetype]:gsub("%%f", vim.fn.expand("%:p"))) 
end

M.vim_interactive = function()
    vim.fn.system(commands.normal[vim.bo.filetype]:gsub("%%f", vim.fn.expand("%:p"))) 
end

M.vim_smart = function()
    if commands.interactive[vim.bo.filetype] then
        vim.fn.system(commands.interactive[vim.bo.filetype]:gsub("%%f", vim.fn.expand("%:p")))
    else
        vim.fn.system(commands.normal[vim.bo.filetype]:gsub("%%f", vim.fn.expand("%:p"))) 
    end
end

M.setup = function(opts)
    if opts then 
        vim.tbl_deep_extend("force", commands , opts)
    end
end

M.cmd = commands

print(vim.inspect(commands))
--return M
return 4
