using DataFrames
using PlotlyJS

function plot_rewards_3d(hook)
    layout = Layout(
            plot_bgcolor="#f1f3f7",
            title = "Reward over Episodes",
            scene = attr(
                xaxis_title = "Time in Seconds",
                yaxis_title = "Episodes",
                zaxis_title = "Reward"),
            width = 1000,
            height = 650,
            margin=attr(l=10, r=10, b=10, t=60, pad=10)
        )

    p = plot(scatter3d(hook.df, x = :time, y = :episode, z = :reward,
                        marker=attr(size=2, color=:reward, colorscale=[[0, "rgb(255,0,0)"], [1, "rgb(0,255,0)"]]),
                        mode = "markers"),
            config = PlotConfig(scrollZoom=true),
            layout)
    display(p)
end

function plot_best_results(;agent, env, hook, states_to_plot = nothing, actions_to_plot = nothing, plot_reward = true, plot_reference = false)
    reset!(env)

    if isnothing(states_to_plot)
        states_to_plot = hook.collect_state_ids
    end

    if isnothing(actions_to_plot)
        actions_to_plot = hook.collect_action_ids
    end

    act_noise_old = agent.policy.act_noise
    agent.policy.act_noise = 0.0
    copyto!(agent.policy.behavior_actor, hook.bestNNA)
    
    temphook = DataHook(collect_state_ids = states_to_plot, collect_action_ids = actions_to_plot, collect_reference = true)
    
    run(agent.policy, env, StopAfterEpisode(1), temphook)
    
    layout = Layout(
            plot_bgcolor="#f1f3f7",
            title = "Results<br><sub>Run with Behavior-Actor-NNA from Episode " * string(hook.bestepisode) * "</sub>",
            xaxis_title = "Time in Seconds",
            yaxis_title = "State values",
            yaxis2 = attr(
                title="Reward",
                overlaying="y",
                side="right",
                titlefont_color="orange",
                range=[-1, 1]
            ),
            legend = attr(
                x=1,
                y=1.02,
                yanchor="bottom",
                xanchor="right",
                orientation="h"
            ),
            width = 1000,
            height = 650,
            margin=attr(l=100, r=80, b=80, t=100, pad=10)
        )


    traces = []

    for state_id in states_to_plot
        push!(traces, scatter(temphook.df, x = :time, y = Symbol(state_id), mode="lines", name = state_id))
    end

    for action_id in actions_to_plot
        push!(traces, scatter(temphook.df, x = :time, y = Symbol(action_id), mode="lines", name = action_id))
    end

    if plot_reward
        push!(traces, scatter(temphook.df, x = :time, y = :reward, yaxis = "y2", mode="lines", name = "Reward"))
    end

    if plot_reference
        push!(traces, scatter(temphook.df, x = :time, y = :reference_1, mode="lines", name = "Reference"))
    end

    traces = Array{GenericTrace}(traces)
    
    p = plot(traces, layout, config = PlotConfig(scrollZoom=true))
    display(p)
    
    copyto!(agent.policy.behavior_actor, hook.currentNNA)
    agent.policy.act_noise = act_noise_old
    
    reset!(env)

    return nothing
end

