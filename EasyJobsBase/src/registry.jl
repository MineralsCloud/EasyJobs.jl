export initialize!, isexecuted

const JOB_REGISTRY = Dict{Job,Union{Nothing,Task}}()

function initialize!()
    empty!(JOB_REGISTRY)
    return nothing
end

isexecuted(job::Job) = job in keys(JOB_REGISTRY)
