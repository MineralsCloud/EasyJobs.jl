using Dates: DateTime, now, format
using UUIDs: UUID, uuid1

using .Thunks: Think, printfunc

export SimpleJob

@enum JobStatus begin
    PENDING
    RUNNING
    SUCCEEDED
    FAILED
    INTERRUPTED
    TIMED_OUT
end

abstract type Job end
# Reference: https://github.com/cihga39871/JobSchedulers.jl/blob/aca52de/src/jobs.jl#L35-L69
"""
    Job(core::Thunk; desc="", user="")

Create a simple job.

# Arguments
- `core`: a `Thunk` that encloses the job definition.
- `desc::String=""`: describe briefly what this job does.
- `user::String=""`: indicate who executes this job.

# Examples
```jldoctest
julia> a = Job(Thunk(sleep)(5); user="me", desc="Sleep for 5 seconds");

julia> b = Job(Thunk(run, `pwd` & `ls`); user="me", desc="Run some commands");
```
"""
mutable struct SimpleJob <: Job
    id::UUID
    core::Think
    desc::String
    user::String
    created_time::DateTime
    start_time::DateTime
    stop_time::DateTime
    "Track the job status."
    status::JobStatus
    count::UInt64
    "These jobs runs before the current job."
    parents::Vector{Job}
    "These jobs runs after the current job."
    children::Vector{Job}
    function SimpleJob(core::Think; desc="", user="")
        return new(
            uuid1(), core, desc, user, now(), DateTime(0), DateTime(0), PENDING, 0, [], []
        )
    end
end
"""
    SimpleJob(job::SimpleJob)

Create a new `SimpleJob` from an existing `SimpleJob`.
"""
function SimpleJob(job::SimpleJob)
    new_job = SimpleJob(job.core; desc=job.desc, user=job.user)
    new_job.parents = job.parents
    new_job.children = job.children
    return new_job
end
mutable struct SubsequentJob <: Job
    id::UUID
    core::Think
    desc::String
    user::String
    created_time::DateTime
    start_time::DateTime
    stop_time::DateTime
    "Track the job status."
    status::JobStatus
    count::UInt64
    "These jobs runs before the current job."
    parents::Vector{Job}
    "These jobs runs after the current job."
    children::Vector{Job}
    function SubsequentJob(core::Think; desc="", user="")
        return new(
            uuid1(), core, desc, user, now(), DateTime(0), DateTime(0), PENDING, 0, [], []
        )
    end
end
mutable struct ConsequentJob <: Job
    id::UUID
    core::Think
    desc::String
    user::String
    created_time::DateTime
    start_time::DateTime
    stop_time::DateTime
    "Track the job status."
    status::JobStatus
    count::UInt64
    "These jobs runs before the current job."
    parents::Vector{Job}
    "These jobs runs after the current job."
    children::Vector{Job}
    function ConsequentJob(core::Think; desc="", user="")
        if !isempty(core.args)
            @warn "the functional arguments of a `ConsequentJob` are not empty!"
        end
        return new(
            uuid1(), core, desc, user, now(), DateTime(0), DateTime(0), PENDING, 0, [], []
        )
    end
end

function Base.show(io::IO, job::Job)
    if get(io, :compact, false) || get(io, :typeinfo, nothing) == typeof(job)
        Base.show_default(IOContext(io, :limit => true), job)  # From https://github.com/mauro3/Parameters.jl/blob/ecbf8df/src/Parameters.jl#L556
    else
        println(io, summary(job))
        println(io, ' ', "id: ", job.id)
        if !isempty(job.desc)
            print(io, ' ', "description: ")
            show(io, job.desc)
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
