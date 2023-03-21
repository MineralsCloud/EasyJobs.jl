import Thinkers: getresult

export countexecution,
    getdesc, getcreationtime, getstarttime, getendtime, timecost, getresult

"""
    countexecution(job::Job)

Count how many times a `Job` has been run.
"""
countexecution(job::AbstractJob) = Int(job.count)

"""
    getdesc(job::Job)

Return the description of a `Job`.
"""
getdesc(job::AbstractJob) = job.description

"Return the creation time of a `Job`."
getcreationtime(job::AbstractJob) = job.creation_time

"""
    getstarttime(job::Job)

Return the start time of a `Job`. Return `nothing` if it is still pending.
"""
getstarttime(job::AbstractJob) = ispending(job) ? nothing : job.start_time

"""
    getendtime(job::Job)

Return the stop time of a `Job`. Return `nothing` if it has not exited.
"""
getendtime(job::AbstractJob) = isexited(job) ? job.end_time : nothing

"""
    timecost(job::Job)

Return the time cost of a `Job` since it started running.

If `nothing`, the `Job` is still pending. If it is finished, return how long it took to
complete.
"""
function timecost(job::AbstractJob)
    if ispending(job)
        return nothing
    elseif isrunning(job)
        return now() - job.start_time
    else  # Exited
        return job.end_time - job.start_time
    end
end

"""
    getresult(job::Job)

Get the running result of a `Job`.

The result is wrapped by a `Some` type. Use `something` to retrieve its value.
If it is `nothing`, the `Job` is not finished.
"""
getresult(job::AbstractJob) = isexited(job) ? getresult(job.core) : nothing
