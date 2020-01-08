local evolution = {}

evolution.levels = {}

evolution.levels[1] = {
  name="starting",
  threshold = 0,
  technology = {

  },
  inventory = {
    {name='pistol',count=1},
    {name='raw-fish',count=3},
    {name='light-armor',count=1},
    {name='constant-combinator',count=1},
  },
  filters = {
    'raw-fish',
    'repair-pack',
    'gun-turret',
    'constant-combinator',
  },
  message = "Reloaded: level 1",
}

evolution.levels[2] = {
  name="red",
  threshold = 0,
  technology = {},
  inventory = {
    {name='raw-fish',count=4},
    {name='submachine-gun',count=1},
    {name='shotgun',count=1},
    {name='shotgun-shell',count=50},
    {name='heavy-armor',count=1},
    {name='gun-turret',count=1},
    {name='repair-pack',count=10},
    {name='firearm-magazine',count=200},
  },
  remove = {
    'pistol',
    'light-armor'
  },
  message = "Tech upgraded: Better weapons and armor",
}

evolution.levels[3] = {
  name="red-plus",
  threshold = 5,
  technology = {
    'weapon-shooting-speed-1',
    'physical-projectile-damage-1',
  },
  inventory = {
    {name='raw-fish',count=5},
  },
  message = "Tech upgraded: more dps",
}

evolution.levels[4] = {
  name="green",
  threshold = 15,
  inventory = {
    {name='raw-fish',count=6},
    {name='piercing-rounds-magazine',count=200},
    {name='grenade',count=50},
    {name='car',count=1},
    {name='coal',count=50},
  },
  technology = {},
  message = "Green Science Upgrades incoming: car + piercing ammo",
}

evolution.levels[5] = {
  name="green-plus",
  threshold = 19,
  inventory = {
    {name='raw-fish',count=8},
  },
  technology = {
    'physical-projectile-damage-2',
    'stronger-explosives-1',
    'weapon-shooting-speed-2',
  },
  message = "Green Science Plus Upgrades incoming: damage and shooting speed",
}

evolution.levels[6] = {
  name="black",
  threshold = 23,
  inventory = {
    {name='raw-fish',count=10},
  },
  technology = {
    'stronger-explosives-2',
    'weapon-shooting-speed-3',
    'physical-projectile-damage-3',
  },
  message = "Black Science Upgrades incoming: passive damage buffs",
}

evolution.levels[7] = {
  name="black-plus",
  threshold = 30,
  inventory = {
    {name='raw-fish',count=12},
  },
  technology = {
    'weapon-shooting-speed-4',
    'physical-projectile-damage-4',
  },
  message = "Black Science Upgrades incoming: passive damage buffs",
}

evolution.levels[8] = {
  name="oil",
  threshold = 38,
  inventory = {
    {name='modular-armor',count=1},
    {name='energy-shield-equipment',count=2},
    {name='battery-equipment',count=2},
    {name='night-vision-equipment',count=1},
    {name='solar-panel-equipment',count=5},
    {name='defender-capsule',count=50},
    {name='rocket-launcher',count=1},
    {name='rocket',count=50},
    {name='rocket-fuel',count=50},
    {name='land-mine',count=50},
    {name='flamethrower',count=1},
    {name='flamethrower-ammo',count=200},
    {name='laser-turret',count=1},
    {name='medium-electric-pole',count=1},
    {name='solar-panel',count=5},
    {name='accumulator',count=1},
  },
  technology = {
    'combat-robotics',
  },
  message = "Oil Upgrades 1 incoming: flamethrower + rockets + modular armor",
}

evolution.levels[9] = {
  name="oil-two",
  threshold = 45,
  inventory = {
    {name='raw-fish',count=14},
  },
  technology = {
    'follower-robot-count-1',
    'refined-flammables-1',
    'laser-turret-speed-1',
    'energy-weapons-damage-1',
  },
  message = "Oil Upgrades 2 incoming: passive damage buffs",
}

