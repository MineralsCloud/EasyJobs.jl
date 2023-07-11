using Distributed: addprocs, myid, @everywhere
addprocs(3)
@everywhere using Thinkers
@everywhere using EasyJobsBase
@everywhere using EasyJobsBase: ParallelExecutor, runonce!

@testset "Test `execute!` for `ParallelExecutor`" begin
    i = Job(Thunk(myid); username="me", name="i")
    exec = ParallelExecutor(2; wait=true)
    task1 = execute!(i, exec)
    i′ = fetch(task1)
    @test ispending(i)  # `i` is not executed
    @test issucceeded(i′)  # `i′` is a copy of `i` and was executed
    @test getresult(i′) == Some(2)
    @test i′ != i
    @testset "Test `execute!` returns a different `Job` for `ParallelExecutor`" begin
        task2 = execute!(i, exec)
        @test task1 != task2
        @test i′ != fetch(task2)
    end
    @testset "Test `execute!` returns the same `Job` when succeeded for `ParallelExecutor`" begin
        task2 = execute!(i′, exec)
        @test i′ == fetch(task2)
        task3 = execute!(i′, exec)
        @test i′ == fetch(task3)
    end
end

@testset "Test `execute!` returns the same `Job` for `ParallelExecutor` on the same worker" begin
    f₁(x) = x^2
    i = Job(Thunk(f₁, 5); username="me", name="i")
    exec = ParallelExecutor(1; wait=true)
    task1 = execute!(i, exec)
    newjob = fetch(task1)
    @test newjob == i
    @test getresult(newjob) == Some(25)
    @testset "Test `execute!` returns the same `Job` when succeeded for `ParallelExecutor`" begin
        task2 = execute!(i, exec)
        @test task1 != task2
        @test i == fetch(task2)
    end
end
