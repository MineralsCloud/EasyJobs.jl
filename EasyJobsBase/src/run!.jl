using Dates: Period, now

using Thinkers: TimeoutException, ErrorInfo, reify!, haserred, _kill

export run!, interrupt!

"""
    run!(job::Job; maxattempts=1, separation=1, skip=0)

Run a `Job` with a maximum number of attempts, with each attempt separated by a few seconds.
"""
run!(job::AbstractJob; kwargs...) = run!(Runner(job, kwargs...))
function run!(runner::Runner)
    dynamic_check(runner)
    return run_outer!(runner)
end
function run!(runner::Runner{DependentJob})
    dynamic_check(runner)
    job = runner.job
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
    return run_outer!(runner)
end
function run_outer!(runner::Runner)
    _sleep(runner.waitfor)
    for _ in runner.maxattempts
        run_inner!(runner)
        if issucceeded(runner.job)
            return runner  # Stop immediately
        else
            if !iszero(runner.interval)
                sleep(runner.interval)  # `if-else` is faster than `sleep(0)`
            end
        end
    end
end
function run_inner!(runner)  # Do not export!
    if ispending(runner.job)
        if !isexecuted(runner.job)
            push!(JOB_REGISTRY, runner => nothing)
        end
        schedule(runner.task)
    else
        runner.job.status = PENDING
        return run_inner!(runner)
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

dynamic_check(::Runner) = nothing
function dynamic_check(runner::Runner{DependentJob})
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
function interrupt!(runner::Runner)
    if isexited(runner.job)
        @info "the job $(runner.job.id) has already exited!"
    elseif ispending(runner.job)
        @info "the job $(runner.job.id) has not started!"
    else
        _kill(runner.ref)
    end
    return runner
end

Base.wait(runner::Runner) = wait(runner.ref)
