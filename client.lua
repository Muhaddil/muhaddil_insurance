if Config.FrameWork == "esx" then
    ESX = exports['es_extended']:getSharedObject()
elseif Config.FrameWork == "qb" then
    QBCore = exports['qb-core']:GetCoreObject()
end

lib.locale()

function Notify(msgtitle, msg, time, type2)
    if Config.UseOXNotifications then
        lib.notify({
            title = msgtitle,
            description = msg,
            showDuration = true,
            type = type2,
            style = {
                backgroundColor = 'rgba(0, 0, 0, 0.75)',
                color = 'rgba(255, 255, 255, 1)',
                ['.description'] = {
                    color = '#909296',
                    backgroundColor = 'transparent'
                }
            }
        })
    else
        if Config.Framework == 'qb' then
            QBCore.Functions.Notify(msg, type2, time)
        elseif Config.Framework == 'esx' then
            TriggerEvent('esx:showNotification', msg, type2, time)
        end
    end
end

RegisterNetEvent("muhaddil_insurances:Notify")
AddEventHandler("muhaddil_insurances:Notify", function(msgtitle, msg, time, type)
    Notify(msgtitle, msg, time, type)
end)

function CanAccessInsurance()
    local playerJob = nil

    if Config.FrameWork == "esx" then
        playerJob = ESX.GetPlayerData().job.name
    elseif Config.FrameWork == "qb" then
        playerJob = QBCore.Functions.GetPlayerData().job.name
    end

    if not Config.OnlyAllowedJobs then
        return true
    end

    if #Config.AllowedJobs == 0 then
        return true
    end

    for _, job in pairs(Config.AllowedJobs) do
        if playerJob == job then
            return true
        end
    end

    return false
end

function TargetingBoxZone(name, coords, x, y, z, list1, list2, list3)
    if not coords or (not coords.x and not coords.z) then
        print("Error: coordenadas no definidas o incorrectas.")
        return
    end

    local adjustedCoords = coords

    if coords.w then
        adjustedCoords = vector3(coords.x, coords.y, coords.z - 1)
    else
        adjustedCoords = vector3(coords.x, coords.y, coords.z - 1)
    end

    if Config.UseOxTarget then
        exports.ox_target:addBoxZone({
            coords = vec3(coords),
            size = vec3(x, y, z),
            rotation = 0,
            debug = false,
            drawSprite = true,
            options = {
                list1,

                list2,

                list3,
            }
        })
    else
        exports[Config.TargetName]:AddBoxZone(name, adjustedCoords, x, y, {
            name = name,
            heading = 0,
            debugPoly = false,
            minZ = adjustedCoords.z - (z / 2),
            maxZ = adjustedCoords.z + (z / 2),
        }, {
            options = {
                list1,
                list2,
                list3,
            },
            distance = Config.TargetDistance
        })
    end
end

CreateThread(function()
    for k, v in pairs(Config.Locations["insurances"]) do
        TargetingBoxZone("insurances" .. k, v, 3.5, 2, 2,
            {
                type = "client",
                icon = Config.TargetIcon,
                event = "muhaddil_insurances:checkInsurance",
                label = Config.ZoneLabel or 'Seguros Médicos',
            }
        )
    end
end)

Citizen.CreateThread(function()
    local insurancePeds = {}
    local insurancePedsSpawned = false

    local function SpawnInsurancePeds()
        if insurancePedsSpawned then
            return
        end

        RequestModel(Config.PedModel)
        while not HasModelLoaded(Config.PedModel) do
            Wait(0)
        end

        for _, spawnPosition in ipairs(Config.Locations["insurances"]) do
            local heading = spawnPosition.w

            local insurancePed = CreatePed(4, GetHashKey(Config.PedModel), spawnPosition.x, spawnPosition.y,
                spawnPosition.z - 1.0,
                heading, false, true)
            SetEntityAsMissionEntity(insurancePed, true, true)
            SetBlockingOfNonTemporaryEvents(insurancePed, true)
            SetEntityInvincible(insurancePed, true)
            FreezeEntityPosition(insurancePed, true)
            SetModelAsNoLongerNeeded(Config.PedModel)

            table.insert(insurancePeds, insurancePed)
        end

        insurancePedsSpawned = true
    end

    while true do
        Citizen.Wait(Config.PedSpawnCheckInterval)

        if not insurancePedsSpawned then
            SpawnInsurancePeds()
        end

        local playerCoords = GetEntityCoords(PlayerPedId())
        for _, insurancePed in ipairs(insurancePeds) do
            local insurancePedCoords = GetEntityCoords(insurancePed)
            local distance = #(playerCoords - insurancePedCoords)
            if distance < Config.PedInteractionDistance then
                isNearInsurancePed = true
            end
        end
    end
end)

