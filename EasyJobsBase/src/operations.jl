export chain!, →, ←

"""
    chain!(x::Job, y::Job, z::Job...)

Chain multiple `Job`s one after another.
"""
function chain!(x::AbstractJob, y::AbstractJob)
    if x == y
        throw(ArgumentError("a job cannot be followed by itself!"))
    end
    if y in x.children && x in y.parents
        @info "You cannot chain the same jobs twice! No operations will be done!"
    elseif y in x.children || x in y.parents  # This should never happen
        error("Only one job is linked to the other, something is wrong!")
    else
        push!(x.children, y)
        push!(y.parents, x)
    end
    return x
end
chain!(x::AbstractJob, y::AbstractJob, z::AbstractJob...) = foldr(chain!, (x, y, z...))
# function chain!(x::DependentJob, y::DependentJob)
#     chain!(x, y)
#     y.strict = true
#     return x
# end
# function chain!(x::ArgDependentJob, y::ArgDependentJob)
#     chain!(x, y)
#     push!(y.args_from, x)
#     return x
# end
"""
    →(x, y)

Chain two `Job`s.
"""
→(x::AbstractJob, y::AbstractJob) = chain!(x, y)
"""
    ←(y, x)

Chain two `Job`s reversely.
"""
←(y::AbstractJob, x::AbstractJob) = x → y
