local handler = require("event_handler")
local claims = require("radar-claims")
local no_military = require("no-military")
local starting_areas = require("starting-areas")


local on_created_or_loaded = function()

end

local on_game_created_from_scenario = function()

  on_created_or_loaded()
end

local on_player_created = function(event)
  local player = game.players[event.player_index]
  if event.player_index == 1 then

  else
    local new_force = game.create_force(player.name)
    player.force = new_force
    for force_name, force in pairs(game.forces) do
      if force_name ~= 'enemy' then
        force.set_friend(new_force,true)
        new_force.set_friend(force,true)
      end
    end
  end
end

local on_chunk_generated = function(event)
  --if this chunk contains stone deposits, make a mixed deposit
  local resources = event.surface.find_entities_filtered({
    type = 'resource',
    area = event.area
  })
  local valid_swaps = {'iron-ore','copper-ore','coal','stone'}

  for _, resource in pairs(resources) do
     local random_type = valid_swaps[math.random(1,#valid_swaps)]
    if random_type ~= resource.name then
      local new_dep = event.surface.create_entity({
        name = random_type,
        position = resource.position,
      })
      new_dep.amount = resource.amount
      resource.destroy()
    end
  end
end

local main_events = {
  [defines.events.on_game_created_from_scenario] = on_game_created_from_scenario,
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_chunk_generated] = on_chunk_generated,
}

handler.add_lib({events = main_events})
handler.add_lib(claims)
handler.add_lib(no_military)
handler.add_lib(starting_areas)

script.on_load(on_created_or_loaded)