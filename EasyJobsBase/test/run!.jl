using EasyJobsBase.Thunks

@testset "Test running `Job`s" begin
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
    i = Job(Thunk(f₁, ()); username="me", name="i")
    j = Job(Thunk(f₂, 3); username="he", name="j")
    k = Job(Thunk(f₃, 6); name="k")
    l = Job(Thunk(f₄, ()); name="l", username="me")
    m = Job(Thunk(f₅, 3, 1); name="m")
    n = Job(Thunk(f₆, 1; x=3); username="she", name="n")
    for job in (i, j, k, l, m, n)
        run!(job)
    end
end

@testset "Test running `PipeJob`s" begin
    f₁(x) = x^2
    f₂(y) = y + 1
    f₃(z) = z / 2
    i = Job(Thunk(f₁, 5); username="me", name="i")
    j = PipeJob(Thunk(f₂, 3); username="he", name="j")
    k = PipeJob(Thunk(f₃, 6); username="she", name="k")
    i → j → k
    @test_throws AssertionError run!(j)
    run!(i)
    wait(i)
    @test getresult(i) == Some(25)
    @test_throws AssertionError run!(k)
    run!(j)
    wait(j)
    @test getresult(j) == Some(26)
    run!(k)
    wait(k)
    @test getresult(k) == Some(13.0)
end

@testset "Test running a `PipeJob` with more than one parents" begin
    f₁(x) = x^2
    f₂(y) = y + 1
    f₃(z) = z / 2
    f₄(iter) = sum(iter)
    i = Job(Thunk(f₁, 5); username="me", name="i")
    j = Job(Thunk(f₂, 3); username="he", name="j")
    k = Job(Thunk(f₃, 6); username="she", name="k")
    l = PipeJob(Thunk(f₄, ()); username="she", name="me")
    for job in (i, j, k)
        job → l
    end
    @test_throws AssertionError run!(l)
    for job in (i, j, k)
        run!(job)
        wait(job)
    end
    run!(l)
    wait(l)
    @test getresult(i) == Some(25)
    @test getresult(j) == Some(4)
    @test getresult(k) == Some(3.0)
    @test getresult(l) == Some(32.0)
end
