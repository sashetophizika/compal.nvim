local M = {}
local conf = require("compal.config")

M.concat_args = function(argv, first, last)
    local res = ""
    for i = first or 1, last or #argv do
        res = res .. " " .. argv[i]
    end
    return res
end

M.get_cmd = function(args)
    local ft = vim.bo.filetype
    if args[2] == nil then
        print(vim.inspect(conf[ft]))
    elseif args[3] == nil then
        print(vim.inspect(conf[ft][args[2]]))
    else
        print(conf[ft][args[2]][args[3]])
    end
end

M.set_cmd = function(args)
    local ft = vim.bo.filetype
    local new_cmd
    if ft ~= "" and ft ~= args[2] then
        new_cmd = M.concat_args(args, 4):sub(2)
        conf[ft][args[2]][args[3]] = new_cmd
    else
        new_cmd = M.concat_args(args, 5):sub(2)
        conf[args[2]][args[3]][args[4]] = new_cmd
    end
    print(new_cmd)
end

M.add_to_pickers = function(args)
    local new_cmd = M.concat_args(args, 3):sub(2)
    table.insert(conf[vim.bo.filetype][args[2]].extra, new_cmd)
    print(new_cmd)
end

M.extend_conf = function (t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" then
            if type(t1[k]) == "table" then
                M.extend_conf(t1[k], v)
            else
                t1[k] = v
            end
        else
            t1[k] = v
        end
    end
end

return M