evolution.levels[10] = {
  name="oil-three",
  threshold = 50,
  inventory = {},
  technology = {
    'refined-flammables-2',
    'laser-turret-speed-2',
    'energy-weapons-damage-2',
  },
  message = "Oil Upgrades 3 incoming: passive damage buffs",
}

evolution.levels[11] = {
  name="oil-four",
  threshold = 55,
  inventory = {},
  technology = {
    'energy-weapons-damage-3',
    'follower-robot-count-2',
  },
  message = "Oil Upgrades 4 incoming: more laser damage",
}

evolution.levels[12] = {
  name="blue",
  threshold = 60,
  inventory = {
    {name='poison-capsule',count=50},
    {name='slowdown-capsule',count=50},
    {name='combat-shotgun',count=1},
    {name='distractor-capsule',count=50},
  },
  technology = {},
  message = "Blue Science upgrades incoming: tank + capsules + passive boost",
}

evolution.levels[13] = {
  name="blue-two",
  threshold = 65,
  inventory = {
    {name='tank',count=1},
    {name='cannon-shell',count=50},
    {name='rocket',count=100},
  },
  technology = {
    'energy-weapons-damage-4',
    'follower-robot-count-3',
    'laser-turret-speed-3',
    'physical-projectile-damage-5',
    'refined-flammables-3',
    'stronger-explosives-3',
    'weapon-shooting-speed-5',
  },
  message = "Blue Science 2 upgrades incoming: moar damage",
}

evolution.levels[14] = {
  name="blue-three",
  threshold = 70,
  inventory = {
    {name='explosive-cannon-shell',count=50},
    {name='explosive-rocket',count=50},
  },
  technology = {
    'follower-robot-count-4',
    'laser-turret-speed-4',
  },
  message = "Blue Science 3 upgrades incoming: moar robots",
}

evolution.levels[15] = {
  name="processing",
  threshold = 75,
  technology = {},
  inventory = {
    {name='power-armor',count=1},
    {name='exoskeleton-equipment',count=1},
    {name='discharge-defense-equipment',count=3},
    {name='discharge-defense-remote',count=1},
    {name='energy-shield-mk2-equipment',count=3},
    {name='battery-mk2-equipment',count=3},
    {name='personal-laser-defense-equipment',count=3},
  },
  message = "Processing Unit upgrades incoming: power armor + better equipment",
}

evolution.levels[16] = {
  name="yellow",
  threshold = 80,
  inventory = {
    {name='destroyer-capsule',count=50},
    {name='cluster-grenade',count=50},
    {name='piercing-shotgun-shell',count=50},
    {name='power-armor-mk2',count=1},
    {name='fusion-reactor-equipment',count=1},
  },
  technology = {},
  message = "Yellow Science upgrades incoming: new power armor + robots + ammo",
}

evolution.levels[17] = {
  name="yellow-two",
  threshold = 82,
  inventory = {},
  technology = {
    'energy-weapons-damage-5',
    'follower-robot-count-5',
    'laser-turret-speed-5',
    'physical-projectile-damage-6',
    'refined-flammables-4',
    'stronger-explosives-4',
    'weapon-shooting-speed-6',
  },
  message = "Yellow Science 2 upgrades incoming: damage techs",
}

evolution.levels[18] = {
  name="yellow-three",
  threshold = 85,
  inventory = {},
  technology = {
    'energy-weapons-damage-6',
    'follower-robot-count-6',
    'laser-turret-speed-6',
    'refined-flammables-5',
    'stronger-explosives-5'
  },
  message = "Yellow Science 3 upgrades incoming: more damage techs",
}

evolution.levels[19] = {
  name="yellow-four",
  threshold = 87,
  inventory = {},
  technology = {
    'laser-turret-speed-7',
    'refined-flammables-6',
    'stronger-explosives-6'
  },
  message = "Yellow Science 4 upgrades incoming: more more damage techs",
}

evolution.levels[20] = {
  name="nuclear",
  threshold = 90,
  technology = {},
  inventory = {
    {name='uranium-rounds-magazine',count=50},
    {name='uranium-cannon-shell',count=50},
    {name='explosive-uranium-cannon-shell',count=50},
    {name='atomic-bomb',count=1},
  },
  message = "Nuclear upgrades incoming: DU rounds and nukes",
}

