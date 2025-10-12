local webHookLink =
''                                                                                                     -- Discord WebHook Link
local webHookName =
'Logs Muhaddil Insurance'                                                                              -- Name of the WebHook
local webHookLogo =
'https://github.com/Muhaddil/RSSWikiPageCreator/blob/main/public/assets/other/MuhaddilOG.png?raw=true' -- Logo of the WebHook bot

local ESXVer = Config.ESXVer
local FrameWork = nil

if Config.FrameWork == "auto" then
    if GetResourceState('es_extended') == 'started' then
        if ESXVer == 'new' then
            ESX = exports['es_extended']:getSharedObject()
            FrameWork = 'esx'
        else
            ESX = nil
            while ESX == nil do
                TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
                Citizen.Wait(0)
            end
        end
    elseif GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
        FrameWork = 'qb'
    end
elseif Config.FrameWork == "esx" and GetResourceState('es_extended') == 'started' then
    if ESXVer == 'new' then
        ESX = exports['es_extended']:getSharedObject()
        FrameWork = 'esx'
    else
        ESX = nil
        while ESX == nil do
            TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
            Citizen.Wait(0)
        end
    end
elseif Config.FrameWork == "qb" and GetResourceState('qb-core') == 'started' then
    QBCore = exports['qb-core']:GetCoreObject()
    FrameWork = 'qb'
else
    print('===NO SUPPORTED FRAMEWORK FOUND===')
end

local function discordWebHookSender(name, message, color)
    local connect = {
        {
            ["color"] = color,
            ["title"] = "**" .. name .. "**",
            ["description"] = message,
            ["footer"] = {
                ["text"] = os.date("%Y-%m-%d %H:%M:%S"),
            },
        }
    }
    PerformHttpRequest(webHookLink, function(err, text, headers) end, 'POST',
        json.encode({ username = webHookName, avatar_url = webHookLogo, embeds = connect }),
        { ['Content-Type'] = 'application/json' })
end

local function tryPay(xPlayer, accountType, price)
    local hasEnoughMoney = false
    local currentMoney = 0
    local success = false

    local accounts = {}

    if accountType == "bank" then
        accounts = { "bank", "cash" } -- prioridad bank, fallback cash
    else
        accounts = { "cash", "bank" } -- prioridad cash, fallback bank
    end

    for _, acc in ipairs(accounts) do
        if FrameWork == "esx" then
            if acc == "bank" then
                currentMoney = xPlayer.getAccount('bank').money
                if currentMoney >= price then
                    xPlayer.removeAccountMoney('bank', price)
                    TriggerEvent('esx_addonaccount:getSharedAccount', 'society_ambulance', function(account)
                        account.addMoney(price)
                    end)
                    success = true
                    break
                end
            else -- cash
                currentMoney = xPlayer.getMoney()
                if currentMoney >= price then
                    xPlayer.removeMoney(price)
                    TriggerEvent('esx_addonaccount:getSharedAccount', 'society_ambulance', function(account)
                        account.addMoney(price)
                    end)
                    success = true
                    break
                end
            end
        elseif FrameWork == "qb" then
            if acc == "bank" then
                currentMoney = xPlayer.PlayerData.money["bank"]
                if currentMoney >= price then
                    xPlayer.Functions.RemoveMoney('bank', price, 'Bill')
                    exports['qb-management']:AddMoney("ambulance", price)
                    success = true
                    break
                end
            else -- cash
                currentMoney = xPlayer.PlayerData.money["cash"]
                if currentMoney >= price then
                    xPlayer.Functions.RemoveMoney('cash', price, 'Bill')
                    exports['qb-management']:AddMoney("ambulance", price)
                    success = true
                    break
                end
            end
        end
    end

    return success, currentMoney
end

