using Dare
using Test
using Logging
using CSV
using DataFrames
using Distributions

@testset "Classical_Controllers_Dynamics" begin

        #_______________________________________________________________________________
        # Network Parameters

        #-------------------------------------------------------------------------------
        # Time simulation

        Timestep = 100e-6  # time step, seconds ~ 100μs => 10kHz, 50μs => 20kHz, 20μs => 50kHz
        t_end    = 0.045     # total run time, seconds
        num_eps  = 3       # number of episodes to run

        #-------------------------------------------------------------------------------
        # Connectivity Matrix

        CM = [ 0. 0. 0. 1.
                0. 0. 0. 2.
                0. 0. 0. 3.
                -1. -2. -3. 0.]

        #-------------------------------------------------------------------------------
        # Cable Impedances

        cable_list = []

        cable = Dict()
        cable["R"]       = 0.208   # Ω, line resistance
        cable["L"]       = 0.00025 # H, line inductance
        cable["C"]       = 0.4e-3  # F, line capacitance
        cable["i_limit"] = 10e12   # A, line current limit

        push!(cable_list, cable, cable, cable)

        #-------------------------------------------------------------------------------
        # Sources

        #= Modes:
        1 -> "Swing" - voltage source without dynamics (i.e. an Infinite Bus)
        2 -> "PQ" - grid following controllable source/load (active and reactive Power)
        3 -> "Droop" - simple grid forming with power balancing
        4 -> "Synchronverter" - enhanced droop control
        =#

        source_list = []

        source = Dict()

        source["mode"]         = "PQ"
        source["control_type"] = "classic"

        source["fltr"]         = "LCL"  # Filter type

        source["pwr"]          = 100e3  # Rated Apparent Power, VA
        source["p_set"]        = 50e3   # Real Power Set Point, Watt
        source["q_set"]        = 10e3   # Imaginary Power Set Point, VAi

        source["v_pu_set"]     = 1.00   # Voltage Set Point, p.u.
        source["v_δ_set"]      = 0      # Voltage Angle, degrees
        source["vdc"]          = 800    # V

        source["std_asy"]      = 50e3   # Asymptotic Standard Deviation
        source["σ"]            = 0.0    # Brownian motion scale i.e. ∝ diffusion, volatility parameter
        source["Δt"]           = 0.02   # Time Step, seconds
        source["X₀"]           = 0      # Initial Process Values, Watt
        source["k"]            = 0      # Interpolation degree

        source["τv"]           = 0.002  # Time constant of the voltage loop, seconds
        source["τf"]           = 0.002  # Time constant of the frequency loop, seconds

        source["Observer"]     = true   # Discrete Luenberger Observer

        source["L1"]           = 0.0003415325753131024
        source["R1"]           = 0.06830651506262048
        source["L2"]           = 4.670680436888136e-5
        source["R2"]           = 0.009341360873776272
        source["R_C"]          = 0.17210810076926025
        source["C"]            = 0.00015412304086843381

        push!(source_list, source)

        source = Dict()

        source["mode"]         = "Droop"
        source["control_type"] = "classic"

        source["fltr"]         = "LC"   # Filter type

        source["pwr"]          = 150e3  # Rated Apparent Power, VA
        source["p_set"]        = 50e3   # Real Power Set Point, Watt
        source["q_set"]        = 10e3   # Imaginary Power Set Point, VAi

        source["v_pu_set"]     = 1.00   # Voltage Set Point, p.u.
        source["v_δ_set"]      = 0      # Voltage Angle, degrees
        source["vdc"]          = 800    # V

        source["std_asy"]      = 50e3   # Asymptotic Standard Deviation
        source["σ"]            = 0.0    # Brownian motion scale i.e. ∝ diffusion, volatility parameter
        source["Δt"]           = 0.02   # Time Step, seconds
        source["X₀"]           = 0      # Initial Process Values, Watt
        source["k"]            = 0      # Interpolation degree

        source["τv"]           = 0.002  # Time constant of the voltage loop, seconds
        source["τf"]           = 0.002  # Time constant of the frequency loop, seconds

        source["Observer"]     = true   # Discrete Luenberger Observer

        source["L1"]           = 0.0002276883835420683
        source["R1"]           = 0.04553767670841366
        source["R_C"]          = 0.006473167716474219
        source["C"]            = 0.00023118456130265068

        push!(source_list, source)

        source = Dict()

        source["mode"]         = "Synchronverter"
        source["control_type"] = "classic"

        source["fltr"]         = "LCL"  # Filter type

        source["pwr"]          = 100e3  # Rated Apparent Power, VA
        source["p_set"]        = 50e3   # Real Power Set Point, Watt
        source["q_set"]        = 10e3   # Imaginary Power Set Point, VAi

        source["v_pu_set"]     = 1.00   # Voltage Set Point, p.u.
        source["v_δ_set"]      = 0      # Voltage Angle, degrees
        source["vdc"]          = 800    # V

        source["std_asy"]      = 50e3   # Asymptotic Standard Deviation
        source["σ"]            = 0.0    # Brownian motion scale i.e. ∝ diffusion, volatility parameter
        source["Δt"]           = 0.02   # Time Step, seconds
        source["X₀"]           = 0      # Initial Process Values, Watt
        source["k"]            = 0      # Interpolation degree

        source["τv"]           = 0.002  # Time constant of the voltage loop, seconds
        source["τf"]           = 0.002  # Time constant of the frequency loop, seconds

        source["Observer"]     = true   # Discrete Luenberger Observer

        source["L1"]           = 0.0003415325753131024
        source["R1"]           = 0.06830651506262048
        source["L2"]           = 4.670680436888136e-5
        source["R2"]           = 0.009341360873776272
        source["R_C"]          = 0.17210810076926025
        source["C"]            = 0.00015412304086843381

        push!(source_list, source)

        #-------------------------------------------------------------------------------
        # Loads

        R_load, L_load, _, _ = Parallel_Load_Impedance(100e3, 0.6, 230)

        load_list = []
        load = Dict()

        load["impedance"] = "RL"
        load["R"] = R_load
        load["L"] = L_load
        load["i_limit"] = 10e12
        load["v_limit"] = 10e12

        push!(load_list, load)

        #-------------------------------------------------------------------------------
        # Network

        grid = Dict()

        grid["v_rms"] = 230
        grid["ramp_end"] = 0.04
        grid["process_start"] = 0.04
        grid["f_grid"] = 50
        grid["Δfmax"] = 0.005 # The drop (increase) in frequency that causes a 100% increase (decrease) in power
        grid["ΔEmax"] = 0.05 # The drop (increase) in rms voltage that causes a 100% increase (decrease) in reactive power (from nominal)

        #-------------------------------------------------------------------------------
        # Amalgamation

        parameters = Dict()

        parameters["source"] = source_list
        parameters["cable"] = cable_list
        parameters["load"] = load_list
        parameters["grid"] = grid

        #_______________________________________________________________________________
        # Defining the environment

        env = SimEnv(ts = Timestep, CM = CM, parameters = parameters, t_end = t_end, verbosity = 0)

        #_______________________________________________________________________________
        # Setting up data hooks

        hook = DataHook(collect_sources  = [1 2 3],
                        vrms             = [1 2 3],
                        irms             = [1 2 3],
                        power_pq         = [1 2 3],
                        freq             = [1 2 3],
                        )

        #_______________________________________________________________________________
        # initialising the agents

        Multi_Agent = setup_agents(env)
        Source = Multi_Agent.agents["classic"]["policy"].policy.Source

        #_______________________________________________________________________________
        # running the time simulation

        hook = simulate(Multi_Agent, env, num_episodes = num_eps, hook = hook)

        #_______________________________________________________________________________
        # Plotting

        #= for eps in 1:num_eps

                plot_hook_results(hook = hook,
                                        episode = eps,
                                        states_to_plot  = ["source1_v_C_filt_a"],
                                        actions_to_plot = [],
                                        power_p         = [1 2 3],
                                        power_q         = [1 2 3],
                                        vrms            = [1 2 3],
                                        irms            = [1 2 3],
                                        freq            = [1 2 3])
        end =#

        #_______________________________________________________________________________
        # Tests

        D = [6.710040724346115e-5 0.0003909248293754465; 202.64236728467552 6148.754619013457]
        I_kp = [0.003212489119409699; 0.0021416594129397997; 0.003212489119409699]
        I_ki = [0.34970957351408755; 0.23313971567605846; 0.34970957351408755]
        V_kp = [0.44465925382594856; 0.2964395025506326]
        V_ki = [8.78477386799335; 5.85651591199507]

        #CSV.write("Classical_Control_Unit_test.csv", hook.df)
        old_data = convert.(Float64, Matrix(CSV.read("./test/Classical_Control_Unit_test.csv", DataFrame))[1:end, 1:17])

        new_data = convert.(Float64, Matrix(hook.df)[1:end, 1:17])

        total_steps = Int(env.maxsteps)

        @test Source.D[2:end, :] ≈ D atol = 0.001
        @test Source.I_kp ≈ I_kp atol = 0.001
        @test Source.I_ki ≈ I_ki atol = 0.001
        @test Source.V_kp[2:end] ≈ V_kp atol = 0.001
        @test Source.V_ki[2:end] ≈ V_ki atol = 0.001
        @test new_data ≈ old_data atol = 0.001
        @test new_data[1:total_steps, 2:end] ≈ new_data[total_steps + 1:2*total_steps, 2:end] atol = 0.001
        @test new_data[1:total_steps, 2:end] ≈ new_data[2*total_steps + 1:end, 2:end] atol = 0.001
