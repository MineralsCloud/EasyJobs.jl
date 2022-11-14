```@meta
CurrentModule = EasyJobsBase
```

# Library

```@contents
Pages = ["public.md"]
```

```@meta
CurrentModule = EasyJobsBase.Thunks
```

## `Thunks` module

```@docs
Thunk
ErredResult
reify!
getresult(::Thunk)
```

```@meta
CurrentModule = EasyJobsBase
DocTestSetup = quote
    using EasyJobsBase
    using EasyJobsBase: Job
end
```

## `Jobs` module

```@docs
SimpleJob
getresult(::Job)
getstatus(::Job)
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
run!(::Job)
interrupt!
ntimes
```
