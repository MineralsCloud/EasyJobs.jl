using Distributed: @spawnat
using Thinkers: TimeoutException, ErrorInfo, reify!, setargs!, haserred, _kill

export shouldrun, run!, execute!

# See https://github.com/MineralsCloud/SimpleWorkflows.jl/issues/137
abstract type Executor end
"""
    AsyncExecutor(; maxattempts=1, interval=1, delay=0, wait=false)

Handle the asynchronous execution of jobs.

# Arguments
- `maxattempts::UInt64=1`: the maximum number of attempts to execute the job.
- `interval::Real=1`: the time interval between each attempt to execute the job, in seconds.
- `delay::Real=0`: the delay before the first attempt to execute the job, in seconds.
- `wait::Bool=false`: determines whether to wait for the job to complete before executing the next task.
"""
mutable struct AsyncExecutor <: Executor
    maxattempts::UInt64
    interval::Real
    delay::Real
    wait::Bool
    function AsyncExecutor(maxattempts=1, interval=1, delay=0, wait=false)
        @assert maxattempts >= 1
        @assert interval >= zero(interval)
        @assert delay >= zero(delay)
        return new(maxattempts, interval, delay, wait)
    end
end
AsyncExecutor(; maxattempts=1, interval=1, delay=0, wait=false) =
    AsyncExecutor(maxattempts, interval, delay, wait)
mutable struct ParallelExecutor <: Executor
    spawnat::Union{Symbol,UInt64}
    maxattempts::UInt64
    interval::Real
    delay::Real
    wait::Bool
    function ParallelExecutor(spawnat=:any, maxattempts=1, interval=1, delay=0, wait=false)
        if isinteger(spawnat)
            spawnat = UInt64(spawnat)
        else
            @assert spawnat == :any
        end
        @assert maxattempts >= 1
        @assert interval >= zero(interval)
        @assert delay >= zero(delay)
        return new(spawnat, maxattempts, interval, delay, wait)
    end
end
ParallelExecutor(spawnat=:any; maxattempts=1, interval=1, delay=0, wait=false) =
    ParallelExecutor(spawnat, maxattempts, interval, delay, wait)

"""
    run!(job::Job; maxattempts=1, interval=1, delay=0, wait=false)

Run a `Job` with a maximum number of attempts, with each attempt separated by `interval` seconds
and an initial `delay` in seconds.
"""
run!(job::AbstractJob; kwargs...) = execute!(job, AsyncExecutor(; kwargs...))

"""
    execute!(job::AbstractJob, exec::AsyncExecutor)

Execute a given `AbstractJob` associated with the `AsyncExecutor`.

This function checks if the `job` has succeeded. If so, it stops immediately. If not, it
sleeps for a `exec.delay`, then runs the `job`. If `exec.maxattempts` is more than ``1``, it
loops over the remaining attempts, sleeping for an `exec.interval`, running the `job`, and
waiting in each loop.
"""
function execute!(job::AbstractJob, exec::AsyncExecutor)
    @assert shouldrun(job)
    prepare!(job)
    task = if issucceeded(job)
        @task job  # Just return the job if it has succeeded
    else
        sleep(exec.delay)
        @task for _ in Base.OneTo(exec.maxattempts)
            runonce!(job, exec)  # Update job with the modified one for `ParallelExecutor`
            if issucceeded(job)
                break  # Stop immediately if the job has succeeded
            end
        end
    end
    schedule(task)
    if exec.wait
        wait(task)
    end
    return task
end
function execute!(job::AbstractJob, exec::ParallelExecutor)
    @assert shouldrun(job)
    prepare!(job)
    task = if issucceeded(job)
        @task job  # Just return the job if it has succeeded
    else
        sleep(exec.delay)
        @task dispatch!(job, exec)
    end
    schedule(task)
    if exec.wait
        wait(task)
    end
    return task
end

function dispatch!(job::AbstractJob, exec::ParallelExecutor)
    copiedjob = job  # Initialize `copiedjob` outside the loop with the original job
    for _ in Base.OneTo(exec.maxattempts)
        copiedjob = runonce!(copiedjob, exec)  # Update `job` with the modified one for `ParallelExecutor`
        if issucceeded(copiedjob)
            break  # Stop immediately if the job has succeeded
        end
    end
    return copiedjob  # Now it's valid to return `copiedjob`
end

function runonce!(job::AbstractJob, exec::AsyncExecutor)
    if isfailed(job) || isinterrupted(job)
        setpending!(job)
        return runonce!(job, exec)
    end
    if ispending(job)
        task = @task _run!(job)
        schedule(task)
        wait(task)
    end
    return job  # Do nothing for running and succeeded jobs
end
function runonce!(job::AbstractJob, exec::ParallelExecutor)
    if isfailed(job) || isinterrupted(job)
        setpending!(job)
        return runonce!(job, exec)
    end
    if ispending(job)
        future = @spawnat exec.spawnat _run!(job)  # It is likely that `job` will not be modified
        job = fetch(future)
    end
    return job  # Do nothing for running and succeeded jobs
end

# Internal function to execute a specific `AbstractJob`.
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

prepare!(::AbstractJob) = nothing  # No op
function prepare!(job::ArgDependentJob)
    # Use previous results as arguments
    args = if countparents(job) == 1
        parent = only(eachparent(job))
        if issucceeded(parent)
            something(getresult(parent))
        else
            error("the parent job has failed!")
        end
    else  # > 1
        parents = if job.skip_incomplete
            Iterators.filter(issucceeded, eachparent(job))
        else
            eachparent(job)
        end
        Set(something(getresult(parent)) for parent in parents)  # Could be empty if all parents failed
    end
    setargs!(job.core, args)
    return nothing
end

shouldrun(::IndependentJob) = true
function shouldrun(job::ConditionalJob)
    if countparents(job) == 0
        return false
    end
    if job.skip_incomplete
        return all(isexited(parent) for parent in eachparent(job))
    else
        return all(issucceeded(parent) for parent in eachparent(job))
    end
end
function shouldrun(job::ArgDependentJob)
    if countparents(job) == 0
        return false
    elseif countparents(job) == 1  # No matter `job.skip_incomplete` is `true` or `false`
        return issucceeded(only(eachparent(job)))
    else  # > 1
        if job.skip_incomplete
            return all(isexited(parent) for parent in eachparent(job))
        else
            return all(issucceeded(parent) for parent in eachparent(job))
        end
    end
end
