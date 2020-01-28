local handler = require("__base__.lualib.event_handler")
local free_builder = require('free-builder')
local math2d = require('math2d')

local on_game_created_from_scenario = function()
  free_builder.on_load()
end

local on_player_created = function(event)
  local player = game.players[event.player_index]
  free_builder.set_player_active(player)
end

local events = {
  [defines.events.on_game_created_from_scenario] = on_game_created_from_scenario,
  [defines.events.on_player_created] = on_player_created,
}

local event_receivers = {
  events,
  free_builder.events
}

handler.setup_event_handling(event_receivers)