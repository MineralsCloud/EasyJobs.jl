using EasyJobsBase: Job
using Query: @from, @select, @orderby
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
query(table, id::UUID) = table |> @filter _.id == id
query(table, ids::AbstractVector{<:UUID}) = table |> @filter _.id in ids
query(table, ids::Union{Integer,<:AbstractVector{<:Integer}}) = query(table, UUID.(ids))
