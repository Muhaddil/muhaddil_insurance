local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version')
local resourceRepo = 'Muhaddil/muhaddil_insurance'
local githubApiUrl = 'https://api.github.com/repos/' .. resourceRepo .. '/releases/latest'
local webHookLink = '' -- Discord WebHook Link
local webHookName = 'Logs Muhaddil Insurance' -- Name of the WebHook
local webHookLogo = 'https://github.com/Muhaddil/RSSWikiPageCreator/blob/main/public/assets/other/MuhaddilOG.png?raw=true' -- Logo of the WebHook bot

if Config.FrameWork == "esx" then
    ESX = exports['es_extended']:getSharedObject()
elseif Config.FrameWork == "qb" then
    QBCore = exports['qb-core']:GetCoreObject()
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
    local expiration = os.time() + (duration * 24 * 60 * 60)

    local playerId = targetPlayerId or source

    if Config.FrameWork == "esx" then
        xPlayer = ESX.GetPlayerFromId(playerId)
        identifier = xPlayer.identifier
        playerName = xPlayer.getName() or xPlayer.getIdentifier()
    elseif Config.FrameWork == "qb" then
        xPlayer = QBCore.Functions.GetPlayer(playerId)
        identifier = xPlayer.PlayerData.citizenid
        playerName = (xPlayer.PlayerData.charinfo.firstname and xPlayer.PlayerData.charinfo.lastname) and
            xPlayer.PlayerData.charinfo.firstname .. " " .. xPlayer.PlayerData.charinfo.lastname or
            xPlayer.PlayerData.citizenid
    end

    -- Money checking
    if accountType == 'bank' then
        if Config.FrameWork == "esx" then
            currentMoney = xPlayer.getAccount('bank').money
            hasEnoughMoney = currentMoney >= price

            if hasEnoughMoney then
                xPlayer.removeAccountMoney('bank', price)
                TriggerEvent('esx_addonaccount:getSharedAccount', 'society_ambulance', function(account)
                    account.addMoney(price)
                end)
            end
        elseif Config.FrameWork == "qb" then
            currentMoney = xPlayer.PlayerData.money["bank"]
            hasEnoughMoney = currentMoney >= price

            if hasEnoughMoney then
                xPlayer.Functions.RemoveMoney('bank', price, 'Bill')
                exports['qb-management']:AddMoney("ambulance", price)
            end
        end
    else
        if Config.FrameWork == "esx" then
            currentMoney = xPlayer.getMoney()
            hasEnoughMoney = currentMoney >= price

            if hasEnoughMoney then
                xPlayer.removeMoney(price)
                TriggerEvent('esx_addonaccount:getSharedAccount', 'society_ambulance', function(account)
                    account.addMoney(price)
                end)
            end
        elseif Config.FrameWork == "qb" then
            currentMoney = xPlayer.PlayerData.money["cash"]
            hasEnoughMoney = currentMoney >= price

            if hasEnoughMoney then
                xPlayer.Functions.RemoveMoney('cash', price, 'Bill')
                exports['qb-management']:AddMoney("ambulance", price)
            end
        end
    end

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
                    local successMessage = "El jugador **" .. playerName .. "** (ID: " .. playerId .. ") ha comprado un seguro de tipo **" .. type .. "** por **" .. duration .. "** días. Precio: $" .. price

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

    if Config.FrameWork == "esx" then
        Player = ESX.GetPlayerFromId(playerId)
        if Player then
            identifier = Player.getIdentifier()
        end
    elseif Config.FrameWork == "qb" then
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
                        timeLeft = formatTime(timeLeft),
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

if Config.FrameWork == "esx" then
    ESX.RegisterServerCallback('muhaddil_insurances:insurance:getInsurance', function(source, cb, playerId)
        getInsurance(playerId, cb)
    end)
elseif Config.FrameWork == "qb" then
    QBCore.Functions.CreateCallback('muhaddil_insurances:insurance:getInsurance', function(source, cb, playerId)
        getInsurance(playerId, cb)
    end)
end

local function onPlayerLoaded(playerId)
    local Player
    local identifier

    if Config.FrameWork == "esx" then
        Player = ESX.GetPlayerFromId(playerId)
        if Player then
            identifier = Player.getIdentifier()
        end
    elseif Config.FrameWork == "qb" then
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

if Config.FrameWork == "esx" then
    AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
        onPlayerLoaded(playerId)
    end)
elseif Config.FrameWork == "qb" then
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

local function daysAgo(dateStr)
    local year, month, day = dateStr:match("(%d+)-(%d+)-(%d+)")
    local releaseTime = os.time({ year = year, month = month, day = day })
    local currentTime = os.time()
    local difference = os.difftime(currentTime, releaseTime) / (60 * 60 * 24) -- Diferencia en días
    return math.floor(difference)
end

