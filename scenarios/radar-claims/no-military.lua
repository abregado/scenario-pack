local no_military = {}

local on_game_created_from_scenario = function()
  global.no_military_data = {}

  local group = game.permissions.create_group('pacifists')
  group.set_allows_action(defines.input_action.change_picking_state,true)
  group.set_allows_action(defines.input_action.change_shooting_state,true)
  group.set_allows_action(defines.input_action.open_kills_gui,true)
  group.set_allows_action(defines.input_action.select_next_valid_gun,true)
  group.set_allows_action(defines.input_action.set_car_weapons_control,true)
  group.set_allows_action(defines.input_action.wire_dragging,true)
  group.set_allows_action(defines.input_action.use_artillery_remote,true)
  group.set_allows_action(defines.input_action.use_item,true)

  global.no_military_data.banned_technologies = {


  }

  global.no_military_data.banned_recipes = {
    'pistol',
    'firearm-magazine'
  }
  local settings = game.surfaces['nauvis'].map_gen_settings
  settings.peaceful_mode = true
  settings.autoplace_controls['enemy-base'] = {
    frequency = 0,
    richness = 0,
    size = 0
  }

  game.surfaces['nauvis'].map_gen_settings = settings

  game.map_settings.pollution.enabled = false
  game.map_settings.enemy_evolution.enabled = false
  game.map_settings.enemy_expansion.enabled = false
end

local on_player_created = function(event)
  local player = game.players[event.player_index]
  if event.player_index == 1 then

  else
    player.print("Welcome "..player.name)
    game.permissions.get_group('pacifists').add_player(player)
    for _, item_name in pairs(global.no_military_data.banned_recipes) do
      player.remove_item({name=item_name,count=9999})
    end
  end
end

local on_player_respawned = function(event)
  local player = game.players[event.player_index]
  for _, item_name in pairs(global.no_military_data.banned_recipes) do
      player.remove_item({name=item_name,count=9999})
  end
end

local on_force_created = function(event)
  for _, technology_name in pairs(global.no_military_data.banned_technologies) do
    if event.force.technologies[technology_name] then
      event.force.technologies[technology_name].enabled = false
    end
  end
  for _, recipe_name in pairs(global.no_military_data.banned_recipes) do
    if event.force.recipes[recipe_name] then
      event.force.recipes[recipe_name].enabled = false
    end
  end
end

local on_research_finished = function(event)
  for _, recipe_name in pairs(global.no_military_data.banned_recipes) do
    if event.research.force.recipes[recipe_name] then
      event.research.force.recipes[recipe_name].enabled = false
    end
  end
end

local on_chunk_generated = function(event)
  local enemies = event.surface.find_entities_filtered({
    force = 'enemy',
    area = area,
  })
  for _, ent in pairs(enemies) do
    ent.destroy()
  end
end

no_military.events = {
  [defines.events.on_game_created_from_scenario] = on_game_created_from_scenario,
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_player_respawned] = on_player_respawned,
  [defines.events.on_force_created] = on_force_created,
  [defines.events.on_research_finished] = on_research_finished,
  [defines.events.on_chunk_generated] = on_chunk_generated,
}

return no_military