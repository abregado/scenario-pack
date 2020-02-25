

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

local market = {}

market.update = function()
  for _, requester in pairs(global.market_data.requesters) do
    local slots = requester.request_slot_count
    for slot=1, slots do
      local requested_stack = requester.get_request_slot(slot)
      if requested_stack then
        if requester.get_item_count(requested_stack.name) == 0 then
          local found_in = nil
          for _, provider in pairs(global.market_data.providers) do
            if provider.get_item_count(requested_stack.name) >= requested_stack.count then
              found_in = provider
              break
            end
          end

          if found_in then
            requester.insert(requested_stack)
            found_in.get_inventory(defines.inventory.chest).remove(requested_stack)
          end
        end
      end
    end
  end
end

market.on_load = function()
  global.market_data = {
    requesters = {},
    providers = {},
    orders_by_product = {}
  }
end

market.events = {
  [defines.events.on_built_entity] = on_built_entity,
  [defines.events.on_player_mined_entity] = on_player_mined_entity,
}

return market