using Dates: Period, now

using Thinkers: TimeoutException, ErrorInfo, reify!, haserred, _kill

export run!, interrupt!

"""
    run!(job::Job; maxattempts=1, separation=1, skip=0)

Run a `Job` with a maximum number of attempts, with each attempt separated by a few seconds.
"""
run!(job::AbstractJob; kwargs...) = start!(Executor(job; kwargs...))

function start!(exe::Executor)
    dynamic_check(exe)
    return _run!(exe)
end
function start!(exe::Executor{DependentJob})
    dynamic_check(exe)
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
    _sleep(exe.waitfor)
    for _ in exe.maxattempts
        __run!(exe)
        if issucceeded(exe.job)
            return exe  # Stop immediately
        else
            if !iszero(exe.interval)
                sleep(exe.interval)  # `if-else` is faster than `sleep(0)`
            end
        end
    end
end
function __run!(exe::Executor)  # Do not export!
    if ispending(exe.job)
        if !isexecuted(exe.job)
            push!(JOB_REGISTRY, exe => nothing)
        end
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
        ex = something(getresult(job.def)).thrown
        ex isa Union{InterruptException,TimeoutException} ? INTERRUPTED : FAILED
    else
        SUCCEEDED
    end
    job.count += 1
    return job
end

dynamic_check(::Executor) = nothing
function dynamic_check(runner::Executor{DependentJob})
    if runner.job.strict
        @assert all(issucceeded(parent) for parent in runner.job.parents)
    else
        @assert all(isexited(parent) for parent in runner.job.parents)
    end
    return nothing
end

function _sleep(t)
    if t > zero(t)
        sleep(t)
    end
    return nothing
end

"""
    interrupt!(runner::JobRunner)

Manually interrupt a `Job`, works only if it is running.
"""
function interrupt!(runner::Runner)
    if isexited(runner.job)
        @info "the job $(runner.job.id) has already exited!"
    elseif ispending(runner.job)
        @info "the job $(runner.job.id) has not started!"
    else
        _kill(runner.task)
    end
    return runner
end

Base.wait(runner::Executor) = wait(runner.task)