local function formatDate(releaseDate)
    local days = daysAgo(releaseDate)
    if days < 1 then
        return "Today"
    elseif days == 1 then
        return "Yesterday"
    else
        return days .. " days ago"
    end
end

local function shortenTexts(text)
    local maxLength = 35
    if #text > maxLength then
        local shortened = text:sub(1, maxLength - 3) .. '...'
        return shortened
    else
        return text
    end
end

local function printWithColor(message, colorCode)
    if type(message) ~= "string" then
        message = tostring(message)
    end
    print('\27[' .. colorCode .. 'm' .. message .. '\27[0m')
end

local function printCentered(text, length, colorCode)
    local padding = math.max(length - #text - 2, 0)
    local leftPadding = math.floor(padding / 2)
    local rightPadding = padding - leftPadding
    printWithColor('│' .. string.rep(' ', leftPadding) .. text .. string.rep(' ', rightPadding) .. '│', colorCode)
end

local function printWrapped(text, length, colorCode)
    if type(text) ~= "string" then
        text = tostring(text)
    end

    local maxLength = length - 2
    local pos = 1

    while pos <= #text do
        local endPos = pos + maxLength - 1
        if endPos > #text then
            endPos = #text
        else
            local spaceIndex = text:sub(pos, endPos):match('.*%s') or maxLength
            endPos = pos + spaceIndex - 1
        end

        local line = text:sub(pos, endPos)
        local paddedLine = line .. string.rep(' ', maxLength - #line)

        printWithColor('│' .. paddedLine .. '│', colorCode)

        pos = endPos + 1
    end
end

local versionData = {
    latestVersion = nil,
    releaseDate = nil,
    notes = nil,
    downloadUrl = nil
}

local isUpdateAvailable = false

function fetchVersionData()
    PerformHttpRequest(githubApiUrl, function(statusCode, response, headers)
        if statusCode == 200 then
            local data = json.decode(response)

            if data and data.tag_name then
                versionData.latestVersion = data.tag_name
                versionData.releaseDate = formatDate(data.published_at or "Unknown")
                versionData.notes = shortenTexts(data.body or "No notes available")
                versionData.downloadUrl = shortenTexts(data.html_url or "No download link available")
                displayVersionData()
                isUpdateAvailable = (versionData.latestVersion ~= currentVersion)
            else
                printWithColor('[Muhaddil_Insurances] - Error: Invalid JSON structure.', '31') -- Red
            end
        else
            printWithColor('[Muhaddil_Insurances] - Failed to fetch version data. Status code: ' .. statusCode, '31') -- Red
        end
    end, 'GET')
end

function displayVersionData()
    local boxWidth = 54
    local boxWidthNotes = 54

    if versionData.latestVersion then
        if versionData.latestVersion ~= currentVersion then
            print('╭────────────────────────────────────────────────────╮')
            printCentered('[Muhaddil_Insurances] - New Version Available', boxWidth, '34') -- Blue
            printWrapped('Current version: ' .. currentVersion, boxWidth, '32')            -- Green
            printWrapped('Latest version: ' .. versionData.latestVersion, boxWidth, '33')  -- Yellow
            printWrapped('Released: ' .. versionData.releaseDate, boxWidth, '33')          -- Yellow
            printWrapped('Notes: ' .. versionData.notes, boxWidthNotes, '33')              -- Yellow
            printWrapped('Download: ' .. versionData.downloadUrl, boxWidth, '32')          -- Green
            print('╰────────────────────────────────────────────────────╯')
        else
            print('╭────────────────────────────────────────────────────╮')
            printWrapped('[Muhaddil_Insurances] - Up-to-date', boxWidth, '32')  -- Green
            printWrapped('Current version: ' .. currentVersion, boxWidth, '32') -- Green
            print('╰────────────────────────────────────────────────────╯')
        end
    else
        printWithColor('[Muhaddil_Insurances] - No version data available.', '31') -- Red
    end
end

Citizen.CreateThread(function()
    if Config.AutoVersionChecker then
        fetchVersionData()
    end
end)

local updateCronExpression = getCronExpression(30)
lib.cron.new(updateCronExpression, function()
    if isUpdateAvailable then
        displayVersionData()
    end
end)

exports("hasValidInsurance", function(playerId)
    local Player
    local identifier

    if not playerId then
        playerId = source
    end

    if Config.FrameWork == "esx" then
        Player = ESX.GetPlayerFromId(playerId)
        if Player then
            identifier = Player.getIdentifier()
        end
    elseif Config.FrameWork == "qb" then
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

    if Config.FrameWork == "esx" then
        local xPlayer = ESX.GetPlayerFromId(targetPlayerServerId)
        if not xPlayer then return playerData end

        local result = MySQL.Sync.fetchAll('SELECT firstname, lastname FROM `users` WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.identifier
        })

        if result[1] then
            playerData.firstname = result[1].firstname or "Unknown"
            playerData.lastname = result[1].lastname or ""
        end
    elseif Config.FrameWork == "qb" then
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
