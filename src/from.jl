using Configurations: Maybe, OptionField, @option
using .Thunks: Thunk

import Configurations: from_dict

export Command, Code, Step, Steps, evaluate

@option "cmd" struct Command
    exec::Vector{String} = []
    env::Dict{String,String} = Dict()
    dir::String = pwd()
end

@option "code" struct Code
    expr::Expr
end

@option struct Step
    name::String = ""
    cmd::Maybe{Command} = nothing
    code::Maybe{Code} = nothing
    needs::Vector{String} = []
    function Step(name, cmd, code, needs)
        @assert cmd isa Command && isnothing(code) || isnothing(cmd) && code isa Code
        return new(name, cmd, code, needs)
    end
end

@option struct Steps
    jobs::Vector{Step} = []
    args::Dict = Dict()
end

function from_dict(
    ::Type{Command}, ::OptionField{:exec}, ::Type{Vector{String}}, str::AbstractString
)
    return split(str; keepempty=false)
end
function from_dict(::Type{Code}, ::OptionField{:expr}, ::Type{Expr}, str::AbstractString)
    return Meta.parse(str)
end

function evaluate(command::Command)
    return setenv(Cmd(command.exec), command.env; dir=abspath(expanduser(command.dir)))
end
evaluate(code::Code) = () -> @eval code.expr
function evaluate(step::Step)
    thunk = if isnothing(step.code)
        cmd = evaluate(step.cmd)
        Thunk(run, cmd)
    else
        code = evaluate(step.code)
        Thunk(code, ())
    end
    return SimpleJob(thunk; name=step.name)
end
function evaluate(steps::Steps)
    jobs = map(evaluate, steps.jobs)
    for (job, nextjob) in zip(jobs, jobs[2:end])
        chain(job, nextjob)
    end
    return jobs
end
