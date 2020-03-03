local handler = require("__base__.lualib.event_handler")
local free_builder = require('free-builder')
local land = require('planetary_real_estate')
local market = require('active_market')
local math2d = require('math2d')

local on_game_created_from_scenario = function()
  free_builder.on_load()
  free_builder.add_free_item('electric-mining-drill',10)
  market.on_load()
  land.on_load()

  main_events[remote.call("planetary_real_estate", "get_events").on_player_changed_land] = on_player_changed_land

  handler.setup_event_handling(event_receivers)

  global.next_update = 0

  game.create_surface('abregado-rae',{
    seed=555,
    water='none',
    starting_area='none',
    property_expression_names={
      moisture=0,
      elevation=100,
    },
    autoplace_controls={
      ['iron-ore'] = {size='none'},
      ['copper-ore'] = {size='none'},
      ['coal'] = {size='none'},
      ['enemy-base'] = {size='none'},
    },
    width=0,
    height=0
  })
  game.create_surface('skudakan',{
    seed=187,
    water='none',
    starting_area='none',
    property_expression_names={
      moisture=0.5,
      elevation=100,
    },
    autoplace_controls={
      ['iron-ore'] = {size='none'},
      ['stone'] = {size='none'},
      ['coal'] = {size='none'},
    }
  })
  game.create_surface('brekkenridge',{
    seed=341,
    water='none',
    starting_area='none',
    property_expression_names={
      moisture=1,
      elevation=100,
    },
    autoplace_controls={
      ['iron-ore'] = {size='none'},
      ['stone'] = {size='none'},
      ['copper-ore'] = {size='none'},
    }
  })
  game.create_surface('penelope',{
    seed=997,
    water='none',
    starting_area='none',
    property_expression_names={
      aux=1,
      elevation=100,
    },
    autoplace_controls={
      ['stone'] = {size='none'},
      ['copper-ore'] = {size='none'},
      ['coal'] = {size='none'},
    }
  })
  land.add_plot('abregado-rae',{x=0,y=0})
  land.add_plot('abregado-rae',{x=512,y=0})
  land.add_plot('skudakan',{x=0,y=0})
  land.add_plot('skudakan',{x=512,y=0})
  land.add_plot('brekkenridge',{x=0,y=0})
  land.add_plot('brekkenridge',{x=512,y=0})
  land.add_plot('penelope',{x=0,y=0})
  land.add_plot('penelope',{x=512,y=0})

end

local on_player_created = function(event)
  local player = game.players[event.player_index]
  free_builder.set_player_state(player)
  market.init_player(player)
end

local on_tick = function(event)
  if not global.next_update then
    global.next_update = 0
  end
  if event.tick > global.next_update then
    market.update()
    global.next_update = event.tick + 60*60*5
  elseif event.tick % 60 == 0 then
    market.update_wallets()
  end
end

local on_gui_click = function(event)
  local player = game.players[event.player_index]
  if event.element.valid then
    if event.element.name == 'buy_land' then
      local plot_data = global.land_data.plots[global.land_data.players[player.name].current_land]
      if plot_data then
        market.add_market_area(player,plot_data.surface,{
          left_top = {
            x = plot_data.position.x - 32,
            y = plot_data.position.y - 32,
          },
          right_bottom = {
            x = plot_data.position.x + 32,
            y = plot_data.position.y + 32,
          }
        })
        plot_data.owner = player.name
        market.buy(player,plot_data.price,1)
        land.update_player(player)
      end
    elseif event.element.name =='refresh_market' then
      
    end
  end
end

local on_player_changed_land = function(event)
  game.print("event received")
  local player = game.players[event.player_index]
  local land = global.land_data.plots[event.land_index]
  free_builder.set_player_build_area(player,land.view.box)
end

main_events = {
  [defines.events.on_game_created_from_scenario] = on_game_created_from_scenario,
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_tick] = on_tick,
  [defines.events.on_gui_click] = on_gui_click,
}

event_receivers = {
  main_events,
  free_builder.events,
  market.events,
  land.events,
}

handler.setup_event_handling(event_receivers)