using EasyJobsBase: Job
using Query: @from, @select, @orderby
using Requires: @require
using UUIDs: UUID

export maketable, queue, query

defaultsink() = collect

function maketable(sink, registry)
    return @from job in registry begin
        @select {
            id = job.id,
            def = string(job.core),
            user = string(job.username),
            created_time = job.created_time,
            start_time = starttime(job),
            stop_time = stoptime(job),
            duration = elapsed(job),
            status = getstatus(job),
            times = ntimes(job),
        }
        @collect sink
    end
end
maketable(registry=Job[]) = maketable(defaultsink(), registry)

"""
    queue(table; sortby=:created_time)

Print all `Job`s that are pending, running, or finished as a table.

Accpetable arguments for `sortby` are `:user`, `:created_time`, `:start_time`, `:stop_time`,
`:duration`, `:status`, and `:times`.
"""
function queue(table; sortby=:created_time)
    @assert sortby in
        (:user, :created_time, :start_time, :stop_time, :duration, :status, :times)
    return @from item in table begin
        @orderby descending(getfield(item, sortby))
        @select item
    end
end

"""
    query(table, id::Integer)
    query(table, ids::AbstractVector{<:Integer})

Query a specific (or a list of `Job`s) by its (theirs) ID.
"""
function query(table, id::UUID)
    return @from item in table begin
        @where item.id == id
        @select item
    end
end
function query(table, ids::AbstractVector{<:UUID})
    return @from item in table begin
        @where item.id in ids
        @select item
    end
end
query(table, ids::Union{Integer,<:AbstractVector{<:Integer}}) = query(table, UUID.(ids))

function __init__()
    @require DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0" begin
        @eval using DataFrames: DataFrame
        defaultsink() = DataFrame
    end
    @require IndexedTables = "6deec6e2-d858-57c5-ab9b-e6ca5bd20e43" begin
        @eval using IndexedTables: table
        defaultsink() = table
    end
    @require TypedTables = "9d95f2ec-7b3d-5a63-8d20-e2491e220bb9" begin
        @eval using TypedTables: Table
        defaultsink() = Table
    end
end
