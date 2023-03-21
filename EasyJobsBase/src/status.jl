export getstatus,
    ispending,
    isrunning,
    isexited,
    issucceeded,
    isfailed,
    isinterrupted,
    listpending,
    listrunning,
    listexited,
    listsucceeded,
    listfailed,
    listinterrupted

"""
    getstatus(x::Job)

Get the current status of a `Job`.
"""
getstatus(job::AbstractJob) = job.status

"Test if the `Job` is still pending."
ispending(job::AbstractJob) = getstatus(job) === PENDING

"Test if the `Job` is running."
isrunning(job::AbstractJob) = getstatus(job) === RUNNING

"Test if the `Job` has exited."
isexited(job::AbstractJob) = getstatus(job) in (SUCCEEDED, FAILED, INTERRUPTED)

"Test if the `Job` was successfully run."
issucceeded(job::AbstractJob) = getstatus(job) === SUCCEEDED

"Test if the `Job` failed during running."
isfailed(job::AbstractJob) = getstatus(job) === FAILED

"Test if the `Job` was interrupted during running."
isinterrupted(job::AbstractJob) = getstatus(job) === INTERRUPTED

"""
    listpending(jobs)

Filter only the pending jobs in a sequence of `Job`s.
"""
listpending(jobs) = filter(ispending, jobs)

"""
listrunning(jobs)

Filter only the running jobs in a sequence of `Job`s.
"""
listrunning(jobs) = filter(isrunning, jobs)

"""
    listexited(jobs)

Filter only the exited jobs in a sequence of `Job`s.
"""
listexited(jobs) = filter(isexited, jobs)

"""
    listsucceeded(jobs)

Filter only the succeeded jobs in a sequence of `Job`s.
"""
listsucceeded(jobs) = filter(issucceeded, jobs)

"""
    listfailed(jobs)

Filter only the failed jobs in a sequence of `Job`s.
"""
listfailed(jobs) = filter(isfailed, jobs)

"""
    listinterrupted(jobs)

Filter only the interrupted jobs in a sequence of `Job`s.
"""
listinterrupted(jobs) = filter(isinterrupted, jobs)
