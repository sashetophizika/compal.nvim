# compal.nvim
Set a keybinding to compile and run code in any language inside the neovim terminal or a seperate tmux pane.

## Installation
Using [Lazy](https://github.com/folke/lazy.nvim)
```lua
{ 'sasheto-phizika/compal.nvim' }
```
Using [packer](https://github.com/wbthomason/packer.nvim)
```lua
use 'sasheto-phizika/compal.nvim'

```
Using [Plug](https://github.com/junegunn/vim-plug)
```lua
Plug('sasheto-phizika/compal.nvim')
```

## Basic Usage
The plugin provides 3 functions that execute commands based on the filetype defined by `vim.bo.filetype`. Modifications to filetype detection can be made with [`vim.filetype.add`](https://neovim.io/doc/user/lua.html#lua-filetype).

`run_shell`: Runs the command in the first shell pane in the window or if there are none, spawns a shell pane and runs there. 
`run_interactive`: For languages that provide a repl, works like `run_shell` but it uses the corresponding repl instead of the shell. Also overrides existing shell panes by default.
`run_smart`: Defaults to `run_interactive`, with `run_shell` if filetype doesn't have a repl and the builtin terminal if neovim isn't running inside tmux.

Set keybindings inside `init.lua`

```lua
local compal = require("compal").setup()
vim.keymap.set("n", "<leader>ee", compal.run_smart)
vim.keymap.set("n", "<leader>er", compal.run_interactive)
vim.keymap.set("n", "<leader>ew", compal.run_shell)
```
For programs that take arguments, there is the `Compal [smart | interactive | shell | set | get] *args` command. For convenience, you can create a keybinding that enters command mode and autofills part of the command.

```lua
vim.keymap.set("n", "<leader>ed", ":Compal smart ")
```

The `set` and `get` options let you check and change the configuration for the current session. For example, `:Compal set shell cmd cmake .` or `:Compal set shell cd` to remove the default cd command, where the filetype is inferred from `vim.bo.filetype`, but can also be given as the first argument.


## Configuration
### Language Configuration
The configuration for each language is a table of the form

```lua
filetype = { 
        shell = {
            cd = optional_cd_before_cmd,
            cmd = command_for_shell,
        },
        interactive = {
            repl = command_to_launch_repl,
            cmd = command_to_load_file,
            title = tmux_pane_current_command,
        },
}

```

The `cmd` and `cd` options allow the use of some wildcards. When using `cd` make sure to end the command with `;` or `&&` or it would not work. The `interactive.title` field is there because of certain repls have a title different from the command like `ghci` where the title is `ghc` and `ipython` where the title is `python`.

| Wildcard | Description
|----------|------------|
| `%f` | filename with full path
| `%s` | filename with full path and truncated extension
| `%h` | full path to parent directory of current buffer
| `%g` | full path to git root directory if it exists

### Global Options
| Option | Default | Description
|--------|---------|------------|
| `tmux_split`           | `"tmux split -v"` | Command for creating the new tmux pane
| `builtin_split`        | `"split"`         | Command for creating the new nevim split window
| `save`                 | `true`            | Whether to write changes to the file before execution
| `focus_shell`          | `true`            | Whether to focus the shell after execution of `run_shell`  
| `focus_repl`           | `true`            | Whether to focus the shell after execution of `run_interactive`  
| `override_shell`       | `true`            | Whether to execute repl command in an available shell pane for `run_interactive`
| `window`               | `false`           | Whether to use tmux windows and neovim tabs instead of panes
| `prefer_tmux`          | `true`            | Whether to use the neovim terminal even inside tmux
| `telescope`            | `false`           | Enables telescope integration

### Example configuration
```lua
local compal = require("compal").setup({
    rust = {
        shell = {
            cd = "cd %g;",
            cmd = "cargo run --release",
        },
    },
    python = {
        interactive = {
            repl = "ipython",
            title = "python",
            cmd = "%run %f",
        },
    },
    split = "tmux split -v -p 40 -c #{pane_current_path}",
    focus_shell = false,
})
```

## Telescope Integration
If you have [telescope](https://github.com/nvim-telescope/telescope.nvim) installed and set `telescope = { enabled = true }` in your setup, you can add an `extra` argument to the `shell` and `interactive` tables of a language and use the `picker_shell` and `picker_interactive` to spawn a menu with extra commands and and execute them instead of the normal one. For example:

```lua
local compal = require("compal").setup({
    rust = {
        shell = {
            extra = {"cargo run --release", "cargo build --release", "rustc %f;%s"},
        },
    },
    python = {
        interactive = {
            extra = {"%run %f 42", "%run %f 3.14", "%run %f 01011001"},
        },
    },
    telescope = { 
        enabled = true,
        auto_append = true,
    }
})

vim.keymap.set('n', '<leader>fe', compal.picker_shell)
vim.keymap.set('n', '<leader>fr', compal.picker_interactive)

```

You can also `CompalPicker add [shell|interactive] cmd` to add a new command to the list for the current session (e.g.`CompalPicker add shell cargo run --release`). Using the `Compal` command to add arguments appends the new command to the list, unless `telescope.auto_append = false`. To set the selected command as default for the session, use `<C-Enter>` when selecting.

##  Default Language table
Any missing language can be added when calling `setup()` using the given format. The is also an `interactive.in_shell [bool]` parameter for each language that defines if the repl should be nested inside a shell, by default only `true` for `ocaml` because `utop` doesn't work otherwise. If you are using an alternative repl (eg. `croissant` for `lua`) and the interactive function fails, try setting this option to true.

| Language      | Shell                                                             | Interactive
| ---------     | --------                                                          | -----------
| `bash`        | `cd = ""`         `cmd = "bash %f"`                               | `repl = nil`            `title = ""`           `cmd = ""`               
| `c`           | `cd = "cd %g;"`   `cmd = "make"`                                  | `repl = nil`            `title = ""`           `cmd = ""`               
| `cpp`         | `cd = "cd %g;"`   `cmd = "make"`                                  | `repl = nil`            `title = ""`           `cmd = ""`               
| `cs`          | `cd = "cd %g;"`   `cmd = "dotnet run"`                            | `repl = nil`            `title = ""`           `cmd = ""`               
| `clojure`     | `cd = ""`         `cmd = "clj -M %f"`                             | `repl = "clj"`          `title = "clj"`        `cmd = 'load-file "%f"'` 
| `dart`        | `cd = "cd %g;"`   `cmd = "dart run"`                              | `repl = nil`            `title = ""`           `cmd = ""`               
| `elixir`      | `cd = "cd %g;"`   `cmd = "mix compile"`                           | `repl = "iex -S mix"`   `title = "beam.smp"`   `cmd = "recompile()"`    
| `go`          | `cd = "cd %g;"`   `cmd = "go run ."`                              | `repl = nil`            `title = ""`           `cmd = ""`               
| `haskell`     | `cd = "cd %g;"`   `cmd = "cabal run"`                             | `repl = "ghci"`         `title = "ghc"`        `cmd = ":l %f"`          
| `java`        | `cd = ""`         `cmd = "javac %f"`                              | `repl = nil`            `title = ""`           `cmd = ""`               
| `javascript`  | `cd = ""`         `cmd = "node %f"`                               | `repl = nil`            `title = ""`           `cmd = ""`               
| `julia`       | `cd = ""`         `cmd = "julia %f"`                              | `repl = "julia"`        `title = "julia"`      `cmd = 'include("%f")'`  
| `kotlin`      | `cd = ""`         `cmd = "kotlinc %f"`                            | `repl = nil`            `title = ""`           `cmd = ""`               
| `lua`         | `cd = ""`         `cmd = "lua %f"`                                | `repl = "lua"`          `title = "lua"`        `cmd = 'dofile("%f")'`   
| `ocaml`       | `cd = "cd %g;"`   `cmd = "dune build; dune exec $(basename %g)"`  | `repl = "dune utop"`    `title = "utop"`       `cmd = ""`               
| `php`         | `cd = ""`         `cmd = "php %f"`                                | `repl = nil`            `title = ""`           `cmd = ""`               
| `python`      | `cd = ""`         `cmd = "python %f"`                             | `repl = "ipython"`      `title = "python"`     `cmd = "%run %f"`        
| `ruby`        | `cd = ""`         `cmd = "ruby %f"`                               | `repl = "irb"`          `title = "irb"`        `cmd = 'require "%f"'`   
| `rust`        | `cd = "cd %g;"`   `cmd = "cargo run"`                             | `repl = nil`            `title = ""`           `cmd = ""`               
| `tex`         | `cd = ""`         `cmd = "pdflatex %f"`                           | `repl = nil`            `title = ""`           `cmd = ""`               
| `typescript`  | `cd = ""`         `cmd = "npx tsc %f"`                            | `repl = nil`            `title = ""`           `cmd = ""`               
| `zig`         | `cd = "cd %g;"`   `cmd = "zig build run"`                         | `repl = nil`            `title = ""`           `cmd = ""`               