function plot_hook_results(; hook, states_to_plot = nothing, actions_to_plot = nothing ,plot_reward = false, plot_reference = false, episode = nothing)

    if isnothing(states_to_plot)
        states_to_plot = hook.collect_state_ids
    end

    if isnothing(actions_to_plot)
        actions_to_plot = hook.collect_action_ids
    end

    if isnothing(episode)
        df = hook.df
    else
        df = hook.df[hook.df.episode .== episode, :]
    end

    layout = Layout(
        plot_bgcolor="#f1f3f7",
        #title = "Results<br><sub>Run with Behavior-Actor-NNA from Episode " * string(hook.bestepisode) * "</sub>",
        xaxis_title = "Time in Seconds",
        yaxis_title = "State values",
        yaxis2 = attr(
            title="Action values",
            overlaying="y",
            side="right",
            titlefont_color="orange",
            #range=[-1, 1]
        ),
        legend = attr(
            x=1,
            y=1.02,
            yanchor="bottom",
            xanchor="right",
            orientation="h"
        ),
        width = 1000,
        height = 650,
        margin=attr(l=100, r=80, b=80, t=100, pad=10)
    )
    
    
    traces = []
    
    for state_id in states_to_plot
        push!(traces, scatter(df, x = :time, y = Symbol(state_id), mode="lines", name = state_id))
    end
    
    for action_id in actions_to_plot
        push!(traces, scatter(df, x = :time, y = Symbol(action_id), mode="lines", name = action_id, yaxis = "y2"))
    end
    
    if plot_reference
        #TODO: how to check which refs to plot? 
        push!(traces, scatter(df, x = :time, y = :reference_1, mode="lines", name = "Reference"))
        push!(traces, scatter(df, x = :time, y = :reference_2, mode="lines", name = "Reference"))
        push!(traces, scatter(df, x = :time, y = :reference_3, mode="lines", name = "Reference"))
    end

    if plot_reward
        push!(traces, scatter(df, x = :time, y = :reward, yaxis = "y2", mode="lines", name = "Reward"))
    end
    
    traces = Array{GenericTrace}(traces)
    
    p = plot(traces, layout, config = PlotConfig(scrollZoom=true))
    display(p)

end


function plot_p_source(;env, hook, episode, source_ids)
    layout = Layout(
        plot_bgcolor="#f1f3f7",
        xaxis_title = "Time in Seconds",
        yaxis_title = "Power / W",
        width = 1000,
        height = 650,
        margin=attr(l=100, r=80, b=80, t=100, pad=10)
    )

    stepinteval=((episode-1)*env.maxsteps)+1:((episode)*env.maxsteps)
    time = hook.df[stepinteval, :time]
    powers=[]
    if env.nc.parameters["grid"]["phase"] === 1

        
        for id in source_ids

            if id <= env.nc.num_fltr_LCL
                push!(powers, PlotlyJS.scatter(; x = time, y = hook.df[stepinteval, Symbol("i_$id")] .* hook.df[stepinteval , Symbol("u_$id")], mode="lines", name = "Power_Source_$id"*"_Ep_$episode"))
                
            elseif id <= env.nc.num_fltr_LCL+ env.nc.num_fltr_LC
                push!(powers, PlotlyJS.scatter(; x = time, y = (hook.df[stepinteval, Symbol("i_f$id")] - hook.df[stepinteval, Symbol("op_u_f$id")]).* hook.df[stepinteval , Symbol("u_$id")], mode="lines", name = "Power_Source_$id"))
            
            elseif id <= env.nc.num_fltr_LCL+ env.nc.num_fltr_LC+ env.nc.num_fltr_L
                push!(powers, PlotlyJS.scatter(; x = time, y = hook.df[stepinteval, Symbol("i_$id")] .* hook.df[stepinteval , Symbol("u_$id")], mode="lines", name = "Power_Source_$id"))
            else
                throw("Expect sourc_ids to correspond to the amount of sources, not $id")

            end
        end

    elseif env.nc.parameters["grid"]["phase"] === 3
       
        for id in source_ids

            if id <= env.nc.num_fltr_LCL
                power = (hook.df[stepinteval , Symbol("i_$id"*"_a")] .* hook.df[stepinteval , Symbol("u_$id"*"_a")])+(hook.df[stepinteval, Symbol("i_$id"*"_b")] .* hook.df[stepinteval , Symbol("u_$id"*"_b")])+(hook.df[stepinteval , Symbol("i_$id"*"_c")] .* hook.df[stepinteval , Symbol("u_$id"*"_c")])
                push!(powers, PlotlyJS.scatter(; x = time, y = power, mode="lines", name = "Power_Source_$id"))

            elseif id <= env.nc.num_fltr_LCL+ env.nc.num_fltr_LC
                power = (hook.df[stepinteval , Symbol("i_f$id"*"_a")] - hook.df[stepinteval , Symbol("op_u_f$id"*"_a")]).* hook.df[stepinteval , Symbol("u_$id"*"_a")]+ (hook.df[stepinteval , Symbol("i_f$id"*"_b")] - hook.df[stepinteval , Symbol("op_u_f$id"*"_b")]).* hook.df[stepinteval , Symbol("u_$id"*"_b")]+(hook.df[stepinteval , Symbol("i_f$id"*"_c")] - hook.df[stepinteval , Symbol("op_u_f$id"*"_c")]).* hook.df[stepinteval , Symbol("u_$id"*"_c")]
                push!(powers, PlotlyJS.scatter(; x = time, y = power, mode="lines", name = "Power_Source_$id"))
            
            elseif id <= env.nc.num_fltr_LCL+ env.nc.num_fltr_LC+ env.nc.num_fltr_L
                power = hook.df[stepinteval , Symbol("i_$id"*"_a")] .* hook.df[stepinteval , Symbol("u_$id"*"_a")]+hook.df[stepinteval , Symbol("i_$id"*"_b")] .* hook.df[stepinteval , Symbol("u_$id"*"_b")]+hook.df[stepinteval, Symbol("i_$id"*"_c")] .* hook.df[stepinteval, Symbol("u_$id"*"_c")]
                push!(powers, PlotlyJS.scatter(; x = time, y = power, mode="lines", name = "Power_Source_$id"))
            else
                throw("Expect source_ids to correspond to the amount of sources, not $id")

            end
        end
    end

    powers = Array{GenericTrace}(powers)
    
    p = PlotlyJS.plot(powers, layout, config = PlotConfig(scrollZoom=true))
    display(p)


