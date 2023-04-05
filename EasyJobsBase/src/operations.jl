export chain!, follow!, pipe!, converge!, spindle!, →, ←, ↠, ↞, ⇒, ⇐, ⭃

"""
    chain(x::Job, y::Job, z::Job...)

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

function follow!(x::AbstractJob, y::AbstractJob)
    chain!(x, y)
    y.strict = true
    return x
end
follow!(x::AbstractJob, y::AbstractJob, z::AbstractJob...) = foldr(follow!, (x, y, z...))
↠(x::AbstractJob, y::AbstractJob) = follow!(x, y)
↞(y::AbstractJob, x::AbstractJob) = x ↠ y

"""
    pipe!(x::Job, y::Job, z::Job...)

Chain multiple jobs one after another, as well as
directing the returned value of one job to the input of another.
"""
function pipe!(x::AbstractJob, y::AbstractJob)
    chain!(x, y)
    push!(y.args_from, x)
    return x
end
pipe!(x::AbstractJob, y::AbstractJob, z::AbstractJob...) = foldr(pipe!, (x, y, z...))
"""
    ⇒(x, y)

"Pipe" two jobs together.
"""
⇒(x::AbstractJob, y::AbstractJob) = pipe!(x, y)
"""
    ⇐(x, y)

"Pipe" two jobs reversely.
"""
⇐(y::AbstractJob, x::AbstractJob) = x ⇒ y

"""
    converge(xs::AbstractVector{Job}, y::Job)
    ⭃(xs, y)

Finish a group a parallel `Job`s (`xs`) by a single `Job` (`y`).
"""
function converge!(xs::AbstractVector, y::AbstractJob)
    for x in xs
        chain!(x, y)
    end
    return xs
end
const ⭃ = converge!

"""
    spindle(x::Job, ys::AbstractVector{Job}, z::Job)

Start from a `Job` (`x`), followed by a series of `Job`s (`ys`), finished by a single `Job` (`z`).
"""
spindle!(x::AbstractJob, ys::AbstractVector, z::AbstractJob) = x ⇉ ys ⭃ z
