local handler = require("event_handler")
local math2d = require("math2d")

local core_names = {
  "Prime",
  "Secundus",
  "Tertius",
  "Four",
  "Five",
  "Six",
}

local clear_all_ids_at_core = function(core)
  for _, id in pairs(core.overlay_ids) do
    rendering.destroy(id)
  end
  core.overlay_ids = {}
end

local recreate_core_rendering_objects = function(core)
  if #core.overlay_ids > 0 then
    clear_all_ids_at_core(core)
  end

  local box_id = rendering.draw_rectangle({
    color = {0,1,0},
    left_top = core.view_box.left_top,
    right_bottom = core.view_box.right_bottom,
    surface = game.surfaces[1]
  })
  table.insert(core.overlay_ids,box_id)

  for index, player in pairs(core.players) do
    local name_id = rendering.draw_text({
      text = player.name,
      color = player.color,
      target = {
        x = core.structure.bounding_box.right_bottom.x + 1,
        y = core.structure.bounding_box.left_top.y + index - 1,
      },
      surface = game.surfaces[1]
    })
    table.insert(core.overlay_ids,name_id)
  end

  for _, id in pairs(core.overlay_ids) do
    rendering.set_players(id,core.players)
  end
end

local map_core_for_force = function(core,force)
  force.add_chart_tag(core.structure.surface,{
    position = core.structure.position,
    text = core.name,
  })
end

local discover_core = function(core,force)
  if not force then force = game.forces.player end
  --give_found_core_alert(core,force)
  map_core_for_force(core,force)
  game.print("Discovered core: "..core.name)
  core.discovered = true
end

local store_player_inventory_in_core = function(player,core)
  local main_inventory = player.get_main_inventory()
  if not core.inventories[player.name] then
    core.inventories[player.name] = {}
  end
  for item_name, count in pairs(main_inventory.get_contents()) do
    table.insert(core.inventories[player.name],{name=item_name,count=count})
    main_inventory.remove({name=item_name,count=count})
  end
end

local retrieve_player_inventory_from_core = function(player,core)
  if core.inventories[player.name] then
    for _, item_stack in pairs(core.inventories[player.name]) do
      --print(serpent.line(item_stack))
      player.insert(item_stack)
    end
    core.inventories[player.name] = {}
  else
    core.inventories[player.name] = {}
  end
end

local transfer_player_between_cores = function(player,source,destination)
  if source then
    for index, current in pairs(source.players) do
      if current.name == player.name then
        store_player_inventory_in_core(player,source)
        source.players[index] = nil
      end
    end
    recreate_core_rendering_objects(source)
  end
  table.insert(destination.players,player)
  retrieve_player_inventory_from_core(player,destination)
  recreate_core_rendering_objects(destination)
  player.teleport(destination.structure.position)
end

local set_core_view_area_by_radius = function(core)
  core.view_box = {
      left_top = {
        x = core.structure.position.x - core.radius,
        y = core.structure.position.y - core.radius,
      },
      right_bottom = {
        x = core.structure.position.x + core.radius,
        y = core.structure.position.y + core.radius,
      },
    }
  recreate_core_rendering_objects(core)
end

local set_core_radius = function(core,radius)
  core.radius = radius
end

local create_core_at = function(position,area)
  local core_number = #global.cores + 1
  local radius = math.random(10,50)
  local fit_position = nil
  if area then
    print(serpent.line(area))
    fit_position = game.surfaces[1].find_non_colliding_position_in_box(
      'crash-site-lab-repaired',
      area,
      0.1,
      true
    )
  end
  if fit_position ==nil then
    local area_under_pos = math2d.bounding_box.create_from_centre(position,5,3)
    local ents_to_destroy = game.surfaces[1].find_entities_filtered({
      area = area_under_pos
    })
    for _, ent in pairs(ents_to_destroy) do
      ent.destroy()
    end
    local tiles = {}
    for x = area_under_pos.left_top.x,area_under_pos.right_bottom.x do
      for y = area_under_pos.left_top.y, area_under_pos.right_bottom.y do
        table.insert(tiles,{name='dirt-1',position={x=x,y=y}})
      end
    end
    game.surfaces[1].set_tiles(tiles)
  end
  local new_core = game.surfaces[1].create_entity({
    name='crash-site-lab-repaired',
    position = fit_position or position,
    force = game.forces.player,
  })
  new_core.backer_name = core_names[core_number] or 'core'..tostring(core_number)
  new_core.minable = false
  new_core.destructible = false

  local core_data = {
    name = core_names[core_number] or 'core'..tostring(core_number),
    structure = new_core,
    radius = radius,
    view_box = {},
    free_power = true,
    players = {},
    overlay_ids = {},
    inventories = {},
    discovered = false
  }
  set_core_view_area_by_radius(core_data)
  table.insert(global.cores,core_data)
  recreate_core_rendering_objects(core_data)
  return core_data
