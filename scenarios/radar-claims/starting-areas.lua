local show_creation_gui = function(player)
  local frame = player.gui.center.add({
    type = 'frame',
    name = 'build_frame',
    direction = 'vertical',
    caption = {'starting-areas-gui.heading'}
  })
  frame.add({
    type ='label',
    name = 'build_label',
    caption = {'starting-areas-gui.text'}
  })
  frame.add({
    type = 'textfield',
    name = 'build_amount',
    text = 8,
    numeric = true,
    allow_decimal = false,
    allow_negative = false,
  })
  frame.add({
    type = 'button',
    name = 'build_button',
    caption = {'starting-areas-gui.button'}
  })
end

local top_bottom_row = function(areas,side_length,spacing)

  local row = {}
  table.insert(row,0)
  for x = 1, side_length do
    if x % (spacing+1) == 0 then
      table.insert(row,1)
    else
      table.insert(row,0)
    end
  end
  table.insert(row,0)
  table.insert(row,0)
  return row
end


local empty_row = function(length)
  local row = {}
  for x = 1, length+1 do
    table.insert(row,0)
  end
  return row
end

local row_with_areas = function(length)
  local row = {}
  table.insert(row, 1)
  for x = 1, length-2 do
    table.insert(row,0)
  end
  table.insert(row,0)
  table.insert(row,1)
  return row
end

local request_generate_mapped_chunks = function()
  local map = global.starting_areas_data.map
  for x, row in pairs(map) do
    for y, state in pairs(row) do
      game.surfaces[1].request_to_generate_chunks({
        x = x,
        y = y,
      },3)
    end
  end
  game.surfaces[1].force_generate_chunk_requests()
end

local destroy_mapped_chunks = function()
  local map = global.starting_areas_data.map
  for x, row in pairs(map) do
    for y, state in pairs(row) do
      game.surfaces[1].delete_chunk({
        x = x,
        y = y,
      })
    end
  end
  request_generate_mapped_chunks()
end

local generate_map = function(areas)
  local per_side = math.ceil(areas/4)
  local spacing = 1
  local side_length = per_side*(1+spacing)

  local map = {}
  table.insert(map,top_bottom_row(areas,side_length,spacing))
  for y=1,per_side do
    table.insert(map,empty_row(side_length+2))
    table.insert(map,row_with_areas(side_length+2))
  end
  table.insert(map,empty_row(side_length+2))
  table.insert(map,top_bottom_row(areas,side_length,spacing))

  for _, row in pairs(map) do
    print(serpent.line(row))
  end

  global.starting_areas_data.map = map
  global.starting_areas_data.generated = true

  for x, row in pairs(map) do
    for y, state in pairs(row) do
      if state == 1 then
        table.insert(global.starting_areas_data.areas,{generated=false,position = {x=x,y=y},area={
          left_top = {
            x = x * 32,
            y = y * 32
          },
          right_bottom = {
            x = x * 32+32,
            y = y * 32+32
          },
        },owner='none'})
      end
    end
  end

  destroy_mapped_chunks()
end

local build_starting_area = function(surface,area)
  for x=2,16 do
    for y=2,3 do
      local res = surface.create_entity({
        name='iron-ore',
        position = {
          x = x + area.left_top.x,
          y = y + area.left_top.y,
        }
      })
      res.amount = 1000000
    end
  end

  for x=2,10 do
    for y=7,8 do
      local res = surface.create_entity({
        name='copper-ore',
        position = {
          x = x + area.left_top.x,
          y = y + area.left_top.y,
        }
      })
      res.amount = 1000000
    end
  end

  for x=2,8 do
    for y=13,14 do
      local res = surface.create_entity({
        name='coal',
        position = {
          x = x + area.left_top.x,
          y = y + area.left_top.y,
        }
      })
      res.amount = 1000000
    end
  end

  for x=2,4 do
    for y=18,19 do
      local res = surface.create_entity({
        name='stone',
        position = {
          x = x + area.left_top.x,
          y = y + area.left_top.y,
        }
      })
      res.amount = 1000000
    end
  end

  local water={}
  for x=2,5 do
    for y=2,5 do
      table.insert(water,{
        name='water',
        position = {
          x = area.left_top.x+x,
          y = area.right_bottom.y-y,
        }
      })
    end
  end
  surface.set_tiles(water)

end

local on_game_created_from_scenario = function()
  global.starting_areas_data = {}
  global.starting_areas_data.map = {}
  global.starting_areas_data.areas = {}
  global.starting_areas_data.generated = false
  end

local on_player_created = function(event)
  local player = game.players[event.player_index]
  if event.player_index == 1 and global.starting_areas_data.generated == false then
    show_creation_gui(player)
  end

  --move player to centre of their starting chunk
  --set their spawn here

end

local on_gui_click = function(event)
  local clicked = event.element
  if clicked.name == 'build_button' then
    local parent = clicked.parent
    generate_map(parent.build_amount.text)
    destroy_mapped_chunks()
    request_generate_mapped_chunks()
    clicked.parent.destroy()
  end
end

local find_unoccupied_starting_area = function()
  game.print(#global.starting_areas_data.areas)
  for _, area_data in pairs(global.starting_areas_data.areas) do
    if area_data.owner == 'none' then
      return area_data
    end
  end
  return nil
end

local on_chunk_generated = function(event)
  if global.starting_areas_data.map and global.starting_areas_data.map[1] then
    local map = global.starting_areas_data.map
    if map[event.position.x] and map[event.position.x][event.position.y] then
      local state = map[event.position.x][event.position.y]
      local tiles = {}
      for x=event.area.left_top.x,event.area.right_bottom.x do
        for y=event.area.left_top.y,event.area.right_bottom.y do
          if state == 0 then
            --table.insert(tiles,{position={x,y},name='water'})
          elseif state == 1 then
            table.insert(tiles,{position={x,y},name='refined-concrete'})
          end
        end
      end
      event.surface.set_tiles(tiles)
      if state == 1 then
        local ents = event.surface.find_entities(event.area)
        for _, ent in pairs(ents) do ent.destroy() end
        event.surface.destroy_decoratives({area=event.area})
        build_starting_area(event.surface,event.area)
      end
      game.forces.player.chart(event.surface,event.area)
    end
  end
end

local starting_areas = {}

starting_areas.find_unoccupied_starting_area = find_unoccupied_starting_area
starting_areas.generate_map = generate_map

starting_areas.events = {
  [defines.events.on_game_created_from_scenario] = on_game_created_from_scenario,
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_gui_click] = on_gui_click,
  [defines.events.on_chunk_generated] = on_chunk_generated,
}

return starting_areas