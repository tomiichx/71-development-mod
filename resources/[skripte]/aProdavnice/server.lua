ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local deadPeds = {}

RegisterServerEvent('loffe_robbery:pedDead')
AddEventHandler('loffe_robbery:pedDead', function(store)
    if not deadPeds[store] then
        deadPeds[store] = 'deadlol'
        TriggerClientEvent('loffe_robbery:onPedDeath', -1, store)
        local second = 1000
        local minute = 60 * second
        local hour = 60 * minute
        local cooldown = Config.Shops[store].cooldown
        local wait = cooldown.hour * hour + cooldown.minute * minute + cooldown.second * second
        Wait(wait)
        if not Config.Shops[store].robbed then
            for k, v in pairs(deadPeds) do if k == store then table.remove(deadPeds, k) end end
            TriggerClientEvent('loffe_robbery:resetStore', -1, store)
        end
    end
end)

RegisterServerEvent('loffe_robbery:handsUp')
AddEventHandler('loffe_robbery:handsUp', function(store)
    TriggerClientEvent('loffe_robbery:handsUp', -1, store)
end)

RegisterServerEvent('loffe_robbery:pickUp')
AddEventHandler('loffe_robbery:pickUp', function(store)
    local xPlayer = ESX.GetPlayerFromId(source)
    local randomAmount = math.random(Config.Shops[store].money[1], Config.Shops[store].money[2])
    xPlayer.addMoney(randomAmount)
    sendToDiscord('Dobitak od Prodavnice', GetPlayerName(soruce) .. ' je dobio ' .. ' ' .. randomAmount .. ' od pljacke ')
    TriggerClientEvent('esx:showNotification', source, Translation[Config.Locale]['cashrecieved'] .. ' ~g~' .. randomAmount .. ' ' .. Translation[Config.Locale]['currency'])
    TriggerClientEvent('loffe_robbery:removePickup', -1, store) 
end)

ESX.RegisterServerCallback('loffe_robbery:canRob', function(source, cb, store)
    local cops = 0
    local xPlayers = ESX.GetPlayers()
    for i = 1, #xPlayers do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        if xPlayer.job.name == 'police' then
            cops = cops + 1
        end
    end
    if cops >= Config.Shops[store].cops then
        if not Config.Shops[store].robbed and not deadPeds[store] then
            cb(true)
        else
            cb(false)
        end
    else
        cb('no_cops')
    end
end)

RegisterServerEvent('loffe_robbery:rob')
AddEventHandler('loffe_robbery:rob', function(store)
    local src = source
    Config.Shops[store].robbed = true
    local xPlayers = ESX.GetPlayers()
    for i = 1, #xPlayers do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        if xPlayer.job.name == 'police' then
            TriggerClientEvent('loffe_robbery:msgPolice', xPlayer.source, store, src)
        end
    end
    TriggerClientEvent('loffe_robbery:rob', -1, store)
    sendToDiscord('Pljackanje Prodavnice', GetPlayerName(source) .. ' je zapoceo pljacku prodavnice ' .. store)
    Wait(30000)
    TriggerClientEvent('loffe_robbery:robberyOver', src)

    local second = 1000
    local minute = 60 * second
    local hour = 60 * minute
    local cooldown = Config.Shops[store].cooldown
    local wait = cooldown.hour * hour + cooldown.minute * minute + cooldown.second * second
    Wait(wait)
    Config.Shops[store].robbed = false
    for k, v in pairs(deadPeds) do if k == store then table.remove(deadPeds, k) end end
    TriggerClientEvent('loffe_robbery:resetStore', -1, store)
end)

CreateThread(function()
    while true do
        for i = 1, #deadPeds do TriggerClientEvent('loffe_robbery:pedDead', -1, i) end -- update dead peds
        Wait(500)
    end
end)

function sendToDiscord(name,message, color)
	local vreme = os.date("*t")
	local DiscordWebHook = "OVDE WEBHOOK"
	local embeds = {
		{
			["title"]=message,
			["type"]="rich",
			["color"] =color,
			["footer"]=  {
		  ["text"]= "Vreme: " .. vreme.hour .. ":" .. vreme.min .. ":" .. vreme.sec,
  
		   },
		}
	} 
	if message == nil or message == '' then return FALSE end
	PerformHttpRequest(DiscordWebHook, function(err, text, headers) end, 'POST', json.encode({ username = name, embeds = embeds}), { ['Content-Type'] = 'application/json' })
end