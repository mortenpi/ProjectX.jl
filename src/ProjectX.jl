module ProjectX
using Pkg: TOML

function __init__()
    project = Base.active_project()
    if !isfile(project)
        @warn "$(project) not a file"
        return
    end
    toml = TOML.parsefile(project)
    haskey(toml, "environment") || return
    update_environment!(dirname(project), toml["environment"])
    return
end

function update_environment!(root, d)
    if haskey(d, "load_path")
        loadpath = map(Base.parse_load_path(d["load_path"])) do path
            startswith(path, "@") && return path
            joinpath(root, path)
        end
        empty!(LOAD_PATH)
        append!(LOAD_PATH, loadpath)
        @debug "LOAD_PATH updated based in Project.toml" LOAD_PATH
    end
end

end
