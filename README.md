# vim-compiler.nvim
Set a keybinding to compile and run code in any language inside nvim or a seperate tmux pane.

## Installation
Using [Plug](https://github.com/junegunn/vim-plug)
```lua
Plug('sasheto-phizika/vim-compiler.nvim')
```
Using [packer](https://github.com/wbthomason/packer.nvim)
```lua
use 'sasheto-phizika/vim-compiler.nvim'
```

## Basic Usage
The plugin provides 4 functions that execute commands based on the filetype defined by `vim.bo.filetype`. Modifications to filetype detection can be made with [`vim.filetype.add`](https://neovim.io/doc/user/lua.html#lua-filetype).

`compile_vim`: Runs the corresponding command inside the vim window.

`compile_normal`: Runs the command in the first shell pane in the window or if there are none, spawns a shell pane and runs there. Requires an attached tmux session.

`compile_interactive`: For languages that provide a repl, works like `compile_normal` but it uses the corresponding repl instead of the shell. Also overrides existing shell panes by default.

`compile_smart`: Defaults to `compile_interactive`, with `compile_normal` as fallback if filetype doesn't have a repl and `compile_vim` as fallback if neovim isn't running inside tmux.

Set keybindings inside `init.lua`

```lua
local vim_compiler = require("vim-compiler").setup()
vim.keymap.set("n", "<leader>ee", vim_compiler.compile_smart)
vim.keymap.set("n", "<leader>er", vim_compiler.compile_interactive)
vim.keymap.set("n", "<leader>ew", vim_compiler.compile_normal)
vim.keymap.set("n", "<leader>ef", ":VimCompiler vim<cr>")
```
For programs that take arguments, there is the `VimCompiler [smart | interactive | normal | vim] *args` command. For convenience, you can create a keybinding that enters command mode and autofills part of the command.

```lua
vim.keymap.set("n", "<leader>ed", ":VimCompiler smart")
```

## Configuration
### Language Configuration
The configuration for each language is a table of the form

```lua
filetype = { 
        normal = {
            cmd = command_for_shell,
            cd = optional_cd_before_cmd,
        },
        interactive = {
            repl = command_to_launch_repl,
            cmd = command_to_load_file,
            title = tmux_pane_current_command,
        },
}

```

The `cmd` and `cd` options allow the use of some wildcards. The `interactive.title` field is there because of certain repls with a title different from the command like `ghci` where title is `ghc` and `ipython` where title is `python`.

| Wildcard | Description
|----------|------------|
| `%f` | filename with full path
| `%s` | filename with full path and truncated extension
| `%h` | full path to parent directory of current buffer
| `%g` | full path to git root directory if it exists

### Global Commands
| Option | Default | Description
|--------|---------|------------|
| `split`                | `"tmux split -v"` | Command for creating the new pane
| `save`                 |  `true`   | Whether to save before execution
| `focus_shell`          |   `true`  | Whether to focus the shell after execution of `compile_normal`  
| `focus_repl`           |   `true`  | Whether to focus the shell after execution of `compile_interactive`  
| `override_shell`       |   `true`  | Whether to execute repl command in an available shell pane for `compile_interactive`


### Example configuration
```lua
local vim_compiler = require("vim-compiler").setup({
    python = {
        interactive = {
            repl = "ipython",
            title = "python",
            cmd = "%run %f",
        }
    },
    rust = {
        normal = {
            cd = "cd %g;",
            cmd = "cargo run --release"
        },
    },
    split = "tmux split -v -p 40 -c #{pane_current_path}",
    focus_shell = false,
})
```
##  Default Language table
Any missing language can be added when calling `setup()` using the given format.

|Language | Normal | Interactive
|---------|--------|-----------
|`bash`|`cd = "", cmd = "bash %f"`|`repl = nil, title = "", cmd = ""`
|`c`|`cd = "cd %g;", cmd = "make"`|`repl = nil, title = "", cmd = ""`
|`cpp`|`cd = "cd %g;", cmd = "make"`|`repl = nil, title = "", cmd = ""`
|`cs`|`cd = "cd %g;", cmd = "dotnet run"`|`repl = nil, title = "", cmd = ""`
|`clojure`|`cd = "", cmd = "clj -M %f"`|`repl = "clj", title = "clj", cmd = 'load-file "%f"'`
|`dart`|`cd = "cd %g;", cmd = "dart run"`|`repl = nil, title = "", cmd = ""`
|`elixir`|`cd = "cd %g", cmd = "mix compile"`|`repl = "iex -S mix", title = "beam.smp", cmd = "recompile()"`
|`go`|`cd = "cd %g;", cmd = "go run ."`|`repl = nil, title = "", cmd = ""`
|`haskell`|`cd = "cd %g;", cmd = "cabal run"`|`repl = "ghci", title = "ghc", cmd = ":l %f"`
|`java`|`cd = "", cmd = "javac %f"`|`repl = nil, title = "", cmd = ""`
|`javascript`|`cd = "", cmd = "node %f"`|`repl = nil, title = "", cmd = ""`
|`julia`|`cd = "", cmd = "julia %f"`|`repl = "julia", title = "julia", cmd = 'include("%f")'`
|`kotlin`|`cd = "", cmd = "kotlinc %f"`|`repl = nil, title = "", cmd = ""`
|`lua`|`cd = "", cmd = "lua %f"`|`repl = "lua", title = "lua", cmd = 'require("%f")'`
|`php`|`cd = "", cmd = "php %f"`|`repl = nil, title = "", cmd = ""`
|`python`|`cd = "", cmd = "python %f"`|`repl = "ipython", title = "python", cmd = "%run %f"`
|`ruby`|`cd = "", cmd = "ruby %f"`|`repl = "irb", title = "irb", cmd = 'require "%f"'`
|`rust`|`cd = "cd %g;", cmd = "cargo run"`|`repl = nil, title = "", cmd = ""`
|`tex`|`cd = "", cmd = "pdflatex %f"`|`repl = nil, title = "", cmd = ""`
|`typescript`|`cd = "", cmd = "npx tsc %f"`|`repl = nil, title = "", cmd = ""`
|`zig`|`cd = "cd %g;", cmd = "zig build run"`|`repl = nil, title = "", cmd = ""`

