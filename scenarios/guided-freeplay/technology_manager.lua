local technology_manager = {}
local technology_manager_data =
{
  current_technology_level = nil,
  current_revealed_technology_level = nil,
  optional_levels = {},
  revealed_optional_levels = {},
}

local main_technology_levels
local optional_technology_levels

local check_tech_levels_correct = function()
  local check = function(levels)
    for _, level in pairs(levels) do
      for _, name in pairs(level.techs) do
        assert(game.technology_prototypes[name], "bad technology name in tech levels: " .. name)
      end
    end
  end

  check(main_technology_levels)
  check(optional_technology_levels)
end

technology_manager.get_current_tech_level = function()
  return technology_manager_data.current_technology_level
end

technology_manager.init = function(_technology_levels, _optional_technology_levels)
  main_technology_levels = _technology_levels
  optional_technology_levels = _optional_technology_levels
  global.technology_manager_data = technology_manager_data

  check_tech_levels_correct()

  technology_manager.reset()
end

technology_manager.on_load = function(_technology_levels, _optional_technology_levels)
  main_technology_levels = _technology_levels
  optional_technology_levels = _optional_technology_levels
  technology_manager_data = global.technology_manager_data or technology_manager_data
end

technology_manager.tech_level_exists = function(level_name)
  for _, level in pairs(main_technology_levels) do
    if level.name == level_name then
      return true
    end
  end

  return false
end

technology_manager.optional_tech_level_exists = function(level_name)
  for _, level in pairs(optional_technology_levels) do
    if level.name == level_name then
      return true
    end
  end

  return false
end

technology_manager.set_tech_level = function(level_name)
  if not technology_manager.tech_level_exists(level_name) then
    error("Tech level " .. level_name .. " does not exist!")
  end

  technology_manager_data.current_technology_level = level_name
  technology_manager.reset()
  local position = game.players[1].position
  if not position.x then position.x = position[1] end
  if not position.y then position.y = position[2] end
  game.surfaces[1].create_entity{name = "tutorial-flying-text", text = {"flying-text.new-technologies-available"},
                                 position = {position.x, position.y - 1.5}, color = {r = 1, g = 0.8, b = 0}}
end

technology_manager.set_revealed_tech_level = function(level_name)
  if not technology_manager.tech_level_exists(level_name) then
    error("Tech level " .. level_name .. " does not exist!")
  end

  technology_manager_data.current_revealed_technology_level = level_name
  technology_manager.reset()
end

technology_manager.reveal_all_tech_levels = function()
  technology_manager.set_revealed_tech_level(main_technology_levels[#main_technology_levels].name)
end

technology_manager.enable_optional_tech_level = function(level_name)
   if not technology_manager.optional_tech_level_exists(level_name) then
    error("Optional tech level " .. level_name .. " does not exist!")
  end

  table.insert(technology_manager_data.optional_levels, level_name)
  technology_manager.reset()
end

technology_manager.reveal_optional_tech_level = function(level_name)
   if not technology_manager.optional_tech_level_exists(level_name) then
    error("Optional tech level " .. level_name .. " does not exist!")
  end

  table.insert(technology_manager_data.revealed_optional_levels, level_name)
  technology_manager.reset()
end

technology_manager.research_up_to = function (level_name)
  if not technology_manager.tech_level_exists(level_name) then
    error("Tech level " .. level_name .. " does not exist!")
  end

  local found = false

  if technology_manager_data.current_technology_level then
    for _, level in pairs(main_technology_levels) do
      if level.name == level_name then
        found = true
        break
      end

      if level.name == technology_manager_data.current_technology_level then
        break
      end
    end
  end

  assert(found) -- make sure we are on a tech level at or above the one we are researching up to

  for _, level in pairs(main_technology_levels) do
    for _, technology in pairs(level.techs) do
      game.forces.player.technologies[technology].researched = true
    end

    if level.name == level_name then
      break
    end
  end
end

technology_manager.reset = function()
  -- first disable and hide everything
  for _, technology in pairs(game.forces.player.technologies) do
    technology.enabled = false
    technology.visible_when_disabled = false
  end


  if technology_manager_data.current_technology_level ~= nil then
    for _, level in pairs(main_technology_levels) do
      for _, technology in pairs(level.techs) do
        game.forces.player.technologies[technology].enabled = true
      end

      if level.name == technology_manager_data.current_technology_level then
        break
      end
    end
  end

  if technology_manager_data.current_revealed_technology_level ~= nil then
    for _, level in pairs(main_technology_levels) do
      for _, technology in pairs(level.techs) do
        game.forces.player.technologies[technology].visible_when_disabled = true
      end

      if level.name == technology_manager_data.current_revealed_technology_level then
        break
      end
    end
  end

  for _, level in pairs(optional_technology_levels) do
    for _, level_name in pairs(technology_manager_data.optional_levels) do
      if level.name == level_name then
        for _, technology in pairs(level.techs) do
          game.forces.player.technologies[technology].enabled = true
        end
      end
    end
  end

  for _, level in pairs(optional_technology_levels) do
    for _, level_name in pairs(technology_manager_data.revealed_optional_levels) do
      if level.name == level_name then
        for _, technology in pairs(level.techs) do
          game.forces.player.technologies[technology].visible_when_disabled = true
        end
      end
    end
  end
end

technology_manager.migrate = function()
  if global.CAMPAIGNS_VERSION < 13 then
    technology_manager_data.optional_levels = {}
    technology_manager_data.revealed_optional_levels = {}
  end
end

return technology_manager