export chain!, chain_succeeded!, →, ←, ↣, ↢

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

function chain_succeeded!(x::AbstractJob, y::Union{ConditionalJob,ArgDependentJob})
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
        y.skip_incomplete = true
    end
    return x
end
chain_succeeded!(x::AbstractJob, y::AbstractJob, z::AbstractJob...) =
    foldr(chain_succeeded!, (x, y, z...))
↣(x::AbstractJob, y::AbstractJob) = chain_succeeded!(x, y)
↢(y::AbstractJob, x::AbstractJob) = x ↣ y

# See https://github.com/JuliaLang/julia/blob/70c873e/base/number.jl#L279-L280
Base.iterate(x::AbstractJob) = (x, nothing)
Base.iterate(::AbstractJob, ::Any) = nothing

# See https://github.com/JuliaLang/julia/blob/70c873e/base/number.jl#L92
Base.IteratorSize(::Type{<:AbstractJob}) = Base.HasShape{0}()

# See https://github.com/JuliaLang/julia/blob/70c873e/base/number.jl#L84
Base.eltype(::Type{T}) where {T<:AbstractJob} = T

# See https://github.com/JuliaLang/julia/blob/70c873e/base/number.jl#L87
Base.length(::AbstractJob) = 1

# See https://github.com/JuliaLang/julia/blob/70c873e/base/number.jl#L80-L81
Base.size(::AbstractJob) = ()
Base.size(::AbstractJob, dim::Integer) = dim < 1 ? throw(BoundsError()) : 1

# See https://github.com/JuliaLang/julia/blob/70c873e/base/number.jl#L282
Base.in(x::AbstractJob, y::AbstractJob) = x == y
