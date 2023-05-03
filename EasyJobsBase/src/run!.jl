using Dates: Period, now

using Thinkers: TimeoutException, ErrorInfo, reify!, haserred, _kill

export run!, interrupt!

"""
    run!(job::Job; n=1, δt=1, t=0)

Run a `Job` with maximum `n` attempts, with each attempt separated by `δt` seconds.
"""
function run!(job::AbstractJob; n=1, δt=1, t=0)
    run_check(job; n=1)
    return run_outer!(job; n=n, δt=δt, t=t)
end
function run!(job::DependentJob; n=1, δt=1, t=0)
    run_check(job; n=1)
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
    return run_outer!(job; n=n, δt=δt, t=t)
end
function run_outer!(job; n=1, δt=1, t=0)
    _sleep(t)
    return run_repeatedly!(job; n=n, δt=δt)
end
function run_repeatedly!(job; n=1, δt=1)
    if iszero(n)
        return job
    else
        run_inner!(job)
        if issucceeded(job)
            return job  # Stop immediately
        else
            if !iszero(δt)
                sleep(δt)  # `if-else` is faster than `sleep(0)`
            end
            return run_repeatedly!(job; n=n - 1, δt=δt)
        end
    end
end
function run_inner!(job)  # Do not export!
    if ispending(job)
        if !isexecuted(job)
            push!(JOB_REGISTRY, job => nothing)
        end
        runner = JobRunner(job)
        runner.ref = @async run_core!(job)
    else
        job.status = PENDING
        return run_inner!(job)
    end
end
function run_core!(job)  # Do not export!
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
run_check(::AbstractJob; n=1, kwargs...) = @assert isinteger(n) && n >= 1
function run_check(job::DependentJob; n=1, kwargs...)
    @assert isinteger(n) && n >= 1
    if job.strict
        @assert all(issucceeded(parent) for parent in job.parents)
    else
        @assert all(isexited(parent) for parent in job.parents)
    end
    return nothing
end

function _sleep(t)
    if t > zero(t)
        sleep(t)
    end
    return nothing
end
function _sleep(t::DateTime)
    current_time = now()
    if t > current_time
        sleep(t - current_time)
    end
    return nothing
end

"""
    interrupt!(runner::JobRunner)

Manually interrupt a `Job`, works only if it is running.
"""
function interrupt!(runner::JobRunner)
    if isexited(runner.job)
        @info "the job $(runner.job.id) has already exited!"
    elseif ispending(runner.job)
        @info "the job $(runner.job.id) has not started!"
    else
        _kill(runner.ref)
    end
    return runner
end

Base.wait(runner::JobRunner) = wait(runner.ref)