end

function plot_p_load(;env, hook, episode, load_ids)
    layout = Layout(
        plot_bgcolor="#f1f3f7",
        xaxis_title = "Time in Seconds",
        yaxis_title = "Power / W",
        width = 1000,
        height = 650,
        margin=attr(l=100, r=80, b=80, t=100, pad=10)
    )

    stepinteval=((episode-1)*env.maxsteps)+1:((episode)*env.maxsteps)
    time = hook.df[stepinteval, :time]
    powers=[]
    if env.nc.parameters["grid"]["phase"] === 1

        for id in load_ids

            if id <= env.nc.num_loads_RLC
                power= hook.df[stepinteval, Symbol("u_load$id")] .* (hook.df[stepinteval, Symbol("i_load$id")] + hook.df[stepinteval, Symbol("u_load$id")] *(env.nc.parameters["load"][id]["R"])^(-1)+ (env.nc.parameters["load"][id]["C"])*(hook.collect_state_paras[env.nc.num_fltr+env.nc.num_connections+2*id-1])^(-1) * hook.df[stepinteval, Symbol("op_u_load$id")])
                push!(powers, PlotlyJS.scatter(; x = time, y = power, mode="lines", name = "Power_Load_$id"*"_Ep_$episode"))
                
            elseif id <= env.nc.num_loads_RLC+ env.nc.num_loads_LC
                power= hook.df[stepinteval, Symbol("u_load$id")] .* (hook.df[stepinteval, Symbol("i_load$id")] + (env.nc.parameters["load"][id]["C"])*(hook.collect_state_paras[env.nc.num_fltr+env.nc.num_connections+2*id-1])^(-1) * hook.df[stepinteval, Symbol("op_u_load$id")])
                push!(powers, PlotlyJS.scatter(; x = time, y = power , mode="lines", name = "Power_Load_$id"*"_Ep_$episode"))
            
            elseif id <= env.nc.num_loads_RLC+ env.nc.num_loads_LC+ env.nc.num_loads_RL
                power= hook.df[stepinteval, Symbol("u_load$id")] .* (hook.df[stepinteval, Symbol("i_load$id")] + hook.df[stepinteval, Symbol("u_load$id")] *(env.nc.parameters["load"][id]["R"])^(-1))
                push!(powers, PlotlyJS.scatter(; x = time, y = power, mode="lines", name = "Power_Load_$id"*"_Ep_$episode"))
            
            elseif id <= env.nc.num_loads_RLC+ env.nc.num_loads_LC+ env.nc.num_loads_RL+ env.nc.num_loads_L
                power= hook.df[stepinteval, Symbol("u_load$id")] .* hook.df[stepinteval, Symbol("i_load$id")]
                push!(powers, PlotlyJS.scatter(; x = time, y = power, mode="lines", name = "Power_Load_$id"*"_Ep_$episode"))
            
            elseif id <= env.nc.num_loads_RLC+ env.nc.num_loads_LC+ env.nc.num_loads_RL+ env.nc.num_loads_L+ env.nc.num_loads_RC
                power= hook.df[stepinteval, Symbol("u_load$id")] .* (hook.df[stepinteval, Symbol("u_load$id")] *(env.nc.parameters["load"][id]["R"])^(-1)+ (env.nc.parameters["load"][id]["C"])*(hook.collect_state_paras[env.nc.num_fltr+env.nc.num_connections+(env.nc.num_loads_RLC + env.nc.num_loads_LC + env.nc.num_loads_RL + env.nc.num_loads_L)+id])^(-1) * hook.df[stepinteval, Symbol("op_u_load$id")])
            
            elseif id <= env.nc.num_loads_RLC+ env.nc.num_loads_LC+ env.nc.num_loads_RL+ env.nc.num_loads_L+ env.nc.num_loads_RC+ env.nc.num_loads_C
                power= hook.df[stepinteval, Symbol("u_load$id")] .* ((env.nc.parameters["load"][id]["C"])*(hook.collect_state_paras[env.nc.num_fltr+env.nc.num_connections+(env.nc.num_loads_RLC + env.nc.num_loads_LC + env.nc.num_loads_RL + env.nc.num_loads_L)+id])^(-1) * hook.df[stepinteval, Symbol("op_u_load$id")])
            
            elseif id <= env.nc.num_loads_RLC+ env.nc.num_loads_LC+ env.nc.num_loads_RL+ env.nc.num_loads_L+ env.nc.num_loads_RC+ env.nc.num_loads_C+ env.nc.num_loads_R
                power= hook.df[stepinteval, Symbol("u_load$id")] .* (hook.df[stepinteval, Symbol("u_load$id")] *(env.nc.parameters["load"][id]["R"])^(-1))

            else
                throw("Expect laod_ids to correspond to the amount of loads, not $id")

            end
        end
        

    elseif env.nc.parameters["grid"]["phase"] === 3
        
        for id in load_ids

            if id <= env.nc.num_loads_RLC
                power_a= hook.df[stepinteval, Symbol("u_load$id"*"_a")] .* (hook.df[stepinteval, Symbol("i_load$id"*"_a")] + hook.df[stepinteval, Symbol("u_load$id"*"_a")] *(env.nc.parameters["load"][id]["R"])^(-1)+ (env.nc.parameters["load"][id]["C"])*(hook.collect_state_paras[env.nc.num_fltr+env.nc.num_connections+2*id-1])^(-1) * hook.df[stepinteval, Symbol("op_u_load$id"*"_a")])
                power_b= hook.df[stepinteval, Symbol("u_load$id"*"_b")] .* (hook.df[stepinteval, Symbol("i_load$id"*"_b")] + hook.df[stepinteval, Symbol("u_load$id"*"_b")] *(env.nc.parameters["load"][id]["R"])^(-1)+ (env.nc.parameters["load"][id]["C"])*(hook.collect_state_paras[env.nc.num_fltr+env.nc.num_connections+2*id-1])^(-1) * hook.df[stepinteval, Symbol("op_u_load$id"*"_b")])
                power_c= hook.df[stepinteval, Symbol("u_load$id"*"_c")] .* (hook.df[stepinteval, Symbol("i_load$id"*"_c")] + hook.df[stepinteval, Symbol("u_load$id"*"_c")] *(env.nc.parameters["load"][id]["R"])^(-1)+ (env.nc.parameters["load"][id]["C"])*(hook.collect_state_paras[env.nc.num_fltr+env.nc.num_connections+2*id-1])^(-1) * hook.df[stepinteval, Symbol("op_u_load$id"*"_c")])
                push!(powers, PlotlyJS.scatter(; x = time, y = power_a + power_b + power_c, mode="lines", name = "Power_Load_$id"*"_Ep_$episode"))
                
            elseif id <= env.nc.num_loads_RLC+ env.nc.num_loads_LC
                power_a= hook.df[stepinteval, Symbol("u_load$id"*"_a")] .* (hook.df[stepinteval, Symbol("i_load$id"*"_a")] + (env.nc.parameters["load"][id]["C"])*(hook.collect_state_paras[env.nc.num_fltr+env.nc.num_connections+2*id-1])^(-1) * hook.df[stepinteval, Symbol("op_u_load$id"*"_a")])
                power_b= hook.df[stepinteval, Symbol("u_load$id"*"_b")] .* (hook.df[stepinteval, Symbol("i_load$id"*"_b")] + (env.nc.parameters["load"][id]["C"])*(hook.collect_state_paras[env.nc.num_fltr+env.nc.num_connections+2*id-1])^(-1) * hook.df[stepinteval, Symbol("op_u_load$id"*"_b")])
                power_c= hook.df[stepinteval, Symbol("u_load$id"*"_c")] .* (hook.df[stepinteval, Symbol("i_load$id"*"_c")] + (env.nc.parameters["load"][id]["C"])*(hook.collect_state_paras[env.nc.num_fltr+env.nc.num_connections+2*id-1])^(-1) * hook.df[stepinteval, Symbol("op_u_load$id"*"_c")])
                push!(powers, PlotlyJS.scatter(; x = time, y = power_a + power_b + power_c , mode="lines", name = "Power_Load_$id"*"_Ep_$episode"))
            
            elseif id <= env.nc.num_loads_RLC+ env.nc.num_loads_LC+ env.nc.num_loads_RL
                power_a= hook.df[stepinteval, Symbol("u_load$id"*"_a")] .* (hook.df[stepinteval, Symbol("i_load$id"*"_a")] + hook.df[stepinteval, Symbol("u_load$id"*"_a")] *(env.nc.parameters["load"][id]["R"])^(-1))
                power_b= hook.df[stepinteval, Symbol("u_load$id"*"_b")] .* (hook.df[stepinteval, Symbol("i_load$id"*"_b")] + hook.df[stepinteval, Symbol("u_load$id"*"_b")] *(env.nc.parameters["load"][id]["R"])^(-1))
                power_c= hook.df[stepinteval, Symbol("u_load$id"*"_c")] .* (hook.df[stepinteval, Symbol("i_load$id"*"_c")] + hook.df[stepinteval, Symbol("u_load$id"*"_c")] *(env.nc.parameters["load"][id]["R"])^(-1))
                push!(powers, PlotlyJS.scatter(; x = time, y = power_a + power_b + power_c , mode="lines", name = "Power_Load_$id"*"_Ep_$episode"))
            
            elseif id <= env.nc.num_loads_RLC+ env.nc.num_loads_LC+ env.nc.num_loads_RL+ env.nc.num_loads_L
                power_a= hook.df[stepinteval, Symbol("u_load$id"*"_a")] .* hook.df[stepinteval, Symbol("i_load$id"*"_a")]
                power_b= hook.df[stepinteval, Symbol("u_load$id"*"_b")] .* hook.df[stepinteval, Symbol("i_load$id"*"_b")]
                power_c= hook.df[stepinteval, Symbol("u_load$id"*"_c")] .* hook.df[stepinteval, Symbol("i_load$id"*"_c")]
                push!(powers, PlotlyJS.scatter(; x = time, y = power_a + power_b + power_c, mode="lines", name = "Power_Load_$id"*"_Ep_$episode"))
            
            elseif id <= env.nc.num_loads_RLC+ env.nc.num_loads_LC+ env.nc.num_loads_RL+ env.nc.num_loads_L+ env.nc.num_loads_RC
                power_a= hook.df[stepinteval, Symbol("u_load$id"*"_a")] .* (hook.df[stepinteval, Symbol("u_load$id"*"_a")] *(env.nc.parameters["load"][id]["R"])^(-1)+ (env.nc.parameters["load"][id]["C"])*(hook.collect_state_paras[env.nc.num_fltr+env.nc.num_connections+(env.nc.num_loads_RLC + env.nc.num_loads_LC + env.nc.num_loads_RL + env.nc.num_loads_L)+id])^(-1) * hook.df[stepinteval, Symbol("op_u_load$id"*"_a")])
                power_b= hook.df[stepinteval, Symbol("u_load$id"*"_b")] .* (hook.df[stepinteval, Symbol("u_load$id"*"_b")] *(env.nc.parameters["load"][id]["R"])^(-1)+ (env.nc.parameters["load"][id]["C"])*(hook.collect_state_paras[env.nc.num_fltr+env.nc.num_connections+(env.nc.num_loads_RLC + env.nc.num_loads_LC + env.nc.num_loads_RL + env.nc.num_loads_L)+id])^(-1) * hook.df[stepinteval, Symbol("op_u_load$id"*"_b")])
                power_c= hook.df[stepinteval, Symbol("u_load$id"*"_c")] .* (hook.df[stepinteval, Symbol("u_load$id"*"_c")] *(env.nc.parameters["load"][id]["R"])^(-1)+ (env.nc.parameters["load"][id]["C"])*(hook.collect_state_paras[env.nc.num_fltr+env.nc.num_connections+(env.nc.num_loads_RLC + env.nc.num_loads_LC + env.nc.num_loads_RL + env.nc.num_loads_L)+id])^(-1) * hook.df[stepinteval, Symbol("op_u_load$id"*"_c")])
                push!(powers, PlotlyJS.scatter(; x = time, y = power_a + power_b + power_c, mode="lines", name = "Power_Load_$id"*"_Ep_$episode"))

            elseif id <= env.nc.num_loads_RLC+ env.nc.num_loads_LC+ env.nc.num_loads_RL+ env.nc.num_loads_L+ env.nc.num_loads_RC+ env.nc.num_loads_C
                power_a= hook.df[stepinteval, Symbol("u_load$id"*"_a")] .* ((env.nc.parameters["load"][id]["C"])*(hook.collect_state_paras[env.nc.num_fltr+env.nc.num_connections+(env.nc.num_loads_RLC + env.nc.num_loads_LC + env.nc.num_loads_RL + env.nc.num_loads_L)+id])^(-1) * hook.df[stepinteval, Symbol("op_u_load$id"*"_a")])
                power_b= hook.df[stepinteval, Symbol("u_load$id"*"_b")] .* ((env.nc.parameters["load"][id]["C"])*(hook.collect_state_paras[env.nc.num_fltr+env.nc.num_connections+(env.nc.num_loads_RLC + env.nc.num_loads_LC + env.nc.num_loads_RL + env.nc.num_loads_L)+id])^(-1) * hook.df[stepinteval, Symbol("op_u_load$id"*"_b")])
                power_c= hook.df[stepinteval, Symbol("u_load$id"*"_c")] .* ((env.nc.parameters["load"][id]["C"])*(hook.collect_state_paras[env.nc.num_fltr+env.nc.num_connections+(env.nc.num_loads_RLC + env.nc.num_loads_LC + env.nc.num_loads_RL + env.nc.num_loads_L)+id])^(-1) * hook.df[stepinteval, Symbol("op_u_load$id"*"_c")])
                push!(powers, PlotlyJS.scatter(; x = time, y = power_a + power_b + power_c, mode="lines", name = "Power_Load_$id"*"_Ep_$episode"))

            elseif id <= env.nc.num_loads_RLC+ env.nc.num_loads_LC+ env.nc.num_loads_RL+ env.nc.num_loads_L+ env.nc.num_loads_RC+ env.nc.num_loads_C+ env.nc.num_loads_R
                power_a= hook.df[stepinteval, Symbol("u_load$id"*"_a")] .* (hook.df[stepinteval, Symbol("u_load$id"*"_a")] *(env.nc.parameters["load"][id]["R"])^(-1))
                power_b= hook.df[stepinteval, Symbol("u_load$id"*"_b")] .* (hook.df[stepinteval, Symbol("u_load$id"*"_b")] *(env.nc.parameters["load"][id]["R"])^(-1))
                power_c= hook.df[stepinteval, Symbol("u_load$id"*"_c")] .* (hook.df[stepinteval, Symbol("u_load$id"*"_c")] *(env.nc.parameters["load"][id]["R"])^(-1))
                push!(powers, PlotlyJS.scatter(; x = time, y = power_a + power_b + power_c, mode="lines", name = "Power_Load_$id"*"_Ep_$episode"))
                
            else
                throw("Expect laod_ids to correspond to the amount of loads, not $id")

            end
        end

        
    end

    powers = Array{GenericTrace}(powers)
    
    p = PlotlyJS.plot(powers, layout, config = PlotConfig(scrollZoom=true))
    display(p)

end