local locations = require(mod_name..".lualib.locations")
local math2d = require('math2d')

local generate_chunk_list = function(area_name)
  local chunks = {}
  local areas
  if type(area_name) == 'string' then
    areas = locations.get_template_surface().get_script_areas(area_name)
  else
    areas = {{area=area_name}}
  end
  for _, data in pairs(areas) do
    for x = data.area.left_top.x, data.area.right_bottom.x,31 do
      for y = data.area.left_top.y, data.area.right_bottom.y,31 do
        local chunk_pos = {x=math.floor(x/32),y=math.floor(y/32)}
        table.insert(chunks,chunk_pos)
      end
    end
  end
  return chunks
end

local chunk_list_subtract = function(chunk_list,chunk_list_2)
  for index, chunk_pos in pairs(chunk_list) do
    local found = false
    for _, chunk_to_remove in pairs(chunk_list_2) do
      if chunk_pos.x == chunk_to_remove.x and chunk_pos.y == chunk_to_remove.y then found = true end
    end
    if found then table.remove(chunk_list,index)
    end
    return chunk_list
  end
end

local recreate_chunks_around_area_name = function(area_name)
  local area = locations.get_area(area_name)
  local outer_area = {
    left_top = {
      x = area.left_top.x -1,
      y = area.left_top.y -1
    },
    right_bottom = {
      x = area.right_bottom.x +1,
      y = area.right_bottom.y +1
    }
  }
  local chunk_list = chunk_list_subtract(generate_chunk_list(outer_area),generate_chunk_list(area))
  for _, chunk_pos in pairs(chunk_list) do
    locations.get_main_surface().delete_chunk(chunk_pos)
    locations.get_main_surface().request_to_generate_chunks({x=chunk_pos.x*32,y=chunk_pos.y*32},1)
  end
end



local is_chunk_in_list = function(chunk_pos,list)
  for _, modified_chunk_pos in pairs(list) do
    if modified_chunk_pos.x == chunk_pos.x and modified_chunk_pos.y == chunk_pos.y then return true end
  end
  return false
end

local is_chunk_modified = function(chunk_pos)
  for _, modified_chunk_pos in pairs(global.template_expand_data.modified_chunks) do
    if modified_chunk_pos.x == chunk_pos.x and modified_chunk_pos.y == chunk_pos.y then return true end
  end
  return false
end

local regen_chunks_in_list = function(chunk_list)
  for _, chunk_pos in pairs(chunk_list) do
    locations.get_main_surface().delete_chunk(chunk_pos)
    --locations.get_main_surface().request_to_generate_chunks({x=chunk_pos.x*32,y=chunk_pos.y*32},1)
  end
end

local recreate_chunks_in_area_name = function(area_name,exclusion_area_name)
  local chunk_list = generate_chunk_list(area_name)
  if exclusion_area_name then
    chunk_list = chunk_list_subtract(chunk_list,generate_chunk_list(exclusion_area_name))
  end
  regen_chunks_in_list(chunk_list)
end

local delete_all_chunks_except_area = function(area_name)
  local surface = locations.get_main_surface()
  local safe_chunks = generate_chunk_list(area_name)
  local chunks_to_delete = {}
  print("total: "..#surface.get_chunks().." safe: "..#safe_chunks)
  for chunk_pos in surface.get_chunks() do
    if is_chunk_in_list(chunk_pos,safe_chunks) == false then
      table.insert(chunks_to_delete,chunk_pos)
    end
  end
  regen_chunks_in_list(chunks_to_delete)
end

local set_play_area_size = function(width,height)
  local settings = locations.get_main_surface().map_gen_settings
  if width == nil then width = settings.width end
  if width == height then width = settings.height end
  settings.width = width
  settings.height = height
  locations.get_main_surface().map_gen_settings = settings
  global.template_expand_data.play_area = {
    left_top = {
      x = width/-2,
      y = height/-2
    },
    right_bottom = {
      x = width/2,
      y = height/2
    }
  }
end

local resize_keeping_area = function(width,height,area_name)
  if area_name == nil then area_name = global.template_expand_data.play_area end
  delete_all_chunks_except_area(area_name)
  set_play_area_size(width,height)
end

local on_chunk_generated = function(event)
  if math2d.bounding_box.contains_box(global.template_expand_data.play_area,event.area) then
    if event.surface.name == locations.get_main_surface().name and is_chunk_modified(event.position) then
      locations.get_template_surface().clone_area(
        {
          source_area = event.area,
          destination_area = event.area,
          destination_surface = locations.get_main_surface(),
        })
    end
  else
    local lt = event.area.left_top
    local rb = event.area.right_bottom
    local tiles = {}
    for x=lt.x,rb.x-1 do
      for y=lt.y,rb.y-1 do
        table.insert(tiles,{name='out-of-map',position={x=x,y=y}})
      end
    end
    event.surface.set_tiles(tiles)

  end
end

local on_entity_cloned = function(event)
  if event.destination.type == 'unit-spawner' then
    event.destination.active = true
  end
end

local on_game_created_or_loaded = function()
  global.template_expand_data.modified_chunks = generate_chunk_list('modified')
end

local init = function(starting_area)
  global.template_expand_data = {}
  global.template_expand_data.play_area = starting_area
end

local template_expand = {}

template_expand.on_load = on_game_created_or_loaded
template_expand.init = init
template_expand.resize_keeping_area = resize_keeping_area


template_expand.events = {
  [defines.events.on_chunk_generated] = on_chunk_generated,
  [defines.events.on_entity_cloned] = on_entity_cloned,
}

return template_expand