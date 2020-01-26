local room_gui = {}

room_gui.build_door_gui = function(door_data,player,has_all)
  local frame = player.gui.left.add({
    type = 'frame',
    caption = {'door-gui.heading'},
    direction = 'vertical',
    name = door_data.name,
  })
  frame.style.width = 300
  local text = frame.add({
    type = 'label',
    caption = {'door-gui.text'},
    name = 'door-text'
  })
  text.style.single_line = false
  local table = frame.add({
    type = 'table',
    name = 'cost-table',
    column_count = 3,
  })
  local heading = table.add({
    type = 'label',
    caption = {"",'[font=default-bold]',{'door-gui.ingredient-heading'},'[/font]'},
  })
  heading.style.width = 120
  local icon_heading = table.add({
    type = 'label',
    caption = " ",
  })
  icon_heading.style.width = 32
  table.add({
    type = 'label',
    caption = {"",'[font=default-bold]',{'door-gui.count-heading'},'[/font]'},
  })
  for _, ingredient in pairs(door_data.cost) do
    table.add({
      type = 'label',
      caption = game.item_prototypes[ingredient[1]].localised_name,
    })
    table.add({
      type = 'label',
      caption = "[img=item/"..ingredient[1].."]",
    })
    table.add({
      type = 'label',
      caption = ingredient[2],
    })
  end
  local button = frame.add({
    type = 'button',
    caption = {'door-gui.button'},
    name = 'button-unlock'
  })
  button.enabled = has_all
end


return room_gui