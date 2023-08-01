@testset "With `skip_incomplete` initially to `false` but use `↣`" begin
    @testset "With only one parent" begin
        f(x) = x^2
        g(iter) = sum(iter)
        i = Job(Thunk(error); username="me", name="i")
        l = ArgDependentJob(Thunk(g), false; username="me", name="l")
        i ↣ l
        @assert l.skip_incomplete
        @test !shouldrun(l)
        exec = run!(i)
        wait(exec)
        @test !shouldrun(l)
        @test_throws AssertionError run!(l)
        @test getresult(l) === nothing
    end
    @testset "With multiple parents" begin
        f(x) = x^2
        g(iter) = sum(iter)
        i = Job(Thunk(f, 5); username="me", name="i")
        j = Job(Thunk(error); username="he", name="j")
        k = Job(Thunk(error); username="she", name="k")
        l = ArgDependentJob(Thunk(g), false; username="me", name="l")
        (i, j, k) .↣ l
        @assert l.skip_incomplete
        @test !shouldrun(l)
        execs = map((i, j, k)) do job
            run!(job)
        end
        for exec in execs
            wait(exec)
        end
        @test shouldrun(l)
        exec = run!(l)
        wait(exec)
        @test getresult(l) == Some(25)
    end
end