end

@testset "Ornstein_Uhlenbeck_Filters_Angles" begin

        #_______________________________________________________________________________
        # Network Parameters

        #-------------------------------------------------------------------------------
        # Time simulation

        Timestep = 100e-6  # time step, seconds ~ 100μs => 10kHz, 50μs => 20kHz, 20μs => 50kHz
        t_end    = 15     # total run time, seconds
        num_eps  = 1       # number of episodes to run

        #-------------------------------------------------------------------------------
        # Connectivity Matrix

        CM = [ 0. 0. 0. 1.
                0. 0. 0. 2.
                0. 0. 0. 3.
                -1. -2. -3. 0.]

        #-------------------------------------------------------------------------------
        # Cable Impedances

        cable_list = []

        cable = Dict()
        cable["R"]       = 0.208   # Ω, line resistance
        cable["L"]       = 0.00025 # H, line inductance
        cable["C"]       = 0.4e-3  # F, line capacitance
        cable["i_limit"] = 10e12   # A, line current limit

        push!(cable_list, cable, cable, cable)

        #-------------------------------------------------------------------------------
        # Sources

        source_list = []

        source = Dict()

        source["mode"]         = "Swing"
        source["control_type"] = "classic"

        source["fltr"]         = "LCL"  # Filter type

        source["pwr"]          = 100e3  # Rated Apparent Power, VA

        source["v_pu_set"]     = 1.00   # Voltage Set Point, p.u.
        source["v_δ_set"]      = -1.0      # Voltage Angle, degrees
        source["vdc"]          = 800    # V

        push!(source_list, source)

        source = Dict()

        source["mode"]         = "Voltage"
        source["control_type"] = "classic"

        source["fltr"]         = "LC"   # Filter type

        source["pwr"]          = 150e3  # Rated Apparent Power, VA

        source["v_pu_set"]     = 1.00   # Voltage Set Point, p.u.
        source["v_δ_set"]      = 3.5      # Voltage Angle, degrees
        source["vdc"]          = 800    # V

        push!(source_list, source)

        source = Dict()

        source["mode"]         = "PQ"
        source["control_type"] = "classic"

        source["fltr"]         = "L"    # Filter type

        source["pwr"]          = 100e3  # Rated Apparent Power, VA
        source["p_set"]        = 50e3   # Real Power Set Point, Watt
        source["q_set"]        = -10e3   # Imaginary Power Set Point, VAi

        source["v_pu_set"]     = 1.00   # Voltage Set Point, p.u.
        source["vdc"]          = 800    # V

        source["std_asy"]      = 5e3   # Asymptotic Standard Deviation
        source["σ"]            = 25e3    # Brownian motion scale i.e. ∝ diffusion, volatility parameter
        source["Δt"]           = 0.02   # Time Step, seconds
        source["X₀"]           = 30e3   # Initial Process Values, Watt
        source["k"]            = 1      # Interpolation degree
        source["γ"]            = 50e3   # Asymptotoic Mean

        push!(source_list, source)

        #-------------------------------------------------------------------------------
        # Loads

        R_load, L_load, _, _ = Parallel_Load_Impedance(100e3, 0.95, 230)

        load_list = []
        load = Dict()

        load["impedance"] = "RL"
        load["R"] = R_load
        load["L"] = L_load
        load["i_limit"] = 10e12
        load["v_limit"] = 10e12

        push!(load_list, load)

        #-------------------------------------------------------------------------------
        # Network

        grid = Dict()

        grid["v_rms"] = 230
        grid["ramp_end"] = 0.03
        grid["process_start"] = 0.04
        grid["f_grid"] = 50

        #-------------------------------------------------------------------------------
        # Amalgamation

        parameters = Dict()

        parameters["source"] = source_list
        parameters["cable"] = cable_list
        parameters["load"] = load_list
        parameters["grid"] = grid

        #_______________________________________________________________________________
        # Defining the environment

        env = SimEnv(ts = Timestep, CM = CM, parameters = parameters, t_end = t_end, verbosity = 0)

        #_______________________________________________________________________________
        # Setting up data hooks

        hook = DataHook(collect_sources  = [1 2 3],
                        vrms             = [1 2 3],
                        irms             = [1 2 3],
                        power_pq         = [1 2 3],
                        freq             = [1 2 3],
                        angles           = [1 2 3],
                        )

        #_______________________________________________________________________________
        # initialising the agents

        Multi_Agent = setup_agents(env)
        Source = Multi_Agent.agents["classic"]["policy"].policy.Source

        #_______________________________________________________________________________
        # running the time simulation

        hook = simulate(Multi_Agent, env, num_episodes = num_eps, hook = hook)

        #_______________________________________________________________________________
        # Plotting

        #= for eps in 1:num_eps

                plot_hook_results(hook = hook,
                                        episode = eps,
                                        states_to_plot  = [],
                                        actions_to_plot = [],
                                        power_p         = [3],
                                        power_q         = [3],
                                        vrms            = [],
                                        irms            = [],
                                        freq            = [3],
                                        angles          = [1 2 3])
        end =#

        #_______________________________________________________________________________
        # Tests

        s1_L1 = 0.0006830651506262048
        s1_R1 = 0.13661303012524095
        s1_L2 = 9.341360873776272e-5
        s1_R2 = 0.018682721747552544
        s1_C = 7.706152043421691e-5
        s1_R_C = 0.3442162015385205

        s2_L1 = 0.0004553767670841366
        s2_R1 = 0.09107535341682732
        s2_C = 0.00011559228065132534
        s2_R_C = 0.22947746769234703

        s3_L1 = 0.0006830651506262048
        s3_R1 = 0.13661303012524095
        
        step = Int(parameters["source"][3]["Δt"]/Timestep)
        start = Int(parameters["grid"]["process_start"]/Timestep) + 1 + step

        new_data = convert.(Float64, Matrix(hook.df)[start:step:end, 7])
        new_angles = convert.(Float64, Matrix(hook.df)[:, 18:19])

        angles_eval = ones(size(new_angles, 1), 2)
        angles_eval[:,1] = parameters["source"][1]["v_δ_set"].*angles_eval[:,1]
        angles_eval[:,2] = parameters["source"][2]["v_δ_set"].*angles_eval[:,2]

        stats = fit(Normal{Float32}, new_data)

        @test 1 ≈ stats.μ/parameters["source"][3]["γ"] atol = 0.015
        @test 1 ≈ stats.σ/parameters["source"][3]["std_asy"] atol = 0.1
        @test new_angles ≈ angles_eval atol = 0.001

        @test s1_L1 ≈ env.nc.parameters["source"][1]["L1"] atol = 0.00001
        @test s1_R1 ≈ env.nc.parameters["source"][1]["R1"] atol = 0.00001
        @test s1_L2 ≈ env.nc.parameters["source"][1]["L2"] atol = 0.00001
        @test s1_R2 ≈ env.nc.parameters["source"][1]["R2"] atol = 0.00001
        @test s1_C ≈ env.nc.parameters["source"][1]["C"] atol = 0.00001
        @test s1_R_C ≈ env.nc.parameters["source"][1]["R_C"] atol = 0.00001

        @test s2_L1 ≈ env.nc.parameters["source"][2]["L1"] atol = 0.00001
        @test s2_R1 ≈ env.nc.parameters["source"][2]["R1"] atol = 0.00001
        @test s2_C ≈ env.nc.parameters["source"][2]["C"] atol = 0.00001
        @test s2_R_C ≈ env.nc.parameters["source"][2]["R_C"] atol = 0.00001

        @test s3_L1 ≈ env.nc.parameters["source"][3]["L1"] atol = 0.00001
        @test s3_R1 ≈ env.nc.parameters["source"][3]["R1"] atol = 0.00001

                #= 
        println("stats.μ = ", stats.μ)
        println("γ = ", parameters["source"][3]["γ"])
        println("stats.σ = ", stats.σ)
        println("std_asy = ", parameters["source"][3]["std_asy"])  
        println()
        println(env.nc.parameters["source"][1]["L1"])
        println(env.nc.parameters["source"][1]["R1"])
        println(env.nc.parameters["source"][1]["L2"])
        println(env.nc.parameters["source"][1]["R2"])
        println(env.nc.parameters["source"][1]["C"])
        println(env.nc.parameters["source"][1]["R_C"])
        println()
        println(env.nc.parameters["source"][2]["L1"])
        println(env.nc.parameters["source"][2]["R1"])
        println(env.nc.parameters["source"][2]["C"])
        println(env.nc.parameters["source"][2]["R_C"])
        println()
        println(env.nc.parameters["source"][3]["L1"])
        println(env.nc.parameters["source"][3]["R1"])=#

        return nothing
