# See https://docs.julialang.org/en/v1/manual/types/#man-custom-pretty-printing
function Base.show(io::IO, job::AbstractJob)
    if get(io, :compact, false)
        print(
            IOContext(io, :limit => true, :compact => true), summary(job), '(', job.id, ')'
        )
    else
        print(io, summary(job), '(', job.id, "), ", job.core)
    end
end
function Base.show(io::IO, ::MIME"text/plain", job::AbstractJob)
    println(io, summary(job))
    println(io, ' ', "id: ", job.id)
    if !isempty(job.description)
        print(io, ' ', "description: ")
        show(io, job.description)
        println(io)
    end
    print(io, ' ', "core: ")
    printf(io, job.core)
    print(io, '\n', ' ', "status: ")
    printstyled(io, getstatus(job); bold=true)
    if !ispending(job)
        println(io, '\n', ' ', "from: ", format(starttimeof(job), "HH:MM:SS.s, mm/dd/yyyy"))
        if isrunning(job)
            print(io, " still running...")
        else
            println(io, ' ', "to: ", format(endtimeof(job), "HH:MM:SS.s, mm/dd/yyyy"))
            print(io, ' ', "used: ", timecostof(job))
        end
    end
end

function printf(io::IO, think::Think)
    print(io, think.callable, '(')
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
        print(io, ' ', last(keys(kwargs)), '=', last(values(kwargs)))
        print(io, ')')
    end
end
