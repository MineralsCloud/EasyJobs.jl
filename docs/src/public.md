```@meta
CurrentModule = EasyJobs
```

# Library

```@contents
Pages = ["public.md"]
```

```@meta
CurrentModule = EasyJobs.Thunks
```

## `Thunks` module

```@docs
Thunk
ErredResult
reify!
getresult(::Thunk)
```

```@meta
CurrentModule = EasyJobs
DocTestSetup = quote
    using EasyJobs
    using EasyJobs: AbstractJob
end
```

## `Jobs` module

```@docs
SimpleJob
getresult(::AbstractJob)
getstatus
ispending
isrunning
isexited
issucceeded
isfailed
isinterrupted
pendingjobs
runningjobs
exitedjobs
succeededjobs
failedjobs
interruptedjobs
createdtime
starttime
stoptime
elapsed
description
run!
interrupt!
queue
query
ntimes
```
