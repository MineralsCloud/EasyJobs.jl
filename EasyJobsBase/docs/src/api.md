```@meta
CurrentModule = EasyJobsBase
```

# API Reference

```@contents
Pages = ["api.md"]
Depth = 2
```

## Public API

```@docs
Job
chain!
→
←
run!
execute!
kill!
wait
getstatus
ispending
isrunning
isexited
issucceeded
isfailed
isinterrupted
listpending
listrunning
listexited
listsucceeded
listfailed
listinterrupted
countexecution
descriptionof
creationtimeof
starttimeof
endtimeof
timecostof
getresult
```

## Private API

The functions and types mentioned here are considered part of the private API and are not
intended for direct use by users. They may be modified, moved, or removed without notice and
are primarily meant for internal use within the package. Using them directly may result in
unexpected errors or compatibility issues in your code.

```@docs
Executor
launch!
singlerun!
```
