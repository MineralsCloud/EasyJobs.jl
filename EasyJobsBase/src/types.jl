using Dates: DateTime, now, format
using UUIDs: UUID, uuid1

using Thinkers: Think

export Job, WeaklyDependentJob

@enum JobStatus begin
    PENDING
    RUNNING
    SUCCEEDED
    FAILED
    INTERRUPTED
end

abstract type AbstractJob end
# Reference: https://github.com/cihga39871/JobSchedulers.jl/blob/aca52de/src/jobs.jl#L35-L69
"""
    Job(def::Thunk; description="", username="")

Create a simple job.

# Arguments
- `def`: a `Thunk` that encloses the job definition.
- `name`: give a short name to the job.
- `description::String=""`: describe what the job does in more detail.
- `username::String=""`: indicate who executes the job.

# Examples
```jldoctest
julia> using Thinkers

julia> a = Job(Thunk(sleep, 5); username="me", description="Sleep for 5 seconds");

julia> b = Job(Thunk(run, `pwd` & `ls`); username="me", description="Run some commands");
```
"""
mutable struct Job <: AbstractJob
    id::UUID
    def::Think
    name::String
    description::String
    username::String
    creation_time::DateTime
    start_time::DateTime
    end_time::DateTime
    "Track the job status."
    status::JobStatus
    "Count hom many times the job has been run."
    count::UInt64
    "These jobs runs before the current job."
    parents::Set{AbstractJob}
    "These jobs runs after the current job."
    children::Set{AbstractJob}
    function Job(def::Think; name="", description="", username="")
        return new(
            uuid1(),
            def,
            name,
            description,
            username,
            now(),
            DateTime(0),
            DateTime(0),
            PENDING,
            0,
            Set(),
            Set(),
        )
    end
end
abstract type DependentJob <: AbstractJob end
mutable struct WeaklyDependentJob <: DependentJob
    id::UUID
    def::Think
    name::String
    description::String
    username::String
    creation_time::DateTime
    start_time::DateTime
    end_time::DateTime
    "Track the job status."
    status::JobStatus
    "Count hom many times the job has been run."
    count::UInt64
    "These jobs runs before the current job."
    parents::Set{AbstractJob}
    "These jobs runs after the current job."
    children::Set{AbstractJob}
    function WeaklyDependentJob(def::Think; name="", description="", username="")
        return new(
            uuid1(),
            def,
            name,
            description,
            username,
            now(),
            DateTime(0),
            DateTime(0),
            PENDING,
            0,
            Set(),
            Set(),
        )
    end
end
mutable struct StronglyDependentJob <: DependentJob
    id::UUID
    def::Think
    name::String
    description::String
    username::String
    creation_time::DateTime
    start_time::DateTime
    end_time::DateTime
    "Track the job status."
    status::JobStatus
    "Count hom many times the job has been run."
    count::UInt64
    "These jobs runs before the current job."
    parents::Set{AbstractJob}
    "These jobs runs after the current job."
    children::Set{AbstractJob}
    function StronglyDependentJob(def::Think; name="", description="", username="")
        return new(
            uuid1(),
            def,
            name,
            description,
            username,
            now(),
            DateTime(0),
            DateTime(0),
            PENDING,
            0,
            Set(),
            Set(),
        )
    end
end

# See https://github.com/MineralsCloud/SimpleWorkflows.jl/issues/137
struct Executor{T<:AbstractJob}
    job::T
    maxattempts::UInt64
    interval::Real
    waitfor::Real
    task::Task
    function Executor(job::T; maxattempts=1, interval=1, waitfor=0) where {T}
        @assert maxattempts >= 1
        @assert interval >= zero(interval)
        @assert waitfor >= zero(waitfor)
        return new{T}(job, maxattempts, interval, waitfor, Task(() -> ___run!(job)))
    end
end
