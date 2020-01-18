local no_military = {}

local init = function()
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
    'turrets',
    'laser-turrets',
    'laser',
    'laser-turret-speed-1',
    'laser-turret-speed-2',
    'laser-turret-speed-3',
    'laser-turret-speed-4',
    'laser-turret-speed-5',
    'laser-turret-speed-6',
    'laser-turret-speed-7',
    'personal-laser-defense-equipment',
    'discharge-defense-equipment',
    'physical-projectile-damage-1',
    'physical-projectile-damage-2',
    'physical-projectile-damage-3',
    'physical-projectile-damage-4',
    'physical-projectile-damage-5',
    'physical-projectile-damage-6',
    'physical-projectile-damage-7',
    'energy-weapons-damage-1',
    'energy-weapons-damage-2',
    'energy-weapons-damage-3',
    'energy-weapons-damage-4',
    'energy-weapons-damage-5',
    'energy-weapons-damage-6',
    'energy-weapons-damage-7',
    'follower-robot-count-1',
    'follower-robot-count-2',
    'follower-robot-count-3',
    'follower-robot-count-4',
    'follower-robot-count-5',
    'follower-robot-count-6',
    'follower-robot-count-7',
    'refined-flammables-1',
    'refined-flammables-2',
    'refined-flammables-3',
    'refined-flammables-4',
    'refined-flammables-5',
    'refined-flammables-6',
    'refined-flammables-7',
    'stronger-explosives-1',
    'stronger-explosives-2',
    'stronger-explosives-3',
    'stronger-explosives-4',
    'stronger-explosives-5',
    'stronger-explosives-6',
    'stronger-explosives-7',
    'weapon-shooting-speed-1',
    'weapon-shooting-speed-2',
    'weapon-shooting-speed-3',
    'weapon-shooting-speed-4',
    'weapon-shooting-speed-5',
    'weapon-shooting-speed-6',
    'military-2',
    'military-3',
    'military-4',
    'artillery-shell-range-1',
    'artillery-shell-speed-1',
    'tanks',
    'stone-walls',
    'gates',
    'military-science-pack',
    'atomic-bomb',
    'artillery',
    'flamethrower',
    'rocketry',
    'explosive-rocketry',
    'uranium-ammo',
    'combat-robotics',
    'combat-robotics-2',
    'combat-robotics-3',
    'energy-shield-equipment',
    'energy-shield-mk2-equipment',
    'land-mine',
    'explosives',
    'cliff-explosives'
  }

  global.no_military_data.banned_recipes = {
    'pistol',
    'submachine-gun',
    'piercing-rounds-magazine',
    'shotgun',
    'shotgun-shell',
    'firearm-magazine',
    'light-armor',
    'heavy-armor',
  }
  local settings = game.surfaces['nauvis'].map_gen_settings
  settings.peaceful_mode = true
  settings.autoplace_controls['enemy-base'] = {
    frequency = 0,
    richness = 0,
    size = 0
  }

  for _, technology_name in pairs(global.no_military_data.banned_technologies) do
    if game.forces.player.technologies[technology_name] then
      game.forces.player.technologies[technology_name].enabled = false
    end
  end
  for _, recipe_name in pairs(global.no_military_data.banned_recipes) do
    if game.forces.player.recipes[recipe_name] then
      game.forces.player.recipes[recipe_name].enabled = false
    end
  end

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
  --print("no military chunk generation")
  local enemies = event.surface.find_entities_filtered({
    force = 'enemy',
    area = area,
  })
  for _, ent in pairs(enemies) do
    ent.destroy()
  end
end

no_military.init = init

no_military.events = {
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_player_respawned] = on_player_respawned,
  [defines.events.on_force_created] = on_force_created,
  [defines.events.on_research_finished] = on_research_finished,
  [defines.events.on_chunk_generated] = on_chunk_generated,
}

return no_military