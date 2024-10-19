Config = {}

Config.Locations = {
    ["insurances"] = {
        vector4(296.4421, -591.3871, 43.2757, 65.5415), -- Coordinates for the insurance location. You can add several possitions.
        vector4(356.5758, -593.0466, 28.7821, 249.4364),
    }
}

Config.FrameWork = 'esx' -- Select the framework being used: 'esx' for ESX Framework or 'qb' for QBCore Framework.
Config.UseOXNotifications = true -- Enable or disable OX Notifications. If 'true', it will use OX notifications; otherwise, it will use the default notification system for the framework.

Config.Account = 'money' -- Choose the account type for transactions: 'bank' to use the player's bank account or 'money' to use cash.
Config.OnlyAllowedJobs = false -- Enable or disable restricted access to the insurance menu. If 'true', only specific jobs can access. If 'false', everyone can access.
Config.AllowedJobs = {"ambulance", "police", "safd"} -- List of allowed jobs. Only these jobs can access the insurance menu when 'OnlyAllowedJobs' is set to true.
Config.DiscountJobs = { "ambulance" } -- List of jobs that are allowed to sell insurance at a discounted rate.
Config.UseDiscounts = true -- Setting this to true allows players (with specified jobs) to sell insurance at a discounted rate.
Config.CheckInsuranceCommandJob =  { "ambulance" } -- List of jobs allowed to use the command to check insurance status.
Config.DiscountInteractionDistance = '3.0' -- The maximum distance at which players can interact with another player to apply discounts.

Config.PeriodicallyDeleteInsurance = 3600000 -- The interval (in milliseconds) at which expired insurances will be cleaned from the database.

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
            title = 'Seguro Actual', -- Title for the current insurance option.
            description = 'Tipo: ' .. insuranceData.type .. '\nTiempo restante: ' .. insuranceData.timeLeft, -- Description of current insurance.
            icon = 'info-circle',
            disabled = false -- Option is enabled since the player has insurance.
        })
    else -- If the player does not have insurance.
        -- Notify the player that they currently have no insurance.
        table.insert(options, {
            title = 'No tienes seguro actualmente', -- Title for the no insurance option.
            icon = 'info-circle',
            disabled = true -- Option is disabled since the player has no insurance.
        })

        -- Add different insurance options for purchase.
        table.insert(options, {
            title = 'Seguro Básico', -- Title for Basic Insurance.
            description = 'Duración: 3 días\nPrecio: $10000', -- Description of Basic Insurance.
            icon = 'circle',
            event = 'muhaddil_insurances:insurance:buy',
            args = { type = "basico", duration = 3, price = 10000 } -- Arguments for the event.
        })
        table.insert(options, {
            title = 'Seguro Semanal', -- Title for Weekly Insurance.
            description = 'Duración: 7 días\nPrecio: $25000', -- Description of Weekly Insurance.
            icon = 'circle',
            event = 'muhaddil_insurances:insurance:buy',
            args = { type = "semanal", duration = 7, price = 25000 } -- Arguments for the event.
        })
        table.insert(options, {
            title = 'Seguro Completo', -- Title for Full Insurance.
            description = 'Duración: 15 días\nPrecio: $50000', -- Description of Full Insurance.
            icon = 'circle',
            event = 'muhaddil_insurances:insurance:buy',
            args = { type = "completo", duration = 15, price = 50000 } -- Arguments for the event.
        })
        table.insert(options, {
            title = 'Seguro Premium', -- Title for Premium Insurance.
            description = 'Duración: 30 días\nPrecio: $100000', -- Description of Premium Insurance.
            icon = 'circle',
            event = 'muhaddil_insurances:insurance:buy',
            args = { type = "premium", duration = 30, price = 100000 } -- Arguments for the event.
        })
        if CanSellDiscountInsurance() then
            table.insert(options, {
                title = 'Vender Seguro con Descuento',
                description = 'Duración: 30 días\nPrecio: $50000 (descuento)',
                icon = 'circle',
                event = 'muhaddil_insurances:insurance:buyDiscount',
                args = { type = "premium", duration = 30, price = 50000 }
            })
        end
    end

    lib.registerContext({
        id = 'insurance_menu',
        title = 'Menú de Seguros', -- Title of the menu.
        options = options
    })

    lib.showContext('insurance_menu')
end