end

@testset "Saturation" begin

        #_______________________________________________________________________________
        # Network Configuration

        #-------------------------------------------------------------------------------
        # Time simulation

        Timestep = 100e-6  # time step, seconds ~ 100μs => 10kHz, 50μs => 20kHz, 20μs => 50kHz
        t_end    = 0.1     # total run time, seconds

        #-------------------------------------------------------------------------------
        # Connectivity Matrix

        CM = [ 0. 1.
                -1. 0.]

        #-------------------------------------------------------------------------------
        # Parameters

        #= Modes:
        1 -> "Swing" - voltage source without dynamics (i.e. an Infinite Bus)
        2 -> "PQ" - grid following controllable source/load (active and reactive Power)
        3 -> "Droop" - simple grid forming with power balancing
        4 -> "Synchronverter" - enhanced droop control
        =#

        R_load, L_load, _, _ = Parallel_Load_Impedance(100e3, 0.99, 230)

        length = 1
        parameters = Dict{Any, Any}(
                "source" => Any[
                                Dict{Any, Any}("pwr" => 200e3,
                                                "mode" => "Semi-Synchronverter",
                                                "v_pu_set" => 1.05),

                                Dict{Any, Any}("pwr" => 200e3,
                                                "mode" => "PQ",
                                                "p_set" => -51.1e3, # making this slightly less/more, means that the voltage control loop recovers
                                                "q_set" => 100e3),
                                ],
                "cable"   => Any[
                                Dict{Any, Any}("R" => length*0.208,
                                                "L" => length*0.00025,
                                                "C" => length*0.4e-3,
                                                "i_limit" => 10e4,),
                                ],
                "grid" => Dict{Any, Any}("ramp_end" => 0.04, "process_start"=> 0.06)
        )
        #_______________________________________________________________________________
        # Defining the environment

        env = SimEnv(ts = Timestep, CM = CM, parameters = parameters, t_end = t_end, verbosity = 0)

        #_______________________________________________________________________________
        # Setting up data hooks

        hook = DataHook(collect_sources  = [1 2],
                        vrms             = [1 2],
                        irms             = [1 2],
                        power_pq         = [1 2],
                        freq             = [1 2],
                        angles           = [1 2],
                        i_sat            = [1 2],
                        v_sat            = [1],
                        i_err_t          = [1 2],
                        v_err_t          = [1])

        #_______________________________________________________________________________
        # initialising the agents

        Multi_Agent = setup_agents(env)
        Source = Multi_Agent.agents["classic"]["policy"].policy.Source

        #_______________________________________________________________________________
        # running the time simulation

        hook = simulate(Multi_Agent, env, hook = hook)

        #_______________________________________________________________________________
        # Plotting

        #= plot_hook_results(hook = hook,
                        states_to_plot  = [],
                        actions_to_plot = [],
                        power_p         = [],
                        power_q         = [],
                        vrms            = [1 2],
                        irms            = [1 2],
                        i_sat           = [1 2],
                        v_sat           = [1],
                        i_err_t         = [1 2],
                        v_err_t         = [1],
                        freq            = [],
                        angles          = []) =#

        #CSV.write("Control_Saturation_Unit_test.csv", hook.df[end-100:end,:])
        old_data = convert.(Float64, Matrix(CSV.read("./test/Control_Saturation_Unit_test.csv", DataFrame))[1:end, 1:17])

        new_data = convert.(Float64, Matrix(hook.df)[end-100:end, 1:17])

        @test new_data ≈ old_data atol = 0.001

        return nothing
end
