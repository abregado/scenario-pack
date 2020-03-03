local script_data = {

}

local on_built_entity = function()
  game.print("cheese")
end

local player_teleported_to_lobby = function()
  game.print("Welcome to the lobby")
end

local lib = {}

local add_external_events = function()
  if not remote.interfaces['lobby'] then return end
  lib.events[defines.events.on_built_entity] = on_built_entity
  lib.events[remote.call("lobby","get_events").player_sent_to_lobby] = player_teleported_to_lobby
end

lib.events = {}

lib.on_load = function()
  add_external_events()
end

lib.on_init = function()
  add_external_events()
end

return lib