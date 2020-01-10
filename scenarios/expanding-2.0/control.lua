mod_name = '__base__'
local locations = require(mod_name..".lualib.locations")
local quest_gui = require(mod_name..".lualib.quest_gui")
local handler = require("event_handler")

local storytable = {
  {
    name = 'stockpile-iron',
    init = function()
      --stockpile 150 iron plates
      --only belts, burner inserters, furnace, chests, miners, cogs and furnace
      --disable biter expansion and pollution
    end,
  },
  {
    name = 'power-crashed-lab',
    init = function()
      --research automation
      --power lab
    end,
    action = function()
      --swap to damaged lab
      --power down generator/explode it
    end,
  },
  {
    name = 'power-radar',
    init = function()
      --give electric recipes
      --research radar
      --build steam power
    end,
  },
  {
    name = 'build-car',
    init = function()
      --research automoblism
      --smelt steel
      --craft engines
      --craft car
    end,
  },
  {
    name = 'leave-with-science',
    init = function()
      --reach the exit
      --stockpile green science 400
      --stockpile red science 400
      --stockpile firearm magazines 200
    end
  }
}

local on_created_or_loaded = function()
  locations.on_load()
  quest_gui.on_load()
end

local on_game_created_from_scenario = function()
  locations.init('nauvis','nauvis')
  on_created_or_loaded()

  local pod = game.get_entity_by_tag('pod')
  pod.insert({name='pistol',count=1})
  pod.insert({name='firearm-magazine',count=1})
end

local on_player_created = function()

end

local on_tick = function()

end

local main_events = {
  [defines.events.on_game_created_from_scenario] = on_game_created_from_scenario,
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_tick] = on_tick,
}

handler.add_lib({events = main_events})
handler.add_lib(quest_gui)

script.on_load(on_created_or_loaded)