CreateThread(function()
    if Config.ShowBlip then
        for _, location in ipairs(Config.Locations["insurances"]) do
            local x, y, z = table.unpack(location)
            local blip = AddBlipForCoord(x, y, z)
            SetBlipSprite(blip, Config.BlipSprite)
            SetBlipAsShortRange(blip, true)
            SetBlipScale(blip, Config.BlipScale)
            SetBlipColour(blip, Config.BlipColour)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(Config.BlipLabel)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

RegisterNetEvent('muhaddil_insurances:insurance:buy')
AddEventHandler('muhaddil_insurances:insurance:buy', function(data)
    local accountType = Config.Account
    TriggerServerEvent('muhaddil_insurances:insurance:buy', data, accountType)
end)

RegisterCommand('checkInsurance', function()
    local playerId = GetPlayerServerId(PlayerId())
    local jobName = nil

    local allowedJobs = Config.CheckInsuranceCommandJob

    if Config.FrameWork == "esx" then
        ESX.TriggerServerCallback('esx:getPlayerData', function(playerData)
            jobName = playerData.job.name
            local hasAccess = false

            for _, job in ipairs(allowedJobs) do
                if job == jobName then
                    hasAccess = true
                    break
                end
            end

            if hasAccess then
                TriggerEvent('muhaddil_insurances:checkInsurance')
            else
                Notify(Config.AccessDeniedTitle, Config.AccessDeniedMessage, Config.NotificationDuration, "error")
            end
        end, playerId)
    elseif Config.FrameWork == "qb" then
        local PlayerData = QBCore.Functions.GetPlayerData()
        jobName = PlayerData.job.name
        local hasAccess = false

        for _, job in ipairs(allowedJobs) do
            if job == jobName then
                hasAccess = true
                break
            end
        end

        if hasAccess then
            TriggerEvent('muhaddil_insurances:checkInsurance')
        else
            Notify(Config.AccessDeniedTitle, Config.AccessDeniedMessage, Config.NotificationDuration, "error")
        end
    end
end)

RegisterNetEvent('muhaddil_insurances:checkInsurance')
AddEventHandler('muhaddil_insurances:checkInsurance', function()
    if CanAccessInsurance() then
        local playerId = GetPlayerServerId(PlayerId())

        if Config.FrameWork == "esx" then
            ESX.TriggerServerCallback('muhaddil_insurances:insurance:getInsurance', function(insuranceData)
                openInsuranceMenu(insuranceData)
            end, playerId)
        elseif Config.FrameWork == "qb" then
            QBCore.Functions.TriggerCallback('muhaddil_insurances:insurance:getInsurance', function(insuranceData)
                openInsuranceMenu(insuranceData)
            end, playerId)
        end
    else
        Notify(Config.AccessDeniedTitle, Config.AccessDeniedMessage, Config.NotificationDuration, "error")
    end
end)

function CanSellDiscountInsurance()
    if hasUsedDiscount then
        return false
    end

    if Config.UseDiscounts == false then
        return false
    else
        local playerJob = nil
        if Config.FrameWork == "esx" then
            playerJob = ESX.GetPlayerData().job.name
        elseif Config.FrameWork == "qb" then
            playerJob = QBCore.Functions.GetPlayerData().job.name
        end

        for _, job in ipairs(Config.DiscountJobs) do
            if playerJob == job then
                return true
            end
        end

        return false
    end
end

function GetClosestPlayer()
    local players = GetActivePlayers()
    local closestDistance = -1
    local closestPlayer = -1
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    for i = 1, #players do
        local target = GetPlayerPed(players[i])
        if target ~= playerPed then
            local targetCoords = GetEntityCoords(target)
            local distance = #(playerCoords - targetCoords)

            if closestDistance == -1 or distance < closestDistance then
                closestPlayer = players[i]
                closestDistance = distance
            end
        end
    end

    return closestPlayer, closestDistance
end

RegisterNetEvent('muhaddil_insurances:insurance:buyDiscount')
AddEventHandler('muhaddil_insurances:insurance:buyDiscount', function(data)
    if not hasUsedDiscount then
        local closestPlayer, closestDistance = GetClosestPlayer()

        if closestPlayer ~= -1 and closestDistance <= Config.DiscountInteractionDistance then
            local targetPlayerId = GetPlayerServerId(closestPlayer)
            local accountType = Config.Account

            TriggerServerEvent('muhaddil_insurances:insurance:buy', data, accountType, targetPlayerId)
            hasUsedDiscount = true
            Notify(Config.DiscountAppliedTitle, Config.DiscountAppliedMessage, Config.NotificationDuration, "success")
        else
            Notify(Config.ErrorTitle, Config.NoPlayerNearbyMessage, Config.NotificationDuration, "error")
        end
    else
        Notify(Config.DiscountAlreadyUsedTitle, Config.DiscountAlreadyUsedMessage, Config.NotificationDuration, "error")
    end
end)

RegisterNetEvent('muhaddil_insurances:insurance:customPrice', function()
    local nearbyPlayers = lib.getNearbyPlayers(GetEntityCoords(PlayerPedId()), Config.SellInsuraceRange, Config.CanSellInsuraceToHimself)

    if not nearbyPlayers or #nearbyPlayers == 0 then
        print(locale('no_nearby_players'))
        return
    end

    local playerOptions = {}

    for _, player in ipairs(nearbyPlayers) do
        local serverId = GetPlayerServerId(player.id)            
        local playerNameData = lib.callback.await('getPlayerNameInGame', serverId)

        if not playerNameData or not playerNameData.firstname then
            playerNameData = { firstname = "Jugador", lastname = serverId }
        end        
    
        local playerName = playerNameData.firstname .. " " .. playerNameData.lastname
        
        local label
        if Config.ShowName then
            label = locale('select_nearby_player_label') .. ': ' .. playerName .. ' (' .. serverId .. ')'
        else
            label = locale('select_nearby_player_label') .. ': ' .. serverId
        end

        table.insert(playerOptions, {
            value = serverId,
            label = label
        })
    end    

    local selectPlayer = lib.inputDialog(locale('select_nearby_player'), {
        {type = 'select', label = locale('select_nearby_player_label'), options = playerOptions, required = true}
    })

    if not selectPlayer then return end

    local targetPlayerId = selectPlayer[1]

    local input = lib.inputDialog(locale('configure_custom_insurance'), {
        {type = 'input', label = locale('insurance_type'), description = locale('insurance_type_description'), required = true},
        {type = 'number', label = locale('insurance_duration'), description = locale('insurance_duration_description'), required = true, min = 1, max = Config.SellInsuraceMaxDays},
        {type = 'number', label = locale('insurance_price'), description = locale('insurance_price_description'), required = true, min = 1}
    })

    if not input then return end

    local insuranceType = input[1]
    local duration = tonumber(input[2])
    local price = tonumber(input[3])
    local accountType = Config.Account

    if not insuranceType or duration <= 0 or price <= 0 then
        print(locale('invalid_data'))
        return
    end

    TriggerServerEvent('muhaddil_insurances:insurance:offer', targetPlayerId, {
        type = insuranceType,
        duration = duration,
        price = price,
        accountType = accountType,
        sellerId = GetPlayerServerId(PlayerId())
    })
end)

RegisterNetEvent('muhaddil_insurances:insurance:receiveOffer', function(insuranceData)
    local playerId = GetPlayerServerId(PlayerId())
    local accept = lib.inputDialog(locale('insurance_offer_title'), {
        {type = 'text', label = locale('insurance_offer_label', insuranceData.type, insuranceData.duration, insuranceData.price)},
        {type = 'checkbox', label = locale('insurance_offer_accept_label')},
    })

    if accept[2] == true then
        TriggerServerEvent('muhaddil_insurances:insurance:buy', {
            type = insuranceData.type,
            duration = insuranceData.duration,
            price = insuranceData.price
        }, insuranceData.accountType, playerId)
    else
        print(locale('insurance_offer_rejected'))
    end
end)

if Config.EnableSellCommand then
    RegisterCommand('sellinsurances', function()
        local playerId = GetPlayerServerId(PlayerId())
        local jobName, jobGrade = nil, nil
        local allowedJobs = Config.SellCommandJobs

        if Config.FrameWork == "esx" then
            ESX.TriggerServerCallback('esx:getPlayerData', function(playerData)
                jobName = playerData.job.name
                jobGrade = playerData.job.grade
                validateSellAccess(jobName, jobGrade)
            end, playerId)
        elseif Config.FrameWork == "qb" then
            local PlayerData = QBCore.Functions.GetPlayerData()
            jobName = PlayerData.job.name
            jobGrade = PlayerData.job.grade.level
            validateSellAccess(jobName, jobGrade)
        end
    end)
end

function validateSellAccess(jobName, jobGrade)
    local hasAccess = false

    if Config.EnableSellCommandToAllGrades then
        hasAccess = Config.SellCommandJobs[jobName] ~= nil
    else
        local allowedGrades = Config.SellCommandJobs[jobName]

        if allowedGrades then
            for _, grade in ipairs(allowedGrades) do
                if grade == -1 or grade == jobGrade then
                    hasAccess = true
                    break
                end
            end
        end
    end

    if hasAccess then
        openSellInsurance()
    else
        Notify(Config.AccessDeniedTitle, Config.AccessDeniedMessage, Config.NotificationDuration, "error")
    end
end

exports("hasValidInsurance", function(playerId)
    local promise = promise.new()

    if not playerId or playerId == PlayerId() then
        playerId = GetPlayerServerId(PlayerId())
    end

    TriggerServerEvent('muhaddil_insurance:checkInsuranceExport', playerId)

    RegisterNetEvent('muhaddil_insurance:insuranceResult', function(result)
        promise:resolve(result)
    end)

    return Citizen.Await(promise)
end)
