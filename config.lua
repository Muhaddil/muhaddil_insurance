Config = {}

Config.Locations = {
    ["insurances"] = {
        vector3(296.4421, -591.3871, 43.2757),
    }
}
Config.PedHeading = 65.5415

Config.FrameWork = 'esx'
Config.UseOXNotifications = true

Config.Account = 'money' -- bank or money

Config.BlipLabel = 'Seguros Médicos'
Config.ShowBlip = true

Config.AutoRunSQL = true
Config.AutoVersionChecker = true

-- Edit this to you requirements

function openInsuranceMenu(insuranceData)
    local options = {}

    if insuranceData then
        table.insert(options, {
            title = 'Seguro Actual',
            description = 'Tipo: ' .. insuranceData.type .. '\nTiempo restante: ' .. insuranceData.timeLeft,
            icon = 'info-circle',
            disabled = false
        })
    else
        table.insert(options, {
            title = 'No tienes seguro actualmente',
            icon = 'info-circle',
            disabled = true
        })

        table.insert(options, {
            title = 'Seguro Básico',
            description = 'Duración: 3 días\nPrecio: $10000',
            icon = 'circle',
            event = 'muhaddil_insurances:insurance:buy',
            args = { type = "basico", duration = 3, price = 10000 }
        })
        table.insert(options, {
            title = 'Seguro Semanal',
            description = 'Duración: 7 días\nPrecio: $25000',
            icon = 'circle',
            event = 'muhaddil_insurances:insurance:buy',
            args = { type = "semanal", duration = 7, price = 25000 }
        })
        table.insert(options, {
            title = 'Seguro Completo',
            description = 'Duración: 15 días\nPrecio: $50000',
            icon = 'circle',
            event = 'muhaddil_insurances:insurance:buy',
            args = { type = "completo", duration = 15, price = 50000 }
        })
        table.insert(options, {
            title = 'Seguro Premium',
            description = 'Duración: 30 días\nPrecio: $100000',
            icon = 'circle',
            event = 'muhaddil_insurances:insurance:buy',
            args = { type = "premium", duration = 30, price = 100000 }
        })
    end

    lib.registerContext({
        id = 'insurance_menu',
        title = 'Menú de Seguros',
        options = options
    })

    lib.showContext('insurance_menu')
end
