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
    local insurancePed = nil
    local insurancePedSpawned = false

    local function SpawnInsurancePed()
        if insurancePedSpawned then
            return
        end

        RequestModel("s_m_m_doctor_01")
        while not HasModelLoaded("s_m_m_doctor_01") do
            Wait(0)
        end

        local spawnPosition = vector3(Config.Locations["insurances"][1].x, Config.Locations["insurances"][1].y,
            Config.Locations["insurances"][1].z - 1.0)

        insurancePed = CreatePed(4, GetHashKey("s_m_m_doctor_01"), spawnPosition.x, spawnPosition.y, spawnPosition.z,
            Config.PedHeading, false, true)
        SetEntityAsMissionEntity(insurancePed, true, true)
        SetBlockingOfNonTemporaryEvents(insurancePed, true)
        SetEntityInvincible(insurancePed, true)
        FreezeEntityPosition(insurancePed, true)
        SetModelAsNoLongerNeeded("s_m_m_doctor_01")

        insurancePedSpawned = true
    end

    while true do
        Citizen.Wait(5000)

        if not insurancePedSpawned then
            SpawnInsurancePed()
        end

        local playerCoords = GetEntityCoords(PlayerPedId())
        if insurancePed then
            local insurancePedCoords = GetEntityCoords(insurancePed)
            local distance = #(playerCoords - insurancePedCoords)
            isNearInsurancePed = distance < 2.0
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
    local playerId = GetPlayerServerId(PlayerId())
    ESX.TriggerServerCallback('muhaddil_insurances:insurance:getInsurance', function(insuranceData)
        openInsuranceMenu(insuranceData)
    end, playerId)
end)
