using EasyJobs.Thunks

@testset "Test running `SimpleJob`s" begin
    function f₁()
        println("Start job `i`!")
        return sleep(5)
    end
    function f₂(n)
        println("Start job `j`!")
        sleep(n)
        return exp(2)
    end
    function f₃(n)
        println("Start job `k`!")
        return sleep(n)
    end
    function f₄()
        println("Start job `l`!")
        return run(`sleep 3`)
    end
    function f₅(n, x)
        println("Start job `m`!")
        sleep(n)
        return sin(x)
    end
    function f₆(n; x=1)
        println("Start job `n`!")
        sleep(n)
        cos(x)
        return run(`pwd` & `ls`)
    end
    i = SimpleJob(Thunk(f₁, ()); user="me", description="i")
    j = SimpleJob(Thunk(f₂, 3); user="he", description="j")
    k = SimpleJob(Thunk(f₃, 6); description="k")
    l = SimpleJob(Thunk(f₄, ()); description="l", user="me")
    m = SimpleJob(Thunk(f₅, 3, 1); description="m")
    n = SimpleJob(Thunk(f₆, 1; x=3); user="she", description="n")
    for job in (i, j, k, l, m, n)
        run!(job)
    end
end
