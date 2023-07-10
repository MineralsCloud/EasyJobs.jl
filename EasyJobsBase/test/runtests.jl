using EasyJobsBase
using Test

@testset "EasyJobsBase.jl" begin
    include("run.jl")
    include("parallel.jl")
    include("internals.jl")
    include("operations.jl")
end
