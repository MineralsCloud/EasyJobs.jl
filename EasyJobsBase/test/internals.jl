@testset "Test `execute!` returns the same `Job` with differernt statuses of the `Job` for `AsyncExecutor`" begin
    f₁(x) = x^2
    i = Job(Thunk(f₁, 5); username="me", name="i")
    task1 = run!(i; wait=true)
    task2 = run!(i; wait=true)
    @test task1 != task2
    @test fetch(task1) == fetch(task2)
end
