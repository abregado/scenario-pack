local handler = require("event_handler")
local claims = require("radar-claims")
local no_military = require("no-military")
local starting_areas = require("starting-areas")
local math2d = require('math2d')

local on_created_or_loaded = function()

end

local on_game_created_from_scenario = function()

  on_created_or_loaded()
end

local on_player_created = function(event)
  local player = game.players[event.player_index]
  if event.player_index == 1 then
    local character = player.character
    player.character = nil
    character.destroy()
  else
    local new_force = game.create_force(player.name)
    player.force = new_force
    for force_name, force in pairs(game.forces) do
      if force_name ~= 'enemy' then
        force.set_friend(new_force,true)
        new_force.set_friend(force,true)
      end
    end
    local next_starting_area = starting_areas.find_unoccupied_starting_area()
    if next_starting_area then
      player.print("found starting area")
      next_starting_area.owner = new_force.name
      local claim = claims.new_claim(new_force,player.surface,math2d.bounding_box.get_centre(next_starting_area.area))
      claim.requries_power = false
    end

    local starting_items = {
      {name='iron-plate',count=20},
      {name='copper-plate',count=10},
      {name='stone',count=30},
    }
    for _, item in pairs(starting_items) do
      player.insert(item)
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
handler.add_lib(starting_areas)
handler.add_lib(claims)
handler.add_lib(no_military)

script.on_load(on_created_or_loaded)