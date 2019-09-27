# ProjectX

The package is currently unregistered. To install, you need to add it via the URL in the Pkg REPL mode:

```
pkg> add https://github.com/mortenpi/ProjectX.jl.git
```

To use the package, put `using ProjectX` in your startup file (e.g. in `~/.julia/config/startup.jl`). Then every time you start a new Julia session, ProjectX read the `Project.toml` file of the active project environment and apply any


## Environment variables

Using the `environment` table you can set environment variables in `ENV`. I.e. if you have the following in the `Project.toml`

```
[environment]
FOO="bar"
```

It will set the corresponding environment variables

```julia-repl
julia> ENV["FOO"]
"bar"
```

## Julia settings

Currently only setting the `LOAD_PATH` is supported.

**`LOAD_PATH`**: Can be set by specifying `juliaenv.load_path` in the `Project.toml`. It is interpreted as if it was passed via the `JULIA_LOAD_PATH` environment variable.

For exmaple, to add the `lib/` subdirectory to the `LOAD_PATH`, you can set the `Project.toml` up as follows:

```toml
[juliaenv]
load_path = "lib/:@:@v#.#:@stdlib"
```

The `LOAD_PATH` variable will then become

```julia-repl
julia> LOAD_PATH
4-element Array{String,1}:
 "/path/to/project/lib/"
 "@"
 "@v#.#"
 "@stdlib"
```

## Known limitations

* When changing active environments with `pkg> activate` or `Pkg.activate()`, the environment is not reloaded from the new project environment.
