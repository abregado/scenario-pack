local locations = require(mod_name..".lualib.locations")

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
        print(serpent.line(chunk_pos))
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

local recreate_chunks_in_area_name = function(area_name,exclusion_area_name)
  local chunk_list = generate_chunk_list(area_name)
  if exclusion_area_name then
    chunk_list = chunk_list_subtract(chunk_list,generate_chunk_list(exclusion_area_name))
  end
  for _, chunk_pos in pairs(chunk_list) do
    locations.get_main_surface().delete_chunk(chunk_pos)
    locations.get_main_surface().request_to_generate_chunks({x=chunk_pos.x*32,y=chunk_pos.y*32},1)
  end
end

local is_chunk_modified = function(chunk_pos)
  for _, modified_chunk_pos in pairs(global.template_expand_data.modified_chunks) do
    if modified_chunk_pos.x == chunk_pos.x and modified_chunk_pos.y == chunk_pos.y then return true end
  end
  return false
end

local on_chunk_generated = function(event)
  if event.surface.name == locations.get_main_surface().name and is_chunk_modified(event.position) then
    locations.get_template_surface().clone_area(
      {
        source_area = event.area,
        destination_area = event.area,
        destination_surface = locations.get_main_surface(),
      })
  end
end

local on_game_created_or_loaded = function()
  global.template_expand_data.modified_chunks = generate_chunk_list('modified')
end

local init = function()
  global.template_expand_data = {}
  on_game_created_or_loaded()
end

local template_expand = {}

template_expand.on_load = on_game_created_or_loaded
template_expand.init = init
template_expand.recreate_chunks_around_area_name = recreate_chunks_around_area_name

template_expand.events = {
  [defines.events.on_chunk_generated] = on_chunk_generated,
}

return template_expand