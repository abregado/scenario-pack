local handler = require("__base__.lualib.event_handler")
local math2d = require('math2d')
local rooms = require('room-gui')

local unlock_door = function(door_name,player)
  local door_data = nil
  local index_to_remove = nil
  for index, door in pairs(global.locked_doors) do
    if door.name == door_name then
      door_data = door
      index_to_remove = index
      break
    end
  end

  if door_data then
    for _, ingredient in pairs(door_data.cost) do
      player.remove_item({name=ingredient[1],count=ingredient[2]})
    end

    local gates = game.surfaces[1].find_entities_filtered({
      name = 'gate',
      area = door_data.area
    })
    for _, gate in pairs(gates) do
      gate.active = true
    end
    table.remove(global.locked_doors,index_to_remove)
  end
end

local point_inside_rooms = function(rooms,point)
  local result = false
  for _, box in pairs(rooms) do
    if math2d.bounding_box.contains_point(box,point) then result = true end
  end
  return result
end

local rooms_colliding_with_box = function(area)
  local colliding_areas = {}
  for _, zone_data in pairs(global.inner_zones) do
    if math2d.bounding_box.collides_with(area,zone_data.bounding_box) then
      table.insert(colliding_areas,zone_data.bounding_box)
    end
  end
  return colliding_areas
end

local cover_map_with_black = function()
  for chunk in game.surfaces[1].get_chunks() do
    local colliding_areas = rooms_colliding_with_box(chunk.area)
    if #colliding_areas == 0 then
      table.insert(global.outer_zones,{
        bounding_box = chunk.area,
        overlay_id = rendering.draw_rectangle({
          color = {0,0,0},
          left_top = {
            x = chunk.area.left_top.x -0.5,
            y = chunk.area.left_top.y -1.1,
          },
          right_bottom = {
            x = chunk.area.right_bottom.x +0.5,
            y = chunk.area.right_bottom.y -0.1,
          },
          surface = game.surfaces[1],
          filled = true
        })
      })
    else
      --fill with individual black tiles
      for x = chunk.area.left_top.x, chunk.area.right_bottom.x -1 do
        for y = chunk.area.left_top.y, chunk.area.right_bottom.y -1 do
          if #rooms_colliding_with_box({
            left_top = {
              x = x,
              y = y,
            },
            right_bottom = {
              x = x + 1,
              y = y + 1
            }
          }) == 0 then
          --if point_inside_rooms(colliding_areas,{x=x,y=y}) == false then
            table.insert(global.outer_zones,{
              bounding_box = nil,
              overlay_id = rendering.draw_rectangle({
                color = {0,0,0},
                left_top = {
                  x = x - 0.5,
                  y = y - 1.1,
                },
                right_bottom = {
                  x = x + 1.5,
                  y = y + 0.9,
                },
                surface = game.surfaces[1],
                filled = true
              })
            })
          end
        end
      end
    end
  end
end

local setup_unlockable_gate = function(area_name,cost_to_open)
  assert(game.surfaces[1].get_script_areas(area_name),"Invalid area for setting up door "..area_name)
  local area = game.surfaces[1].get_script_areas(area_name)[1].area
  if not global.locked_doors then global.locked_doors = {} end
  local gates = game.surfaces[1].find_entities_filtered({
  name = 'gate',
  area = area,
  })
  for _, gate in pairs(gates) do
    gate.active = false
  end
  table.insert(global.locked_doors, {
    area = game.surfaces[1].get_script_areas(area_name)[1].area,
    name = area_name,
    cost = cost_to_open
  })
end

local make_room_salvagable = function(bounding_box,surface)
  local ents = surface.find_entities_filtered({
    type = {'gate','wall','underground-belt'},
    invert = true
  })
  for _, ent in pairs(ents) do
    ent.minable = true
    ent.destructible = true
  end
end