RegisterServerEvent('muhaddil_insurances:insurance:buy')
AddEventHandler('muhaddil_insurances:insurance:buy', function(data, accountType, targetPlayerId)
    local source = source
    local identifier = nil
    local xPlayer = nil
    local hasEnoughMoney = false
    local playerName = "Desconocido"
    local currentMoney = 0
    local type = data.type
    local duration = data.duration
    local price = data.price
    print(price)
    local expiration = os.time() + (duration * 24 * 60 * 60)

    local playerId = targetPlayerId or source

    if FrameWork == "esx" then
        xPlayer = ESX.GetPlayerFromId(playerId)
        identifier = xPlayer.identifier
        playerName = xPlayer.getName() or xPlayer.getIdentifier()
    elseif FrameWork == "qb" then
        xPlayer = QBCore.Functions.GetPlayer(playerId)
        identifier = xPlayer.PlayerData.citizenid
        playerName = (xPlayer.PlayerData.charinfo.firstname and xPlayer.PlayerData.charinfo.lastname) and
            xPlayer.PlayerData.charinfo.firstname .. " " .. xPlayer.PlayerData.charinfo.lastname or
            xPlayer.PlayerData.citizenid
    end

    hasEnoughMoney, currentMoney = tryPay(xPlayer, accountType, price)

    -- If the player has enough money, proceed with insurance purchase
    if hasEnoughMoney then
        MySQL.Async.execute(
            'INSERT INTO user_insurances (identifier, type, expiration) VALUES (@identifier, @type, @expiration) ON DUPLICATE KEY UPDATE type = @type, expiration = @expiration',
            {
                ['@identifier'] = identifier,
                ['@type'] = type,
                ['@expiration'] = expiration
            }, function(rowsChanged)
                if rowsChanged > 0 then
                    local successMessage = "El jugador **" ..
                        playerName ..
                        "** (ID: " ..
                        playerId ..
                        ") ha comprado un seguro de tipo **" ..
                        type .. "** por **" .. duration .. "** días. Precio: $" .. price

                    TriggerClientEvent('muhaddil_insurances:Notify', playerId, 'Seguro',
                        'Has comprado un seguro: ' .. type .. ' por ' .. duration .. ' días', 5000, 'success')

                    if not Config.UseOXLogger then
                        discordWebHookSender("Compra de Seguro", successMessage, 3066993)
                    else
                        lib.logger(identifier, 'muhaddil_insurances:insurance:buy', successMessage)
                    end
                else
                    TriggerClientEvent('muhaddil_insurances:Notify', playerId, 'Seguro',
                        'Hubo un error al contratar el seguro', 5000, 'error')
                end
            end)
    else
        TriggerClientEvent('muhaddil_insurances:Notify', playerId, 'Seguro',
            'No tienes suficiente dinero para comprar este seguro', 5000, 'error')
    end
end)

local function getInsurance(playerId, cb)
    local Player
    local identifier

    if FrameWork == "esx" then
        Player = ESX.GetPlayerFromId(playerId)
        if Player then
            identifier = Player.getIdentifier()
        end
    elseif FrameWork == "qb" then
        Player = QBCore.Functions.GetPlayer(playerId)
        if Player then
            identifier = Player.PlayerData.license
        end
    end

    if Player then
        local currentTime = os.time()

        MySQL.Async.fetchAll('SELECT type, expiration FROM user_insurances WHERE identifier = @identifier', {
            ['@identifier'] = identifier
        }, function(result)
            if result[1] then
                local expiration = result[1].expiration
                if expiration <= currentTime then
                    MySQL.Async.execute('DELETE FROM user_insurances WHERE identifier = @identifier', {
                        ['@identifier'] = identifier
                    })
                    cb(nil)
                else
                    local timeLeft = expiration - currentTime
                    local insuranceData = {
                        type = result[1].type,
                        timeRemaining = timeLeft,
                        expiration = expiration
                    }
                    cb(insuranceData)
                end
            else
                cb(nil)
            end
        end)
    else
        print('Error: Player is nil for playerId ' .. tostring(playerId))
        cb(nil)
    end
end

if FrameWork == "esx" then
    ESX.RegisterServerCallback('muhaddil_insurances:insurance:getInsurance', function(source, cb, playerId)
        getInsurance(playerId, cb)
    end)
elseif FrameWork == "qb" then
    QBCore.Functions.CreateCallback('muhaddil_insurances:insurance:getInsurance', function(source, cb, playerId)
        getInsurance(playerId, cb)
    end)
end

local function onPlayerLoaded(playerId)
    local Player
    local identifier

    if FrameWork == "esx" then
        Player = ESX.GetPlayerFromId(playerId)
        if Player then
            identifier = Player.getIdentifier()
        end
    elseif FrameWork == "qb" then
        Player = QBCore.Functions.GetPlayer(playerId)
        if Player then
            identifier = Player.PlayerData.license
        end
    end

    if Player then
        MySQL.Async.fetchAll('SELECT type, expiration FROM user_insurances WHERE identifier = @identifier', {
            ['@identifier'] = identifier
        }, function(result)
            if result[1] then
                local expiration = result[1].expiration
                local currentTime = os.time()
                local newExpiration = expiration - (currentTime - os.time())

                MySQL.Async.execute(
                    'UPDATE user_insurances SET expiration = @newExpiration WHERE identifier = @identifier', {
                        ['@newExpiration'] = newExpiration,
                        ['@identifier'] = identifier
                    })
            end
        end)
    end
end

if FrameWork == "esx" then
    AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
        onPlayerLoaded(playerId)
    end)
elseif FrameWork == "qb" then
    AddEventHandler('QBCore:Client:OnPlayerLoaded', function(playerId)
        onPlayerLoaded(playerId)
    end)
end

function formatTime(seconds)
    if seconds < 0 then seconds = 0 end
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%d días %02d:%02d:%02d", days, hours, minutes, secs)
end

