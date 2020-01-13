mod_name = '__base__'
local locations = require(mod_name..".lualib.locations")
local quest_gui = require(mod_name..".lualib.quest_gui")
local check = require(mod_name..".lualib.check")
local campaign_util = require(mod_name..".lualib.campaign_util")
local effect = require(mod_name..".lualib.effects")
local handler = require("event_handler")
local story = require("story_2")
local template_expand = require("template-expand")
local math2d = require("math2d")

local generate_congrats_node = function(unique_name)
  return
  {
    name = 'congrats_' .. unique_name,
    init = function()
      local position = game.players[1].position
      if not position.x then position.x = position[1] end
      if not position.y then position.y = position[2] end
      game.surfaces[1].create_entity{name = "tutorial-flying-text", text = {"tutorial-gui.objective-complete"},
                                 position = {position.x, position.y - 1.5}, color = {r = 12, g = 243, b = 56}}
      game.forces.player.play_sound({ path = "utility/achievement_unlocked" })
    end,
    condition = function () return story.check_seconds_passed('main_story',2) end
  }
end

local storytable = {
  {
    name = 'stockpile-iron',
    init = function()
      local quest_layout =
      {
        {
          item_name = 'stockpile-iron-plate',
          goal = 1,
        },
        {
          item_name = 'place-stone-furnace',

        },
        {
          item_name = 'craft-stone',
          goal = 5,
        }
      }
      quest_gui.set('stockpile-iron', quest_layout)
      quest_gui.visible(true)

      quest_gui.add_hint({'quest-hints.info-move-wasd'})
      quest_gui.add_hint({'quest-hints.info-inventory'})
      quest_gui.add_hint({'quest-hints.info-hand-mining'})
      quest_gui.add_hint({'quest-hints.info-move-click'})
      quest_gui.add_hint({'quest-hints.info-rotate'})

      game.forces.player.disable_all_prototypes()
      game.forces.player.disable_research()
      game.forces.player.clear_chart(game.surfaces[1])
      local recipes = {
        'transport-belt',
        'burner-inserter',
        'stone-furnace',
        'wooden-chest',
        'iron-chest',
        'burner-mining-drill',
        'iron-gear-wheel',
        'iron-plate',
        'copper-plate',
      }

      for _, recipe_name in pairs(recipes) do
        game.forces.player.recipes[recipe_name].enabled = true
      end

      game.map_settings.pollution.enabled = false
      game.map_settings.enemy_evolution.enabled = false
      game.map_settings.enemy_expansion.enabled = false
    end,
    update = function()
      if game.ticks_played < 60 then
        game.players[1].zoom = 2
      end
    end,
    condition = function()
      local placed = check.entity_placed('stone-furnace')
      local mined = check.player_crafted_list({{name='stone',goal=5}})
      local stockpile = check.player_stockpiled_list({{name='iron-plate',goal=1}})
      return placed and mined and stockpile
    end,
    action = function()
      --TODO replace this with a proper chunk remover script
      for x=-3,2 do
        for y=-3,0 do
          locations.get_main_surface().delete_chunk({x=x,y=y})
          locations.get_main_surface().request_to_generate_chunks({x=x*32,y=y*32},1)
        end
      end
      for x=-1,2 do
        for y=0,2 do
          locations.get_main_surface().delete_chunk({x=x,y=y})
          locations.get_main_surface().request_to_generate_chunks({x=x*32,y=y*32},1)
        end
      end
    end
  },
  generate_congrats_node('stockpile-iron'),
  {
    name = 'chart-crash',
    init = function()
      game.forces.player.chart(locations.get_main_surface(),locations.get_area('crash-trigger'))
    end,
    condition = function () return story.check_seconds_passed('main_story',1) end
  },
  {
    name = 'investigate-crash',
    init = function ()
      local quest_layout =
      {
        {
          item_name = 'arrive-crash-trigger',
          icons = {'virtual-signal/signal-1'},
        },
      }
      quest_gui.set('investigate-crash', quest_layout)


      game.forces.player.add_chart_tag(locations.get_main_surface(),{
        icon = {
          type = 'virtual',
          name = 'signal-1',
        },
        position = game.get_entity_by_tag('crash-lab').position
      })

      quest_gui.add_hint({'quest-hints.info-objective-markers'})
      quest_gui.add_hint({'quest-hints.info-map'})
    end,
    condition = function()
      return check.player_inside_area('crash-trigger')
    end,
    action = function ()
      local tags = game.forces.player.find_chart_tags(locations.get_main_surface(),locations.get_area('crash-trigger'))
      for _, tag in pairs(tags) do
        tag.destroy()
      end
    end
  },
  generate_congrats_node('investigate-crash'),
  {
    name = 'power-crashed-lab',
    init = function()
      local quest_layout =
      {
        {
          item_name = 'research-automation',
        },
        {
          item_name = 'craft-automation-science-pack',
          goal = 10,
        },
        {
          item_name = 'power-crash-lab',
        },
      }
      quest_gui.set('power-crashed-lab', quest_layout)

      quest_gui.add_hint({'quest-hints.info-research-screen'})
      quest_gui.add_hint({'quest-hints.info-pole'})
      quest_gui.add_hint({'quest-hints.info-science-packs'})

      game.forces.player.recipes['automation-science-pack'].enabled = true
      game.forces.player.recipes['copper-cable'].enabled = true
      game.forces.player.recipes['small-electric-pole'].enabled = true
      game.forces.player.enable_research()
      game.forces.player.technologies['automation'].enabled = true
      game.forces.player.technologies['radar'].visible_when_disabled = true
      game.forces.player.technologies['electronics'].visible_when_disabled = true
    end,
    condition = function()
      local researched = check.research_list_complete({'automation'})
      local powered = check.tagged_entity_powered('crash-lab')
      local crafted = check.player_crafted_list({{name='automation-science-pack',goal=10}})
      return researched and powered and crafted
    end,
    action = function()
      local lab = game.get_entity_by_tag('crash-lab');
      local gen = game.get_entity_by_tag('crash-gen');
      lab.surface.create_entity({
        name = 'medium-explosion',
        position = lab.position,
      })
      gen.surface.create_entity({
        name = 'medium-explosion',
        position = gen.position,
      })
      effect.swap_tagged_with_fixed_entity('crash-lab','crash-site-lab-broken')
      gen.destroy()

      local settings = locations.get_main_surface().map_gen_settings
      settings.width = 448
      settings.height = 384
      locations.get_main_surface().map_gen_settings = settings
    end,
  },
  generate_congrats_node('power-crashed-lab'),
  {
    name = 'power-radar',
    init = function()
      local quest_layout = {
        {
          item_name = 'power-radar',
        },
        {
          item_name = 'research-radar',
        },
        {
          item_name = 'power-lab',
          icons = { 'item/lab' },
        },
        {
          item_name = 'connection',
          icons = { 'item/small-electric-pole' },
        },
        {
          item_name = 'provide-steam',
          icons = { 'item/steam-engine', 'fluid/steam' },
        },
        {
          item_name = 'provide-water',
          icons = { 'item/boiler', 'fluid/water', 'item/coal' },
        },
        {
          item_name = 'build-offshore-pump',
          icons = {'item/offshore-pump'},
        }
      }

      quest_gui.set('power-radar', quest_layout)

      quest_gui.add_hint({'quest-hints.info-alt-mode'})

      local recipes = {
        'electronic-circuit',
        'offshore-pump',
        'boiler',
        'steam-engine',
        'lab',
        'inserter',
        'pipe',
        'pipe-to-ground',
        'electric-mining-drill',
        'repair-pack',
        'firearm-magazine',
        'pistol',
        'light-armor',
      }

      for _, recipe_name in pairs(recipes) do
        game.forces.player.recipes[recipe_name].enabled = true
      end

      game.forces.player.technologies['radar'].enabled = true
      game.forces.player.technologies['electronics'].enabled = true
    end,
    condition = function()
      if game.ticks_played % 60 ~= 0 then return end

      check.steam_engine_operational()
      check.entity_powered('lab')
      local researched = check.research_list_complete({'radar'})
      local powered = check.entity_powered('radar')
      return researched and powered
    end,
  },
  generate_congrats_node('power-radar'),
  {
    name = 'build-car',
    init = function()
      local quest_layout =
      {
        {
          item_name = 'place-car',
        },
        {
          item_name = 'research-automobilism'
        },
        {
          item_name = 'craft-engine-unit',
          goal = 8,
        },
        {
          item_name = 'craft-steel-plate',
          goal = 5
        },
      }
      quest_gui.set('build-car', quest_layout)

      quest_gui.add_hint({'quest-hints.info-test-fire'})
      quest_gui.add_hint({'quest-hints.info-enter-car'})

      local techs = {
        'logistic-science-pack',
        'steel-processing',
        'logistics',
        'logistics-2',
        'engine',
        'automobilism',
        'fast-inserter',
        'heavy-armor',
        'military',
        'stone-walls',
        'optics',
        'steel-axe',
      }

      for _, tech_name in pairs(techs) do
        assert(game.forces.player.technologies[tech_name],"no tech called: "..tech_name)
        game.forces.player.technologies[tech_name].enabled = true
      end

      game.forces.player.recipes['stone-brick'].enabled = true
      game.forces.player.recipes['iron-stick'].enabled = true

    end,
    condition = function()
      local crafted = check.player_crafted_list({
        {name='steel-plate', goal = 5},
        {name='engine-unit', goal = 8},
      })
      local car = check.entity_placed('car')
      local research = check.research_list_complete({'automobilism'})
      return crafted and car and research
    end,
    action = function()
      local settings = locations.get_main_surface().map_gen_settings
      settings.width = 1792
      settings.height = 768
      locations.get_main_surface().map_gen_settings = settings
      locations.get_main_surface().request_to_generate_chunks({x=21,y=0})
    end
  },
  generate_congrats_node('power-build-car'),
  {
    name = 'chart-train',
    init = function()
      game.forces.player.chart(locations.get_main_surface(),locations.get_area('train-trigger'))
    end,
    condition = function () return story.check_seconds_passed('main_story',1) end
  },
  {
    name = 'investigate-train',
    init = function ()
      local quest_layout =
      {
        {
          item_name = 'arrive-train-trigger',
          icons = {'virtual-signal/signal-1'},
        },
      }
      quest_gui.set('investigate-train', quest_layout)

      game.forces.player.add_chart_tag(locations.get_main_surface(),{
        icon = {
          type = 'virtual',
          name = 'signal-1',
        },
        position = math2d.bounding_box.get_centre(locations.get_area('train-trigger'))
      })

    end,
    condition = function()
      return check.player_inside_area('train-trigger')
    end,
    action = function ()
      local tags = game.forces.player.find_chart_tags(locations.get_main_surface(),locations.get_area('train-trigger'))
      for _, tag in pairs(tags) do
        tag.destroy()
      end
    end
  },

  --{
  --  name = 'leave-with-science',
  --  init = function()
  --    local quest_layout =
  --    {
  --      {
  --        item_name = 'arrive-leave-trigger'
  --      },
  --      {
  --        item_name = 'stockpile-logistic-science-pack',
  --        goal = 400,
  --      },
  --      {
  --        item_name = 'stockpile-automation-science-pack',
  --        goal = 400
  --      },
  --      {
  --        item_name = 'stockpile-firearm-magazine',
  --        goal = 200
  --      },
  --    }
  --    quest_gui.set('leave-with-science', quest_layout)
  --  end,
  --  condition = function()
  --    local list = check.player_stockpiled_list({
  --      {name='logistic-science-pack',goal=400},
  --      {name='automation-science-pack',goal=400},
  --      {name='firearm-magazine',goal=200},
  --    })
  --    local inside_box = check.player_inside_area('leave-trigger',false)
  --    return list and inside_box == false
  --  end,
  --  action = function()
  --    game.set_game_state({game_finished=true, player_won=true, can_continue=false})
  --  end
  --}
}

local on_player_mined_entity = function(event)
  if event.entity.type == 'simple-entity' then
    for name, count in pairs(event.buffer.get_contents()) do
      local current_count = game.players[event.player_index].force.item_production_statistics.get_input_count(name)
      game.players[event.player_index].force.item_production_statistics.set_input_count(name,current_count + count)
    end
  end
end

local on_created_or_loaded = function()
  locations.on_load()
  quest_gui.on_load()
  template_expand.on_load()
  story.on_load("main_story", storytable)
end

local on_game_created_from_scenario = function()
  locations.init('nauvis','template')
  template_expand.init()
  story.init("main_story", storytable)
  on_created_or_loaded()

  local pod = game.get_entity_by_tag('pod')
  pod.insert({name='pistol',count=1})
  pod.insert({name='firearm-magazine',count=1})
end

local on_player_created = function(event)

end

local on_tick = function()
  story.update("main_story")
end

local main_events = {
  [defines.events.on_game_created_from_scenario] = on_game_created_from_scenario,
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_player_mined_entity] = on_player_mined_entity,
  [defines.events.on_tick] = on_tick,
}

handler.add_lib({events = main_events})
handler.add_lib(quest_gui)
handler.add_lib(template_expand)

script.on_load(on_created_or_loaded)