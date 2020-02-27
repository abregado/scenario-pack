
local create_land_gui = function(player)
  local frame = player.gui.left.add({
    type = 'frame',
    name = 'land_frame',
    direction = 'vertical',
    caption = 'Your colonies'
  })
  local controls = frame.add({
    type = 'table',
    name = 'land_controls',
    column_count = 3,
  })
  controls.add({
    type = 'button',
    name = 'previous_land',
    caption = "<"
  })
  controls.add({
    type = 'label',
    name = 'current_land_name',
    caption = "no land"
  })
  controls.add({
    type = 'button',
    name = 'next_land',
    caption = ">"
  })
end

local update_land_gui = function(player)
  if not player.gui.left.land_frame then
    create_land_gui(player)
  end
  if player.gui.left.land_frame.owner_label then player.gui.left.land_frame.owner_label.destroy() end
  if player.gui.left.land_frame.buy_land then player.gui.left.land_frame.buy_land.destroy() end
  local prev = player.gui.left.land_frame.land_controls.previous_land
  local next = player.gui.left.land_frame.land_controls.next_land
  local current = player.gui.left.land_frame.land_controls.current_land_name
  local current_player_land = global.land_data.players[player.name].current_land
  local current_land_data = global.land_data.plots[current_player_land] or nil
  if current_land_data then
    current.caption = current_land_data.name
  else
    current.caption = 'No land selected'
  end
  if global.land_data.plots[current_player_land+1] then
    next.enabled = true
  else
    next.enabled = false
  end
  if global.land_data.plots[current_player_land-1] then
    prev.enabled = true
  else
    prev.enabled = false
  end
  if current_land_data and current_land_data.owner then
    player.gui.left.land_frame.add({
      type = 'label',
      caption = 'owner: '..current_land_data.owner,
      name = 'owner_label'
    })
  elseif current_player_land > 0 then
    player.gui.left.land_frame.add({
      type = 'button',
      caption = 'Buy: '..current_land_data.price,
      name = 'buy_land'
    })
  end
end

local new_plot = function(surface,position)
  table.insert(global.land_data.plots,{
    name = surface.name..'-'..tostring(position.x)..'-'..tostring(position.y),
    surface = surface,
    position = position,
    initialized = false,
    price = 10000,
  })
end

local init_plot = function(plot)
  local surface = plot.surface
  local position = plot.position
  local interface = surface.create_entity({
    name = 'electric-energy-interface',
    position = position,
    force = 'free-builders'
  })
  local buy = surface.create_entity({
    name = 'logistic-chest-requester',
    position = {
      x = position.x - 3,
      y = position.y
    },
    force = 'free-builders'
  })
  local sell = surface.create_entity({
    name = 'logistic-chest-active-provider',
    position = {
      x = position.x + 3,
      y = position.y
    },
    force = 'free-builders'
  })
  interface.operable = false
  interface.minable = false
  buy.minable = false
  sell.minable = false
  interface.destructible = false
  buy.destructible = false
  sell.destructible = false
  plot.initialized = true
end

local goto_land = function(player,land_index)
  if global.land_data.plots[land_index] then
    local plot_data = global.land_data.plots[land_index]
    player.teleport(plot_data.position,plot_data.surface)
    global.land_data.players[player.name].current_land = land_index
    update_land_gui(player)
    if plot_data.initialized == false then
      init_plot(plot_data)
    end
  end
end

local on_gui_click = function(event)
  local player = game.players[event.player_index]
  if event.element.valid then
    if event.element.name == 'next_land' then
      if global.land_data.plots[global.land_data.players[player.name].current_land+1] then
        goto_land(player,global.land_data.players[player.name].current_land+1)
      end
    elseif event.element.name == 'previous_land' then
      if global.land_data.plots[global.land_data.players[player.name].current_land-1] then
        goto_land(player,global.land_data.players[player.name].current_land-1)
      end
    end
  end
end

local on_player_created = function(event)
  local player = game.players[event.player_index]
  global.land_data.players[player.name] = {
    current_land = 0
  }
  update_land_gui(player)
end

local land = {}

land.update_player = update_land_gui

land.add_plot = function(surface_name,position)
  local surface = game.surfaces[surface_name] or game.create_surface(surface_name)
  new_plot(surface,position)
end

land.on_load = function()
  global.land_data = {
    plots = {},
    players = {}
  }
end

land.events = {
  [defines.events.on_gui_click] = on_gui_click,
  [defines.events.on_player_created] = on_player_created
}

return land