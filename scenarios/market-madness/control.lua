local handler = require("__base__.lualib.event_handler")
local free_builder = require('free-builder')
local market = require('active_market')
local math2d = require('math2d')

local on_game_created_from_scenario = function()
  free_builder.on_load()
  free_builder.add_free_item('logistic-chest-active-provider',10)
  free_builder.add_free_item('logistic-chest-requester',10)
  free_builder.add_free_item('electric-mining-drill',10)
  market.on_load()
  local interface = game.surfaces[1].create_entity({
    position = {0,0},
    name = 'electric-energy-interface',
    force = 'free-builders'
  })
  interface.destructible = false
  interface.minable = false
end

local on_player_created = function(event)
  local player = game.players[event.player_index]
  free_builder.set_player_active(player)
  market.init_player(player)
end


local on_tick = function(event)
  if not global.next_update then
    global.next_update = 0
  end
  if event.tick > global.next_update then
    market.update()
    global.next_update = event.tick + 300
  end
end

local events = {
  [defines.events.on_game_created_from_scenario] = on_game_created_from_scenario,
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_tick] = on_tick,
}

local event_receivers = {
  events,
  free_builder.events,
  market.events,
}

handler.setup_event_handling(event_receivers)