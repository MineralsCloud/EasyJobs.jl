using EasyJobsBase: Job
using Query: @from, @filter
using UUIDs: UUID

export maketable, queue, query

function maketable(registry)
    return @from job in registry begin
        @select {
            id = job.id,
            def = string(job.core),
            created_by = string(job.username),
            created_at = creationtimeof(job),
            started_at = starttimeof(job),
            stopped_at = endtimeof(job),
            spent = timecostof(job),
            status = getstatus(job),
            n = countexecution(job),
        }
    end
end

"""
    queue(table; sortby=:created_time)

Return all `Job`s that are pending, running, or finished.

Accpetable arguments for `sortby` are `:user`, `:created_time`, `:start_time`, `:stop_time`,
`:duration`, `:status`, and `:times`.
"""
function queue(table; sortby=:created_time)
    @assert sortby in
        (:user, :created_time, :start_time, :stop_time, :duration, :status, :times)
    return @from job in table begin
        @orderby descending(getfield(job, sortby))
        @select job
    end
end

"""
    query(table, id::Integer)
    query(table, ids::AbstractVector{<:Integer})

Query a specific (or a list of `Job`s) by its (theirs) ID(s).
"""
query(table, id::UUID) = table |> @filter _.id == id
query(table, ids::AbstractVector{<:UUID}) = table |> @filter _.id in ids
query(table, ids::Union{Integer,<:AbstractVector{<:Integer}}) = query(table, UUID.(ids))
