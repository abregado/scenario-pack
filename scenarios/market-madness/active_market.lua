local fake_supply = {
  {name = 'iron-ore', price = 10},
  {name = 'copper-ore', price = 10},
  {name = 'coal', price = 10},
  {name = 'stone', price = 10},
}

local fake_demand = {
  {name = 'iron-plate', price = 11},
  {name = 'copper-plate', price = 11},
  {name = 'stone-brick', price = 11},
}


local add_order_headers = function(order_gui)
  local name = order_gui.add({
    type = 'label',
    name = 'item_header',
    caption = 'Commodity'
  })
  name.style.width = 150
  local buy = order_gui.add({
    type = 'label',
    name = 'buy_header',
    caption = 'Buying at'
  })
  buy.style.width = 70
  local sell = order_gui.add({
    type = 'label',
    name = 'sell_header',
    caption = 'Selling at'
  })
  sell.style.width = 70
end

local create_wallet_gui = function(player)
  local frame = player.gui.left.add({
    type = 'frame',
    name = 'wallet_frame',
    direction = 'vertical',
    caption = 'Wallet'
  })
  frame.add({
    type = 'label',
    caption = '0',
    name = 'money'
  })
end

local update_wallet_gui = function(player)
  if not player.gui.left.wallet_frame then
    create_wallet_gui(player)
  end
  player.gui.left.wallet_frame.money.caption = '$'..tostring(global.market_data.player_wallets[player.name])
end

local create_market_gui = function(player)
  local frame = player.gui.left.add({
    type = 'frame',
    name = 'market_frame',
    direction = 'vertical',
    caption = 'Local Market Settings'
  })
  local order_gui = frame.add({
    type = 'table',
    name = 'market_orders',
    column_count = 3,
    draw_vertical_lines = true,
  })
  add_order_headers(order_gui)
  frame.add({
    type = 'button',
    name = 'refresh_market',
    caption = "Refresh"
  })
end

local refresh_market_gui = function(player,area)
  if not player.gui.left.market_frame then
    create_market_gui(player)
  end
  local market_orders = player.gui.left.market_frame.market_orders

  local old_prices = {}
  for index, child in pairs(market_orders.children) do
    if index % 3 == 1 and index > 1 then
      if old_prices[child.caption] then
        old_prices[child.caption].buy = old_prices[child.caption].buy + market_orders.children[index+1].text
        old_prices[child.caption].sell = old_prices[child.caption].sell + market_orders.children[index+2].text
        old_prices[child.caption] = false
      else
        old_prices[child.caption] = {
          buy = market_orders.children[index+1].text,
          sell = market_orders.children[index+2].text,
          active = false,
        }
      end
    end
  end

  market_orders.clear()

  --tally items
  local providers = player.surface.find_entities_filtered({
    name = 'logistic-chest-active-provider',
    area = area,
  })

  for _, provider in pairs(providers) do
    local contents = provider.get_inventory(defines.inventory.chest).get_contents()
    for item_name, count in pairs(contents) do
      if old_prices[item_name] then
        old_prices[item_name].active = true
      else
        old_prices[item_name] = {
          active = true,
          buy = nil,
          sell = nil,
        }
      end
    end
  end

  local requesters = player.surface.find_entities_filtered({
    name = 'logistic-chest-requester',
    area = area,
  })
  for _, requester in pairs(requesters) do
    local slots = requester.request_slot_count
    for slot=1, slots do
      local requested_stack = requester.get_request_slot(slot)
      if requested_stack then
        if old_prices[requested_stack.name] then
          old_prices[requested_stack.name].active = true
        else
          old_prices[requested_stack.name] = {
            active = true,
            buy = nil,
            sell = nil,
          }
        end
      end
    end
  end

  add_order_headers(market_orders)

  for item_name, data in pairs(old_prices) do
    if data.active then
      local saved_prices = global.market_data.player_prices[player.name][item_name] or {}
      market_orders.add({
        type = 'label',
        name = item_name..'-name',
        caption = item_name,
      })
      local buy = market_orders.add({
        type = 'textfield',
        name = item_name..'-buy',
        numeric = true,
        allow_negative = false,
        allow_decimal = true
      })
      buy.text = data.buy or saved_prices.buy or ""
      --if data.buy then buy.text = data.buy end
      --if buy.text == nil and saved_prices.buy then
      --  buy.text = saved_prices.buy
      --end
      buy.style.width = 70
      local sell = market_orders.add({
        type = 'textfield',
        name = item_name..'-sell',
        numeric = true,
        allow_negative = false,
        allow_decimal = true
      })
      sell.text = data.sell or saved_prices.sell or ""
      --if data.sell then sell.text = data.sell end
      sell.style.width = 70

      global.market_data.player_prices[player.name][item_name] = {
        buy = data.buy,
        sell = data.sell
      }
    end
  end