function cleanExpiredInsurances()
    local currentTime = os.time()

    MySQL.Async.execute('DELETE FROM user_insurances WHERE expiration <= @currentTime', {
        ['@currentTime'] = currentTime
    }, function(affectedRows)
        if affectedRows > 0 then
            print('Limpieza de seguros expirados: ' .. affectedRows .. ' seguros eliminados.')
        end
    end)
end

local function getCronExpression(intervalInMinutes)
    if intervalInMinutes < 1 then
        error('El intervalo debe ser un valor positivo.')
    elseif intervalInMinutes <= 59 then
        return string.format("*/%d * * * *", intervalInMinutes)
    elseif intervalInMinutes % 60 == 0 then
        local intervalInHours = intervalInMinutes / 60
        return string.format("0 */%d * * *", intervalInHours)
    else
        error('Intervalos mayores a una hora deben ser múltiplos de 60.')
    end
end

local cronExpression = getCronExpression(Config.PeriodicallyDeleteInsurance)
lib.cron.new(cronExpression, function()
    print('Limpieza de seguros expirados.')
    cleanExpiredInsurances()
end)

RegisterNetEvent('muhaddil_insurances:insurance:offer', function(targetPlayerId, insuranceData)
    TriggerClientEvent('muhaddil_insurances:insurance:receiveOffer', targetPlayerId, insuranceData)
end)

if Config.AutoRunSQL then
    if not pcall(function()
            local fileName = "InstallSQL.sql"
            local file = assert(io.open(GetResourcePath(GetCurrentResourceName()) .. "/" .. fileName, "rb"))
            local sql = file:read("*all")
            file:close()

            MySQL.query.await(sql)
        end) then
        print(
            "^1[SQL ERROR] There was an error while automatically running the required SQL. Don't worry, you just need to run the SQL file. If you've already ran the SQL code previously, and this error is annoying you, set Config.AutoRunSQL = false^0")
    end
end

exports("hasValidInsurance", function(playerId)
    local Player
    local identifier

    if not playerId then
        playerId = source
    end

    if FrameWork == "esx" then
        Player = ESX.GetPlayerFromId(playerId)
        if Player then
            identifier = Player.getIdentifier()
        end
    elseif FrameWork == "qb" then
        Player = QBCore.Functions.GetPlayer(playerId)
        if Player then
            identifier = Player.PlayerData.license
        end
    end

    if identifier then
        local promise = promise.new()
        MySQL.Async.fetchScalar('SELECT COUNT(*) FROM user_insurances WHERE identifier = @identifier', {
            ['@identifier'] = identifier
        }, function(result)
            if result > 0 then
                promise:resolve(true)
            else
                promise:resolve(false)
            end
        end)
        return Citizen.Await(promise)
    else
        return false
    end
end)

RegisterNetEvent('muhaddil_insurance:syncInsuranceStatus', function(playerId)
    local hasInsurance = exports['muhaddil_insurance']:hasValidInsurance(playerId)
    TriggerClientEvent('muhaddil_insurance:updateInsuranceStatus', playerId, hasInsurance)
end)

RegisterNetEvent('muhaddil_insurance:checkInsuranceExport', function(playerId)
    local requestingPlayer = source
    local targetPlayerId = playerId or requestingPlayer
    local hasInsurance = exports['muhaddil_insurance']:hasValidInsurance(targetPlayerId)

    TriggerClientEvent('muhaddil_insurance:insuranceResult', requestingPlayer, hasInsurance)
end)

lib.callback.register('getPlayerNameInGame', function(targetPlayerServerId)
    local playerData = { firstname = "Desconocido", lastname = "" }

    if FrameWork == "esx" then
        local xPlayer = ESX.GetPlayerFromId(targetPlayerServerId)
        if not xPlayer then return playerData end

        local result = MySQL.Sync.fetchAll('SELECT firstname, lastname FROM `users` WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.identifier
        })

        if result[1] then
            playerData.firstname = result[1].firstname or "Unknown"
            playerData.lastname = result[1].lastname or ""
        end
    elseif FrameWork == "qb" then
        local player = QBCore.Functions.GetPlayer(targetPlayerServerId)
        if not player then return playerData end

        local result = MySQL.Sync.fetchAll('SELECT firstname, lastname FROM `players` WHERE citizenid = @citizenid', {
            ['@citizenid'] = player.PlayerData.citizenid
        })

        if result[1] then
            playerData.firstname = result[1].firstname or "Unknown"
            playerData.lastname = result[1].lastname or ""
        end
    end

    return playerData
end)

lib.callback.register('muhaddil_insurances:getLocaleData', function(source)
    local resourceName = GetCurrentResourceName()
    local locale = json.decode(LoadResourceFile(resourceName, ('locales/%s.json'):format(Config.NUILocale)))
    return locale
end)
