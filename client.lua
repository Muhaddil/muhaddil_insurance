if Config.FrameWork == "esx" then
    ESX = exports['es_extended']:getSharedObject()
elseif Config.FrameWork == "qb" then
    QBCore = exports['qb-core']:GetCoreObject()
end

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
end

CreateThread(function()
    for k, v in pairs(Config.Locations["insurances"]) do
        TargetingBoxZone("insurances" .. k, v, 3.5, 2, 2,
            {
                type = "client",
                icon = "fa fa-clipboard",
                event = "muhaddil_insurances:checkInsurance",
                label = 'Seguros Médicos',
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

        RequestModel("s_m_m_doctor_01")
        while not HasModelLoaded("s_m_m_doctor_01") do
            Wait(0)
        end

        for _, spawnPosition in ipairs(Config.Locations["insurances"]) do
            local heading = spawnPosition.w

            local insurancePed = CreatePed(4, GetHashKey("s_m_m_doctor_01"), spawnPosition.x, spawnPosition.y, spawnPosition.z - 1.0,
                heading, false, true)
            SetEntityAsMissionEntity(insurancePed, true, true)
            SetBlockingOfNonTemporaryEvents(insurancePed, true)
            SetEntityInvincible(insurancePed, true)
            FreezeEntityPosition(insurancePed, true)
            SetModelAsNoLongerNeeded("s_m_m_doctor_01")

            table.insert(insurancePeds, insurancePed)
        end

        insurancePedsSpawned = true
    end

    while true do
        Citizen.Wait(5000)

        if not insurancePedsSpawned then
            SpawnInsurancePeds()
        end

        local playerCoords = GetEntityCoords(PlayerPedId())
        for _, insurancePed in ipairs(insurancePeds) do
            local insurancePedCoords = GetEntityCoords(insurancePed)
            local distance = #(playerCoords - insurancePedCoords)
            if distance < 2.0 then
                isNearInsurancePed = true
            end
        end
    end
end)

CreateThread(function()
    if Config.ShowBlip then
        local x, y, z = table.unpack(Config.Locations["insurances"][1])
        local blip = AddBlipForCoord(x, y, z)
        SetBlipSprite(blip, 408)
        SetBlipAsShortRange(blip, true)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 0)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.BlipLabel)
        EndTextCommandSetBlipName(blip)
    end
end)


RegisterNetEvent('muhaddil_insurances:insurance:buy')
AddEventHandler('muhaddil_insurances:insurance:buy', function(data)
    local accountType = Config.Account
    TriggerServerEvent('muhaddil_insurances:insurance:buy', data, accountType)
end)

RegisterNetEvent('muhaddil_insurances:checkInsurance')
AddEventHandler('muhaddil_insurances:checkInsurance', function()
    if CanAccessInsurance() then
        local playerId = GetPlayerServerId(PlayerId())
        ESX.TriggerServerCallback('muhaddil_insurances:insurance:getInsurance', function(insuranceData)
            openInsuranceMenu(insuranceData)
        end, playerId)
    else
        Notify("Acceso denegado", "No tienes el trabajo adecuado para acceder a esta función.", 5000, "error")
    end
end)
