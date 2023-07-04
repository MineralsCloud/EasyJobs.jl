using Dates: DateTime, now
using UUIDs: UUID, uuid1

using Thinkers: Think

export Job, IndependentJob, ConditionalJob, ArgDependentJob

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
    Job(core::Thunk; description="", username="")

Create a simple job.

# Arguments
- `core`: a `Thunk` that encloses the job core definition.
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
mutable struct IndependentJob <: AbstractJob
    id::UUID
    core::Think
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
    function IndependentJob(core::Think; name="", description="", username="")
        return new(
            uuid1(),
            core,
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
const Job = IndependentJob
abstract type DependentJob <: AbstractJob end
mutable struct ConditionalJob <: DependentJob
    id::UUID
    core::Think
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
    skip_incomplete::Bool
    function ConditionalJob(
        core::Think, skip_incomplete=true; name="", description="", username=""
    )
        return new(
            uuid1(),
            core,
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
            skip_incomplete,
        )
    end
end
mutable struct ArgDependentJob <: DependentJob
    id::UUID
    core::Think
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
    skip_incomplete::Bool
    function ArgDependentJob(
        core::Think, skip_incomplete=true; name="", description="", username=""
    )
        return new(
            uuid1(),
            core,
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
            skip_incomplete,
        )
    end
end