evolution.levels[21] = {
  name="artillery",
  threshold = 93,
  technology = {},
  inventory = {
    {name='artillery-turret',count=1},
    {name='artillery-shell',count=10},
    {name='artillery-targeting-remote',count=1},
  },
  message = "Artillery upgrades incoming: you win!",
}

evolution.levels[22] = {
  name="artillery-plus",
  threshold = 96,
  technology = {
    'artillery-shell-range-1',
    'artillery-shell-speed-1',
    'energy-weapons-damage-7',
    'follower-robot-count-7',
    'physical-projectile-damage-7',
    'refined-flammables-7',
    'stronger-explosives-7',
  },
  inventory = {},
  message = "Final Upgrades: you win!",
}

evolution.levels[23] = {
  threshold = 120,
  technology = {},
  inventory = {},
  robots = {},
  message = "You shouldnt see this message",
}

evolution.current_package = function()
  local biter_evo = game.forces.enemy.evolution_factor * 100
  print("Biter Evolution at: "..biter_evo.."%")
  local package_index = 1
  for count, package in pairs(evolution.levels) do
    if package.threshold <= biter_evo and evolution.levels[count+1].threshold > biter_evo then
      package_index = count
    end
  end
  
  return package_index
end

evolution.clear_all_players_above = function(package_index)
  if package_index < global.current_level then
    for _, technology in pairs(game.forces.player.technologies) do
      technology.enabled = false
      technology.researched = false
    end
    for _, recipe in pairs(game.forces.player.recipes) do
      recipe.enabled = false
    end
    for _, player in pairs(game.forces.player.players) do
      player.clear_items_inside()
    end
  end
end

evolution.loadout_list = function()
  local list = ""
  for index, package in pairs(evolution.levels) do
    if index < #evolution.levels then
      list = list .. " "..index..":"..package.name..", "
    end
  end
  return list
end

evolution.reload_all_players = function()
  local package_index = evolution.current_package()
  evolution.clear_all_players_above(package_index)
  for _, player in pairs(game.forces.player.players) do
    evolution.set_player_package(player,package_index)
  end
  global.current_level = package_index
end

evolution.set_evo_to_package = function(package_index)
  local package = evolution.levels[package_index]
  if package then
    evolution.clear_all_players_above(package_index)
    game.forces.enemy.evolution_factor = package.threshold / 100
    for _, player in pairs(game.forces.player.players) do
      evolution.set_player_package(player,package_index)
    end
    global.current_level = package_index
    return true
  end
  return false
end

evolution.set_player_package = function(player,package_index)
  local was_changed = false
  local reloaded = false
  for index = 1, package_index do
    local package = evolution.levels[index]
    for _, tech in pairs(package.technology) do
      if game.forces.player.technologies[tech] then
        local force_tech = game.forces.player.technologies[tech]
        if force_tech.enabled == false then
          force_tech.enabled = true
          force_tech.researched = true
          was_changed = true
        end
      else
        print("Couldnt find technology: "..tech)
      end
    end

    --set_filters
    if package.filters then
      for s = 1, 20 do
        if package.filters[s] and game.item_prototypes[package.filters[s]] then
          player.set_quick_bar_slot(s,package.filters[s])
        end
      end
    end

    --clear old items
    if package.remove then
      for _, item_name in pairs(package.remove) do
        player.remove_item({name=item_name,count=1000})
      end
    end

    --add new items
    for _, item in pairs(package.inventory) do
      if game.item_prototypes[item.name] then
        local current_count = player.get_item_count(item.name) 
        if current_count < item.count then
          player.insert({name=item.name,count=item.count-current_count})
          reloaded = true
        end
      else
        print("Couldnt find item: "..item.name)
      end
    end
  end
  
  if was_changed then
    player.print(evolution.levels[package_index].message)
  end
  
  if reloaded then
    player.print("Reloaded: tech level "..package_index-1)
  end
end

return evolution