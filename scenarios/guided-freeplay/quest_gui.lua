local tree_view = require("tree_view")
local util = require('util')

local quest_gui = {}
local quest_gui_data =
{
  current_quest_name = nil,
  current_quest_gui_data = nil,
  hints_showing = {},
  hints = {},
}

quest_gui.init = function()
  print("quest_gui init")
  global.quest_controller_data = quest_gui_data
end

quest_gui.on_load = function()
  print("quest_gui onload")
  quest_gui_data = global.quest_controller_data or quest_gui_data
end

local states_named =
{
  default =
  {
    name = 'default',
    icon = '[img=quest_gui_empty_status]',
    color = '1,1,1',
    desc = 'uncomplete',
    tileset = 'normal',
  },
  progress =
  {
    name = 'progress',
    icon = '[img=quest_gui_empty_status]',
    color = '1,0.8,0',
    desc = 'progressing',
    tileset = 'yellow',
  },
  success =
  {
    name = 'success',
    icon = '[img=virtual-signal/signal-check]',
    color = '0.82353,0.99216,0.56863',
    desc = 'complete',
    tileset = 'green',
  },
  fail =
  {
    name = 'fail',
    icon = '[img=virtual-signal/signal-red]',
    color = '1,0,0',
    desc = 'failed'
  },
}

local create_empty_quest_and_hints_gui = function(player)
  local objective_flow = player.gui.left.add
  {
    type = 'frame',
    name = 'objective_flow',
    direction = 'vertical',
    style='quest_gui_frame',
  }

  -- objectives
  objective_flow.add
  {
    type = "label",
    style = "frame_title",
    caption = { "gui-goal-description.title" }
  }
  objective_flow.add
  {
    type = 'frame',
    name = 'quest',
    direction = 'vertical',
    style = 'quest_gui_inner_frame',
  }

  -- hints
  local hints_title_flow = objective_flow.add
  {
    type = "flow",
    name = "hints_title_flow",
    direction = "horizontal"
  }
  hints_title_flow.add
  {
    name = 'expand_hints_button',
    type = 'sprite-button',
    direction = 'vertical',
    style='open_close_hints_button',
    sprite = "utility/collapse",
  }
  hints_title_flow.add
  {
    type = "label",
    style = "frame_title",
    caption = {"campaign-common.hints-heading"}
  }

  local hints_section = objective_flow.add
  {
    type = 'scroll-pane',
    name = 'all_hints',
    style = 'quest_gui_inner_scroll_pane',
  }

  hints_section.style.maximal_height = 580 / 2
  hints_section.vertical_scroll_policy = "always"
end

local get_objective_flow_section = function(player, name)
  local objective_flow = player.gui.left.objective_flow

  if not objective_flow then
    return nil
  end

  return objective_flow[name]
end

local get_all_hints_gui = function(player)
  return get_objective_flow_section(player, 'all_hints')
end

local get_quest_frame = function(player)
   return get_objective_flow_section(player, 'quest')
end

local add_description = function(parent, state, text)
  local style_mod = states_named[state].desc

  parent.add
  {
    type = 'flow',
    direction='horizontal',
    name = 'desc_flow',
    style= 'quest_item_description_wrapper'
  }
  .add
  {
    type = 'label',
    style = 'quest_item_description_' .. style_mod,
    caption = text,
    name = "inner"
  }
end

local add_icons = function(parent,icons)
  local icon_text = ""
  for _, icon in pairs(icons) do
    icon_text = icon_text..'[img='..icon..']'
  end

  parent.add
  {
    type = 'flow',
    direction='horizontal',
    style= 'quest_item_icons_wrapper'
  }
  .add
  {
    type = 'label',
    caption = icon_text,
    name = "inner",
    style = 'quest_item_icons_label'
  }
end

local add_count = function(parent, state, max)
  local style_mod = states_named[state].desc

  parent.add
  {
    type = 'flow',
    direction='horizontal',
    name = 'count_flow',
    style= 'quest_item_count_wrapper'
  }
  .add
  {
    type = 'label',
    style = 'quest_item_description_'..style_mod,
    caption = "0/" .. max,
    name = "inner"
  }
end

