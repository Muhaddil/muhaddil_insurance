Config = {}

Config.webHook = 'https://discord.com/api/webhooks/1308527212382785597/WZJe9WyQUb-lxf0-db1kNY_yCnE7TiO18yzrHgEG1wYfEC2RxAhun1XxaXxSKEnHKFwF'
Config.webHookName = 'Logs muhaddil-machines' -- Name of the WebHook
Config.webHookLogo = 'https://github.com/Muhaddil/RSSWikiPageCreator/blob/main/public/assets/other/MuhaddilOG.png?raw=true' -- Logo of the WebHook bot

Config.Locations = {
    ["insurances"] = {
        vector4(296.4421, -591.3871, 43.2757, 65.5415), -- Coordinates for the insurance location. You can add several possitions.
        vector4(356.5758, -593.0466, 28.7821, 249.4364),
    }
}

Config.FrameWork = 'esx' -- Select the framework being used: 'esx' for ESX Framework or 'qb' for QBCore Framework.
Config.UseOXNotifications = true -- Enable or disable OX Notifications. If 'true', it will use OX notifications; otherwise, it will use the default notification system for the framework.
Config.UseOxTarget = true  -- Enables or disables the use of the OxTarget system.
Config.TargetName = ''  -- Specifies the name of the target resource. Only needed if using qb-target or qtarget. Leave it empty if using OxTarget.
Config.TargetDistance = 7.0  -- Sets the maximum interaction distance for targeting.

Config.Account = 'money' -- Choose the account type for transactions: 'bank' to use the player's bank account or 'money' to use cash.
Config.OnlyAllowedJobs = false -- Enable or disable restricted access to the insurance menu. If 'true', only specific jobs can access. If 'false', everyone can access.
Config.AllowedJobs = {"ambulance", "police", "safd"} -- List of allowed jobs. Only these jobs can access the insurance menu when 'OnlyAllowedJobs' is set to true.
Config.DiscountJobs = { "ambulance" } -- List of jobs that are allowed to sell insurance at a discounted rate.
Config.UseDiscounts = true -- Setting this to true allows players (with specified jobs) to sell insurance at a discounted rate.
Config.CheckInsuranceCommandJob =  { "ambulance" } -- List of jobs allowed to use the command to check insurance status.
Config.DiscountInteractionDistance = '3.0' -- The maximum distance at which players can interact with another player to apply discounts.

Config.PeriodicallyDeleteInsurance = 120 -- The interval (in minutes) at which expired insurances will be cleaned from the database.

Config.TargetIcon = 'fa fa-clipboard' -- The icon used for the targeting box when interacting with insurance locations.
Config.ZoneLabel = 'Seguros Médicos' -- The label displayed for the insurance interaction zone.

Config.PedModel = "s_m_m_doctor_01" -- The model used for the insurance NPCs.
Config.PedSpawnCheckInterval = 5000 -- The interval (in milliseconds) at which the script checks if insurance NPCs need to be spawned.
Config.PedInteractionDistance = 2.0 -- The distance at which players can interact with the insurance NPCs.

Config.BlipLabel = 'Seguros Médicos' -- The label displayed for the blip on the map, indicating the location of medical insurance services.
Config.ShowBlip = true -- Enable or disable the display of the blip on the map. If 'true', the blip will be shown; if 'false', it will be hidden.
Config.BlipSprite = 408 -- The sprite ID for the blip, determining its appearance on the map.
Config.BlipScale = 0.8 -- The scale of the blip on the map.
Config.BlipColour = 0 -- The color of the blip on the map.

Config.AccessDeniedTitle = 'Acceso Denegado' -- The title displayed in notifications when access to a feature is denied.
Config.AccessDeniedMessage = 'No tienes el trabajo adecuado para acceder a esta función.' -- The message displayed in notifications when access to a feature is denied.
Config.NotificationDuration = '5000' -- The duration (in milliseconds) for which notifications are displayed.
Config.DiscountAppliedTitle = 'Descuento aplicado' -- The title displayed in notifications when a discount is successfully applied.
Config.DiscountAppliedMessage = 'Has vendido un seguro con descuento al jugador más cercano.' -- The message displayed in notifications when a discount is successfully applied.
Config.ErrorTitle = 'Error' -- The title displayed in error notifications.
Config.NoPlayerNearbyMessage = 'No hay ningún jugador cerca para aplicar el descuento.' -- The message displayed when there are no players nearby to apply a discount.
Config.DiscountAlreadyUsedTitle = 'Descuento ya utilizado' -- The title displayed when a player tries to use a discount they have already used.
Config.DiscountAlreadyUsedMessage = 'Ya has usado el descuento para esta sesión.' -- The message displayed when a player tries to use a discount they have already used.

