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
    type = 'frame',
    name = 'combat_frame',
    direction = 'vertical',
    caption = {"combat-gui.heading"},
  })
  combat_gui.style.width = 250
  combat_gui.add({
    type = 'label',
    name = 'spawners_remaining',
    caption = {'combat-gui.targets-remaining',1000}
  })
  combat_gui.add({
    type = 'label',
    name = 'enemy_evolution',
    caption = {'combat-gui.enemy-evolution',game.forces.enemy.evolution_factor}
  })
  local reload_frame = player.gui.left.add({
    type = 'frame',
    name = 'reload_frame',
    direction = 'vertical'
  })
  reload_frame.style.width = 250
  reload_frame.add({
    type = 'label',
    name = 'combat_status',
    caption = {'combat-gui.status-out'}
  })
  local reload_bar = reload_frame.add({
    type = 'progressbar',
    name = 'reload_bar'
  })
  reload_bar.style.width = 230
  local tech_frame = player.gui.left.add({
    type = 'frame',
    name = 'tech_frame',
    direction = 'vertical'
  })
  tech_frame.style.width = 250
  tech_frame.add({
    type = 'label',
    name = 'experience_label',
    caption = {'combat-gui.team-experience'}
  })
  local tech_bar = tech_frame.add({
    type = 'progressbar',
    name = 'experience_bar'
  })
  tech_bar.style.color = {138,43,226}
  tech_bar.style.width = 230
  tech_frame.add({
    type = 'label',
    name = 'team_level_label',
    caption = {'combat-gui.team-level',1}
  })
  tech_frame.add({
    type = 'label',
    name = 'your_level_label',
    caption = {'combat-gui.your-level',1}
  })
end

local update_combat_gui = function(player)
  --player.gui.left['combat'].reload_cooldown.caption = global.combat_evo_data.player_list[player.name].next_reload - game.ticks_played
end

local update_tech_gui = function(player)
  if not player.gui.left.combat_frame then
    create_combat_gui(player)
  end

  local percent_to_next = evolution_levels.get_percent_to_next_level()

  local bar = player.gui.left.tech_frame.experience_bar
  bar.value = percent_to_next

  local team_level = player.gui.left.tech_frame.team_level_label
  team_level.caption = {'combat-gui.team-level',evolution_levels.current_package()}
end

local update_own_tech_level = function(player)
  if not player.gui.left.combat_frame then
    create_combat_gui(player)
  end
  local your_level = player.gui.left.tech_frame.your_level_label
  your_level.caption = {'combat-gui.your-level',evolution_levels.current_package()}
end

local update_goal_gui = function(player)
  if not player.gui.left.combat_frame then
    create_combat_gui(player)
  end
  local remaining = player.gui.left.combat_frame.spawners_remaining
  remaining.caption = {'combat-gui.targets-remaining',math.max(global.combat_evo_data.kills_goal-global.combat_evo_data.spawner_kills,0)}
  local evo = player.gui.left.combat_frame.enemy_evolution
  evo.caption = {'combat-gui.enemy-evolution',math.floor(game.forces.enemy.evolution_factor*100)}
end

local update_reload_gui = function(player)
  if not player.gui.left.reload_frame then
    create_combat_gui(player)
  end

  local player_data = global.combat_evo_data.player_list[player.name]
  local label = player.gui.left.reload_frame.combat_status
  local bar = player.gui.left.reload_frame.reload_bar

  local percent_reloaded =  (player_data.next_reload - game.ticks_played) / global.combat_evo_data.cooldown

  if player.in_combat and player_data.in_combat then
    label.caption = {'combat-gui.status-in'}
    bar.value = 1
    bar.style.color = {255,140,0}
  elseif player.in_combat == false and player_data.in_combat == false and game.ticks_played < player_data.next_reload then
    label.caption = {'combat-gui.status-leaving'}
    bar.value = percent_reloaded
    bar.style.color = {255,215,0}
  else
    label.caption = {'combat-gui.status-out'}
    bar.value = 1
    bar.style.color = {0,220,0}
  end
end

local check_combat_gui = function(player)
  if player.gui.left.combat_frame then
    update_combat_gui(player)
  else
    create_combat_gui(player)
  end
end

local new_player_data = function(name)
  return {
    name = name,
    next_reload = 0,
    in_combat = false,
    reloaded = true,
    respawn_point = game.forces.player.get_spawn_position(game.surfaces[1]),
    respawn_marker = rendering.draw_circle({
      surface = game.players[name].surface,
      color = game.players[name].color,
      radius = 0.5,
      target = game.forces.player.get_spawn_position(game.surfaces[1]),
      players = {game.players[name]},
      draw_on_ground = true,
      filled = true,
    })
  }