end

local restrict_player_to_core_zone = function(player,core)
  local inside = math2d.bounding_box.contains_point(core.view_box,player.position)
  if not inside then
    if player.position.x > core.view_box.right_bottom.x then
      player.teleport({
        x = core.view_box.right_bottom.x,
        y = player.position.y,
      })
    elseif player.position.x < core.view_box.left_top.x then
      player.teleport({
        x = core.view_box.left_top.x,
        y = player.position.y,
      })
    end
    if player.position.y > core.view_box.right_bottom.y then
      player.teleport({
        x = player.position.x,
        y = core.view_box.right_bottom.y,
      })
    elseif player.position.y < core.view_box.left_top.y then
      player.teleport({
        x = player.position.x,
        y = core.view_box.left_top.y,
      })
    end
  end
end

local create_core_gui = function(player)
  local core_gui = player.gui.center.add({
    type='frame',
    name='core_gui',
  })
  core_gui.style.minimal_width = 100
  core_gui.style.minimal_height = 100
  player.opened = core_gui

  for index, core in pairs(global.cores) do
    if core.discovered then
      local button = core_gui.add({
        type = 'button',
        name = 'teleport-'..index,
        caption = core.name,
      })
      if core.structure.energy > 0 or core.free_power then

      else
        button.enabled = false
      end
    end
  end
end

local find_players_core = function(player)
  for _, core in pairs(global.cores) do
    for _, listed_player in pairs(core.players) do
      if player == listed_player then
        return core
      end
    end
  end
  return nil
end

local on_player_created = function(event)
  local player = game.players[event.player_index]
  local character = player.character
  character.destroy()
  player.character = nil
  transfer_player_between_cores(player,nil,global.cores[1])
end

local on_game_created_from_scenario = function(event)
  global.cores = {}
  local prime_core = create_core_at({x=0,y=0})
  set_core_radius(prime_core,100)
  set_core_view_area_by_radius(prime_core)
end

local on_gui_click = function(event)
  local player = game.players[event.player_index]
  if event.element.parent.name == 'core_gui' and event.element.type == 'button' then
    local destination = string.sub(event.element.name,10)
    local source = find_players_core(player)
    transfer_player_between_cores(player,source,global.cores[tonumber(destination)])
    player.opened = nil
  end
end

local on_gui_opened = function(event)
  local player = game.players[event.player_index]
  if event.entity and event.entity.name == 'crash-site-lab-repaired' then
    player.opened = nil
    create_core_gui(player)
  end
end

local on_gui_closed = function(event)
  local player = game.players[event.player_index]
  if player.gui.center.core_gui then
    player.gui.center.core_gui.destroy()
  end
end

local on_player_changed_position = function(event)
 local player = game.players[event.player_index]

  for _, core in pairs(global.cores) do
    for _, listed_player in pairs(core.players) do
      if player == listed_player then
        restrict_player_to_core_zone(player,core)
      end
    end
  end
end

local on_chunk_generated = function(event)
  local contains_core = math.random() > 0.995
  if contains_core then
    create_core_at(math2d.bounding_box.get_centre(event.area),event.area)
  end
end

local on_chunk_charted = function(event)
  local count = game.surfaces[event.surface_index].count_entities_filtered({
    name = 'crash-site-lab-repaired',
    area = event.area
  })
  if count > 0 then
    local found = nil
    for _, existing_core in pairs(global.cores) do
      if math2d.bounding_box.contains_point(event.area,existing_core.structure.position) then
        found = existing_core
        if existing_core.discovered == false then
          discover_core(existing_core)
        end
      end
    end
    --assert(found,"Charted a core that isnt attached to a core_data: "..tostring(found and found.name))
  end
end

local main_events = {
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_game_created_from_scenario] = on_game_created_from_scenario,
  [defines.events.on_gui_opened] = on_gui_opened,
  [defines.events.on_gui_closed] = on_gui_closed,
  [defines.events.on_gui_click] = on_gui_click,
  [defines.events.on_player_changed_position] = on_player_changed_position,
  [defines.events.on_chunk_generated] = on_chunk_generated,
  [defines.events.on_chunk_charted] = on_chunk_charted
}

handler.add_lib({events= main_events})