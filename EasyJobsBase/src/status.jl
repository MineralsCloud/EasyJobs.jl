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
    getstatus(job::AbstractJob)

Get the current status of `job`.
"""
getstatus(job::AbstractJob) = job.status

"""
    ispending(job::AbstractJob)

Test if `job` is still pending.
"""
ispending(job::AbstractJob) = getstatus(job) === PENDING

"""
    isrunning(job::AbstractJob)

Test if `job` is running.
"""
isrunning(job::AbstractJob) = getstatus(job) === RUNNING

"""
    isexited(job::AbstractJob)

Test if `job` has exited.
"""
isexited(job::AbstractJob) = getstatus(job) in (SUCCEEDED, FAILED, INTERRUPTED)

"""
    issucceeded(job::AbstractJob)

Test if `job` was successfully run.
"""
issucceeded(job::AbstractJob) = getstatus(job) === SUCCEEDED

"""
    isfailed(job::AbstractJob)

Test if `job` failed during running.
"""
isfailed(job::AbstractJob) = getstatus(job) === FAILED

"""
    isinterrupted(job::AbstractJob)

Test if `job` was interrupted during running.
"""
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
