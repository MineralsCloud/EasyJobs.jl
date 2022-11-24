using Dates: DateTime, now, format
using UUIDs: UUID, uuid1

using .Thunks: Think, printfunc

export Job, SubsequentJob, PipeJob

@enum JobStatus begin
    PENDING
    RUNNING
    SUCCEEDED
    FAILED
    INTERRUPTED
    TIMED_OUT
end

abstract type AbstractJob end
abstract type DependentJob <: AbstractJob end
# Reference: https://github.com/cihga39871/JobSchedulers.jl/blob/aca52de/src/jobs.jl#L35-L69
"""
    Job(core::Thunk; description="", username="")

Create a simple job.

# Arguments
- `core`: a `Thunk` that encloses the job definition.
= `name`: give a short name to the job.
- `description::String=""`: describe what the job does in more detail.
- `username::String=""`: indicate who executes the job.

# Examples
```jldoctest
julia> using EasyJobsBase.Thunks

julia> a = Job(Thunk(sleep, 5); username="me", description="Sleep for 5 seconds");

julia> b = Job(Thunk(run, `pwd` & `ls`); username="me", description="Run some commands");
```
"""
mutable struct Job <: AbstractJob
    id::UUID
    core::Think
    name::String
    description::String
    username::String
    created_time::DateTime
    start_time::DateTime
    stop_time::DateTime
    "Track the job status."
    status::JobStatus
    count::UInt64
    "These jobs runs before the current job."
    parents::Vector{AbstractJob}
    "These jobs runs after the current job."
    children::Vector{AbstractJob}
    function Job(core::Think; name="", description="", username="")
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
            [],
            [],
        )
    end
end
"""
    Job(job::Job)

Create a new `Job` from an existing `Job`.
"""
function Job(job::Job)
    new_job = Job(
        job.core; name=job.name, description=job.description, username=job.username
    )
    new_job.parents = job.parents
    new_job.children = job.children
    return new_job
end
mutable struct SubsequentJob <: DependentJob
    id::UUID
    core::Think
    name::String
    description::String
    username::String
    created_time::DateTime
    start_time::DateTime
    stop_time::DateTime
    "Track the job status."
    status::JobStatus
    count::UInt64
    "These jobs runs before the current job."
    parents::Vector{AbstractJob}
    "These jobs runs after the current job."
    children::Vector{AbstractJob}
    function SubsequentJob(core::Think; name="", description="", username="")
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
            [],
            [],
        )
    end
end
mutable struct PipeJob <: DependentJob
    id::UUID
    core::Think
    name::String
    description::String
    username::String
    created_time::DateTime
    start_time::DateTime
    stop_time::DateTime
    "Track the job status."
    status::JobStatus
    count::UInt64
    "These jobs runs before the current job."
    parents::Vector{AbstractJob}
    "These jobs runs after the current job."
    children::Vector{AbstractJob}
    function PipeJob(core::Think; name="", description="", username="")
        if !isempty(core.args)
            @warn "the functional arguments of a `PipeJob` are not empty!"
        end
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
            [],
            [],
        )
    end
end

function Base.show(io::IO, job::AbstractJob)
    if get(io, :compact, false) || get(io, :typeinfo, nothing) == typeof(job)
        Base.show_default(IOContext(io, :limit => true), job)  # From https://github.com/mauro3/Parameters.jl/blob/ecbf8df/src/Parameters.jl#L556
    else
        println(io, summary(job))
        println(io, ' ', "id: ", job.id)
        if !isempty(job.description)
            print(io, ' ', "description: ")
            show(io, job.description)
            println(io)
        end
        print(io, ' ', "def: ")
        printfunc(io, job.core)
        print(io, '\n', ' ', "status: ")
        printstyled(io, getstatus(job); bold=true)
        if !ispending(job)
            println(io, '\n', ' ', "from: ", format(starttime(job), "dd-u-YYYY HH:MM:SS.s"))
            print(io, ' ', "to: ")
            if isrunning(job)
                print(io, "still running...")
            else
                # println(io, format(stoptime(job), "dd-u-YYYY HH:MM:SS.s"))
                print(io, ' ', "uses: ", elapsed(job))
            end
        end
    end
end