local set_player_quest_gui = function(player, quest_name, tree_view_rows)
  local quest_frame = get_quest_frame(player)
  local tree_view_data = tree_view.add_tree_view_to_frame(quest_frame, tree_view_rows, 'quest_main_table')
  tree_view_data.table.style = 'quest_item_table'

  for index, row in pairs(tree_view_data.rows) do
    local state = "default"
    local item_data = row.original_data_row
    local text = {'quest-' .. quest_name .. '.' .. item_data.item_name}

    add_description(row.row_flow, state, text)

    if index == 1 then
      row.row_flow.desc_flow.inner.style = "quest_item_description_first"
    end

    local push_remaining_to_right = row.row_flow.add{ type = "flow", direction = "horizontal", name = "push_remaining_to_right"}
    push_remaining_to_right.style.horizontally_stretchable = true
    push_remaining_to_right.style.vertically_stretchable = true

    if item_data.goal then
      add_count(row.row_flow, state, item_data.goal or 0)
    end

    if item_data.icons then
      add_icons(row.row_flow, item_data.icons)
    end
  end
end

local do_add_hint_header = function(hints_list, item_text)
  local hint_row = hints_list.add
  {
    type = 'flow',
    direction='horizontal',
    style= 'quest_hint_row'
  }

  -- Add the text line to the row in a wrapper flow
  hint_row.add
  {
    type = 'flow',
    direction='horizontal',
    style = 'quest_hint_description_wrapper'
  }
  .add
  {
    type = 'label',
    caption = item_text,
    style = 'quest_item_subheading',
  }
end

local do_add_hint = function(hints_list, item_text)
  local hint_row = hints_list.add
  {
    type = 'flow',
    direction='horizontal',
    style= 'quest_hint_row'
  }

  hint_row.add
  {
    type = "sprite",
    sprite = "info_no_border",
    style = "quest_hint_info_sprite",
  }

  -- Add the text line to the row in a wrapper flow
  hint_row.add
  {
    type = 'flow',
    direction='horizontal',
    style = 'quest_hint_description_wrapper'
  }
  .add
  {
    type = 'label',
    caption = item_text,
    style = 'quest_hint_description',
  }
end

local set_player_hints_gui = function(player)
  local all_hints_list = get_all_hints_gui(player)
  local added_first_quest = false

  for i = #quest_gui_data.hints, 1, -1 do
    local quest_hints = quest_gui_data.hints[i]

    if #quest_hints.hints > 0 then

      -- add in an empty line between each quest
      if added_first_quest then
        all_hints_list.add
        {
          type = 'flow',
          direction='horizontal',
          style= 'quest_hint_row'
        }.style.minimal_height = 15
      end

      added_first_quest = true
      do_add_hint_header(all_hints_list, {'quest-' .. quest_hints.quest_name .. '.heading'})
      for _, item in pairs(quest_hints.hints) do
        do_add_hint(all_hints_list, item)
      end
    end
  end
end

local rebuild_player_gui = function(player)
  local objective_flow = player.gui.left.objective_flow
  if objective_flow then
    objective_flow.destroy()
  end

  local data = quest_gui_data.current_quest_gui_data
  if not data then
    return
  end

  create_empty_quest_and_hints_gui(player)

  set_player_quest_gui(player, data.quest_name, data.tree_view_rows)
  set_player_hints_gui(player)

  if not quest_gui_data.hints_showing[player.index] then
    player.gui.left.objective_flow.all_hints.visible = false
    player.gui.left.objective_flow.hints_title_flow.expand_hints_button.sprite = "utility/expand"
  end
end

-- If there is a quest in progress, insert the correct gui into the new player
local on_player_joined_game = function(event)
  local player = game.players[event.player_index]
  rebuild_player_gui(player)
end

quest_gui.set = function(quest_name, tree_view_rows)
  quest_gui.unset()

  -- Create a toplevel node with the quest name as it's name, and all the specified objectives as children
  tree_view_rows =
  {
    {
      item_name = 'heading',
      children = tree_view_rows,
    }
  }

  quest_gui_data.current_quest_gui_data =
  {
    quest_name = quest_name,
    tree_view_rows = tree_view_rows,
    flat_rows = tree_view.flatten_rows(tree_view_rows)
  }

  table.insert(quest_gui_data.hints,
    {
      quest_name = quest_name,
      hints = {}
    })

  for _, player in pairs(game.forces.player.players) do
    rebuild_player_gui(player)
  end
end

