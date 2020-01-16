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
local autodeploy = require ("autodeploy")

local generate_congrats_node = function(unique_name)
  return
  {
    name = 'congrats_' .. unique_name,
    init = function()
      local position = game.players[1].position
      if not position.x then position.x = position[1] end
      if not position.y then position.y = position[2] end
      game.surfaces[1].create_entity{name = "tutorial-flying-text", text = {"flying-text.objective-complete"},
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

      local pre_placed = game.forces['pre-placed'] or game.create_force('pre-placed')
      local pre_placed_agro_biters = game.forces['pre-placed-agro-biters'] or game.create_force('pre-placed-agro-biters')
      local pre_placed_agro_all = game.forces['pre-placed-agro-all'] or game.create_force('pre-placed-agro-all')

      for _, force in pairs(game.forces) do
        if force.name == 'pre-placed' then
          for _, to_be_allied in pairs(game.forces) do
            force.set_friend(to_be_allied,true)
            to_be_allied.set_friend(force,true)
          end
        elseif force.name == 'pre-placed-agro-biters' then
          game.forces.player.set_friend(force,true)
          force.set_friend(game.forces.player,true)
          game.forces['pre-placed'].set_friend(force,true)
          force.set_friend(game.forces['pre-placed'],true)
        elseif force.name == 'pre-placed-agro-all' then
          game.forces['pre-placed'].set_friend(force,true)
          force.set_friend(game.forces['pre-placed'],true)
        end
      end

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
      game.map_settings.unit_group.max_unit_group_size = 1
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
      game.map_settings.enemy_expansion.enabled = true
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
      local area_centres = {
        math2d.bounding_box.get_centre(locations.get_area('exploration-1-trigger')),
        math2d.bounding_box.get_centre(locations.get_area('exploration-2-trigger')),
        math2d.bounding_box.get_centre(locations.get_area('exploration-3-trigger')),
      }
      for _, position in pairs(area_centres) do
        locations.get_main_surface().request_to_generate_chunks({x=math.floor(position.x/32),y=math.floor(position.y/32)})
      end
    end
  },
  generate_congrats_node('power-build-car'),
  {
    name = 'chart-exploration-sites',
    init = function()
       local chart_areas = {
        locations.get_area('exploration-1-trigger'),
        locations.get_area('exploration-2-trigger'),
        locations.get_area('exploration-3-trigger'),
      }
      for _, area in pairs(chart_areas) do
        game.forces.player.chart(locations.get_main_surface(),area)
      end
    end,
    condition = function () return story.check_seconds_passed('main_story',1) end
  },
  {
    name = 'investigate-exploration-sites',
    init = function ()
      local quest_layout =
      {
        {
          item_name = 'visited-exploration-1-trigger',
          icons = {'virtual-signal/signal-1'},
        },
        {
          item_name = 'visited-exploration-2-trigger',
          icons = {'virtual-signal/signal-2'},
        },
        {
          item_name = 'visited-exploration-3-trigger',
          icons = {'virtual-signal/signal-3'},
        },
        {
          item_name = 'arrive-crash-trigger',
        },
      }
      quest_gui.set('investigate-exploration-sites', quest_layout)

      global.story_variable_data.explored_site_one = false
      global.story_variable_data.explored_site_two = false
      global.story_variable_data.explored_site_three = false

      for n=1,3 do
        game.forces.player.add_chart_tag(locations.get_main_surface(),{
          icon = {
            type = 'virtual',
            name = 'signal-'..n,
          },
          position = math2d.bounding_box.get_centre(locations.get_area('exploration-'..n..'-trigger'))
        })
      end
    end,
    update = function(event)
      if technology_manager.get_current_tech_level() == 'car' and (global.story_variable_data.explored_site_one or
        global.story_variable_data.explored_site_two or
        global.story_variable_data.explored_site_three) then
        technology_manager.set_tech_level('trains')
        technology_manager.set_revealed_tech_level('oil')
      end
    end,
    condition = function()
      if global.story_variable_data.explored_site_one == false and check.player_inside_area('exploration-1-trigger',false) then
        global.story_variable_data.explored_site_one = true
        quest_gui.update_state('visited-exploration-1-trigger','success')
      end
      if global.story_variable_data.explored_site_two == false and check.player_inside_area('exploration-2-trigger',false) then
        global.story_variable_data.explored_site_two = true
        quest_gui.update_state('visited-exploration-2-trigger','success')
      end
      if global.story_variable_data.explored_site_three == false and check.player_inside_area('exploration-3-trigger',false) then
        global.story_variable_data.explored_site_three = true
        quest_gui.update_state('visited-exploration-3-trigger','success')
      end
      local returned = check.player_inside_area('crash-trigger')
      return global.story_variable_data.explored_site_one == true and
        global.story_variable_data.explored_site_two == true and
        global.story_variable_data.explored_site_three == true and returned

    end,
    action = function ()
      --TODO clean this sucker up
      local tags = game.forces.player.find_chart_tags(locations.get_main_surface(),locations.get_area('exploration-1-trigger'))
      for _, tag in pairs(tags) do
        tag.destroy()
      end
      tags = game.forces.player.find_chart_tags(locations.get_main_surface(),locations.get_area('exploration-2-trigger'))
      for _, tag in pairs(tags) do
        tag.destroy()
      end
      tags = game.forces.player.find_chart_tags(locations.get_main_surface(),locations.get_area('exploration-3-trigger'))
      for _, tag in pairs(tags) do
        tag.destroy()
      end
    end,
  },
  generate_congrats_node('investigate-exploration-sites'),
  {
    name = 'bring-train',
    init = function()
      local quest_layout =
      {
        {
          item_name = 'wait-for-entity-in-leave-trigger',
        },
        {
          item_name = 'arrive-crash-trigger',
        },
      }
      quest_gui.set('bring-train', quest_layout)
      global.story_variable_data.fluid_wagon = locations.get_main_surface().find_entities_filtered({
        name='fluid-wagon'
      })[1]

    end,
    condition = function()
      local wagon_at_crash = global.story_variable_data.fluid_wagon and
        check.entity_inside_area('leave-trigger',global.story_variable_data.fluid_wagon)
      local returned = check.player_inside_area('crash-trigger')
      return wagon_at_crash and returned
    end,
    action = function()
      global.story_variable_data.fluid_wagon.destructible = true
      global.story_variable_data.fluid_wagon.minable = true

    end
  },
  generate_congrats_node('bring-train'),
  {
    name = 'charge-accumulators',
    init = function()
      local quest_layout =
      {
        {
          item_name = 'place-accumulator',
          goal = 100,
        },
        {
          item_name = 'charge-radar',
          goal = 100,
        },
      }
      quest_gui.set('charge-accumulators', quest_layout)

      technology_manager.set_tech_level('oil')
      technology_manager.set_revealed_tech_level('robots')
    end,
    condition = function()
      local placed = check.player_placed_quantity('accumulator',100)
      if game.ticks_played % 300 ~= 0 then return false end
      local charge = check.one_of_entity_has_charge_on_network('radar',100)
      return placed and charge
    end,
    action = function()
      game.set_game_state({game_finished=true, player_won=true, can_continue=false})
    end,
  }
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

local on_created_or_loaded = function()
  locations.on_load()
  quest_gui.on_load()
  template_expand.on_load()
  story.on_load("main_story", storytable)
  technology_manager.on_load(tech_levels,{})
  autodeploy.on_load()
end

local on_game_created_from_scenario = function()
  global.story_variable_data = {}
  global.story_variable_data.attacks_sent = 1
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

local on_unit_group_finished_gathering = function(event)
  --every three attacks, increase wave size
  if global.story_variable_data.attacks_sent % 3 == 0 then
    game.map_settings.unit_group.max_unit_group_size = math.min(math.ceil(game.map_settings.unit_group.max_unit_group_size * 1.5),200)
    --1,2,3,5,8,12,18,27,41,62,93,140,200
  end
  global.story_variable_data.attacks_sent = global.story_variable_data.attacks_sent + 1
end

local main_events = {
  [defines.events.on_game_created_from_scenario] = on_game_created_from_scenario,
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_player_mined_entity] = pass_event_to_story,
  [defines.events.on_tick] = pass_event_to_story,
  [defines.events.on_unit_group_finished_gathering] = on_unit_group_finished_gathering,
}

handler.add_lib({events = main_events, on_load = on_created_or_loaded})
handler.add_lib(quest_gui)
handler.add_lib(template_expand)
handler.add_lib(autodeploy)

--script.on_load(on_created_or_loaded)