end

local on_built_entity = function(event)
  if event.created_entity.name == 'logistic-chest-active-provider' then
    table.insert(global.market_data.providers,event.created_entity)
  elseif event.created_entity.name == 'logistic-chest-requester' then
    table.insert(global.market_data.requesters,event.created_entity)
  end
end

local on_player_mined_entity = function(event)
  if event.entity.name == 'logistic-chest-active-provider' then
    for index, provider in pairs(global.market_data.providers) do
      if provider == event.entity then
        table.remove(global.market_data.providers,index)
        break
      end
    end
  elseif event.entity.name == 'logistic-chest-requester' then
    for index, requester in pairs(global.market_data.requesters) do
      if requester == event.entity then
        table.remove(global.market_data.requesters,index)
        break
      end
    end
  end
end

local tally_sell_orders = function()
  global.market_data.sell_orders_by_product = {}

  for _, player_area in pairs(global.market_data.player_areas) do
    local name = player_area.name
    local area = player_area.area

    local providers = game.players[name].surface.find_entities_filtered({
    name = 'logistic-chest-active-provider',
    area = area,
    })

    for _, provider in pairs(providers) do
      local contents = provider.get_inventory(defines.inventory.chest).get_contents()
      for item_name, count in pairs(contents) do
        if global.market_data.player_prices[name][item_name] and global.market_data.player_prices[name][item_name].sell then
          if not global.market_data.sell_orders_by_product[item_name] then
            global.market_data.sell_orders_by_product[item_name] = {}
          end
          table.insert(global.market_data.sell_orders_by_product[item_name],{
            count = count,
            location = provider,
            price = tonumber(global.market_data.player_prices[name][item_name].sell),
            player = name
          })
        end
      end
    end
  end

  --add market makers
  for _, raw_data in pairs(fake_supply) do
    if not global.market_data.sell_orders_by_product[raw_data.name] then
      global.market_data.sell_orders_by_product[raw_data.name] = {}
    end
    table.insert(global.market_data.sell_orders_by_product[raw_data.name],{count = 100, price = raw_data.price, location = nil, player = nil})
  end

  for item_name, orders in pairs(global.market_data.sell_orders_by_product) do
    table.sort(orders,function(a,b) return a.price < b.price end)
  end
end


local tally_buy_orders = function()
  global.market_data.buy_orders_by_product = {}

  for _, player_area in pairs(global.market_data.player_areas) do
    local name = player_area.name
    local area = player_area.area

    local requesters = game.players[name].surface.find_entities_filtered({
      name = 'logistic-chest-requester',
      area = area,
    })

    for _, requester in pairs(requesters) do
      local slots = requester.request_slot_count
      for slot=1, slots do
        local requested_stack = requester.get_request_slot(slot)
        if requested_stack and requester.get_inventory(defines.inventory.chest).get_item_count(requested_stack.name) == 0 then
          local item_name = requested_stack.name
          if global.market_data.player_prices[name][item_name] and global.market_data.player_prices[name][item_name].buy then
            if not global.market_data.buy_orders_by_product[item_name] then
              global.market_data.buy_orders_by_product[item_name] = {}
            end
            table.insert(global.market_data.buy_orders_by_product[item_name],{
              count = requested_stack.count,
              location = requester,
              price = tonumber(global.market_data.player_prices[name][item_name].buy),
              player = name
            })
          end
        end
      end
    end
  end

  --add market makers
  for _, raw_data in pairs(fake_demand) do
    if not global.market_data.buy_orders_by_product[raw_data.name] then
      global.market_data.buy_orders_by_product[raw_data.name] = {}
    end
    table.insert(global.market_data.buy_orders_by_product[raw_data.name],{count = 10, price = raw_data.price, location = nil, player = nil})
    table.insert(global.market_data.buy_orders_by_product[raw_data.name],{count = 100, price = raw_data.price/2, location = nil, player = nil})
    table.insert(global.market_data.buy_orders_by_product[raw_data.name],{count = 400, price = raw_data.price/4, location = nil, player = nil})
  end

  for item_name, orders in pairs(global.market_data.buy_orders_by_product) do
    table.sort(orders,function(a,b) return a.price > b.price end)
  end
