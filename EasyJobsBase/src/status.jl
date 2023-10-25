export getstatus,
    ispending,
    isrunning,
    isexited,
    issucceeded,
    isfailed,
    filterpending,
    filterrunning,
    filterexited,
    filtersucceeded,
    filterfailed,
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
isexited(job::AbstractJob) = getstatus(job) in (SUCCEEDED, FAILED)

"""
    issucceeded(job::AbstractJob)

Test if the `job` was successfully run.
"""
issucceeded(job::AbstractJob) = getstatus(job) === SUCCEEDED

"""
    isfailed(job::AbstractJob)

Test if the `job` failed during running.
"""
isfailed(job::AbstractJob) = getstatus(job) === FAILED

"""
    filterpending(jobs)

Filter the pending jobs in a sequence of jobs.
"""
filterpending(jobs) = Iterators.filter(ispending, jobs)

"""
    filterrunning(jobs)

Filter the running jobs in a sequence of jobs.
"""
filterrunning(jobs) = Iterators.filter(isrunning, jobs)

"""
    filterexited(jobs)

Filter the exited jobs in a sequence of jobs.
"""
filterexited(jobs) = Iterators.filter(isexited, jobs)

"""
    filtersucceeded(jobs)

Filter the succeeded jobs in a sequence of jobs.
"""
filtersucceeded(jobs) = Iterators.filter(issucceeded, jobs)

"""
    filterfailed(jobs)

Filter the failed jobs in a sequence of jobs.
"""
filterfailed(jobs) = Iterators.filter(isfailed, jobs)

setsucceeded!(job::AbstractJob) = job.status = SUCCEEDED

setpending!(job::AbstractJob) = job.status = PENDING

setfailed!(job::AbstractJob) = job.status = FAILED
