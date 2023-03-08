using Test
using Dare
using JuMP

include("utils.jl")

# Simple one source - one load model that optimiser can solve feasibly
CM = [
        0 1
       -1 0
    ]


@testset "Optimizer status: FEASIBLE" begin

    parameters = PopulateParams(100e3, 0.95)

    env = SimEnv(ts=0.0001, CM=CM, parameters=parameters, t_end=0.1, verbosity=2, action_delay=1)
    # Dare.optimizer_status

    @test Dare.optimizer_status["termination_status"] == LOCALLY_SOLVED  #add other feasible enums from https://jump.dev/JuMP.jl/stable/moi/reference/models/#MathOptInterface.TerminationStatusCode
    @test Dare.optimizer_status["primal_status"] == FEASIBLE_POINT  # add other feasible status from above

end

@testset "Optimizer status: INFEASIBLE" begin

    parameters = PopulateParams(230e3, 0.95)
    
    env = SimEnv(ts=0.0001, CM=CM, parameters=parameters, t_end=0.1, verbosity=2, action_delay=1)
    # Dare.optimizer_status

    @test Dare.optimizer_status["termination_status"] == LOCALLY_INFEASIBLE  #add other feasible enums from https://jump.dev/JuMP.jl/stable/moi/reference/models/#MathOptInterface.TerminationStatusCode
    @test Dare.optimizer_status["primal_status"] == INFEASIBLE_POINT  # add other feasible status from above

end
   

@testset "Optimizer status: NEARLY_FEASIBLE" begin

    parameters = PopulateParams(230e3, 0.95)
    pop!(parameters, "load")
    parameters["load"] = Any[
                            Dict{Any, Any}("impedance" => "RL", "R" => 1.5, "L" => 1e-3),
                        ]

    env = SimEnv(ts=0.0001, CM=CM, parameters=parameters, t_end=0.1, verbosity=2, action_delay=1)
    # Dare.optimizer_status

    @test Dare.optimizer_status["termination_status"] == ALMOST_LOCALLY_SOLVED  
    @test Dare.optimizer_status["primal_status"] == NEARLY_FEASIBLE_POINT  

end



    
    
