local math2d = require("math2d")

local new_claim_data = function(entity)
  local chunk_pos = {
    x = math.floor(entity.position.x/32),
    y = math.floor(entity.position.y/32),
  }
  local chunk_area = {
    left_top = {
      x=chunk_pos.x*32,
      y=chunk_pos.y*32,
    },
    right_bottom = {
      x=chunk_pos.x*32+32,
      y=chunk_pos.y*32+32,
    },
  }
  return {
    radars = {
      entity
    },
    area = chunk_area,
    overlay_ids = {
      rendering.draw_rectangle({
        surface = entity.surface,
        color = {0.6,0.6,0.6},
        left_top = {
          x= chunk_area.left_top.x+0.1,
          y= chunk_area.left_top.y+0.1,
        },
        right_bottom = {
          x = chunk_area.right_bottom.x-0.1,
          y = chunk_area.right_bottom.y-0.1
        },
        forces = nil,--{entity.force},
      })
    },
    force = entity.force.name,
    active = false,
    requires_power = true,
  }
end

local set_claim_overlay_visiblilty = function(claim,state)
  for _, id in pairs(claim.overlay_ids) do
    local color = (game.forces[claim.force].players[1] and game.forces[claim.force].players[1].color) or {1,0,0}
    if state then
      rendering.set_color(id, color)
    else
      rendering.set_color(id,{0.6,0.6,0.6})
    end
    --rendering.set_visible(id,state)
  end
end

local remove_claim_overlays = function(claim)
  for _, id in pairs(claim.overlay_ids) do
    rendering.destroy(id)
  end
end

local are_entities_the_same = function(ent1,ent2)
  return ent1.name == ent2.name and
    ent1.position.x == ent2.position.x and
    ent1.position.y == ent2.position.y
end

local remove_claim = function(claim)
  for index, listed_claim in pairs(global.radar_claim_data.claims) do
    if listed_claim == claim then
      remove_claim_overlays(claim)
      table.remove(global.radar_claim_data.claims,index)
    end
  end
end

local find_claim_at_position = function(position,return_inactive)
  for _, claim in pairs(global.radar_claim_data.claims) do
    if (return_inactive or claim.active) and math2d.bounding_box.contains_point(claim.area,position) then
      return claim
    end
  end
  return nil
end

local remove_radar_from_claim = function(radar,claim)
  for index, listed_radar in pairs(claim.radars) do
    if are_entities_the_same(radar,listed_radar) then
      table.remove(claim.radars,index)
    end
  end
end

local add_radar_to_claim = function(radar,claim)
  table.insert(claim.radars,radar)
  if #claim.radars > 0 then
    claim.active = true
    set_claim_overlay_visiblilty(claim,true)
  end
end

local check_claim_is_active = function(claim)
  local starting_state = false
  if claim.active then
    starting_state = true
  end
  --remove invalid radars
  for index, radar in pairs(claim.radars) do
    if not radar.valid then
      table.remove(claim.radars,index)
    end
  end
  --check claim status
  if claim.requires_power and #claim.radars == 0 then
    remove_claim(claim)
    return false
  elseif claim.requires_power then
    local powered = false
    for _, radar in pairs(claim.radars) do
      if radar.valid == true and radar.is_connected_to_electric_network() and radar.energy > 800 then powered = true end
    end
    claim.active = powered
    set_claim_overlay_visiblilty(claim,claim.active)
  else
    claim.active = true
    set_claim_overlay_visiblilty(claim,claim.active)
  end

  if claim.active and starting_state == false then
    --swap entities
    local ents = claim.radars[1].surface.find_entities_filtered({
        area = claim.area,
      })
    for _, ent in pairs(ents) do
      if ent.force then
        ent.force = claim.force
      end
    end
  end

  return claim.active
end

