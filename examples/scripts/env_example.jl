using Dare
#using ReinforcementLearning
CM = [0. 1.
    -1. 0.]

S_source = 200e3

S_load = 3e6
pf_load = 1
v_rms = 230
R_load, L_load, X, Z = Parallel_Load_Impedance(S_load, pf_load, v_rms)

parameters = Dict{Any, Any}(
        "source" => Any[
                        Dict{Any, Any}("pwr" => S_source, "control_type" => "classic", "mode" => "Step", "fltr" => "LC", "i_limit" => 1e4, "v_limit" => 1e4,),
                        ],
        "load"   => Any[
                        Dict{Any, Any}("impedance" => "RLC", "R" => R_load, "v_limit" => 1e4, "i_limit" => 1e4)
                        ],
        "grid" => Dict{Any, Any}("fs"=>1e4, "phase"=>3, "v_rms"=>230, "f_grid" => 50, "ramp_end"=>0.0)
    )


#env = SimEnv(CM = CM, parameters = parameters, verbosity = 2)
env = SimEnv(num_sources = 2, num_loads = 1)

#env.nc.parameters["cable"][1]["i_limit"] = 10e3



Multi_Agent = setup_agents(env)
Source = Multi_Agent.agents["classic"]["policy"].policy.Source

#_______________________________________________________________________________
# running the time simulation

#hook = simulate(Multi_Agent, env)

#hook = data_hook(collect_state_ids = env.state_ids,
#                collect_action_ids = env.action_ids
#                #collect_sources  = [1]  # alternative
#                );

states_to_plot = ["source1_v_C_filt_a", "source1_v_C_filt_b", "source1_v_C_filt_c"]

hook = data_hook(collect_state_ids = states_to_plot)

simulate(Multi_Agent, env, hook=hook)

#_______________________________________________________________________________
# Plotting

plot_hook_results(hook = hook,
                    states_to_plot  = states_to_plot,
                    actions_to_plot = [])
#env.state_ids

#env = SimEnv(num_sources = 1, num_loads = 1)

#reset!(env)
#env([1])
#for _ in 1:2
#    env([1,1,1])
#end

#println(env.done)
#=
hook = data_hook(collect_state_ids = env.state_ids,
                collect_action_ids = env.action_ids
                #collect_sources  = [1]  # alternative
                );
                =#

#println(env.nc.parameters["cable"][1])
#=
Power_System_Dynamics(env, hook, num_episodes = 1)

plot_hook_results(hook = hook,
                    episode = 1,
                    states_to_plot  = env.state_ids,
                    actions_to_plot = env.action_ids)
=#
