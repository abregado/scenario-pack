local util = require("util")
local handler = require("event_handler")
local math2d = require("math2d")
local evolution_levels = require("levels")

local clear_player_recipes = function()
  for _, recipe in pairs(game.forces.player.recipes) do
    recipe.enabled = false
  end
end

local create_combat_gui = function(player)
  local combat_gui = player.gui.left.add({
    type='frame',
    name='combat',
    caption={"combat-gui.heading"},
  })
  combat_gui.add({
    type='label',
    name='reload_cooldown',
    caption='0',
  })
end

local update_combat_gui = function(player)
  player.gui.left['combat'].reload_cooldown.caption = global.combat_evo_data.player_list[player.name].next_reload - game.ticks_played
end

local check_combat_gui = function(player)
  if player.gui.left.combat then
    update_combat_gui(player)
  else
    create_combat_gui(player)
  end
end

local new_player_data = function(name)
  return {
    name = name,
    next_reload = 0,
    respawn_point = game.forces.player.get_spawn_position(game.surfaces[1]),
  }
end

local reset_cooldown = function(player)
  if global.combat_evo_data.player_list[player.name] == nil then
    global.combat_evo_data.player_list[player.name] = new_player_data(name)
  end
  global.combat_evo_data.player_list[player.name].next_reload = game.ticks_played + global.combat_evo_data.cooldown
end

local evo_skip = function(data)
  local player = game.players[data.player_index]
  if type(tonumber(data.parameter)) == 'number' and (tonumber(data.parameter) >= 0 and tonumber(data.parameter) <= 100) then
    local new_evo = 0
    if tonumber(data.parameter) > 0 then
      new_evo = tonumber(data.parameter)/100
    end
    game.forces.enemy.evolution_factor = new_evo
    evolution_levels.reload_all_players()
    clear_player_recipes()
  else
    player.print({"evolution-skip-command.error-number-out-of-range"})
  end
end

local loadout_skip = function(data)
  local player = game.players[data.player_index]
  if data.parameter then
    local result = evolution_levels.set_evo_to_package(tonumber(data.parameter))
    if result then
      return true
    end
  else
    local result = evolution_levels.set_evo_to_package(global.current_level + 1)
    if result then
      return true
    end
  end
  player.print({"",{"loadout-skip-command.error-non-existant-loadout"},evolution_levels.loadout_list()})
  return false
end

local on_created_or_loaded = function()
  commands.add_command("skipevo",{"evolution-skip-command.description"},evo_skip)
  commands.add_command("skiploadout",{"loadout-skip-command.description"},loadout_skip)
end

local on_game_created_from_scenario = function()
  global.current_level = 3
  global.combat_evo_data = {
  player_list = {},
  cooldown = 30*60,
  }

  clear_player_recipes()
  on_created_or_loaded()

  game.map_settings.enemy_evolution.time_factor = 0.00002
  game.map_settings.enemy_evolution.destroy_factor = 0.01
  game.map_settings.enemy_evolution.pollution_factor = 0

  for _, technology in pairs(game.forces.player.technologies) do
    technology.enabled = false
  end

end

local on_built_entity =  function(event)
  local player = game.players[event.player_index]
  local ent =  event.created_entity
  if ent.name == "constant-combinator" then
    player.force.set_spawn_position(ent.position,player.surface)
    global.combat_evo_data.player_list[player.name].respawn_point = ent.position
    ent.destroy()
    player.insert({name='constant-combinator',count=1})
    player.print({"spawn-point.personal-set"})
  end
end

local on_entity_damaged =  function(event)
  if event.entity.force == game.forces['enemy'] then
    if event.cause and event.cause.force == game.forces['player'] then
      if event.cause.name == 'character' then
        reset_cooldown(event.cause.player)
      elseif event.cause.last_user then
        reset_cooldown(event.cause.last_user)
      end
    end
  elseif event.entity.name == 'character' then
    reset_cooldown(event.entity.player)
  end
end

local on_tick = function(event)
  if game.ticks_played % 10 ~= 0 then return end

  for _, player in pairs(game.players) do
    check_combat_gui(player)

    if game.ticks_played >= global.combat_evo_data.player_list[player.name].next_reload then
      local package = evolution_levels.current_package()
      evolution_levels.set_player_package(player,package)
      clear_player_recipes()
      reset_cooldown(player)
    end

  end
end

local on_player_created = function(event)
  local player = game.players[event.player_index]
  local package = evolution_levels.current_package()
  evolution_levels.set_player_package(player,package)
  clear_player_recipes()

  local r = 200
  player.force.chart(player.surface, {{player.position.x - r, player.position.y - r}, {player.position.x + r, player.position.y + r}})

  local player = game.players[event.player_index]
  global.combat_evo_data.player_list[player.name] = new_player_data(player.name)
  reset_cooldown(player)
end

local on_player_respawned = function(event)
  local player = game.players[event.player_index]
  local package = evolution_levels.current_package()
  evolution_levels.set_player_package(player,package)
  clear_player_recipes()
  reset_cooldown(player)
  player.teleport(global.combat_evo_data.player_list[player.name].respawn_point)
end

local main_events = {
  [defines.events.on_game_created_from_scenario] = on_game_created_from_scenario,
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_player_respawned] = on_player_respawned,
  [defines.events.on_built_entity] = on_built_entity,
  [defines.events.on_entity_damaged] = on_entity_damaged,
  [defines.events.on_tick] = on_tick,
}

handler.add_lib({events= main_events})

script.on_load(on_created_or_loaded)