end

local transfer = function(item_name,from,to)
  local transferred = 0
  if not from.location then
    --fake supplier
    transferred = math.min(from.count,to.count)
    --from.count = from.count - transferred
  else
    --real supplier
    transferred = from.location.get_inventory(defines.inventory.chest).remove({name=item_name,count=to.count})
    --from.count = from.count - transferred
  end

  if not to.location then
    --fake demander
  else
    to.location.get_inventory(defines.inventory.chest).insert({name=item_name,count=transferred})
    --to.count = to.count - transferred
  end

  return transferred
end

local player_buy = function(player_name,price,count)
  if player_name then
    global.market_data.player_wallets[player_name] = global.market_data.player_wallets[player_name] - (price*count)
    game.print(game.tick..':transaction: '..tostring(price*count*-1))
    update_wallet_gui(game.players[player_name])
  end
end

local player_sell = function(player_name,price,count)
  if player_name then
    global.market_data.player_wallets[player_name] = global.market_data.player_wallets[player_name] + (price*count)
    game.print(game.tick..':transaction: '..tostring(price*count))
    update_wallet_gui(game.players[player_name])
  end
end

local process_sales = function()
  for item_name, buy_orders in pairs(global.market_data.buy_orders_by_product) do
    if global.market_data.sell_orders_by_product[item_name] and #global.market_data.sell_orders_by_product[item_name] > 0 then
      for _, buy_order in pairs(buy_orders) do
        local sell_orders = global.market_data.sell_orders_by_product[item_name] or {}
        while #sell_orders > 0 and buy_order.price >= sell_orders[1].price and buy_order.count > 0 do
          local sold_amount = transfer(item_name,sell_orders[1],buy_order)
          player_buy(buy_order.player,sell_orders[1].price,sold_amount)
          player_sell(sell_orders[1].player,sell_orders[1].price,sold_amount)
          buy_order.count = buy_order.count - sold_amount
          sell_orders[1].count = sell_orders[1].count - sold_amount
          --game.print("matched sale for "..item_name.." buy count="..buy_order.count..", sell count="..sell_orders[1].count)
          if sell_orders[1].count == 0 then table.remove(sell_orders,1) end
        end
      end
    end
  end
end

local on_gui_click = function(event)
  local player = game.players[event.player_index]
  if event.element.name == 'refresh_market' then
    refresh_market_gui(player,{left_top={-500,-500},right_bottom={500,500}})
  end
end

local market = {}

market.init_player = function(player)
  create_wallet_gui(player)
  create_market_gui(player)
  table.insert(global.market_data.player_areas,{name=player.name,area={left_top={-500,-500},right_bottom={500,500}}})
  global.market_data.player_prices[player.name] = {}
  global.market_data.player_wallets[player.name] = 100000
end

market.update = function()
  tally_sell_orders()
  tally_buy_orders()
  process_sales()
  --for _, requester in pairs(global.market_data.requesters) do
  --  local slots = requester.request_slot_count
  --  for slot=1, slots do
  --    local requested_stack = requester.get_request_slot(slot)
  --    if requested_stack then
  --      if requester.get_item_count(requested_stack.name) == 0 then
  --
  --
  --        local found_in = nil
  --        for _, provider in pairs(global.market_data.providers) do
  --          if provider.get_item_count(requested_stack.name) >= requested_stack.count then
  --            found_in = provider
  --            break
  --          end
  --        end
  --
  --        if found_in then
  --          requester.insert(requested_stack)
  --          found_in.get_inventory(defines.inventory.chest).remove(requested_stack)
  --        end
  --      end
  --    end
  --  end
  --end
end

market.on_load = function()
  global.market_data = {
    requesters = {},
    providers = {},
    sell_orders_by_product = {},
    buy_orders_by_product = {},
    player_prices = {},
    player_wallets ={},
    player_areas={},
  }
end

market.events = {
  [defines.events.on_built_entity] = on_built_entity,
  [defines.events.on_player_mined_entity] = on_player_mined_entity,
  [defines.events.on_gui_click] = on_gui_click,
}

return market