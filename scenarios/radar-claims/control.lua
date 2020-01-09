local util = require("util")
local handler = require("event_handler")
local math2d = require("math2d")


local new_force_data = function(name)

end

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
        left_top = chunk_area.left_top,
        right_bottom = chunk_area.right_bottom,
        forces = {entity.force},
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
      if radar.is_connected_to_electric_network() and radar.energy > 0 then powered = true end
    end
    claim.active = powered
    set_claim_overlay_visiblilty(claim,claim.active)
  else
    claim.active = true
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
  local player = game.players[event.player_index]
  local claim = new_claim_data(event.created_entity)
  table.insert(global.radar_claim_data.claims,claim)
end

local on_created_or_loaded = function()

end

local on_game_created_from_scenario = function()
  global.radar_claim_data = {}
  global.radar_claim_data.claims = {}
  global.radar_claim_data.settings = {
    allow_placement_in_unclaimed_chunks = true,
    allow_placement_in_others_claims = false,
    radar_power_check_frequency = 60,
  }
  --TODO: disable biters for this world
  on_created_or_loaded()
end

local on_built_entity =  function(event)
  local active_claim = find_claim_at_position(event.created_entity.position)
  local claim = find_claim_at_position(event.created_entity.position,true)
  local continue = true
  if continue and global.radar_claim_data.settings.allow_placement_in_unclaimed_chunks == false and active_claim == nil then
    continue = deny_building(event,{'flying-text.no-building-outside-claims'},true)
  end

  if continue and global.radar_claim_data.settings.allow_placement_in_others_claims == false and
    claim and claim.force ~= event.created_entity.force.name then
    continue = deny_building(event,{'flying-text.no-building-in-others-claims'})
  end


  if continue and event.created_entity.name == 'radar' then
    local claim = find_claim_at_position(event.created_entity.position,true)
    if claim then
      add_radar_to_claim(event.created_entity,claim)
    else
      new_claim_using_event(event)
    end
  end

  --TODO only allow if player owns chunk
  --TODO disallow joining of different forces electric networks
end

local on_player_mined_entity = function(event)
  --TODO only allow if player owns chunk
  if event.entity.name == 'radar' then
    local claim = find_claim_at_position(event.entity.position)
    if claim then
      remove_radar_from_claim(event.entity,claim)
    end
  end
end

local on_player_created = function(event)
  local player = game.players[event.player_index]
  --TODO move player to closest radar on their force
  player.insert({name='solar-panel',count=10})
  player.insert({name='radar',count=4})
  player.insert({name='medium-electric-pole',count=4})
end

local on_player_respawned = function(event)
  --TODO respawn at closest radar
end

local on_tick = function()
  if game.ticks_played % global.radar_claim_data.settings.radar_power_check_frequency ~= 0 then return end
  for _, claim in pairs(global.radar_claim_data.claims) do
    check_claim_is_active(claim)
  end
end

local main_events = {
  [defines.events.on_game_created_from_scenario] = on_game_created_from_scenario,
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_player_respawned] = on_player_respawned,
  [defines.events.on_built_entity] = on_built_entity,
  [defines.events.on_player_mined_entity] = on_player_mined_entity,
  [defines.events.on_tick] = on_tick,
}

handler.add_lib({events= main_events})

script.on_load(on_created_or_loaded)

