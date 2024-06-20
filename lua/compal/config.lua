return {
    c = {
        shell = {
            cd = "cd %g",
            cmd = "make",
        },
        interactive = {
            repl = nil,
            title = "",
            cmd = "",
            in_shell = false
        }
    },
    rust = {
        shell = {
            cd = "cd %g",
            cmd = "cargo run",
            extra = { "cargo build --release", "cargo build", "rustc %f" }
        },
        interactive = {
            repl = nil,
            title = "",
            cmd = "",
            in_shell = false
        }
    },
    cpp = {
        shell = {
            cd = "cd %g",
            cmd = "make"
        },
        interactive = {
            repl = nil,
            title = "",
            cmd = "",
            in_shell = false
        }
    },
    julia = {
        shell = {
            cd = "",
            cmd = "julia %f"
        },
        interactive = {
            repl = "julia",
            title = "julia",
            cmd = 'include("%f")',
            in_shell = false
        }
    },
    python = {
        shell = {
            cd = "",
            cmd = "python %f"
        },
        interactive = {
            repl = "ipython",
            title = "python",
            cmd = "%run %f",
            in_shell = nil
        }
    },
    sh = {
        shell = {
            cd = "",
            cmd = "bash %f"
        },
        interactive = {
            repl = nil,
            title = "",
            cmd = "",
            in_shell = false
        }
    },
    cs = {
        shell = {
            cd = "cd %g",
            cmd = "dotnet run"
        },
        interactive = {
            repl = nil,
            title = "",
            cmd = "",
            in_shell = false
        }
    },
    php = {
        shell = {
            cd = "",
            cmd = "php %f"
        },
        interactive = {
            repl = nil,
            title = "",
            cmd = "",
            in_shell = false
        }
    },
    haskell = {
        shell = {
            cd = "cd %g",
            cmd = "cabal run"
        },
        interactive = {
            repl = "ghci",
            title = "ghc",
            cmd = ":l %f",
            in_shell = false
        }
    },
    lua = {
        shell = {
            cd = "",
            cmd = "lua %f"
        },
        interactive = {
            repl = "lua",
            title = "lua",
            cmd = "dofile(\"%f\")",
            in_shell = false
        }
    },
    java = {
        shell = {
            cd = "",
            cmd = "javac %f"
        },
        interactive = {
            repl = nil,
            title = "",
            cmd = "",
            in_shell = false
        }
    },
    javascript = {
        shell = {
            cd = "",
            cmd = "node %f"
        },
        interactive = {
            repl = nil,
            title = "",
            cmd = "",
            in_shell = false
        }
    },
    ruby = {
        shell = {
            cd = "",
            cmd = "ruby %f"
        },
        interactive = {
            repl = "irb",
            title = "irb",
            cmd = 'require "%f"',
            in_shell = false
        }
    },
    tex = {
        shell = {
            cd = "",
            cmd = "pdflatex %f"
        },
        interactive = {
            repl = nil,
            title = "",
            cmd = "",
            in_shell = false
        }
    },
    kotlin = {
        shell = {
            cd = "",
            cmd = "kotlinc %f"
        },
        interactive = {
            repl = nil,
            title = "",
            cmd = "",
            in_shell = false
        }
    },
    zig = {
        shell = {
            cd = "cd %g",
            cmd = "zig build run"
        },
        interactive = {
            repl = nil,
            title = "",
            cmd = "",
            in_shell = false
        }
    },
    typescript = {
        shell = {
            cd = "",
            cmd = "npx tsc %f"
        },
        interactive = {
            repl = nil,
            title = "",
            cmd = "",
            in_shell = false
        }
    },
    elixir = {
        shell = {
            cd = "cd %g",
            cmd = "mix compile"
        },
        interactive = {
            repl = "iex -S mix",
            title = "beam.smp",
            cmd = "recompile()",
            in_shell = false
        }
    },
    ocaml = {
        shell = {
            cd = "cd %g",
            cmd = "dune build;dune exec $(basename %g)"
        },
        interactive = {
            repl = "dune utop",
            title = "utop",
            cmd = "",
            in_shell = true
        }
    },
    clojure = {
        shell = {
            cd = "",
            cmd = "clj -M %f"
        },
        interactive = {
            repl = "clj",
            title = "rlwrap",
            cmd = '(load-file "%f")',
            in_shell = false
        }
    },
    go = {
        shell = {
            cd = "cd %g",
            cmd = "go run ."
        },
        interactive = {
            repl = nil,
            title = "",
            cmd = "",
            in_shell = false
        }
    },
    dart = {
        shell = {
            cd = "cd %g",
            cmd = "dart run"
        },
        interactive = {
            repl = nil,
            title = "",
            cmd = "",
            in_shell = false
        }
    },

    split = nil,
    tmux_split = "tmux split -v",
    builtin_split = "split",
    prefer_tmux = true,
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
