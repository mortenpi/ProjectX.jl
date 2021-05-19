module ProjectX
using Pkg: TOML

function generate_docstring_path(mod)
    """
        $(mod).path(args...)

    Returns an absolute path that is relative to the project root directory.
    """
end

function generate_docstring_dir(mod)
    """
        $(mod).dir(args...; create=false)

    Returns an absolute path to a directory relative to the project root directory.
    If `create = true`, it will try to create the directory (if it already does not exist). If
    `false` (default), it will throw an error if the directory does not exist.
    """
end

export @projectx

"""
    @projectx

Should be used as follows:

```julia
module MyProjectModule
using ProjectX; @projectx
# other project module code
end
```

It generates two functions into your module: `path` and `dir`.

---
$(generate_docstring_path("MyProjectModule"))
---
$(generate_docstring_dir("MyProjectModule"))
---

It also generates an `__init__` function. To have your own initialization code,
use a `begin ... end` block as an argument to the macro (TODO).
"""
macro projectx(args...)
    project_root = dirname(dirname(string(__source__.file)))
    @debug "Determining project root to be: $(project_root)"

    # TODO: we need some error handling here...
    user_init_body = if isempty(args)
        :()
    else
        args[1]
    end

    quote
        @doc $(generate_docstring_path(__module__))
        $(esc(:path))(args...) = joinpath($(project_root), args...)

        @doc $(generate_docstring_dir(__module__))
        function $(esc(:dir))(args...; create::Bool = false)
            p = $(esc(:path))(args...)
            if create && !isdir(p)
                mkpath(p)
            elseif !create && !isdir(p)
                error("Required project directory missing ($p)")
            end
            return p
        end

        function $(esc(:__init__))()
            init_hook(@__MODULE__)
            $(esc(user_init_body))
        end
    end
end

function init_hook(mod)
    # placeholder for future implementation
    @debug "Calling ProjectX.init_hook for $mod"
    nothing
end

function deprecated__init__()
    project = Base.active_project()
    if !isfile(project)
        @warn "$(project) not a file"
        return
    end
    toml = TOML.parsefile(project)
    haskey(toml, "environment") && update_environment!(dirname(project), toml["environment"])
    haskey(toml, "juliaenv") && update_juliaenv!(dirname(project), toml["juliaenv"])
    return
end

function update_environment!(root, d)
    for (k, v) in d
        if v isa String
            @debug "Setting env. \$$(k)=`$(v)`"
            ENV[k] = v
        elseif v isa Dict{String,T} where T
            if !haskey(v, "method")
                @error "env. \$$k missing `method`. Skipping" v
                continue
            end
            if v["method"] == "abspath"
                if !haskey(v, "path")
                    @error "env. \$$k (method `abspath`) missing `path`. Skipping" v
                    continue
                end
                ENV[k] = normpath(joinpath(root, v["path"]))
                @debug "Setting \$$(k)=`$(ENV[k])`"
            else
                @error "Unrecognized method for env. \$$k: $(v["method"]) Skipping" v
                continue
            end
        else
            @error "Invalid value type for env. \$$k: $(typeof(v)). Skipping." v
            continue
        end
    end
end

function update_juliaenv!(root, d)
    if haskey(d, "load_path")
        loadpath = map(Base.parse_load_path(d["load_path"])) do path
            startswith(path, "@") && return path
            joinpath(root, path)
        end
        empty!(LOAD_PATH)
        append!(LOAD_PATH, loadpath)
        @debug "LOAD_PATH updated based in Project.toml" LOAD_PATH
    end
    if haskey(d, "startup")
        isa(d["startup"], String) || error("juliaenv.startup is not a string")
        @debug "Running a project startup script:\n$(d["startup"])"
        for (ex, str) in parseblock(d["startup"])
            @debug "Evaluating in Main:\n$(str)"
            Main.eval(ex)
        end
    end
end

# Parsing multi-expression code snippets, borrowed with modificatoins from
# Documenter.jl (https://github.com/JuliaDocs/Documenter.jl)
# Copyright (c) 2016: Michael Hatherly
function parseblock(code::AbstractString; skip = 0, keywords = true, raise=true)
    # Drop `skip` leading lines from the code block. Needed for deprecated `{docs}` syntax.
    code = string(code, '\n')
    code = last(split(code, '\n', limit = skip + 1))
    endofstr = lastindex(code)
    results = []
    cursor = 1
    while cursor < endofstr
        # Check for keywords first since they will throw parse errors if we `parse` them.
        line = match(r"^(.*)\r?\n"m, SubString(code, cursor)).match
        keyword = Symbol(strip(line))
        (ex, ncursor) =
            # TODO: On 0.7 Symbol("") is in Docs.keywords, remove that check when dropping 0.6
            if keywords && (haskey(Docs.keywords, keyword) || keyword == Symbol(""))
                (QuoteNode(keyword), cursor + lastindex(line))
            else
                try
                    Meta.parse(code, cursor; raise=raise)
                catch err
                    @warn "ProjectX: failed to parse an expression" exception = err
                    break
                end
            end
        str = SubString(code, cursor, prevind(code, ncursor))
        if !isempty(strip(str))
            push!(results, (ex, str))
        end
        cursor = ncursor
    end
    results
end

end
