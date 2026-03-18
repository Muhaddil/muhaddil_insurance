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
    else
        print('===NO SUPPORTED FRAMEWORK FOUND===')
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
        if FrameWork == 'qb' then
            QBCore.Functions.Notify(msg, type2, time)
        elseif FrameWork == 'esx' then
            TriggerEvent('esx:showNotification', msg, type2, time)
        end
    end
end

RegisterNetEvent("muhaddil_insurances:Notify")
AddEventHandler("muhaddil_insurances:Notify", function(msgtitle, msg, time, type)
    Notify(msgtitle, msg, time, type)
end)

RegisterNetEvent('muhaddil_insurances:NotifyLocale')
AddEventHandler('muhaddil_insurances:NotifyLocale', function(titleKey, msgKey, time, type, args)
    local title = locale(titleKey)
    local msg = locale(msgKey)

    if args and #args > 0 then
        msg = string.format(msg, table.unpack(args))
    end
    Notify(title, msg, time, type)
end)

function CanAccessInsurance()
    local playerJob = nil

    if FrameWork == "esx" then
        playerJob = ESX.GetPlayerData().job.name
    elseif FrameWork == "qb" then
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

    if FrameWork == "esx" then
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
                Notify(locale('access_denied_title'), locale('access_denied_message'), Config.NotificationDuration,
                    "error")
            end
        end, playerId)
    elseif FrameWork == "qb" then
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
            Notify(locale('access_denied_title'), locale('access_denied_message'), Config.NotificationDuration, "error")
        end
    end
end)

RegisterNetEvent('muhaddil_insurances:checkInsurance')
AddEventHandler('muhaddil_insurances:checkInsurance', function()
    if CanAccessInsurance() then
        local playerId = GetPlayerServerId(PlayerId())

        if FrameWork == "esx" then
            ESX.TriggerServerCallback('muhaddil_insurances:insurance:getInsurance', function(insuranceData)
                OpenInsuranceNUI(insuranceData)
            end, playerId)
        elseif FrameWork == "qb" then
            QBCore.Functions.TriggerCallback('muhaddil_insurances:insurance:getInsurance', function(insuranceData)
                OpenInsuranceNUI(insuranceData)
            end, playerId)
        end
    else
        Notify(locale('access_denied_title'), locale('access_denied_message'), Config.NotificationDuration, "error")
    end
end)

function sendLocaleData()
    local localeData = lib.callback.await('muhaddil_insurances:getLocaleData', false)

    SendNUIMessage({
        action = "setLocale",
        localeData = localeData
    })
end

function OpenInsuranceNUI(insuranceData)
    local canSellDiscount = CanSellDiscountInsurance()
    local canSellCustom = CanSellCustomInsurance()
    sendLocaleData()

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openInsurance",
        data = {
            insurance = insuranceData,
            canSellDiscount = canSellDiscount,
            canSellCustom = canSellCustom,
            config = {
                insuranceTypes = Config.InsuranceTypes,
                useDiscounts = Config.UseDiscounts,
                discountPercentage = Config.DiscountPercentage
            }
        }
    })
end

