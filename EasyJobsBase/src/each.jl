export eachparent, eachchild

struct EachParent{T<:AbstractJob}
    job::T
end
struct EachChild{T<:AbstractJob}
    job::T
end

eachparent(job::AbstractJob) = EachParent(job)

eachchild(job::AbstractJob) = EachChild(job)

Base.iterate(iter::EachParent) = iterate(iter.job.parents)
Base.iterate(iter::EachParent, state) = iterate(iter.job.parents, state)
Base.iterate(iter::EachChild) = iterate(iter.job.children)
Base.iterate(iter::EachChild, state) = iterate(iter.job.children, state)

Base.eltype(iter::EachParent) = eltype(iter.job.parents)
Base.eltype(iter::EachChild) = eltype(iter.job.children)

Base.length(iter::EachParent) = length(iter.job.parents)
Base.length(iter::EachChild) = length(iter.job.children)