local deny_removal = function(event,message,do_filtering)
  local allowed = false
  if do_filtering then
    local allowed_types = {
      'tree',
      'rock'
    }
    local allowed_names = {

    }
    for _, name in pairs(allowed_names) do
      if event.entity.name == name then allowed = true end
    end
    for _, type_name in pairs(allowed_types) do
      if event.entity.type == type_name then allowed = true end
    end
  end
  if allowed == false then
    local player = game.players[event.player_index]
    event.buffer.clear()
    player.surface.create_entity{
      name = "tutorial-flying-text",
      text = message,
      position = {
        event.entity.position.x,
        event.entity.position.y - 1.5
      },
      color = {r = 1, g = 0.2, b = 0}}
    player.surface.clone_entities({
      entities = {event.entity},
      destination_offset = {0.0,0.0},
    })
    return false
  end
  return true
end

local deny_building = function(event,message,do_filtering)
  local allowed = false
  if do_filtering then
    local allowed_types = {
      'radar',
      'solar-panel',
      'electric-pole',
    }
    local allowed_names = {
      'radar',
      'solar-panel',
      'small-electric-pole',
      'big-electric-pole',
      'medium-electric-pole',
    }
    for _, name in pairs(allowed_names) do
      if event.created_entity.name == name then allowed = true end
    end
    for _, type_name in pairs(allowed_types) do
      if event.created_entity.type == type_name then allowed = true end
    end
  end
  if allowed == false then
    local player = game.players[event.player_index]
    player.insert(event.stack)
    player.surface.create_entity{
      name = "tutorial-flying-text",
      text = message,
      position = {
        event.created_entity.position.x,
        event.created_entity.position.y - 1.5
      },
      color = {r = 1, g = 0.2, b = 0}}
    event.created_entity.destroy()
    return false
  end
  return true
end

local new_claim_using_event = function(event)
  local claim = new_claim_data(event.created_entity)
  table.insert(global.radar_claim_data.claims,claim)
  return claim
end

local new_claim_using_force = function(force,surface,position)
  local radar = surface.create_entity({
    name = 'radar',
    force = force,
    position = position
  })
  local claim = new_claim_data(radar)
  table.insert(global.radar_claim_data.claims,claim)
  return claim
end

local find_closest_claim_on_force = function(position,force_name)
  local closest = nil
  local distance = 999999
  for _, claim in pairs(global.radar_claim_data.claims) do
    if force_name == claim.force then
      game.print("found claim with force")
      if math2d.position.distance(math2d.bounding_box.get_centre(claim.area),position) < distance then
        game.print("found closer")
        closest = claim
      end
    end
  end
  return closest
end

local tally_claims = function()
  local tally = {}
  for _, claim in pairs(global.radar_claim_data.claims) do
    if claim.active then
      if tally[claim.force] then
        tally[claim.force] = tally[claim.force] + 1
      else
        tally[claim.force] = 1
      end
    end
  end
  table.sort(tally,function(a,b) return a < b; end)
  return tally
end

local create_claims_highscore = function(player)
  if player.gui.left.claims then
    player.gui.left.claims.destroy()
  end

  local frame = player.gui.left.add({
    type = 'frame',
    name = 'claims',
    caption = {'radar-claims-gui.heading'},
    direction = 'vertical'
  })

  local list = frame.add({
    type='table',
    name='score_table',
    column_count = 2,
    draw_horizontal_lines = true
  })

  local name_header = list.add({
    type = 'label',
    name = 'team-header',
    caption = {'radar-claims-gui.team-header'},
  })
  name_header.style.width = 150
  local score_header = list.add({
    type = 'label',
    name = 'score-header',
    caption = {'radar-claims-gui.score-header'},
  })
  score_header.style.width = 50


  for force_name, score in pairs(tally_claims()) do
    list.add({
      type = 'label',
      name=force_name..'-name',
      caption = force_name,
    })
    list.add({
      type = 'label',
      name=force_name..'-count',
      caption = score,
    })
  end

end

local reset_next_power_check = function()
  global.radar_claim_data.next_update = game.ticks_played + global.radar_claim_data.settings.radar_power_check_frequency
end

