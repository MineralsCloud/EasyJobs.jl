module Thunks

using Dates: Period, Second

export Thunk, TimeLimitedThunk, reify!, getresult

# See https://github.com/goropikari/Timeout.jl/blob/c7df3cd/src/Timeout.jl#L4
struct TimeoutException <: Exception end

"Capture errors and stack traces from a running `Thunk`."
struct ErredResult{T}
    thrown::T
    stacktrace::Base.StackTraces.StackTrace
end

abstract type Think end

# Idea from https://github.com/tbenst/Thunks.jl/blob/ff2a553/src/core.jl#L11-L20
"""
    Thunk(::Function, args::Tuple, kwargs::NamedTuple)
    Thunk(::Function, args...; kwargs...)
    Thunk(::Function)

Hold a `Function` and its arguments for lazy evaluation. Use `reify!` to evaluate.

# Examples
```jldoctest
julia> using EasyJobsBase.Thunks

julia> a = Thunk(x -> 3x, 4);

julia> reify!(a)
Some(12)

julia> b = Thunk(+, 4, 5);

julia> reify!(b)
Some(9)

julia> c = Thunk(sleep)(1);

julia> getresult(c)  # `c` has not been evaluated

julia> reify!(c)  # `c` has been evaluated
Some(nothing)

julia> f(args...; kwargs...) = collect(kwargs);

julia> d = Thunk(f)(1, 2, 3; x=1.0, y=4, z="5");

julia> reify!(d)
Some(Pair{Symbol, Any}[:x => 1.0, :y => 4, :z => "5"])

julia> e = Thunk(sin, "1");  # Catch errors

julia> reify!(e);
```
"""
mutable struct Thunk <: Think
    f
    args::Tuple
    kwargs::NamedTuple
    evaluated::Bool
    erred::Bool
    result::Union{Some,Nothing}
    function Thunk(f, args::Tuple, kwargs::NamedTuple=NamedTuple())
        return new(f, args, kwargs, false, false, nothing)
    end
end
Thunk(f, args...; kwargs...) = Thunk(f, args, NamedTuple(kwargs))
Thunk(f) = (args...; kwargs...) -> Thunk(f, args, NamedTuple(kwargs))

mutable struct TimeLimitedThunk <: Think
    time_limit::Period
    f
    args::Tuple
    kwargs::NamedTuple
    evaluated::Bool
    erred::Bool
    result::Union{Some,Nothing}
    function TimeLimitedThunk(time_limit, f, args::Tuple, kwargs::NamedTuple=NamedTuple())
        return new(time_limit, f, args, kwargs, false, false, nothing)
    end
end
function TimeLimitedThunk(time_limit, f, args...; kwargs...)
    return TimeLimitedThunk(time_limit, f, args, NamedTuple(kwargs))
end
function TimeLimitedThunk(time_limit, f)
    return (args...; kwargs...) -> TimeLimitedThunk(time_limit, f, args, NamedTuple(kwargs))
end
function TimeLimitedThunk(time_limit)
    return (f, args...; kwargs...) ->
        TimeLimitedThunk(time_limit, f, args, NamedTuple(kwargs))
end

# See https://github.com/tbenst/Thunks.jl/blob/ff2a553/src/core.jl#L113-L123
"""
    reify!(thunk::Thunk)

Reify a `Thunk` into a value.

Compute the value of the expression.
Walk through the `Thunk`'s arguments and keywords, recursively evaluating each one,
and then evaluating the `Thunk`'s function with the evaluated arguments.

See also [`Thunk`](@ref).
"""
reify!(thunk::Thunk) = thunk.evaluated ? getresult(thunk) : reify_core!(thunk)
# See https://github.com/goropikari/Timeout.jl/blob/c7df3cd/src/Timeout.jl#L18-L45
function reify!(thunk::TimeLimitedThunk)
    istimedout = Channel{Bool}(1)
    main = @async begin
        reify_core!(thunk)
        put!(istimedout, false)
    end
    timer = @async begin
        sleep(thunk.time_limit)
        put!(istimedout, true)
        Base.throwto(main, TimeoutException())
    end
    fetch(istimedout)  # You do not know which of `main` and `timer` finishes first, so you need `istimedout`.
    close(istimedout)
    _kill(main)  # Kill all `Task`s after done.
    _kill(timer)
    return thunk.result
end
function reify_core!(think)
    try
        think.result = Some(think.f(think.args...; think.kwargs...))
    catch e
        think.erred = true
        s = stacktrace(catch_backtrace())
        think.result = Some(ErredResult(e, s))
    finally
        think.evaluated = true
    end
end

"""
    getresult(thunk::Thunk)

Get the result of a `Thunk`. If `thunk` has not been evaluated, return `nothing`, else return a `Some`-wrapped result.
"""
getresult(think::Think) = think.evaluated ? think.result : nothing

# See https://github.com/goropikari/Timeout.jl/blob/c7df3cd/src/Timeout.jl#L6-L11
function _kill(task)
    try
        schedule(task, InterruptException(); error=true)
    catch
    end
end

function Base.show(io::IO, thunk::Thunk)
    if get(io, :compact, false) || get(io, :typeinfo, nothing) == typeof(thunk)
        Base.show_default(IOContext(io, :limit => true), thunk)  # From https://github.com/mauro3/Parameters.jl/blob/ecbf8df/src/Parameters.jl#L556
    else
        println(io, summary(thunk))
        print(io, ' ', "def: ")
        printfunc(io, thunk)
        println(io)
        println(io, " evaluated: ", thunk.evaluated)
        result = thunk.result
        if result isa ErredResult
            println(io, " result: ", result.thrown)
        else
            println(io, " result: ", result)
        end
    end
end
function Base.show(io::IO, thunk::TimeLimitedThunk)
    if get(io, :compact, false) || get(io, :typeinfo, nothing) == typeof(thunk)
        Base.show_default(IOContext(io, :limit => true), thunk)  # From https://github.com/mauro3/Parameters.jl/blob/ecbf8df/src/Parameters.jl#L556
    else
        println(io, summary(thunk))
        print(io, ' ', "def: ")
        printfunc(io, thunk)
        println(io)
        println(io, " time limit: ", thunk.time_limit)
        println(io, " evaluated: ", thunk.evaluated)
        result = thunk.result
        if result isa ErredResult
            println(io, " result: ", result.thrown)
        else
            println(io, " result: ", result)
        end
    end
end

function printfunc(io::IO, think::Think)
    print(io, think.f, '(')
    args = think.args
    if length(args) > 0
        for v in args[1:(end - 1)]
            print(io, v, ", ")
        end
        print(io, args[end])
    end
    kwargs = think.kwargs
    if isempty(kwargs)
        print(io, ')')
    else
        print(io, ";")
        for (k, v) in zip(keys(kwargs)[1:(end - 1)], Tuple(kwargs)[1:(end - 1)])
            print(io, ' ', k, '=', v, ",")
        end
        print(io, ' ', keys(kwargs)[end], '=', kwargs[end])
        print(io, ')')
    end
end

function Base.show(io::IO, erred::ErredResult)
    println(io, summary(erred))
    if erred.thrown isa ErrorException
        show(io, erred.thrown)
    else
        showerror(io, erred.thrown)
    end
    Base.show_backtrace(io, erred.stacktrace)
    return nothing
end

end
