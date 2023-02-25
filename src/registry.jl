using EasyJobsBase: Job
using Query: @from, @select, @orderby

export maketable

function maketable(sink, registry=Job[])
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

"""
    queue(sink, registry=Job[]; sortby=:created_time)

Print all `Job`s that are pending, running, or finished as a table.

Accpetable arguments for `sortby` are `:user`, `:created_time`, `:start_time`, `:stop_time`,
`:duration`, `:status`, and `:times`.
"""
function queue(sink, registry=Job[]; sortby=:created_time)
    @assert sortby in
        (:user, :created_time, :start_time, :stop_time, :duration, :status, :times)
    table = maketable(sink, registry)
    return @from i in table begin
        @orderby descending(getfield(i, sortby))
        @select i
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