local init = function()
  global.radar_claim_data = {}
  global.radar_claim_data.claims = {}
  global.radar_claim_data.next_update = 1
  global.radar_claim_data.settings = {
    allow_placement_in_unclaimed_chunks = true,
    allow_remove_from_unclaimed_chunks = true,
    allow_remove_radars_from_inactive_claims = true,
    allow_removal_from_others_claims = false,
    allow_placement_in_others_claims = false,
    radar_power_check_frequency = 60,
  }
end

local on_built_entity =  function(event)
  local player = game.players[event.player_index]
  local active_claim = find_claim_at_position(event.created_entity.position)
  local claim = find_claim_at_position(event.created_entity.position,true)
  local continue = true
  if continue and global.radar_claim_data.settings.allow_placement_in_unclaimed_chunks == false and active_claim == nil then
    continue = deny_building(event,{'flying-text.no-building-outside-claims'},true)
  end
  if continue and global.radar_claim_data.settings.allow_placement_in_others_claims == false and claim and claim.force ~= player.force.name then
    continue = deny_building(event,{'flying-text.no-building-in-other-claims'})
  end

  if continue and event.created_entity.type == 'radar' then
    local claim = find_claim_at_position(event.created_entity.position,true)
    if claim then
      add_radar_to_claim(event.created_entity,claim)
    else
      new_claim_using_event(event)
      player.surface.create_entity{
      name = "tutorial-flying-text",
      text = {'flying-text.new-claim-created'},
      position = {
        event.created_entity.position.x,
        event.created_entity.position.y - 1.5
      },
      color = {r = 0.2, g = 1, b = 0}}
    end
  elseif continue and event.created_entity.type== 'electric-pole' then
    local neighbours = event.created_entity.neighbours
    for index, neighbour in pairs(neighbours.copper) do
      if neighbour.force ~= event.created_entity.force then
        event.created_entity.disconnect_neighbour(neighbour)
      end
    end
  end
end

local on_player_mined_entity = function(event)
  local player = game.players[event.player_index]
  local active_claim = find_claim_at_position(event.entity.position)
  local claim = find_claim_at_position(event.entity.position,true)
  local continue = true

  if continue and global.radar_claim_data.settings.allow_remove_from_unclaimed_chunks == false and claim == nil then
    continue = deny_removal(event,{'flying-text.no-removal-in-unclaimed-chunk'},true)
  end

  if continue and global.radar_claim_data.settings.allow_removal_from_others_claims == false and
    active_claim and player.force.name ~= active_claim.force then
    continue = deny_removal(event,{'flying-text.no-removal-in-others-claim'})
  end

  if continue and event.entity.name == 'radar' then
    local claim = find_claim_at_position(event.entity.position)
    if claim then
      remove_radar_from_claim(event.entity,claim)
    end
  end
end

local on_entity_cloned = function(event)
  local claim = find_claim_at_position(event.destination.position,true)
  if claim and event.destination.type == 'radar' then
    add_radar_to_claim(event.destination,claim)
    reset_next_power_check()
  elseif event.destination.type == 'radar' then
    new_claim_using_event({created_entity=event.destination})
    reset_next_power_check()
  end
end

local on_player_respawned = function(event)
  local player = game.players[event.player_index]

  local claim = find_closest_claim_on_force(player.character.position,player.force.name)
  if claim then
    player.teleport(player.surface.find_non_colliding_position_in_box('character',claim.area,0.1))
  end
end

local on_tick = function()
  if game.ticks_played > global.radar_claim_data.next_update then
    for _, claim in pairs(global.radar_claim_data.claims) do
      check_claim_is_active(claim)
    end
    for _, player in pairs(game.players) do
      create_claims_highscore(player)
    end
    reset_next_power_check()
  end
end

local claims = {}

claims.new_claim = new_claim_using_force
claims.init = init

claims.events = {
  [defines.events.on_player_respawned] = on_player_respawned,
  [defines.events.on_built_entity] = on_built_entity,
  [defines.events.on_player_mined_entity] = on_player_mined_entity,
  [defines.events.on_tick] = on_tick,
  [defines.events.on_entity_cloned] = on_entity_cloned,
}

return claims