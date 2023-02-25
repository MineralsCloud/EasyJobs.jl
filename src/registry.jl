using EasyJobsBase: Job
using Query

export maketable

"""
    queue(; sortby = :created_time)

Print all `Job`s that are pending, running, or finished as a table.

Accpetable arguments for `sortby` are `:created_time`, `:user`, `:start_time`, `:stop_time`,
`:elapsed`, `:status`, and `:times`.
"""
function maketable(sink, registry)
    return @from job in registry begin
        @select {
            id = job.id,
            def = string(job.core),
            created_time = job.created_time,
            start_time = starttime(job),
            stop_time = stoptime(job),
            duration = elapsed(job),
            status = getstatus(job),
        }
        @collect sink
    end
end

"""
    query(id::Integer)
    query(ids::AbstractVector{<:Integer})

Query a specific (or a list of `Job`s) by its (theirs) ID.
"""
query(id::Integer) = filter(row -> row.id == id, queue())
query(ids::AbstractVector{<:Integer}) = map(id -> query(id), ids)
