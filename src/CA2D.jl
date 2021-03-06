# 2D CA using Agents.jl
module CA2D
using Agents

mutable struct Cell{T<:Integer, Y<:AbstractString} <: AbstractAgent
  id::T
  pos::Tuple{T, T}
  status::Y
end

"""
    build_model(;rules::Tuple, dims=(100,100), Moore=true)

Builds a 2D cellular automaton. `rules` is of type `Tuple{Integer,Integer,Integer}`. The numbers are DSR (Death, Survival, Reproduction). Cells die if the number of their living neighbors are <D, survive if the number of their living neighbors are <=S, come to life if their living neighbors are as many as R. `dims` is the x and y size a grid. `Moore` specifies whether cells should connect to their diagonal neighbors.
"""
function build_model(;rules::Tuple, dims=(100,100), Moore=true)
  space = Space(dims, moore=Moore)
  properties = Dict(:rules => rules, :Moore=>Moore)
  model = ABM(Cell, space; properties = properties, scheduler=by_id)
  nnodes = dims[1]*dims[2]
  for n in 1:nnodes
    add_agent!(Cell(n, vertex2coord(n, dims), "0"), (n,1), model)
  end
  return model
end

"""
    periodic_neighbors(pos::Tuple{Integer, Integer}, dims::Tuple{Integer, Integer})

Returns the the row and column numbers of the rows and columns before and after the pos.
"""
function periodic_neighbors(pos::Tuple{Integer, Integer}, dims::Tuple{Integer, Integer})
  if pos[1] == 1
    xbefore = dims[1]
    if dims[1] == 1
      xafter = 1
    else
      xafter = pos[1] + 1
    end
  elseif pos[1] == dims[1]
    xbefore = pos[1] - 1
    xafter = 1
  else
    xbefore = pos[1] - 1
    xafter = pos[1] + 1
  end
  if pos[2] == 1
    ybefore = dims[2]
    if dims[2] == 1
      yafter = 1
    else
      yafter = pos[2] + 1
    end
  elseif pos[2] == dims[2]
    ybefore = pos[2] - 1
    yafter = 1
  else
    ybefore = pos[2] - 1
    yafter = pos[2] + 1
  end
  return (xbefore, ybefore), (xafter, yafter)
end

function ca_step!(model)
  agentnum = nagents(model)
  new_status = Array{String}(undef, agentnum)
  for agid in 1:agentnum
    agent = model.agents[agid]
    coord = agent.pos
    center = agent.status
    before, after = periodic_neighbors(coord, model.space.dimensions)
    right = model.agents[coord2vertex((after[1], coord[2]), model)].status
    left = model.agents[coord2vertex((before[1], coord[2]), model)].status
    top = model.agents[coord2vertex((coord[1], after[2]), model)].status
    bottom = model.agents[coord2vertex((coord[1], after[2]), model)].status
    topright = model.agents[coord2vertex((after[1], after[2]), model)].status
    topleft = model.agents[coord2vertex((before[1], after[2]), model)].status
    bottomright = model.agents[coord2vertex((after[1], before[2]), model)].status
    bottomleft = model.agents[coord2vertex((before[1], before[2]), model)].status

    if model.properties[:Moore]
      nstatus = [topleft, top, topright, left, right, bottomleft, bottom, bottomright]
      nlive = length(findall(a->a=="1", nstatus))
    else
      nstatus = [top, left, right, bottom]
      nlive = length(findall(a->a=="1", nstatus))
    end

    if agent.status == "1"
      if nlive < model.properties[:rules][1]
        new_status[agid] = "0"
      elseif nlive > model.properties[:rules][2]
        new_status[agid] = "0"
      else
        new_status[agid] = "1"
      end
    else
      if nlive == model.properties[:rules][3]
        new_status[agid] = "1"
      else
        new_status[agid] = "0"
      end
    end
  end
  for ss in 1:agentnum
    model.agents[ss].status = new_status[ss]
  end
end

"""
    ca_run(model::ABM, runs::Integer)

Runs a 2D cellular automaton.
"""
function ca_run(model::ABM, runs::Integer, plot_CA2Dgif::T; nodesize=2) where T<: Function
  data = step!(model, dummystep, ca_step!, 0, [:pos, :status], step0=true)
  anim = plot_CA2Dgif(data, nodesize=nodesize)
  for r in 1:runs
    data = step!(model, dummystep, ca_step!, 1, [:pos, :status], step0=false)
    anim = plot_CA2Dgif(data, anim=anim, nodesize=nodesize)
  end
  return anim
end

end  # module
