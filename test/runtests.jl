using EasyJobs
using Test

@testset "EasyJobs.jl" begin
    include("parallel.jl")
    include("async.jl")
    include("operations.jl")
end
