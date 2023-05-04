export chain!, →, ←

"""
    chain!(x::AbstractJob, y::AbstractJob, z::AbstractJob...)

Chain multiple `AbstractJob`s one after another.
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
"""
    →(x, y)

Chain two `AbstractJob`s.
"""
→(x::AbstractJob, y::AbstractJob) = chain!(x, y)
"""
    ←(y, x)

Chain two `AbstractJob`s reversely.
"""
←(y::AbstractJob, x::AbstractJob) = x → y
