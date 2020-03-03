local script_events =
{
  player_sent_to_lobby = script.generate_event_name()
}

local defaults = {
  spawn_position = {16,16}
}

local script_data = {
  dummies = {}
}

local get_lobby = function()
  local surface = game.surfaces.lobby
  if (surface and surface.valid) then
    return surface
  end

  surface = game.create_surface("lobby",{width = 1, height = 1})

  for x = -1, 1 do
    for y = -1, 1 do
      surface.set_chunk_generated_status({x,y}, defines.chunk_generated_status.entities)
    end
  end

  local tiles = {}
  for chunk in surface.get_chunks() do
    for x = chunk.area.left_top.x, chunk.area.right_bottom.x do
      for y = chunk.area.left_top.y, chunk.area.right_bottom.y do
        table.insert(tiles,{name = "tutorial-grid", position = {x,y}})
      end
    end
  end
  surface.set_tiles(tiles)

  surface.always_day = true
  surface.daytime = 0

  return surface
end

local send_to_lobby = function(player)
  local surface = get_lobby()

  if script_data.dummies[player.name] then
    player.character = nil
    player.teleport(defaults.spawn_position,surface)
    player.character = script_data.dummies[player.name]
  else
    local spawn_location = surface.get_script_positions('lobby-spawn-'..player.force.name)
    if #spawn_location == 0 then spawn_location = surface.get_script_positions('lobby-spawn') end
    if #spawn_location == 0 then spawn_location = defaults.spawn_position else spawn_location = spawn_location[1] end

    local character = surface.create_entity({
      name = 'character',
      position = spawn_location,
      force = player.force
    })
    script_data.dummies[player.name] = character
    player.character = nil
    player.teleport(spawn_location,surface)
    player.character = character
  end

  script.raise_event(script_events.player_sent_to_lobby,{player_index=player.index})
end

local on_player_created = function(event)
  send_to_lobby(game.players[event.player_index])
end

local on_pre_player_died = function(event)
  send_to_lobby(game.players[event.player_index])
end

local lib = {}

lib.send_to_lobby = send_to_lobby

lib.events = {
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_pre_player_died] = on_pre_player_died
}

lib.on_init = function()
  global.lobby_data = global.lobby_data or script_data
  print("lobby init")
end

lib.on_load = function()
  script_data = global.lobby_data or script_data
end

lib.add_remote_interface = function()
  remote.add_interface("lobby",
  {
    get_events = function()
      return script_events
    end
  })
end

return lib


