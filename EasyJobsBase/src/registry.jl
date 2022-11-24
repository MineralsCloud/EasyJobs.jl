export initialize!, isexecuted

const JOB_REGISTRY = Dict{AbstractJob,Union{Nothing,Task}}()

function initialize!()
    empty!(JOB_REGISTRY)
    return nothing
end

isexecuted(job::AbstractJob) = job in keys(JOB_REGISTRY)
