using EasyJobsBase: Job
using Query: @from, @select, @orderby
using Requires: @require
using UUIDs: UUID

export maketable, queue, query

defaultsink() = collect

function maketable(registry)
    return registry |> @map {
        id = _.id,
        def = string(_.core),
        user = string(_.username),
        created_time = _.created_time,
        start_time = starttime(_),
        stop_time = stoptime(_),
        duration = elapsed(_),
        status = getstatus(_),
        times = ntimes(_),
    }
end

"""
    queue(table; sortby=:created_time)

Print all `Job`s that are pending, running, or finished as a table.

Accpetable arguments for `sortby` are `:user`, `:created_time`, `:start_time`, `:stop_time`,
`:duration`, `:status`, and `:times`.
"""
function queue(table; sortby=:created_time)
    @assert sortby in
        (:user, :created_time, :start_time, :stop_time, :duration, :status, :times)
    return table |> @orderby_descending getfield(_, sortby)
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
