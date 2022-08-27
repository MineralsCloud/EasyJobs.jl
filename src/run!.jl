using Dates: Period, now

using .Thunks: TimeoutException, ErredResult, reify!, _kill

export run!, interrupt!

"""
    run!(job::Job; n=1, δt=1)

Run a `Job` with maximum `n` attempts, with each attempt separated by `δt` seconds.
"""
function run!(job::Job; n=1, δt=1)
    @assert isinteger(n) && n >= 1
    return run_repeatedly!(job; n=n, δt=δt)
end
function run!(job::SubsequentJob; n=1, δt=1)
    @assert isinteger(n) && n >= 1
    @assert all(isexited(parent) for parent in job.parents)
    return run_repeatedly!(job; n=n, δt=δt)
end
function run!(job::ConsequentJob; n=1, δt=1)
    @assert isinteger(n) && n >= 1
    # Use previous results as arguments
    parents = job.parents
    @assert all(isexited(parent) for parent in parents)
    job.core.args = if length(parents) == 0
        ()
    elseif length(parents) == 1
        (getresult(parent),)
    else  # > 1
        collect(getresult(parent) for parent in parents)
    end
    return run_repeatedly!(job; n=n, δt=δt)
end
function run_repeatedly!(job; n=1, δt=1)
    for _ in 1:n
        if !issucceeded(job)
            run_inner!(job)
        end
        if issucceeded(job)
            break  # Stop immediately
        end
        if !iszero(δt)  # Still unsuccessful
            sleep(δt)  # `if-else` is faster than `sleep(0)`
        end
    end
    return job
end
function run_inner!(job)  # Do not export!
    if ispending(job)
        if !isexecuted(job)
            push!(JOB_REGISTRY, job => nothing)
        end
        JOB_REGISTRY[job] = @async run_core!(job)
    else
        job.status = PENDING
        return run_inner!(job)
    end
end
function run_core!(job)  # Do not export!
    job.status = RUNNING
    job.start_time = now()
    reify!(job.core)
    job.stop_time = now()
    job.status = if job.core.erred
        thrown = something(getresult(job.core)).thrown
        if thrown isa InterruptException
            INTERRUPTED
        elseif thrown isa TimeoutException
            TIMED_OUT
        else
            FAILED
        end
    else
        SUCCEEDED
    end
    job.count += 1
    return job
end

function waituntil(t::Period)
    if t > zero(t)
        wait(t)
    end
    return nothing
end
function waituntil(t::DateTime)
    current_time = now()
    if t > current_time
        wait(t - current_time)
    end
    return nothing
end

"""
    interrupt!(job::Job)

Manually interrupt a `Job`, works only if it is running.
"""
function interrupt!(job::Job)
    if isexited(job)
        @info "the job $(job.id) has already exited!"
    elseif ispending(job)
        @info "the job $(job.id) has not started!"
    else
        _kill(JOB_REGISTRY[job])
    end
    return job
end

Base.wait(job::Job) = wait(JOB_REGISTRY[job])
