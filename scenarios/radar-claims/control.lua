local util = require("util")
local handler = require("event_handler")
local math2d = require("math2d")


local new_force_data = function(name)

end

local new_claim_data = function(entity)
  --TODO: visualization
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
        color = entity.force.players[1].color,
        left_top = chunk_area.left_top,
        right_bottom = chunk_area.right_bottom,
        forces = {entity.force},
      })
    },
    force = entity.force.name,
    active = true,
  }
end

local set_claim_overlay_visiblilty = function(claim,state)
  for _, id in pairs(claim.overlay_ids) do
    if state then
      rendering.set_color(id,game.forces[claim.force].players[1].color)
    else
      rendering.set_color(id,{0.6,0.6,0.6})
    end
    --rendering.set_visible(id,state)
  end
end

local are_entities_the_same = function(ent1,ent2)
  return ent1.name == ent2.name and
    ent1.position.x == ent2.position.x and
    ent1.position.y == ent2.position.y
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
  if #claim.radars == 0 then
    claim.active = false
    set_claim_overlay_visiblilty(claim,false)
  end
end

local add_radar_to_claim = function(radar,claim)
  table.insert(claim.radars,radar)
  if #claim.radars > 0 then
    claim.active = true
    set_claim_overlay_visiblilty(claim,true)
  end
end

local on_created_or_loaded = function()

end

local on_game_created_from_scenario = function()
  global.radar_claim_data = {}
  global.radar_claim_data.claims = {}
  --TODO: disable biters for this world
  on_created_or_loaded()
end

local on_built_entity =  function(event)
  if event.created_entity.name == 'radar' then
    local claim = find_claim_at_position(event.created_entity.position,true)
    if claim then
      add_radar_to_claim(event.created_entity,claim)
    else
      table.insert(global.radar_claim_data.claims,new_claim_data(event.created_entity))
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
  player.insert({name='radar',count=2})
end

local on_player_respawned = function(event)
  --TODO respawn at closest radar
end

local main_events = {
  [defines.events.on_game_created_from_scenario] = on_game_created_from_scenario,
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_player_respawned] = on_player_respawned,
  [defines.events.on_built_entity] = on_built_entity,
  [defines.events.on_player_mined_entity] = on_player_mined_entity,
}

handler.add_lib({events= main_events})

script.on_load(on_created_or_loaded)

