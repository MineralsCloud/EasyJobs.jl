```@meta
CurrentModule = EasyJobsBase
```

# API Reference

## Public API

```@docs
Job
chain!
→
←
run!
execute!
kill!
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

```@docs
Executor
launch!
singlerun!
```
