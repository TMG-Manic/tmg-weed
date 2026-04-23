local TMGCore = exports['tmg-core']:GetCoreObject()
local housePlants, currentHouse, plantSpawned, closestPlant = {}, nil, false, 0

TMGCore.Functions.CreateCallback('tmg-weed:server:getBuildingPlants', function(source, cb, building)
    if not building then return cb({}) end

    exports['tmgnosql']:FetchAll('house_plants', { ["building"] = building }, function(plants)
        cb(plants or {})
        
        print(string.format("^5[TMG]^7 Botanical: Streamed %s units to Terminal %s for Building [%s]", #plants or 0, source, building))
    end)
end)

RegisterNetEvent('tmg-weed:server:placePlant', function(coords, sort, currentHouse)
    local src = source
    local Player = TMGCore.Functions.GetPlayer(src)
    if not Player then return end

    local gender = (math.random(1, 2) == 1) and 'man' or 'woman'
    local plantId = math.random(111111, 999999)

    local plantData = {
        ["building"] = currentHouse,
        ["coords"] = coords,
        ["gender"] = gender,
        ["sort"] = sort,
        ["plantid"] = plantId,
        ["progress"] = 0,
        ["health"] = 100,
        ["food"] = 100,
        ["stage"] = 1,
        ["owner"] = Player.PlayerData.citizenid -- Biometric link for theft prevention
    }

    exports['tmgnosql']:InsertOne('house_plants', plantData, function(success)
        if success then
            TriggerClientEvent('tmg-weed:client:refreshHousePlants', -1, currentHouse)
        else
            TriggerClientEvent('TMGCore:Notify', src, "Mainframe: Registry rejected plant write.", 'error')
        end
    end)
end)

RegisterNetEvent('tmg-weed:server:applyNutrition', function(house, amount, plantName, plantId)
    local src = source
    local Player = TMGCore.Functions.GetPlayer(src)
    if not Player or not house or not plantId then return end

    if not exports['tmg-inventory']:RemoveItem(src, 'weed_nutrition', 1, false, 'botanical-nutrition-apply') then
        return TriggerClientEvent('TMGCore:Notify', src, "Nutrition supplements missing.", 'error')
    end

    local filter = { ["building"] = house, ["plantid"] = plantId }
    local update = { ["$inc"] = { ["food"] = amount } }

    exports['tmgnosql']:UpdateOne('house_plants', filter, update, function(success)
        if success then
            exports['tmgnosql']:UpdateOne('house_plants', 
                { ["plantid"] = plantId, ["food"] = { ["$gt"] = 100 } }, 
                { ["$set"] = { ["food"] = 100 } }
            )
            TriggerClientEvent('TMGCore:Notify', src, "Vitality supplements applied.", 'success')
            TriggerClientEvent('tmg-weed:client:refreshSectorPlants', -1, house)
        else
            Player.Functions.AddItem('weed_nutrition', 1)
        end
    end)
end)

RegisterNetEvent('tmg-weed:server:removeDeathPlant', function(building, plantId)
    if not building or not plantId then return end
    exports['tmgnosql']:DeleteOne('house_plants', { ["plantid"] = plantId, ["building"] = building }, function(success)
        if success then
            TriggerClientEvent('tmg-weed:client:refreshHousePlants', -1, building)
        end
    end)
end)

RegisterServerEvent('tmg-weed:server:removeSeed', function(itemslot, seed)
    local src = source
    local Player = TMGCore.Functions.GetPlayer(src)
    if not Player or not itemslot or not seed then return end

    local itemData = Player.Functions.GetItemBySlot(itemslot)
    if itemData and itemData.name == seed then
        if exports['tmg-inventory']:RemoveItem(src, seed, 1, itemslot, 'botanical-planting-consume') then
            TriggerClientEvent('tmg-inventory:client:ItemBox', src, TMGCore.Shared.Items[seed], 'remove')
        end
    else
        print(string.format("^1[TMG Security]^7 Terminal %s attempted illegitimate seed removal.", src))
    end
end)

RegisterNetEvent('tmg-weed:server:harvestPlant', function(house, amount, plantName, plantId)
    local src = source
    local Player = TMGCore.Functions.GetPlayer(src)
    if not Player or not house then return end

    local sndAmount = math.random(12, 16)
    local weedBag = Player.Functions.GetItemByName('empty_weed_bag')

    if not weedBag or weedBag.amount < sndAmount then
        return TriggerClientEvent('TMGCore:Notify', src, "Insufficient processing materials (Bags).", 'error')
    end

    exports['tmgnosql']:DeleteOne('house_plants', { ["plantid"] = plantId, ["building"] = house }, function(deleted)
        if deleted then
            local product = 'weed_' .. (plantName or "unknown")
            local seed = product .. '_seed'

            Player.Functions.RemoveItem('empty_weed_bag', sndAmount)
            Player.Functions.AddItem(seed, amount)
            Player.Functions.AddItem(product, sndAmount)

            TriggerClientEvent('tmg-inventory:client:ItemBox', src, TMGCore.Shared.Items[product], 'add')
            TriggerClientEvent('tmg-weed:client:refreshHousePlants', -1, house)
            TriggerClientEvent('TMGCore:Notify', src, "Asset harvested and processed.", 'success')
        end
    end)
end)

RegisterNetEvent('tmg-weed:server:foodPlant', function(house, amount, plantName, plantId)
    local src = source
    local Player = TMGCore.Functions.GetPlayer(src)
    if not Player or not house or not plantId then return end

    if exports['tmg-inventory']:RemoveItem(src, 'weed_nutrition', 1, false, 'botanical-nutrition-apply') then
        local filter = { ["building"] = house, ["plantid"] = plantId }
        local update = { ["$inc"] = { ["food"] = amount } }

        exports['tmgnosql']:UpdateOne('house_plants', filter, update, function(success)
            if success then
                exports['tmgnosql']:UpdateOne('house_plants', 
                    { ["plantid"] = plantId, ["food"] = { ["$gt"] = 100 } }, 
                    { ["$set"] = { ["food"] = 100 } }
                )
                TriggerClientEvent('tmg-weed:client:refreshHousePlants', -1, house)
                TriggerClientEvent('TMGCore:Notify', src, "Nutrients injected. Vitality increasing.", 'success')
            else
                Player.Functions.AddItem('weed_nutrition', 1)
            end
        end)
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    if not TMGWeed or not TMGWeed.Plants then
        return print("^1[TMG Error]^7 Botanical Registry failed to load. Table 'TMGWeed.Plants' is missing.")
    end

    for plantName, _ in pairs(TMGWeed.Plants) do
        local itemName = 'weed_' .. plantName .. '_seed'
        
        TMGCore.Functions.CreateUseableItem(itemName, function(source, item)
            TriggerClientEvent('tmg-weed:client:placePlant', source, plantName, item)
        end)
    end

    TMGCore.Functions.CreateUseableItem('weed_nutrition', function(source, item)
        TriggerClientEvent('tmg-weed:client:foodPlant', source, item)
    end)

    print("^2[TMG]^7 Botanical Grid: ONLINE and Synchronized.")
end)


CreateThread(function()
    local healthTick = false
    while true do
        local tickTime = (TMGWeed and TMGWeed.GrowthTick) or 1
        Wait((60 * 1000) * tickTime)

        local growAmount = math.random(TMGWeed.Progress.min, TMGWeed.Progress.max)
        
        exports['tmgnosql']:UpdateMany('house_plants', 
            { ["health"] = { ["$gt"] = 50 }, ["progress"] = { ["$lt"] = 100 } }, 
            { ["$inc"] = { ["progress"] = growAmount } }
        )

        exports['tmgnosql']:UpdateMany('house_plants', 
            { ["progress"] = { ["$gte"] = 100 } }, 
            { ["$inc"] = { ["stage"] = 1 }, ["$set"] = { ["progress"] = 0 } }
        )

        if healthTick then
            exports['tmgnosql']:UpdateMany('house_plants', {}, { ["$inc"] = { ["food"] = -WeedConfig.FoodUsage } })
            
            exports['tmgnosql']:UpdateMany('house_plants', { ["food"] = { ["$gte"] = 50 }, ["health"] = { ["$lt"] = 100 } }, { ["$inc"] = { ["health"] = 1 } })
            exports['tmgnosql']:UpdateMany('house_plants', { ["food"] = { ["$lt"] = 50 }, ["health"] = { ["$gt"] = 0 } }, { ["$inc"] = { ["health"] = -1 } })
        end

        TriggerClientEvent('tmg-weed:client:refreshHousePlants', -1)
        healthTick = not healthTick
    end
end)