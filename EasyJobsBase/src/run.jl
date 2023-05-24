using Dates: Period, now

using Thinkers: TimeoutException, ErrorInfo, reify!, setargs!, haserred, _kill

export run!, start!, kill!

"""
    run!(job::Job; maxattempts=1, interval=1, waitfor=0)

Run a `Job` with a maximum number of attempts, with each attempt separated by a few seconds.
"""
function run!(job::AbstractJob; kwargs...)
    exec = Executor(job; kwargs...)
    start!(exec)
    return exec
end

function start!(exec::Executor)
    @assert isreadytorun(exec)
    return _run!(exec)
end
function start!(exec::Executor{StronglyDependentJob})
    @assert isreadytorun(exec)
    parents = exec.job.parents
    # Use previous results as arguments
    args = if length(parents) == 1
        something(getresult(first(parents)))
    else  # > 1
        Set(something(getresult(parent)) for parent in parents)
    end
    setargs!(exec.job.core, args)
    return _run!(exec)
end

function _run!(exec::Executor)  # Do not export!
    sleep(exec.waitfor)
    for _ in exec.maxattempts
        __run!(exec)
        if issucceeded(exec.job)
            return exec  # Stop immediately
        else
            sleep(exec.interval)
        end
    end
end

function __run!(exec::Executor)  # Do not export!
    if ispending(exec.job)
        schedule(exec.task)
    else
        exec.job.status = PENDING
        return __run!(exec)
    end
end

function ___run!(job::AbstractJob)  # Do not export!
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

isreadytorun(::Executor) = true
isreadytorun(exec::Executor{<:DependentJob}) =
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