quest_gui.add_hint = function(hint)
  for _, previous_hint in pairs(quest_gui_data.hints) do
    if util.table.compare(previous_hint, hint) then
      error("hint " .. serpent.line(hint) .. " already present")
    end
  end

  assert(quest_gui_data.current_quest_gui_data, "adding hint when no quest set!")


  table.insert(quest_gui_data.hints[#quest_gui_data.hints].hints, hint)

  for _, player in pairs(game.forces.player.players) do
    rebuild_player_gui(player)
  end
end

quest_gui.visible = function(state)
  for _, player in pairs(game.forces.player.players) do
    local objective_flow = player.gui.left.objective_flow
    if objective_flow then
      objective_flow.visible = state
    end
  end
end

quest_gui.unset = function()
  for _, player in pairs(game.forces.player.players) do
    local objective_flow = player.gui.left.objective_flow
    if objective_flow then
      objective_flow.destroy()
    end
  end

  quest_gui_data.current_quest_gui_data = nil

end

local get_item_gui = function(player, item_name)
  local player_quest_gui = get_quest_frame(player)
  if not player_quest_gui then
    return
  end
  player_quest_gui = player_quest_gui.quest_main_table

  local quest_data = quest_gui_data.current_quest_gui_data
  if quest_data and quest_data.quest_name == quest_gui_data.current_quest_gui_data.quest_name then
    for index, item in pairs(quest_data.flat_rows) do
      if item.item_name == item_name then
        return player_quest_gui.children[index]
      end
    end
  end

  error("Cannot find quest item " .. item_name)
end

local update_tilset = function(state, item_gui)
  local update_sprite_widget = function(sprite_widget)
    if     util.string_starts_with(sprite_widget.sprite, "tree_view_tileset-square_l_d") then
      sprite_widget.sprite = "tree_view_tileset-square_l_d-" .. states_named[state].tileset
    elseif util.string_starts_with(sprite_widget.sprite, "tree_view_tileset-square_l") then
      sprite_widget.sprite = "tree_view_tileset-square_l-" .. states_named[state].tileset
    elseif util.string_starts_with(sprite_widget.sprite, "tree_view_tileset-square_d") then
      sprite_widget.sprite = "tree_view_tileset-square_d-" .. states_named[state].tileset
    elseif util.string_starts_with(sprite_widget.sprite, "tree_view_tileset-square_no_lines") then
      sprite_widget.sprite = "tree_view_tileset-square_no_lines-" .. states_named[state].tileset
    end
  end

  local recurse
  recurse = function(widget)
    if widget.type == "sprite" then
      update_sprite_widget(widget)
    end

    if #widget.children then
      for _, child in pairs(widget.children) do
        recurse(child)
      end
    end
  end

  recurse(item_gui)
end

local internal_update_state = function(state, item_gui)
  local desc_style = 'quest_item_description_' .. states_named[state].desc

  -- This check is just an optimisation
  if item_gui.desc_flow.inner.style == desc_style then
    return
  end

  item_gui.desc_flow.inner.style = desc_style
  if item_gui.count_flow then
    item_gui.count_flow.inner.style = desc_style
  end

  update_tilset(state, item_gui)
end

quest_gui.update_count = function(item_name, count, goal)
  for _, player in pairs(game.forces.player.players) do
    local item_gui = get_item_gui(player, item_name)

    if item_gui then
      item_gui.count_flow.inner.caption = count.."/"..goal

      local state = "default"
      if count >= goal then
        count = goal
        state = "success"
      elseif count > 0 then
        state = "progress"
      end

      internal_update_state(state, item_gui)
    end
  end
end

quest_gui.update_state = function(item_name, state)
  for _, player in pairs(game.forces.player.players) do
    local item_gui = get_item_gui(player, item_name)

    if item_gui then
      internal_update_state(state, item_gui)
    end
  end
end

local on_gui_click = function(event)
  if event.element.name and event.element.name == "expand_hints_button" then
    quest_gui_data.hints_showing[event.player_index] = not quest_gui_data.hints_showing[event.player_index]

    rebuild_player_gui(game.players[event.player_index])
  end
end



quest_gui.migrate = function()
  if global.CAMPAIGNS_VERSION < 12 then
    quest_gui_data.hints_showing = {}

    for _, player in pairs(game.forces.player.players) do
      rebuild_player_gui(player)
    end
  end
end

quest_gui.events =
{
  [defines.events.on_player_joined_game] = on_player_joined_game,
  [defines.events.on_gui_click] = on_gui_click,
}

return quest_gui