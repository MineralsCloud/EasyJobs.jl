using Distributed: nprocs, @spawnat
using Thinkers: TimeoutException, ErrorInfo, reify!, setargs!, haserred, _kill

export Async, Parallel, shouldrun, run!, execute!

abstract type ExecutionStyle end
struct Async <: ExecutionStyle end
struct Parallel <: ExecutionStyle end

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
struct AsyncExecutor <: Executor
    maxattempts::UInt64
    interval::Real
    delay::Real
    wait::Bool
end
function AsyncExecutor(; maxattempts=1, interval=1, delay=0, wait=false)
    @assert maxattempts >= 1
    @assert interval >= zero(interval)
    @assert delay >= zero(delay)
    return AsyncExecutor(maxattempts, interval, delay, wait)
end
struct ParallelExecutor <: Executor
    worker::UInt64
    maxattempts::UInt64
    interval::Real
    delay::Real
    wait::Bool
end
function ParallelExecutor(worker=1; maxattempts=1, interval=1, delay=0, wait=false)
    @assert 1 <= worker <= nprocs()
    @assert maxattempts >= 1
    @assert interval >= zero(interval)
    @assert delay >= zero(delay)
    return ParallelExecutor(worker, maxattempts, interval, delay, wait)
end

"""
    run!(job::Job; maxattempts=1, interval=1, delay=0, wait=false)
    run!(job::Job, style::Async; maxattempts=1, interval=1, delay=0, wait=false)
    run!(job::Job, style::Parallel; maxattempts=1, interval=1, delay=0, wait=false)

Run a `Job` with a maximum number of attempts, with each attempt separated by `interval` seconds
and an initial `delay` in seconds.
"""
run!(job::AbstractJob, ::Async; kwargs...) = execute!(job, AsyncExecutor(; kwargs...))
run!(job::AbstractJob, ::Parallel; kwargs...) = execute!(job, ParallelExecutor(; kwargs...))
run!(job::AbstractJob; kwargs...) = run!(job, Async(); kwargs...)

"""
    execute!(job::AbstractJob, exec::Executor)

Execute a given `AbstractJob` associated with the `Executor`.

This function checks if the `job` has succeeded. If so, it stops immediately. If not, it
sleeps for a `exec.delay`, then runs the `job`. If `exec.maxattempts` is more than ``1``, it
loops over the remaining attempts, sleeping for an `exec.interval`, running the `job`, and
waiting in each loop.
"""
function execute!(job::AbstractJob, exec::Executor)
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

function dispatch!(job::AbstractJob, exec::AsyncExecutor)
    for _ in Base.OneTo(exec.maxattempts)
        runonce!(job, exec)  # Update job with the modified one for `ParallelExecutor`
        if issucceeded(job)
            break  # Stop immediately if the job has succeeded
        end
    end
    return job
end
function dispatch!(job::AbstractJob, exec::ParallelExecutor)
    copiedjob = job  # Initialize `copiedjob` outside the loop with the original job
    for _ in Base.OneTo(exec.maxattempts)
        # `copiedjob` will be a new alias everytime using `runonce!`, but it is still run on the
        # same worker specified by `exec.worker`
        copiedjob = runonce!(copiedjob, exec)  # Update `job` with the modified one for `ParallelExecutor`
        if issucceeded(copiedjob)
            break  # Stop immediately if the job has succeeded
        end
    end
    return copiedjob  # Now it's valid to return `copiedjob`
end

function runonce!(job::AbstractJob, exec::AsyncExecutor)
    if isfailed(job)
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
    if isfailed(job)
        setpending!(job)
        return runonce!(job, exec)
    end
    if ispending(job)
        future = @spawnat exec.worker _run!(job)  # It is likely that `job` will not be modified
        job = fetch(future)  # The `future` will be different everytime, so is the `job` fetched
    end
    return job  # Do nothing for running and succeeded jobs
end

# Internal function to execute a specific `AbstractJob`.
function _run!(job::AbstractJob)  # Do not export!
    job.status = RUNNING
    job.start_time = now()
    reify!(job.core)
    job.end_time = now()
    job.status = haserred(job.core) ? FAILED : SUCCEEDED
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
