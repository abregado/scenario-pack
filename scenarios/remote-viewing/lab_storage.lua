local new_lab_data = function(lab_ent)
  return {
    lab = lab_ent,
    tech_name = nil,
    box_id = rendering.draw_rectangle({
      color = { 0, 1, 0 },
      left_top = lab_ent.bounding_box.left_top,
      right_bottom = lab_ent.bounding_box.right_bottom,
      surface = game.surfaces[1],
      forces = {game.forces.player},
      only_in_alt_mode = true,
    }),
    label_id = rendering.draw_text({
      text = { "overlay.ready-for-tech" },
      color = { 0, 1, 0 },
      target = {
        x=lab_ent.position.x,
        y=lab_ent.position.y
      },
      surface = game.surfaces[1],
      alignment = 'center',
      forces = {game.forces.player},
      only_in_alt_mode = true,
    })
  }
end

local set_data_indicator_status = function(data)
  if data.lab and data.tech_name then
    rendering.set_text(data.label_id,{"technology-name."..data.tech_name})
    rendering.set_color(data.label_id,{1,0,0})
    rendering.set_color(data.box_id,{1,0,0})
  else
    rendering.set_text(data.label_id,{ "overlay.ready-for-tech" })
    rendering.set_color(data.label_id,{0,1,0})
    rendering.set_color(data.box_id,{0,1,0})
  end
end

local clean_up_indicators = function(data)
  rendering.destroy(data.label_id)
  rendering.destroy(data.box_id)
end

local reassign_stored_technologies = function()
  local orphaned_techs = {}

  --check labs are valid
  for _, data in pairs(global.lab_storage_data) do
    if data.lab and data.lab.valid == false then
      data.lab = nil
    end
  end
  --check techs have labs
  for _, data in pairs(global.lab_storage_data) do
    if data.tech_name and not data.lab then
      table.insert(orphaned_techs,data.tech_name)
      data.tech_name = nil
    end
  end
  --remove empty data
  for index, data in pairs(global.lab_storage_data) do
    if not data.tech_name and not data.lab then
      table.insert(orphaned_techs,data.tech)
      clean_up_indicators(data)
      table.remove(global.lab_storage_data,index)
    end
  end

  --reassign orphaned_techs
  for index, tech_name in pairs(orphaned_techs) do
    local reassigned = false
    for _, data in pairs(global.lab_storage_data) do
      if not data.tech_name and reassigned == false then
        data.tech_name = tech_name
        reassigned = true
      end
    end
    if reassigned then
      table.remove(orphaned_techs,index)
    end
  end
  --update overlay
  for _, data in pairs(global.lab_storage_data) do
    set_data_indicator_status(data)
  end
  --unresearch orphaned_techs
  for _, tech_name in pairs(orphaned_techs) do
    game.forces.player.technologies[tech_name].researched = false
    game.print({"warnings.research-lost-destroyed-lab"})
  end
end

local on_built_entity = function(event)
  if event.created_entity.valid and event.created_entity.type == 'lab' then
    table.insert(global.lab_storage_data,new_lab_data(event.created_entity))
    global.lab_data_changed = true
  end
end

local are_labs_identical = function(lab1,lab2)
  return lab1.name == lab2.name and
     lab1.position.x == lab2.position.x and
     lab1.position.y == lab2.position.y
end

local find_data_with_space = function()
  for _, data in pairs(global.lab_storage_data) do
    if not data.tech_name then
      return data
    end
  end
  return nil
end

local find_data_from_lab = function(lab)
  for _, data in pairs(global.lab_storage_data) do
    if data.lab and are_labs_identical(lab,data.lab) then
      return data
    end
  end
  return nil
end

local on_player_mined_entity = function(event)
  if event.entity.type == 'lab' then
    local free_data = find_data_with_space()
    local has_tech = find_data_from_lab(event.entity)

    if has_tech and not free_data then
      --cancel mining
      local new_lab = event.entity.surface.create_entity({
        force = event.entity.force,
        position = event.entity.position,
        name = event.entity.name,
      })
      event.entity.surface.create_entity{
        name = "tutorial-flying-text",
        text = {"flying-text.not-minable-contains-tech"},
        position = {
          event.entity.position.x,
          event.entity.position.y - 1.5
        },
        color = {r = 1, g = 0.2, b = 0}}
      event.buffer.clear()
      has_tech.lab = new_lab
    end
    global.lab_data_changed = true
  end
end

local on_research_started = function(event)
  local data = find_data_with_space()
  if not data then
    event.research.force.cancel_current_research()
    game.print({"warnings.research-cancelled-no-storage"})
  end
end

local on_research_finished = function(event)
  local data = find_data_with_space()
  if data then
    data.tech_name = event.research.name
    reassign_stored_technologies()
    game.print({"warnings.research-complete-stored"})
  else
    event.research.researched = false
    game.forces.player.set_saved_technology_progress(event.research,0.999)
    game.print({"warnings.research-cancelled-no-storage"})
  end
end

local on_entity_died = function(event)
  if event.entity.type == 'lab' then
    global.lab_data_changed = true
  end
end

local find_closest_lab = function(position)
  local target = nil
  local distance = -1
  for _, data in pairs(global.lab_storage_data) do
    if data.lab and math2d.position.distance(data.lab,position) < distance then
      target = data.lab
    end
  end
  return target
end

local on_unit_group_finished_gathering = function (event)
  local target_lab = find_closest_lab(event.group.position)
  if target_lab then
    event.group.set_command({
      type = defines.command.attack,
      target = target_lab,
      distraction = defines.distraction.by_enemy
    })
  end
end

local on_game_created_from_scenario = function()
  global.lab_storage_data = {}
  global.lab_data_changed = false
end

local on_tick = function()
  --if game.ticks_played % 5 ~= 0 then return end
  if global.lab_data_changed then
    reassign_stored_technologies()
    global.lab_data_changed = false
  end
end

local lab_storage = {}

lab_storage.init = function()

end

lab_storage.on_load = function()

end

lab_storage.events = {
  [defines.events.on_game_created_from_scenario] = on_game_created_from_scenario,
  [defines.events.on_built_entity] = on_built_entity,
  [defines.events.on_player_mined_entity] = on_player_mined_entity,
  [defines.events.on_research_finished] = on_research_finished,
  [defines.events.on_research_started] = on_research_started,
  [defines.events.on_entity_died] = on_entity_died,
  [defines.events.on_unit_group_finished_gathering] = on_unit_group_finished_gathering,
  [defines.events.on_tick] = on_tick,
}

return lab_storage