using Thinkers

@testset "Test running a `Job` multiple times" begin
    function f()
        n = rand(1:5)
        n < 5 ? error("not the number we want!") : return n
    end
    i = Job(Thunk(f); username="me", name="i")
    run!(i; maxattempts=10, interval=3, wait=true)
    count = countexecution(i)
    @test 1 <= count <= 10
    run!(i; maxattempts=10, interval=3, wait=true)
    @test 1 <= countexecution(i) <= 20
end

# See https://github.com/MineralsCloud/EasyJobsBase.jl/pull/44
@testset "Test `singlerun!` only runs once per attempt" begin
    arr = []
    function f(A)
        push!(A, 1)
        return error("an error occurred!")
    end
    i = Job(Thunk(f, arr); username="me", name="i")
    task = run!(i; maxattempts=5, interval=1, wait=false)
    wait(task)
    @test countexecution(i) == 5
    @test length(arr) == 5  # It proves `singlerun!` only runs once per attempt
end

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
    @testset "No dependency" begin
        i = Job(Thunk(f₁); username="me", name="i")
        j = Job(Thunk(f₂, 3); username="he", name="j")
        k = Job(Thunk(f₃, 6); name="k")
        l = Job(Thunk(f₄); name="l", username="me")
        m = Job(Thunk(f₅, 3, 1); name="m")
        n = Job(Thunk(f₆, 1; x=3); username="she", name="n")
        for job in (i, j, k, l, m, n)
            run!(job; wait=true)
            @test issucceeded(job)
        end
    end
    @testset "Related jobs" begin
        i = Job(Thunk(f₁); username="me", name="i")
        j = Job(Thunk(f₂, 3); username="he", name="j")
        k = Job(Thunk(f₃, 6); name="k")
        l = Job(Thunk(f₄); name="l", username="me")
        m = Job(Thunk(f₅, 3, 1); name="m")
        n = Job(Thunk(f₆, 1; x=3); username="she", name="n")
        i .→ [j, k] .→ [l, m] .→ n
        @assert isempty(i.parents)
        @assert i.children == Set([j, k])
        @assert j.parents == Set([i])
        @assert j.children == Set([l])
        @assert k.parents == Set([i])
        @assert k.children == Set([m])
        @assert l.parents == Set([j])
        @assert l.children == Set([n])
        @assert m.parents == Set([k])
        @assert m.children == Set([n])
        @assert n.parents == Set([l, m])
        @assert isempty(n.children)
        for job in (i, j, k, l, m, n)
            run!(job; wait=true)
            @test issucceeded(job)
        end
    end
end

@testset "Test running `ConditionalJob`s" begin
    f₁(x) = write("file", string(x))
    f₂() = read("file", String)
    h = Job(Thunk(sleep, 3); username="me", name="h")
    i = Job(Thunk(f₁, 1001); username="me", name="i")
    j = ConditionalJob(Thunk(map, f₂); username="he", name="j")
    [h, i] .→ j
    @test !shouldrun(j)
    @test_throws AssertionError run!(j)
    @test getresult(j) === nothing
    run!(h; wait=true)
    @test !shouldrun(j)
    @test_throws AssertionError run!(j)
    @test getresult(j) === nothing
    run!(i; wait=true)
    run!(j; wait=true)
    @test getresult(j) == Some("1001")
end

@testset "Test running `ArgDependentJob`s" begin
    f₁(x) = x^2
    f₂(y) = y + 1
    f₃(z) = z / 2
    i = Job(Thunk(f₁, 5); username="me", name="i")
    j = ArgDependentJob(Thunk(f₂, 3), false; username="he", name="j")
    k = ArgDependentJob(Thunk(f₃, 6), false; username="she", name="k")
    i → j → k
    @test !shouldrun(j)
    @test !shouldrun(k)
    run!(i; wait=true)
    @test getresult(i) == Some(25)
    @test shouldrun(j)
    @test !shouldrun(k)
    run!(j; wait=true)
    @test getresult(j) == Some(26)
    @test shouldrun(k)
    run!(k; wait=true)
    @test getresult(k) == Some(13.0)
end

@testset "Test running a `ArgDependentJob` with more than one parent" begin
    f₁(x) = x^2
    f₂(y) = y + 1
    f₃(z) = z / 2
    f₄(iter) = sum(iter)
    i = Job(Thunk(f₁, 5); username="me", name="i")
    j = Job(Thunk(f₂, 3); username="he", name="j")
    k = Job(Thunk(f₃, 6); username="she", name="k")
    l = ArgDependentJob(Thunk(f₄, ()); username="she", name="me")
    (i, j, k) .→ l
    @test !shouldrun(l)
    map((i, j, k)) do job
        run!(job; wait=true)
    end
    @test shouldrun(l)
    run!(l; wait=true)
    @test getresult(i) == Some(25)
    @test getresult(j) == Some(4)
    @test getresult(k) == Some(3.0)
    @test getresult(l) == Some(32.0)
    @testset "Change `skip_incomplete` to `false`" begin
        i = Job(Thunk(f₁, 5); username="me", name="i")
        j = Job(Thunk(f₂, 3); username="he", name="j")
        k = Job(Thunk(f₃, 6); username="she", name="k")
        l = ArgDependentJob(Thunk(f₄, ()), false; username="she", name="l")
        (i, j, k) .→ l
        @test !shouldrun(l)
        @test_throws AssertionError run!(l)
    end
end
