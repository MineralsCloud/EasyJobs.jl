using Thinkers: TimeoutException, ErrorInfo, reify!, setargs!, haserred, _kill

export run!, execute!, kill!

# See https://github.com/MineralsCloud/SimpleWorkflows.jl/issues/137
mutable struct Executor{T<:AbstractJob}
    job::T
    wait::Bool
    maxattempts::UInt64
    interval::Real
    delay::Real
    task::Task
    function Executor(job::T; wait=false, maxattempts=1, interval=1, delay=0) where {T}
        @assert maxattempts >= 1
        @assert interval >= zero(interval)
        @assert delay >= zero(delay)
        return new{T}(job, wait, maxattempts, interval, delay, @task _run!(job))
    end
end

function newtask!(exec::Executor)
    exec.task = @task _run!(exec.job)  # Start a new task. This is necessary for rerunning!
    return exec
end

"""
    run!(job::Job; maxattempts=1, interval=1, waitfor=0)

Run a `Job` with a maximum number of attempts, with each attempt separated by a few seconds.
"""
function run!(job::AbstractJob; kwargs...)
    exec = Executor(job; kwargs...)
    execute!(exec)
    return exec
end

function execute!(exec::Executor)
    @assert shouldrun(exec)
    prepare!(exec)
    return launch!(exec)
end

function launch!(exec::Executor)  # Do not export!
    sleep(exec.delay)
    singlerun!(exec)
    if exec.maxattempts > 1
        wait(exec)
        for _ in Base.OneTo(exec.maxattempts - 1)
            sleep(exec.interval)
            singlerun!(exec)
            wait(exec)  # Wait no matter whether `exec.wait` is `true` or `false`
        end
    end
    return exec
end

function singlerun!(exec::Executor)
    if ispending(exec.job)
        schedule(exec.task)
        if exec.wait
            wait(exec)
        end
    end
    if isfailed(exec.job) || isinterrupted(exec.job)
        newtask!(exec)
        exec.job.status = PENDING
        return singlerun!(exec)  # Wait or not depends on `exec.wait`
    end
    return exec  # Do nothing for running and succeeded jobs
end

function _run!(job::AbstractJob)  # Do not export!
    job.status = RUNNING
    job.start_time = now()
    reify!(job.core)
    job.end_time = now()
    job.status = if haserred(job.core)
        e = something(getresult(job.core)).thrown
        e isa Union{InterruptException,TimeoutException} ? INTERRUPTED : FAILED
    else
        SUCCEEDED
    end
    job.count += 1
    return job
end

prepare!(::Executor) = nothing  # No op
function prepare!(exec::Executor{StronglyDependentJob})
    parents = exec.job.parents
    # Use previous results as arguments
    args = if length(parents) == 1
        something(getresult(first(parents)))
    else  # > 1
        Set(something(getresult(parent)) for parent in parents)
    end
    setargs!(exec.job.core, args)
    return nothing
end

shouldrun(::Executor) = true
shouldrun(exec::Executor{<:DependentJob}) =
    length(exec.job.parents) >= 1 && all(issucceeded(parent) for parent in exec.job.parents)

"""
    kill!(exec::Executor)

Manually kill a `Job`, works only if it is running.
"""
function kill!(exec::Executor)
    if isexited(exec.job)
        @info "the job $(exec.job.id) has already exited!"
    elseif ispending(exec.job)
        @info "the job $(exec.job.id) has not started!"
    else
        _kill(exec.task)
    end
    return exec
end

Base.wait(exec::Executor) = wait(exec.task)