local create_room_zone = function(area_name,surface)
  local areas = game.surfaces[1].get_script_areas(area_name)
  for _, area in pairs(areas) do
    table.insert(global.inner_zones,{
      bounding_box = area.area,
      overlay_id = rendering.draw_rectangle({
        color = {0,0,0,0.9},
        left_top = {
          x = area.area.left_top.x +0.5,
          y = area.area.left_top.y -0.1,
        },
        right_bottom = {
          x = area.area.right_bottom.x -0.5,
          y = area.area.right_bottom.y -1.1,
        },
        surface = game.surfaces[1],
        filled = true
      })
    })
    make_room_salvagable(area.area,surface)
  end
end

local make_all_fixed = function(surface)
  local ents = surface.find_entities_filtered({
    force = 'player'
  })
  for _, ent in pairs(ents) do
    ent.minable = false
    ent.destructible = false
  end
end

local on_game_created_from_scenario = function()
  global.inner_zones = {}
  global.outer_zones = {}

  make_all_fixed(game.surfaces[1])

  create_room_zone('inner-area',game.surfaces[1])
  create_room_zone('electronics-room',game.surfaces[1])

  areas = game.surfaces[1].get_script_areas('outer-area')
  for _, area in pairs(areas) do
    table.insert(global.outer_zones,{
      bounding_box = area.area,
      overlay_id = rendering.draw_rectangle({
        color = {0,0,0},
        left_top = {
          x = area.area.left_top.x +0.5,
          y = area.area.left_top.y -0.1,
        },
        right_bottom = {
          x = area.area.right_bottom.x -0.5,
          y = area.area.right_bottom.y -1.1,
        },
        surface = game.surfaces[1],
        filled = true
      })
    })
    local gates = game.surfaces[1].find_entities_filtered({
      name = 'gate',
      area = area.area
    })
    for _, gate in pairs(gates) do
      gate.active = false
    end
  end
  setup_unlockable_gate('door-east-corridor',{{'electronic-circuit',10},{'iron-gear-wheel',30}})

  cover_map_with_black()

  game.surfaces[1].freeze_daytime = true
  game.surfaces[1].min_brightness = 0
  game.surfaces[1].daytime = 0.5
end

local on_player_changed_position = function(event)
  local player = game.players[event.player_index]
  if player.controller_type == defines.controllers.character then
    player.zoom = 2
    for _ , zone in pairs(global.inner_zones) do
      rendering.set_visible(zone.overlay_id,not math2d.bounding_box.contains_point(zone.bounding_box,player.position))
    end
  end

  if player.controller_type == defines.controllers.character then
    for _ , door_data in pairs(global.locked_doors) do
      if not player.gui.left[door_data.name] and math2d.bounding_box.contains_point(door_data.area,player.position) then
        local has_all = true
        for _, ingredient in pairs(door_data.cost) do
          if player.get_main_inventory().get_item_count(ingredient[1]) < ingredient[2] then
            has_all = false
          end
        end
        rooms.build_door_gui(door_data,player,has_all)
      elseif player.gui.left[door_data.name] and not math2d.bounding_box.contains_point(door_data.area,player.position) then
        player.gui.left[door_data.name].destroy()
      end
    end
  end
end

local on_gui_click = function(event)
  if event.element.name == 'button-unlock' then
    unlock_door(event.element.parent.name,game.players[event.player_index])
    event.element.parent.destroy()
  end
end

local on_selected_entity_changed = function(event)
  local selected = game.players[event.player_index].selected
  if selected == nil then return end
  local inside = false
  for _, zone in pairs(global.inner_zones) do
    if math2d.bounding_box.contains_point(zone.bounding_box,selected.position) then
      inside = true
    end
  end
  if inside == false then game.players[event.player_index].selected = nil end
end

local events = {
  [defines.events.on_game_created_from_scenario] = on_game_created_from_scenario,
  [defines.events.on_player_changed_position] = on_player_changed_position,
  [defines.events.on_gui_click] = on_gui_click,
  [defines.events.on_selected_entity_changed] = on_selected_entity_changed,
}

local event_recievers = {
  events
}

handler.setup_event_handling(event_recievers)