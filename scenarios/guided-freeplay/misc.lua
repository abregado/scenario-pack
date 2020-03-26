local math2d = require("math2d")
local locations = require('locations')
local story = require("tom_story")

local misc = {}

local misc_update_data =
{
  radar_has_scanned_a_sector = false
}

misc.init = function()
  global.misc_update_data = misc_update_data
end

misc.on_load = function()
  misc_update_data = global.misc_update_data or misc_update_data
end

misc.radar_has_scanned_a_sector = function()
  return misc_update_data.radar_has_scanned_a_sector
end

local on_sector_scanned = function()
  misc_update_data.radar_has_scanned_a_sector = true
end

-- TODO: expose these through LuaDefines
misc.tile_size = 32
misc.chunk_size = 32


-- Figures out the zoom level you need to display a certain area in a cutscene
misc.get_cutscene_show_area_parameters = function(area, resolution, zoom_padding_tiles, position)
  zoom_padding_tiles = zoom_padding_tiles or 5
  position = position or math2d.bounding_box.get_centre(area)

  local horizontal_needed_tiles = math.max(math.abs(area.right_bottom.x - position.x),
                                           math.abs(area.left_top.x - position.x))
  local horizontal_zoom_level = resolution.width /
                                ((horizontal_needed_tiles + zoom_padding_tiles) * misc.tile_size * 2)

  local vertical_needed_tiles = math.max(math.abs(area.right_bottom.y - position.y),
                                         math.abs(area.left_top.y - position.y))
  local vertical_zoom_level = resolution.height /
                              ((vertical_needed_tiles + zoom_padding_tiles) * misc.tile_size * 2)

  local zoom = math.min(horizontal_zoom_level, vertical_zoom_level)

  return {position = position, zoom = zoom}
end

misc.log_evolution_level = function(title)
  local deaths = game.forces.player.kill_count_statistics.get_output_count("character")
  local turret_deaths = 0
  for _, turret in pairs({"gun-turret","laser-turret","flamethrower-turret"}) do
    turret_deaths = turret_deaths + game.forces.player.kill_count_statistics.get_output_count(turret)
  end
  local spawner_kills = 0
  for _, spawner in pairs({"biter-spawner","spitter-spawner"}) do
    spawner_kills = spawner_kills + game.forces.player.kill_count_statistics.get_input_count(spawner)
  end
  local biter_kills = 0
  for _, biter in pairs({"small-biter","medium-biter","big-biter","small-spitter","medium-spitter","big-spitter"}) do
    biter_kills = biter_kills + game.forces.player.kill_count_statistics.get_input_count(biter)
  end

  local data = tostring(game.ticks_played)..","..title..","..tostring(game.forces.enemy.evolution_factor)..
    ","..tostring(deaths)..","..tostring(turret_deaths)..","..tostring(spawner_kills)..","..tostring(biter_kills)..",\n"
  game.write_file("evolution_logs.csv",data,true)
end

misc.generate_screenshot_area_node = function(campaign_name, area_name, title)
  local node =
  {
    name = "screenshot_area_" .. title,

    init = function()
      if global.playthrough_number == nil then
        global.playthrough_number = game.forces.player.item_production_statistics.get_input_count('transport-belt') +
          game.forces.player.item_production_statistics.get_input_count('iron-ore')
      end
      if global.expected_skill == nil then
        _, global.expected_skill = assess_player()
      end

      global.saved_daytime = locations.get_main_surface().daytime
      locations.get_main_surface().daytime = 0
      misc.render_stats_to_area(area_name)
      local area = locations.get_area(area_name)
      local resolution = {width = 4096, height = 4096}
      local show_params = misc.get_cutscene_show_area_parameters(area, resolution, 0)
      game.take_screenshot
      {
        position = show_params.position,
        zoom = show_params.zoom,
        resolution={resolution.width, resolution.height},
        show_gui=false,
        show_entity_info=true,
        path = "campaign_base_screenshots/" ..  campaign_name .. '_' .. global.expected_skill .. '_' ..
          global.playthrough_number ..  "_" .. title  .. '.jpg'
      }
    end,
    condition = function()
      return story.check_seconds_passed("main_story",1)
    end,
    action = function()
      locations.get_main_surface().daytime = global.saved_daytime
      misc.destroy_render_objects(global.stat_lines)
      game.write_file("campaign_base_screenshots/email_to.txt",{"campaign-email-message.text"},false)
    end,
  }

  return node
end

misc.destroy_render_objects = function(list)
  for _, id in pairs(list) do
    rendering.destroy(id)
  end
end

local render_text_at_position = function(text,position)
  local new_id = rendering.draw_text({
    text = text,
    surface = locations.get_main_surface(),
    target = position,
    color = {r=1,g=1,b=1},
    scale = 4,
  })
  table.insert(global.stat_lines,new_id)
end

misc.convert_ticks_to_string = function(ticks)
  local text = ""
  ticks = tonumber(ticks)
  while ticks >= 60 do
    --add hours
    local hours = 60*60*60
    if (ticks / hours) > 0 then
      text = text..tostring(math.floor(ticks/hours))..':'
      ticks = ticks % hours
    end
    local minutes = 60*60
    if (ticks / minutes) > 0 then
      text = text..tostring(math.floor(ticks/minutes))..':'
      ticks = ticks % minutes
    end
    local seconds = 60
    if (ticks / seconds) > 0 then
      text = text..tostring(math.floor(ticks/seconds))
      ticks = ticks % seconds
    end
  end
  if text == "" then text = "0:0:0" end
  return text
end

local calc_distance_travelled = function()
  local total_distance = 0
  local last_pos = nil
  for _, position in pairs(global.player_positions) do
    if last_pos then
      total_distance = total_distance + math.floor(math2d.position.distance(last_pos,position))
    end
    last_pos = position
  end
  return total_distance
end

misc.destroy_all_entities = function(surface, filters)
  local ents = surface.find_entities_filtered(filters)
  for _, ent in pairs(ents) do
    ent.destroy()
  end
end

misc.add_go_to_commands_from_path = function(path, commands, distraction)
  if distraction == nil then
    distraction = defines.distraction.by_damage
  end

  for _, pos in pairs(path) do

    if type(pos) == "string" then
      pos = locations.get_pos(pos)
    end

    table.insert(commands,
      {
        type = defines.command.go_to_location,
        destination=pos,
        distraction = distraction,
        pathfind_flags = {cache = false},
      })
  end
end

misc.events = { [defines.events.on_sector_scanned] = on_sector_scanned }

return misc