Config.AutoRunSQL = true -- Enable or disable automatic integration of the SQL table needed for this script.
Config.AutoVersionChecker = true -- Enable or disable the automatic version checker. If 'true', it will check for updates and warn you if the script isn't up to date.


-- Edit this function to suit your requirements
function openInsuranceMenu(insuranceData)
    local options = {}

    if insuranceData then
        -- If the player has insurance, display the current insurance details.
        table.insert(options, {
            title = locale('current_insurance'),
            description = locale('insurance_type') .. ': ' .. insuranceData.type .. '\n' .. locale('time_left') .. ': ' .. insuranceData.timeLeft,
            icon = 'info-circle',
            disabled = false --The option is enabled since the player has insurance.
        })
    else -- If the player does not have insurance.
        -- Notify the player that he or she currently has no insurance.
        table.insert(options, {
            title = locale('no_current_insurance'),
            icon = 'info-circle',
            disabled = true --The option is disabled since the player does not have insurance.
        })

        table.insert(options, {
            title = locale('basic_insurance'),
            description = locale('duration') .. ': 3 ' .. locale('days') .. '\n' .. locale('price') .. ': $10000',
            icon = 'circle',
            event = 'muhaddil_insurances:insurance:buy',
            args = { type = "basico", duration = 3, price = 10000 } -- Arguments for the event.
        })
        table.insert(options, {
            title = locale('weekly_insurance'),
            description = locale('duration') .. ': 7 ' .. locale('days') .. '\n' .. locale('price') .. ': $25000',
            icon = 'circle',
            event = 'muhaddil_insurances:insurance:buy',
            args = { type = "semanal", duration = 7, price = 25000 } -- Arguments for the event.
        })
        table.insert(options, {
            title = locale('full_insurance'),
            description = locale('duration') .. ': 15 ' .. locale('days') .. '\n' .. locale('price') .. ': $50000',
            icon = 'circle',
            event = 'muhaddil_insurances:insurance:buy',
            args = { type = "completo", duration = 15, price = 50000 } -- Arguments for the event.
        })
        table.insert(options, {
            title = locale('premium_insurance'),
            description = locale('duration') .. ': 30 ' .. locale('days') .. '\n' .. locale('price') .. ': $100000',
            icon = 'circle',
            event = 'muhaddil_insurances:insurance:buy',
            args = { type = "premium", duration = 30, price = 100000 } -- Arguments for the event.
        })
        if CanSellDiscountInsurance() then
            table.insert(options, {
                title = locale('sell_discount_insurance'),
                description = locale('duration') .. ': 30 ' .. locale('days') .. '\n' .. locale('price') .. ': $50000 (' .. locale('discount') .. ')',
                icon = 'circle',
                event = 'muhaddil_insurances:insurance:buyDiscount',
                args = { type = "premium", duration = 30, price = 50000 }
            })
        end
    end

    lib.registerContext({
        id = 'insurance_menu',
        title = locale('insurance_menu_title'),
        options = options
    })

    lib.showContext('insurance_menu')
end

function openSellInsurance()
    local options = {}

    table.insert(options, {
        title = locale('sell_custom_insurance'),
        description = locale('custom_insurance_description'),
        icon = 'circle',
        event = 'muhaddil_insurances:insurance:customPrice'
    })

    lib.registerContext({
        id = 'insurance_menu_sell',
        title = locale('insurance_menu_title'),
        options = options
    })

    lib.showContext('insurance_menu_sell')
end

Config.EnableSellCommand = true
Config.CanSellInsuraceToHimself = true
Config.SellInsuraceRange = 5.0
Config.SellInsuraceMaxDays = 30
Config.EnableSellCommandToAllGrades = false
Config.SellCommandJobs = {
    ["ambulance"] = { 17, 18, 19 }, -- A -1 value would let every grade to access the command
}
