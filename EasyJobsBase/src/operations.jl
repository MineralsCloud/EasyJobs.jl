export chain!,
    follow!, pipe!, thread!, fork!, converge!, spindle!, →, ←, ↠, ↞, ⇒, ⇐, ⇶, ⬱, ⇉, ⭃

"""
    chain(x::Job, y::Job, z::Job...)

Chain multiple `Job`s one after another.
"""
function chain!(x::AbstractJob, y::AbstractJob)
    if x == y
        throw(ArgumentError("a job cannot be followed by itself!"))
    else
        push!(x.children, y)
        push!(y.parents, x)
        return x
    end
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
    pipe(x::Job, y::Job, z::Job...)

Chain multiple jobs one after another, as well as
directing the returned value of one job to the input of another.
"""
function pipe!(x::AbstractJob, y::AbstractJob)
    chain!(x, y)
    y.args_from_previous = true
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
    thread(xs::AbstractVector{Job}, ys::AbstractVector{Job}, zs::AbstractVector{Job}...)

Chain multiple vectors of `Job`s, each `Job` in `xs` has a corresponding `Job` in `ys`.`
"""
function thread!(xs::AbstractVector{AbstractJob}, ys::AbstractVector{AbstractJob})
    if size(xs) != size(ys)
        throw(DimensionMismatch("`xs` and `ys` must have the same size!"))
    end
    for (x, y) in zip(xs, ys)
        chain!(x, y)
    end
    return xs
end
function thread!(
    xs::AbstractVector{AbstractJob},
    ys::AbstractVector{AbstractJob},
    zs::AbstractVector{AbstractJob}...,
)
    return foldr(thread!, (xs, ys, zs...))
end
"""
    ⇶(xs, ys)

Chain two vectors of `Job`s.
"""
⇶(xs::AbstractVector{AbstractJob}, ys::AbstractVector{AbstractJob}) = thread!(xs, ys)
"""
    ⬱(ys, xs)

Chain two vectors of `Job`s reversely.
"""
⬱(ys::AbstractVector{AbstractJob}, xs::AbstractVector{AbstractJob}) = xs ⇶ ys

"""
    fork(x::Job, ys::AbstractVector{Job})
    ⇉(x, ys)

Attach a group of parallel `Job`s (`ys`) to a single `Job` (`x`).
"""
function fork!(x::AbstractJob, ys::AbstractVector{AbstractJob})
    for y in ys
        chain!(x, y)
    end
    return x
end
const ⇉ = fork!

"""
    converge(xs::AbstractVector{Job}, y::Job)
    ⭃(xs, y)

Finish a group a parallel `Job`s (`xs`) by a single `Job` (`y`).
"""
function converge!(xs::AbstractVector{AbstractJob}, y::AbstractJob)
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
spindle!(x::AbstractJob, ys::AbstractVector{AbstractJob}, z::AbstractJob) = x ⇉ ys ⭃ z
