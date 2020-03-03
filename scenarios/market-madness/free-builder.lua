local free_builder = {}

local structure_list = {
  {'transport-belt',1},
  {'underground-belt',9},
  {'splitter',24},
  {'fast-transport-belt',6},
  {'fast-underground-belt',49},
  {'fast-splitter',67},
  {'express-transport-belt',26},
  {'express-underground-belt',149},
  {'express-splitter',42*20+80+73+86,},
  {'assembling-machine-1',27},
  {'assembling-machine-2',10+35+9},
  {'assembling-machine-3',42*30+20+130+148},
  {'pipe',1},
  {'pipe-to-ground',15},
  {'oil-refinery',20+75+40+15},
  {'chemical-plant',25+20+8},
  {'stone-furnace',5},
  {'steel-furnace',20+30},
  {'electric-furnace',20+50+420+10+25},
  {'centrifuge',42*200+250+400+500+1500},
  {'pump',15},
  {'inserter',6},
  {'burner-inserter',3},
  {'fast-inserter',13},
  {'stack-inserter',84+55+32},
  {'filter-inserter',23},
  {'stack-filter-inserter',84+60+40},
  {'long-handed-inserter',9},
  {'small-electric-pole',2},
  {'medium-electric-pole',14},
  {'big-electric-pole',34},
}

free_builder.add_free_item =function(item_name,item_cost)
  global.free_builder_data.free_items[item_name] = {name = item_name,cost = item_cost}
end

free_builder.on_load = function ()
  global.free_builder_data = {
    players = {},
    free_items = {},
    force = game.create_force('free-builders'),
    value = 0
  }
  for _, item_data in pairs(structure_list) do
    global.free_builder_data.free_items[item_data[1]] = {name = item_data[1],cost = item_data[2]}
    --global.free_builder_data.force.recipes[item_data[1]].enabled = true
  end
  print(#global.free_builder_data.free_items," in free item list")
  global.free_builder_data.force.disable_all_prototypes()
end


free_builder.set_player_state = function(player,state)
  if not global.free_builder_data.players[player.name] then
    global.free_builder_data.players[player.name] = {
      player_data = player
    }
  end

  local old_character = player.character
  player.character = nil
  old_character.destroy()


  if state then
    free_builder.set_player_active(player)
  else
    free_builder.set_player_inactive(player)
  end
end

free_builder.set_player_inactive = function(player)
  player.set_controller({type = defines.controllers.ghost})
end

free_builder.set_player_active = function(player)
  player.print({'free-builder.welcome-message'})
  player.set_controller({type = defines.controllers.god})
  player.get_main_inventory().clear()
  for name, item_data in pairs(global.free_builder_data.free_items) do
    player.insert({name=name,count=1})
  end
  player.force = global.free_builder_data.force
end

free_builder.get_value = function()
  return global.free_builder_data.value
end

local on_built_entity = function(event)
  local player = game.players[event.player_index]
  if global.free_builder_data.players[player.name] then
    if global.free_builder_data.free_items[event.created_entity.name] then
      player.insert(event.stack)
      global.free_builder_data.value = global.free_builder_data.value + global.free_builder_data.free_items[event.created_entity.name].cost
      player.print({'free-builder.value-notification',global.free_builder_data.value})
    end
  end
end

local on_player_dropped_item = function(event)
  local player = game.players[event.player_index]
  if global.free_builder_data.players[player.name] then
    if global.free_builder_data.free_items[event.entity.stack.name] then
      player.insert(event.entity.stack)
    end
  end
  event.entity.destroy()
end

local on_player_mined_item = function(event)
  local player = game.players[event.player_index]
  if global.free_builder_data.players[player.name] then
    if not global.free_builder_data.free_items[event.item_stack.name] then
      game.players[event.player_index].remove_item(event.item_stack)
    end
  end
end

local on_picked_up_item = function(event)
  local player = game.players[event.player_index]
  if global.free_builder_data.players[player.name] then
    if not global.free_builder_data.free_items[event.item_stack.name] then
      game.players[event.player_index].remove_item(event.item_stack)
    end
  end
end

local on_player_mined_entity = function(event)
  local player = game.players[event.player_index]
  event.buffer.clear()
  if global.free_builder_data.players[player.name] then
    if global.free_builder_data.free_items[event.entity.name] then
      global.free_builder_data.value = global.free_builder_data.value - global.free_builder_data.free_items[event.entity.name].cost
      player.print({'free-builder.value-notification',global.free_builder_data.value})
    end
  end
end

local on_player_changed_position = function(event)
  local player = game.players[event.player_index]
  if global.free_builder_data.players[player.name] and global.free_builder_data.players[player.name].view_box then
    local box = global.free_builder_data.players[player.name].view_box
    if player.position.x > box.right_bottom.x then player.teleport({x=box.right_bottom.x,y=player.position.y}) end
    if player.position.x < box.left_top.x then player.teleport({x=box.left_top.x,y=player.position.y}) end
    if player.position.y > box.right_bottom.y then player.teleport({x=player.position.x,y=box.right_bottom.y}) end
    if player.position.y < box.left_top.y then player.teleport({x=player.position.x,y=box.left_top.y}) end
  end
end

free_builder.set_player_build_area = function(player,bounding_box)
  if global.free_builder_data.players[player.name] then
    global.free_builder_data.players[player.name].view_box = bounding_box
  end
end

free_builder.events = {
  [defines.events.on_built_entity] = on_built_entity,
  [defines.events.on_player_mined_entity] = on_player_mined_entity,
  [defines.events.on_player_mined_item] = on_player_mined_item,
  [defines.events.on_picked_up_item] = on_picked_up_item,
  [defines.events.on_player_dropped_item] = on_player_dropped_item,
  [defines.events.on_player_changed_position] = on_player_changed_position,
}

return free_builder