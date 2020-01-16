local reset_settings = function()
  global.autodeploy_data = {}
  global.autodeploy_data.version = 1
  global.autodeploy_data.check_time = 300
  global.autodeploy_data.player_settings = {}
end

local change_settings_for_player = function(player,state)
  if global.autodeploy_data == nil then
    reset_settings()
  end
  global.autodeploy_data.player_settings[player.name] = state
  if state == 1 then
    --player.print({"autodeploy.active"})
  elseif state == 0 then
    --player.print({"autodeploy.inactive"})
  end
end

local command_toggle = function(data)
  local player = game.players[data.player_index]
  if global.autodeploy_data == nil then
    reset_settings()
  end
  if global.autodeploy_data.player_settings[player.name] == nil then
    change_settings_for_player(player,1)
    return
  end
  local current_state = global.autodeploy_data.player_settings[player.name] or 1
  if current_state == 1 then
    change_settings_for_player(player,0)
  else
    change_settings_for_player(player,1)
  end
end

local deploy_robots_for_player = function(player)
  local max_robots = game.forces.player.maximum_following_robot_count
  if global.autodeploy_data.player_settings[player.name] == nil then
    change_settings_for_player(player,1)
  end
  if global.autodeploy_data.player_settings[player.name] == 1 and player.character and #player.character.following_robots < max_robots and player.in_combat then
    if player.remove_item({name='destroyer-capsule',count=1}) > 0 then
      player.surface.create_entity({
        name='destroyer-capsule',
        force=player.force,
        position=player.position,
        speed=10,
        source=player.character,
        target=player.position,
      })
    elseif player.remove_item({name='defender-capsule',count=1}) > 0 then
      player.surface.create_entity({
        name='defender-capsule',
        force=player.force,
        position=player.position,
        speed=10,
        source=player.character,
        target=player.position,
      })
    end
  end
end

local update = function()
  if global.autodeploy_data == nil or global.autodeploy_data.check_time == nil then
    reset_settings()
  end
  if game.ticks_played > 0 and game.ticks_played % global.autodeploy_data.check_time == 0 then
    for _, player in pairs(game.connected_players) do
      deploy_robots_for_player(player)
    end
  end
end

local on_player_created = function(event)
  local player = game.players[event.player_index]
  change_settings_for_player(player,1)
end

local autodeploy = {}

autodeploy.init = function()
  reset_settings()
end

autodeploy.set_check_time = function(check_time)
  global.autodeploy_data.check_time = check_time
end

autodeploy.get_check_time = function()
  return global.autodeploy_data.check_time
end

autodeploy.on_load = function()
  commands.add_command('autodeploy',{"autodeploy.command-description"},command_toggle)
end

autodeploy.events = {
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_tick] = update
}

return autodeploy

