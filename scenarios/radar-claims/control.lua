local handler = require("event_handler")
local claims = require("radar-claims")
local no_military = require("no-military")
local starting_areas = require("starting-areas")
local math2d = require('math2d')

local allocate_players_to_teams = function()
  for _, player in pairs(game.players) do
    player.color = {math.random(),math.random(),math.random()}
    local new_force = game.create_force(player.name)
    player.force = new_force
    for force_name, force in pairs(game.forces) do
      if force_name ~= 'enemy' then
        force.set_friend(new_force,true)
        new_force.set_friend(force,true)
      end
    end
    local next_starting_area = starting_areas.find_unoccupied_starting_area()
    if next_starting_area then
      --player.print("found starting area")
      next_starting_area.owner = new_force.name
      local claim = claims.new_claim(new_force,game.surfaces[global.starting_areas_data.surface],math2d.bounding_box.get_centre(next_starting_area.area))
      claim.requires_power = false
      local radars = game.surfaces[global.starting_areas_data.surface].find_entities_filtered({
        name = 'radar',
        force = new_force
      })
      radars[1].minable = false
      radars[1].destructible = false

    end
  end
end

local show_start_game_gui = function(player)
  local frame = player.gui.left.add({
    type = 'frame',
    name = 'start_frame',
    direction = 'vertical',
    caption = {'start-game-gui.heading'}
  })
  frame.style.width = 300
  local text = frame.add({
    type ='label',
    name = 'start_label',
    caption = {'start-game-gui.text',#game.players}
  })
  text.style.single_line = false
  local button = frame.add({
    type = 'button',
    name = 'start_button',
    caption = {'start-game-gui.button'}
  })
  button.enabled = false
end


local show_choose_name_gui = function(player)
  local frame = player.gui.center.add({
    type = 'frame',
    name = 'name_frame',
    direction = 'vertical',
    caption = {'change-name-gui.heading'}
  })
  frame.style.width = 300
  local text = frame.add({
    type ='label',
    name = 'name_label',
    caption = {'change-name-gui.text'}
  })
  frame.add({
    type = 'textfield',
    name = 'name_field',
    text = "",
  })
  text.style.single_line = false
  local button = frame.add({
    type = 'button',
    name = 'name_button',
    caption = {'change-name-gui.button'}
  })
end

local give_players_starting_items = function(item_list)
  for _, player in pairs(game.players) do
    for _, item in pairs(item_list) do
      player.insert(item)
    end
  end
end

local on_created_or_loaded = function()

end

local on_game_created_from_scenario = function()
  global.game_started = false
  game.create_surface('play-area')
  claims.init()
  no_military.init()
  starting_areas.init('play-area')
  on_created_or_loaded()
end

local on_player_created = function(event)
  local player = game.players[event.player_index]
  if event.player_index == 1 then
    show_start_game_gui(player)
  end
  if player.name == "" then
    show_choose_name_gui(player)
  end
end

local on_gui_click = function(event)
  local clicked = event.element
  if clicked.name == 'start_button' then
    local parent = clicked.parent
    global.game_started = true
    --game.print("clicked")
    allocate_players_to_teams()
    starting_areas.teleport_all_players_to_starting_area()
    give_players_starting_items({
      {name='iron-plate',count=20},
      {name='copper-plate',count=10},
      {name='stone',count=30},
      {name='solar-panel',count=3},
      {name='small-electric-pole',count=3},
      {name='radar',count=2},
    })
    clicked.parent.destroy()
  elseif clicked.name == 'name_button' then
    if clicked.parent.name_field.text ~= "" then
      game.players[event.player_index].name = clicked.parent.name_field.text
      clicked.parent.destroy()
    end
  end
end

local on_chunk_generated = function(event)
  --if this chunk contains stone deposits, make a mixed deposit
  --print("main chunk generation")
  local resources = event.surface.find_entities_filtered({
    type = 'resource',
    area = event.area
  })
  local valid_swaps = {'iron-ore','copper-ore','coal','stone'}

  for _, resource in pairs(resources) do
     local random_type = valid_swaps[math.random(1,#valid_swaps)]
    if random_type ~= resource.name then
      local new_dep = event.surface.create_entity({
        name = random_type,
        position = resource.position,
      })
      new_dep.amount = resource.amount
      resource.destroy()
    end
  end
end

local on_tick = function()
  if game.ticks_played % 300 ~= 0 then return end
  if global.game_started == false and starting_areas.are_all_starting_areas_generated() == true then
    game.players[1].gui.left.start_frame.start_button.enabled = true
  end
end

local main_events = {
  [defines.events.on_game_created_from_scenario] = on_game_created_from_scenario,
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_gui_click] = on_gui_click,
  [defines.events.on_tick] = on_tick,
  [defines.events.on_chunk_generated] = on_chunk_generated,
}

handler.add_lib({events = main_events})
handler.add_lib(starting_areas)
handler.add_lib(claims)
handler.add_lib(no_military)

script.on_load(on_created_or_loaded)