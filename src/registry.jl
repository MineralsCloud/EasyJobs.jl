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
    query(table, id::AbstractString)
    query(table, ids::AbstractVector{<:AbstractString})

Query a specific (or a list of `Job`s) by its (theirs) ID.
"""
function query(table, id::AbstractString)
    id = UUID(id)
    return @from item in table begin
        @where item.id == id
        @select item
    end
end
function query(id::AbstractString)
    id = UUID(id)
    return @from item in table begin
        @where item.id == id
        @select item
        @collect defaultsink()
    end
end
function query(ids::AbstractVector{<:AbstractString})
    return @from id in ids begin
        @from item in table
        @where item.id == id
        @select item
        @collect defaultsink()
    end
end
function query(table, ids::AbstractVector{<:AbstractString})
    return @from id in ids begin
        @from item in table
        @where item.id == id
        @select item
    end
end

function __init__()
    @require DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0" begin
        @eval using DataFrames: DataFrame
        defaultsink() = DataFrame
    end
end