end

local reset_cooldown = function(player,in_combat)
  if global.combat_evo_data.player_list[player.name] == nil then
    global.combat_evo_data.player_list[player.name] = new_player_data(name)
  end
  local player_data = global.combat_evo_data.player_list[player.name]
  player_data.next_reload = game.ticks_played + global.combat_evo_data.cooldown
  player_data.in_combat = in_combat
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
  cooldown = 10*60,
  spawner_kills = 0,
  kills_goal = 500,
  }

  clear_player_recipes()
  on_created_or_loaded()

  --game.map_settings.enemy_evolution.time_factor = 0.00002
  --game.map_settings.enemy_evolution.destroy_factor = 0.01
  --game.map_settings.enemy_evolution.pollution_factor = 0

  game.map_settings.enemy_evolution.time_factor = 0
  game.map_settings.enemy_evolution.destroy_factor = 0.02
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
    rendering.set_target(global.combat_evo_data.player_list[player.name].respawn_marker,ent.position)
    rendering.set_color(global.combat_evo_data.player_list[player.name].respawn_marker,player.color)
    ent.destroy()
    player.insert({name='constant-combinator',count=1})
    player.print({"spawn-point.personal-set"})
  end
end

local on_entity_damaged =  function(event)
  if event.entity.force == game.forces['enemy'] then
    if event.cause and event.cause.force == game.forces['player'] then
      if event.cause.name == 'character' then
        reset_cooldown(event.cause.player,true)
      elseif event.cause.last_user then
        reset_cooldown(event.cause.last_user,true)
      end
    end
  elseif event.entity.name == 'character' then
    reset_cooldown(event.entity.player,true)
  end
end

local on_entity_died = function(event)
  if event.entity.type == 'unit-spawner' then
    global.combat_evo_data.spawner_kills = global.combat_evo_data.spawner_kills + 1
  end
  for _, player in pairs(game.players) do
    update_goal_gui(player)
    update_tech_gui(player)
  end
end

local on_tick = function(event)
  if game.ticks_played % 10 ~= 0 then return end

  for _, player in pairs(game.players) do
    local player_data = global.combat_evo_data.player_list[player.name]

    update_reload_gui(player)
    check_combat_gui(player)

    if player.in_combat == false and player_data.in_combat == true then
      reset_cooldown(player,false)
      player_data.reloaded = false
    end

    if player_data.reloaded == false and player.in_combat == false and player_data.in_combat == false and
      game.ticks_played >= player_data.next_reload then
      local package = evolution_levels.current_package()
      evolution_levels.set_player_package(player,package)
      update_own_tech_level(player)
      clear_player_recipes()
      --reset_cooldown(player,false)
      player_data.reloaded = true
    end

  end
end

local on_player_created = function(event)
  local player = game.players[event.player_index]
  local package = evolution_levels.current_package()
  evolution_levels.set_player_package(player,package)
  clear_player_recipes()

  local r = 200
  --player.force.chart(player.surface, {{player.position.x - r, player.position.y - r}, {player.position.x + r, player.position.y + r}})

  local player = game.players[event.player_index]
  global.combat_evo_data.player_list[player.name] = new_player_data(player.name)

  update_tech_gui(player)
  update_own_tech_level(player)
  update_goal_gui(player)
  update_reload_gui(player)
  --reset_cooldown(player,false)
end

local on_player_respawned = function(event)
  local player = game.players[event.player_index]
  local package = evolution_levels.current_package()
  evolution_levels.set_player_package(player,package)
  clear_player_recipes()
  reset_cooldown(player,false)
  player.teleport(global.combat_evo_data.player_list[player.name].respawn_point)
end

local on_chunk_generated = function(event)
  if event.surface.count_entities_filtered({
    force = 'enemy',
    area = event.area,
  }) > 0 then
    game.forces.player.chart(event.surface,event.area)
  end
end

local main_events = {
  [defines.events.on_game_created_from_scenario] = on_game_created_from_scenario,
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_player_respawned] = on_player_respawned,
  [defines.events.on_built_entity] = on_built_entity,
  [defines.events.on_entity_damaged] = on_entity_damaged,
  [defines.events.on_entity_died] = on_entity_died,
  [defines.events.on_chunk_generated] = on_chunk_generated,
  [defines.events.on_tick] = on_tick,
}

handler.add_lib({events= main_events})

script.on_load(on_created_or_loaded)