RegisterNUICallback('closeNUI', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('buyInsurance', function(data, cb)
    local accountType = Config.Account
    TriggerServerEvent('muhaddil_insurances:insurance:buy', data, accountType)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('getNearbyPlayers', function(data, cb)
    local nearbyPlayers = lib.getNearbyPlayers(GetEntityCoords(PlayerPedId()), Config.SellInsuraceRange,
        Config.CanSellInsuraceToHimself)

    if not nearbyPlayers then
        cb({ players = {} })
        return
    end

    local playerOptions = {}

    for _, player in ipairs(nearbyPlayers) do
        local serverId = GetPlayerServerId(player.id)
        local distance = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(GetPlayerPed(player.id)))
        local playerNameData = lib.callback.await('getPlayerNameInGame', serverId)

        if not playerNameData or not playerNameData.firstname then
            playerNameData = { firstname = "Jugador", lastname = serverId }
        end

        local playerName = playerNameData.firstname .. " " .. playerNameData.lastname

        table.insert(playerOptions, {
            id = serverId,
            name = playerName,
            distance = math.floor(distance)
        })
    end

    Wait(100)

    cb({ players = playerOptions })
end)

RegisterNUICallback('sellCustomInsurance', function(data, cb)
    local targetPlayerId = data.targetId
    local insuranceType = data.insuranceType
    local duration = tonumber(data.duration)
    local price = tonumber(data.price)
    local accountType = Config.Account

    if not insuranceType or duration <= 0 or price <= 0 then
        Notify(locale('error'), locale('invalid_arguments'), Config.NotificationDuration, "error")
        cb('error')
        return
    end

    TriggerServerEvent('muhaddil_insurances:insurance:offer', targetPlayerId, {
        type = insuranceType,
        duration = duration,
        price = price,
        accountType = accountType,
        sellerId = GetPlayerServerId(PlayerId())
    })

    SetNuiFocus(false, false)
    cb('ok')
end)

function CanSellDiscountInsurance()
    if hasUsedDiscount then
        return false
    end

    if Config.UseDiscounts == false then
        return false
    else
        local playerJob = nil
        if FrameWork == "esx" then
            playerJob = ESX.GetPlayerData().job.name
        elseif FrameWork == "qb" then
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

function CanSellCustomInsurance()
    if not Config.EnableSellCommand then
        return false
    end

    local playerJob = nil
    local jobGrade = nil

    if FrameWork == "esx" then
        local playerData = ESX.GetPlayerData()
        playerJob = playerData.job.name
        jobGrade = playerData.job.grade
    elseif FrameWork == "qb" then
        local PlayerData = QBCore.Functions.GetPlayerData()
        playerJob = PlayerData.job.name
        jobGrade = PlayerData.job.grade.level
    end

    local hasAccess = false

    if Config.EnableSellCommandToAllGrades then
        hasAccess = Config.SellCommandJobs[playerJob] ~= nil
    else
        local allowedGrades = Config.SellCommandJobs[playerJob]

        if allowedGrades then
            for _, grade in ipairs(allowedGrades) do
                if grade == -1 or grade == jobGrade then
                    hasAccess = true
                    break
                end
            end
        end
    end

    return hasAccess
end

RegisterNetEvent('muhaddil_insurances:insurance:receiveOffer', function(insuranceData)
    local playerId = GetPlayerServerId(PlayerId())
    local accept = lib.inputDialog(locale('insurance_offer_title'), {
        { type = 'text',     label = locale('insurance_offer_label', insuranceData.type, insuranceData.duration, insuranceData.price) },
        { type = 'checkbox', label = locale('insurance_offer_accept_label') },
    })

    if not accept then
        return
    end

    if accept[2] == true then
        TriggerServerEvent('muhaddil_insurances:insurance:buy', {
            type = insuranceData.type,
            duration = insuranceData.duration,
            price = insuranceData.price
        }, insuranceData.accountType, playerId)
    else
        Notify(locale('insurance_offer_rejected'))
    end
end)

if Config.EnableSellCommand then
    RegisterCommand('sellinsurances', function()
        local playerId = GetPlayerServerId(PlayerId())
        local jobName, jobGrade = nil, nil
        local allowedJobs = Config.SellCommandJobs

        if FrameWork == "esx" then
            ESX.TriggerServerCallback('esx:getPlayerData', function(playerData)
                jobName = playerData.job.name
                jobGrade = playerData.job.grade
                validateSellAccess(jobName, jobGrade)
            end, playerId)
        elseif FrameWork == "qb" then
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
        OpenSellInsuranceNUI()
    else
        Notify(locale('access_denied_title'), locale('access_denied_message'), Config.NotificationDuration, "error")
    end
end

function OpenSellInsuranceNUI()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openSellInsurance",
        data = {
            config = {
                insuranceTypes = Config.InsuranceTypes,
                maxDays = Config.SellInsuraceMaxDays,
                showName = Config.ShowName
            }
        }
    })
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

sendLocaleData()

exports('useInsuranceDocument', function(data, metadata, playerId)
    -- ox_inventory no pasa metadata correctamente desde el export,
    -- así que la pedimos directamente del slot
    local slot = data.slot

    if not slot then
        lib.notify({ title = locale('insurance_system'), description = locale('document_invalid'), type = 'error' })
        return
    end

    local slotMetadata = lib.callback.await('muhaddil_insurances:getDocumentMetadata', false, slot)

    if not slotMetadata or not slotMetadata.type then
        lib.notify({ title = locale('insurance_system'), description = locale('document_invalid'), type = 'error' })
        return
    end

    sendLocaleData()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openDocument",
        data = {
            playerName     = slotMetadata.playerName or '—',
            type           = slotMetadata.type,
            duration       = slotMetadata.duration,
            price          = slotMetadata.price,
            expiration     = slotMetadata.expiration,
            expirationDate = slotMetadata.expirationDate or '—',
            issuedAt       = slotMetadata.issuedAt or '—',
        }
    })
end)
