POMDPs.n_states(pomdp::DroneSurveillancePOMDP) = (pomdp.size[1] * pomdp.size[2])^2 + 1

function POMDPs.stateindex(pomdp::DroneSurveillancePOMDP, s::DSState)
    if isterminal(pomdp, s)
        return n_states(pomdp)
    end
    nx, ny = pomdp.size 
    LinearIndices((nx, ny, nx, ny))[s.quad[1], s.quad[2], s.agent[1], s.agent[2]]
end

function state_from_index(pomdp::DroneSurveillancePOMDP, si::Int64)
    if si == n_states(pomdp)
        return pomdp.terminal_state
    end
    nx, ny = pomdp.size 
    s = CartesianIndices((nx, ny, nx, ny))[si]
    return DSState([s[1], s[2]], [s[3], s[4]])
end

# the state space is the POMDP itself
# we define an iterator over it

POMDPs.states(pomdp::DroneSurveillancePOMDP) = pomdp

function Base.iterate(pomdp::DroneSurveillancePOMDP, i::Int64 = 1)
    if i > n_states(pomdp)
        return nothing
    end
    s = state_from_index(pomdp, i)
    return (s, i+1)
end

function POMDPs.initialstate(pomdp::DroneSurveillancePOMDP, rng::AbstractRNG)
    rand(rng, initialstate_distribution(pomdp))
end

function POMDPs.initialstate_distribution(pomdp::DroneSurveillancePOMDP)
    quad = pomdp.region_A
    nx, ny = pomdp.size
    fov_x, fov_y = pomdp.fov
    states = DSState[]
    xspace = fov_x:nx
    yspace = fov_y:ny
    for x in fov_x:nx
        for y in 1:ny
            agent = DSPos(x, y)
            push!(states, DSState(quad, agent))
        end
    end
    for y in fov_y:ny
        for x in 1:fov_x-1
            agent = DSPos(x, y)
            push!(states, DSState(quad, agent))
        end
    end
    probs = normalize!(ones(length(states)), 1)
    return SparseCat(states, probs)
end