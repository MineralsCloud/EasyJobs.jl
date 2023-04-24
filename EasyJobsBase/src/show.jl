# See https://docs.julialang.org/en/v1/manual/types/#man-custom-pretty-printing
function Base.show(io::IO, job::AbstractJob)
    if get(io, :compact, false)
        print(
            IOContext(io, :limit => true, :compact => true), summary(job), '(', job.id, ')'
        )
    else
        print(io, summary(job), '(', job.id, "), ", job.def)
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
    print(io, ' ', "def: ")
    print(io, job.def)
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
