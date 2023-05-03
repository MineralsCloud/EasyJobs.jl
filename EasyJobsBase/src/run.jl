using Dates: Period, now

using Thinkers: TimeoutException, ErrorInfo, reify!, haserred, _kill

export run!, start!, kill!

"""
    run!(job::Job; maxattempts=1, interval=1, waitfor=0)

Run a `Job` with a maximum number of attempts, with each attempt separated by a few seconds.
"""
function run!(job::AbstractJob; kwargs...)
    exe = Executor(job; kwargs...)
    start!(exe)
    return exe
end

function start!(exe::Executor)
    @assert isready(exe)
    return _run!(exe)
end
function start!(exe::Executor{DependentJob})
    @assert isready(exe)
    job = exe.job
    if !isempty(job.args_from)
        # Use previous results as arguments
        source = job.args_from
        args = if length(source) == 0
            ()
        elseif length(source) == 1
            (something(getresult(first(source))),)
        else  # > 1
            (collect(something(getresult(job)) for job in source),)
        end
        job.def = typeof(job.def)(job.def.callable, args, job.def.kwargs)  # Create a new `Think` instance
    end
    return _run!(exe)
end
function _run!(exe::Executor)  # Do not export!
    sleep(exe.waitfor)
    for _ in exe.maxattempts
        __run!(exe)
        if issucceeded(exe.job)
            return exe  # Stop immediately
        else
            sleep(exe.interval)
        end
    end
end
function __run!(exe::Executor)  # Do not export!
    if ispending(exe.job)
        schedule(exe.task)
    else
        exe.job.status = PENDING
        return __run!(exe)
    end
end
function ___run!(job::AbstractJob)  # Do not export!
    job.status = RUNNING
    job.start_time = now()
    reify!(job.def)
    job.end_time = now()
    job.status = if haserred(job.def)
        e = something(getresult(job.def)).thrown
        e isa Union{InterruptException,TimeoutException} ? INTERRUPTED : FAILED
    else
        SUCCEEDED
    end
    job.count += 1
    return job
end

Base.isready(::Executor) = true
Base.isready(exe::Executor{DependentJob}) =
    all(issucceeded(parent) for parent in exe.job.parents)

"""
    kill!(exe::Executor)

Manually kill a `Job`, works only if it is running.
"""
function kill!(exe::Executor)
    if isexited(exe.job)
        @info "the job $(exe.job.id) has already exited!"
    elseif ispending(exe.job)
        @info "the job $(exe.job.id) has not started!"
    else
        _kill(exe.task)
    end
    return exe
end

Base.wait(exe::Executor) = wait(exe.task)
