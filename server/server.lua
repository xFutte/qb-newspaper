local QBCore = exports['qb-core']:GetCoreObject()

function CreateJailStory(name, time)
    exports.oxmysql:execute(
        'INSERT INTO newsstands (story_type, jailed_player, jailed_time, date) VALUES (?, ?, ?, CURRENT_TIMESTAMP)',
        {'jail', name, time})
end

QBCore.Functions.CreateCallback('newsstands:server:getStories', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local isReporter = false
    local reporterLevel = nil
    local amountOfNews = Config.AmountOfNews or 10
    local amountOfSentences = Config.AmountOfSentences or 10
    local playerName = Player.PlayerData.charinfo['firstname'] .. ' ' .. Player.PlayerData.charinfo['lastname']

    local reporterOnDuty = Player.PlayerData.job['onduty']

    if Player.PlayerData.job['name'] == 'reporter' then
        isReporter = true
        reporterLevel = Player.PlayerData.job.grade['level']
    end

    local news = exports.oxmysql:executeSync("SELECT * FROM newsstands WHERE story_type = ? ORDER BY id DESC LIMIT " ..
                                                 amountOfNews .. "", {'news'})

    local sentences = exports.oxmysql:executeSync(
        "SELECT * FROM newsstands WHERE story_type = ? ORDER BY id DESC LIMIT " .. amountOfNews .. "", {'jail'})

    cb(news, sentences, isReporter, reporterLevel, reporterOnDuty, playerName)

    reporterLevel = nil
end)

-- Handle getting papers from stands

QBCore.Functions.CreateUseableItem("newspaper", function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player.Functions.GetItemByName(item.name) ~= nil then
        TriggerClientEvent('newsstands:client:openNewspaper', src)
    end
end)

-- Buy a newspaper
RegisterNetEvent('newsstands:buy', function(type)
    local Player = QBCore.Functions.GetPlayer(source)
    local cash = Player.PlayerData.money['cash']

    if type then
        if cash >= Config.Price then

            Player.Functions.RemoveMoney("cash", Config.Price)
            TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['newspaper'], "add")
            Player.Functions.AddItem(type, 1)
        else
            TriggerClientEvent('QBCore:Notify', source, '$' .. Config.Price .. ' required for buying a newspaper',
                'error')
        end
    end
end)

RegisterNetEvent('newsstands:server:updateStory', function(data)
    local Player = QBCore.Functions.GetPlayer(source)
    local src = source
    local knownPlayers = {}

    knownPlayers[source] = true;

    if Player.PlayerData.job['name'] == 'reporter' then
        if not knownPlayers[source] then
            -- Yeet the player 
            knownPlayers[source] = nil;

            return
        else
            exports.oxmysql:insert('UPDATE newsstands SET title = ?, body = ?, image = ? WHERE id = ?',
                {data.title, data.body, data.image, data.id})

            TriggerClientEvent('QBCore:Notify', src, 'Story has been updated!', 'success')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'You need to be a reporter to update a story', 'success')
    end

    knownPlayers[source] = nil;

end)

RegisterNetEvent('newsstands:server:publishStory', function(data)
    local Player = QBCore.Functions.GetPlayer(source)
    local src = source
    local knownPlayers = {}

    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname

    knownPlayers[source] = true;

    if Player.PlayerData.job['name'] == 'reporter' then
        if not knownPlayers[source] then
            -- Yeet the player 
            knownPlayers[source] = nil;

            return
        else
            exports.oxmysql:insert(
                'INSERT INTO newsstands (story_type, title, body, date, image, publisher) VALUES (?, ?, ?, ?, ?, ?)',
                {'news', data.title, data.body, data.date, data.image, playerName})

            TriggerClientEvent('QBCore:Notify', src, 'Story has been published!', 'success')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'You need to be a reporter to publish a story', 'success')
    end

    knownPlayers[source] = nil;
end)

RegisterNetEvent('newsstands:server:deleteStory', function(data)
    local Player = QBCore.Functions.GetPlayer(source)
    local src = source
    local knownPlayers = {}

    knownPlayers[source] = true;

    if Player.PlayerData.job['name'] == 'reporter' then
        if not knownPlayers[source] then
            -- Player not supposed to have access to this. Ban the player.

            knownPlayers[source] = nil;

            return
        else
            exports.oxmysql:execute('DELETE FROM newsstands WHERE id = ?', {data.id})

            TriggerClientEvent('QBCore:Notify', src, 'Story have been deleted', 'success')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'Not possible to delete story', 'success')
    end

    knownPlayers[source] = nil;
end)
