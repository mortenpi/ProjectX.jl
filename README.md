# ProjectX

_Project environment extensions for the Julia language._

ProjectX allows you store various additional settings in your project's `Project.toml` file. If you have `using ProjectX` in your global `startup.jl` file, it will look at the `Project.toml` of your active project and applies them during the Julia startup phase.

## Installation & usage

The package is currently unregistered. To install, you need to add it via the URL in the Pkg REPL mode:

```
pkg> add https://github.com/mortenpi/ProjectX.jl.git
```

To use the package, put `using ProjectX` in your startup file (e.g. in `~/.julia/config/startup.jl`). The settings from the project environment get applied during the `using` call, so you most likely want it to be the last item in your startup file — this way project-specific settings get applied after your global settings.

Under the hood, ProjectX looks for the active project, reads the `Project.toml` file and applies any known settings it finds. All this happens in ProjectX's `__init__` call, so the first time the package is loaded.

## Supported settings

### Environment variables

Using the `environment` table you can set environment variables in `ENV`. I.e. if you have the following in the `Project.toml`

```
[environment]
FOO="bar"
```

It will set the corresponding environment variable

```julia-repl
julia> ENV["FOO"]
"bar"
```

#### Dynamic environment variables

When setting a variable to just a string, ProjectX set the corresponding environment variables literally to that string. However, sometimes it may be necessary to generate the environment variables more dynamically.

ProjectX allows methods to be applied to environment variables. For that, instead of specifying it as a string, it should be declared as a [TOML table](https://github.com/toml-lang/toml#table) or [inline table](https://github.com/toml-lang/toml#inline-table). The `method` key in that table, which should be a simple string, defined which type of transformation gets applied. Specific methods may require additional key-value pairs to be defined in the table.

The currently supported methods are:

* **`abspath`**: takes the `path` value as a relative path relative to the directory containing the `Project.toml` file and sets the environment variable to the corresponding _absolute_ path. For example: 

  ```toml
  [environment]
  MY_ABSOLUTE_PATH = { method="abspath", path="relative/path/" }
  ```

### `LOAD_PATH`

Can be set by specifying `juliaenv.load_path` in the `Project.toml`. It is interpreted as if it was passed via the `JULIA_LOAD_PATH` environment variable.

For example, to add the `lib/` subdirectory to the `LOAD_PATH`, you can set the `Project.toml` up as follows:

```toml
[juliaenv]
load_path = "lib/:@:@v#.#:@stdlib"
```

ProjectX will then set the `LOAD_PATH` variable to

```julia-repl
julia> LOAD_PATH
4-element Array{String,1}:
 "/path/to/project/lib/"
 "@"
 "@v#.#"
 "@stdlib"
```

### Startup script

A `juliaenv.startup` string will be interpreted as a startup script, similar to a `startup.jl` file, e.g.:

```toml
[juliaenv]
startup = """
using Revise
my_convenience_function(x) = x + 1
"""
```

ProjectX evaluates the startup script in the `Main` module.

## Known limitations

* When changing active environments with `pkg> activate` or `Pkg.activate()`, the environment is not reloaded from the new project environment.
