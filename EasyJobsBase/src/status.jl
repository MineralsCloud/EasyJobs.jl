export getstatus,
    ispending,
    isrunning,
    isexited,
    issucceeded,
    isfailed,
    listpending,
    listrunning,
    listexited,
    listsucceeded,
    listfailed,
    listinterrupted,
    setsucceeded!,
    setpending!,
    setfailed!

"""
    getstatus(job::AbstractJob)

Get the current status of the `job`.
"""
getstatus(job::AbstractJob) = job.status

"""
    ispending(job::AbstractJob)

Test if the `job` is still pending.
"""
ispending(job::AbstractJob) = getstatus(job) === PENDING

"""
    isrunning(job::AbstractJob)

Test if the `job` is running.
"""
isrunning(job::AbstractJob) = getstatus(job) === RUNNING

"""
    isexited(job::AbstractJob)

Test if the `job` has exited.
"""
isexited(job::AbstractJob) = getstatus(job) in (SUCCEEDED, FAILED, INTERRUPTED)

"""
    issucceeded(job::AbstractJob)

Test if the `job` was successfully run.
"""
issucceeded(job::AbstractJob) = getstatus(job) === SUCCEEDED

"""
    isfailed(job::AbstractJob)

Test if the `job` failed during running.
"""
isfailed(job::AbstractJob) = getstatus(job) in (FAILED, INTERRUPTED)

"""
    listpending(jobs)

Filter the pending jobs in a sequence of jobs.
"""
listpending(jobs) = Iterators.filter(ispending, jobs)

"""
    listrunning(jobs)

Filter the running jobs in a sequence of jobs.
"""
listrunning(jobs) = Iterators.filter(isrunning, jobs)

"""
    listexited(jobs)

Filter the exited jobs in a sequence of jobs.
"""
listexited(jobs) = Iterators.filter(isexited, jobs)

"""
    listsucceeded(jobs)

Filter the succeeded jobs in a sequence of jobs.
"""
listsucceeded(jobs) = Iterators.filter(issucceeded, jobs)

"""
    listfailed(jobs)

Filter the failed jobs in a sequence of jobs.
"""
listfailed(jobs) = Iterators.filter(isfailed, jobs)

"""
    listinterrupted(jobs)

Filter the interrupted jobs in a sequence of jobs.
"""
listinterrupted(jobs) = Iterators.filter(isinterrupted, jobs)

setsucceeded!(job::AbstractJob) = job.status = SUCCEEDED

setpending!(job::AbstractJob) = job.status = PENDING

setfailed!(job::AbstractJob) = job.status = FAILED
