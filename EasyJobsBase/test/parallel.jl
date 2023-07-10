using Distributed: addprocs, myid, @everywhere
addprocs(3)
@everywhere using Thinkers
@everywhere using EasyJobsBase
@everywhere using EasyJobsBase: ParallelExecutor, runonce!

@testset "Test `execute!` returns different `Job`s for `ParallelExecutor`" begin
    i = Job(Thunk(myid); username="me", name="i")
    exec = ParallelExecutor(2; wait=true)
    task1 = execute!(i, exec)
    newjob = fetch(task1)
    @test newjob != i
    @test getresult(newjob) == Some(2)
    @testset "Test `execute!` returns different `Job`s with differernt statuses of the `Job` for `ParallelExecutor`" begin
        task2 = execute!(i, exec)
        @test task1 != task2
        @test fetch(task1) != fetch(task2)
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
    @testset "Test `execute!` returns the same `Job` with differernt statuses of the `Job` for `ParallelExecutor`" begin
        task2 = execute!(i, exec)
        @test task1 != task2
        @test i == fetch(task2)
    end
end
