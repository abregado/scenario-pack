mod_name = '__base__'
local locations = require(mod_name..".lualib.locations")
local quest_gui = require(mod_name..".lualib.quest_gui")
local technology_manager = require(mod_name..".lualib.technology_manager")
local tech_levels = require("tech_levels")
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
          goal = 100,
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

      locations.get_main_surface().daytime = 0.5
      locations.get_main_surface().ticks_per_day = 3600*15
      locations.get_main_surface().freeze_daytime = false

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
      game.map_settings.pollution.enemy_attack_pollution_consumption_modifier = 2
      game.map_settings.enemy_evolution.enabled = false
      game.map_settings.enemy_expansion.enabled = false
      game.map_settings.unit_group.max_unit_group_size = 5
    end,
    update = function(event)
      if game.ticks_played < 60 then
        game.players[1].zoom = 2
      end
      if event.name == defines.events.on_player_mined_entity and event.entity.type == 'simple-entity' then
        for name, count in pairs(event.buffer.get_contents()) do
          local current_count = game.players[event.player_index].force.item_production_statistics.get_input_count(name)
          game.players[event.player_index].force.item_production_statistics.set_input_count(name,current_count + count)
        end
      end
    end,
    condition = function()
      local placed = check.entity_placed('stone-furnace')
      local mined = check.player_crafted_list({{name='stone',goal=5}})
      local stockpile = check.player_stockpiled_list({{name='iron-plate',goal=100}})
      return stockpile
    end,
    action = function()
      template_expand.resize_keeping_area(192,192,'starting-area')
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
        position = locations.get_surface_ent_from_tag(locations.get_main_surface(),'crash-lab').position
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

      technology_manager.set_tech_level("initial")
      technology_manager.set_revealed_tech_level("radar")

      game.forces.player.recipes['automation-science-pack'].enabled = true
      game.forces.player.recipes['copper-cable'].enabled = true
      game.forces.player.recipes['small-electric-pole'].enabled = true
      game.forces.player.enable_research()
    end,
    condition = function()
      local researched = check.research_list_complete({'automation'})
      local powered = check.tagged_entity_powered('crash-lab')
      local crafted = check.player_crafted_list({{name='automation-science-pack',goal=10}})
      return researched
    end,
    action = function()
      local lab = locations.get_surface_ent_from_tag(locations.get_main_surface(),'crash-lab');
      local gen = locations.get_surface_ent_from_tag(locations.get_main_surface(),'crash-gen');
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
          children = {
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
        },
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

      technology_manager.set_tech_level("radar")

    end,
    condition = function()
      if game.ticks_played % 60 ~= 0 then return end

      check.steam_engine_operational()
      check.entity_powered('lab')
      local researched = check.research_list_complete({'radar'})
      local powered = check.entity_powered('radar')
      return powered
    end,
    action = function()
      template_expand.resize_keeping_area(448,384)
    end
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
      quest_gui.add_hint({'quest-hints.info-biter-attacks'})

      game.map_settings.pollution.enabled = true
      game.map_settings.enemy_evolution.enabled = true
      technology_manager.set_tech_level('car')
      technology_manager.set_revealed_tech_level('trains')

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
      return car
    end,
    action = function()
      template_expand.resize_keeping_area(1792,768)
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
  {
    name = 'leave-with-science',
    init = function()
      local quest_layout =
      {
        {
          item_name = 'arrive-leave-trigger'
        },
        {
          item_name = 'stockpile-logistic-science-pack',
          goal = 400,
        },
        {
          item_name = 'stockpile-automation-science-pack',
          goal = 400
        },
        {
          item_name = 'stockpile-firearm-magazine',
          goal = 200
        },
      }
      quest_gui.set('leave-with-science', quest_layout)
    end,
    condition = function()
      local list = check.player_stockpiled_list({
        {name='logistic-science-pack',goal=400},
        {name='automation-science-pack',goal=400},
        {name='firearm-magazine',goal=200},
      })
      local inside_box = check.player_inside_area('leave-trigger',false)
      return list and inside_box == false
    end,
    action = function()
      game.set_game_state({game_finished=true, player_won=true, can_continue=false})
    end
  }
}

local on_created_or_loaded = function()
  locations.on_load()
  quest_gui.on_load()
  template_expand.on_load()
  story.on_load("main_story", storytable)
  technology_manager.on_load(tech_levels,{})
end

local on_game_created_from_scenario = function()
  locations.init('nauvis','template')
  quest_gui.init()
  template_expand.init(locations.get_area('starting-area'))
  story.init("main_story", storytable)
  on_created_or_loaded()

  local pod = locations.get_surface_ent_from_tag(locations.get_main_surface(),'pod')
  pod.insert({name='pistol',count=1})
  pod.insert({name='firearm-magazine',count=1})
end

local on_player_created = function(event)
  if game.players[event.player_index].name == 'abregado' then
    game.players[event.player_index].insert('car')
    game.players[event.player_index].insert('radar')
    game.players[event.player_index].insert('stone-furnace')
    game.players[event.player_index].insert('iron-ore')
    game.players[event.player_index].insert('iron-ore')
    game.players[event.player_index].insert('coal')
    game.players[event.player_index].insert('coal')
    game.players[event.player_index].insert('lab')
    game.players[event.player_index].insert('automation-science-pack')
    game.players[event.player_index].insert('solar-panel')
    game.players[event.player_index].insert('small-electric-pole')
  end
end

local pass_event_to_story = function(event)
  story.update("main_story",event)
end

local main_events = {
  [defines.events.on_game_created_from_scenario] = on_game_created_from_scenario,
  --[defines.events.on_player_created] = on_player_created,
  [defines.events.on_player_mined_entity] = pass_event_to_story,
  [defines.events.on_tick] = pass_event_to_story,
}

handler.add_lib({events = main_events, on_load = on_created_or_loaded})
handler.add_lib(quest_gui)
handler.add_lib(template_expand)

--script.on_load(on_created_or_loaded)