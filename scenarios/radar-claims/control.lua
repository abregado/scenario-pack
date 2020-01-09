local handler = require("event_handler")
local claims = require("radar-claims")


local on_created_or_loaded = function()

end

local on_game_created_from_scenario = function()

  --TODO: disable biters for this world
  on_created_or_loaded()
end

local on_player_created = function(event)
  local player = game.players[event.player_index]
  local new_force = game.create_force(player.name)
  player.force = new_force
  for force_name, force in pairs(game.forces) do
    if force_name ~= 'enemy' then
      force.set_friend(new_force,true)
      new_force.set_friend(force,true)
    end
  end
end

local main_events = {
  [defines.events.on_game_created_from_scenario] = on_game_created_from_scenario,
  [defines.events.on_player_created] = on_player_created,
}

handler.add_lib({events = main_events})
handler.add_lib(claims)

script.on_load(on_created_or_loaded)

