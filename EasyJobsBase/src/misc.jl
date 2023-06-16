import Thinkers: getresult

export countexecution,
    descriptionof,
    creationtimeof,
    starttimeof,
    endtimeof,
    timecostof,
    getresult,
    countparents,
    countchildren

"""
    countexecution(job::AbstractJob)

Count how many times the `job` has been run.
"""
countexecution(job::AbstractJob) = Int(job.count)

"""
    descriptionof(job::AbstractJob)

Return the description of the `job`.
"""
descriptionof(job::AbstractJob) = job.description

"""
    creationtimeof(job::AbstractJob)

Return the creation time of the `job`.
"""
creationtimeof(job::AbstractJob) = job.creation_time

"""
    starttimeof(job::AbstractJob)

Return the start time of the `job`. Return `nothing` if it is still pending.
"""
starttimeof(job::AbstractJob) = ispending(job) ? nothing : job.start_time

"""
    endtimeof(job::AbstractJob)

Return the end time of the `job`. Return `nothing` if it has not exited.
"""
endtimeof(job::AbstractJob) = isexited(job) ? job.end_time : nothing

"""
    timecostof(job::AbstractJob)

Return the time cost of the `job` since it started running.

If `nothing`, the `job` is still pending. If it is finished, return how long it took to
complete.
"""
function timecostof(job::AbstractJob)
    if ispending(job)
        return nothing
    elseif isrunning(job)
        return now() - job.start_time
    else  # Exited
        return job.end_time - job.start_time
    end
end

"""
    getresult(job::AbstractJob)

Get the running result of the `job`.

The result is wrapped by a `Some` type. Use `something` to retrieve its value.
If it is `nothing`, the `job` is not finished.
"""
getresult(job::AbstractJob) = isexited(job) ? getresult(job.core) : nothing

"""
    countparents(job::AbstractJob)

Count the number of parent jobs for a given `job`.
"""
countparents(job::AbstractJob) = length(job.parents)

"""
    countchildren(job::AbstractJob)

Count the number of child jobs for a given `job`.
"""
countchildren(job::AbstractJob) = length(job.children)
