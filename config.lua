Config = {}

Config.NUILocale = "es" -- Set the locale for the NUI interface
Config.UseOXLogger = false -- Enable or disable OX Logger. If 'true', it will use OX Logger; otherwise, it will use the discordWebHookSender fuction (server line 14)
-- If not using OX Logger, configure the WebHook on server.lua file, lines 4, 5 and 6

Config.Locations = {
	["insurances"] = {
		vector4(296.4421, -591.3871, 43.2757, 65.5415), -- Coordinates for the insurance location. You can add several possitions.
		vector4(356.5758, -593.0466, 28.7821, 249.4364),
	},
}

Config.FrameWork = "auto" -- Select the framework being used: 'esx' for ESX Framework or 'qb' for QBCore Framework.
Config.ESXVer = "new" -- Select ESX version, 'new' or 'old'
Config.UseOXNotifications = true -- Enable or disable OX Notifications. If 'true', it will use OX notifications; otherwise, it will use the default notification system for the framework.
Config.UseOxTarget = true -- Enables or disables the use of the OxTarget system.
Config.TargetName = "" -- Specifies the name of the target resource. Only needed if using qb-target or qtarget. Leave it empty if using OxTarget.
Config.TargetDistance = 7.0 -- Sets the maximum interaction distance for targeting.

Config.Account = "money" -- Choose the account type for transactions: 'bank' to use the player's bank account or 'money' to use cash.
Config.OnlyAllowedJobs = false -- Enable or disable restricted access to the insurance menu. If 'true', only specific jobs can access. If 'false', everyone can access.
Config.AllowedJobs = { "ambulance", "police", "safd" } -- List of allowed jobs. Only these jobs can access the insurance menu when 'OnlyAllowedJobs' is set to true.
Config.DiscountJobs = { "ambulance" } -- List of jobs that are allowed to sell insurance at a discounted rate.
Config.UseDiscounts = true -- Setting this to true allows players (with specified jobs) to sell insurance at a discounted rate.
Config.DiscountPercentage = 25 -- Percentage applied to jobs with discounts
Config.CheckInsuranceCommandJob = { "ambulance" } -- List of jobs allowed to use the command to check insurance status.
Config.DiscountInteractionDistance = "3.0" -- The maximum distance at which players can interact with another player to apply discounts.

Config.PeriodicallyDeleteInsurance = 120 -- The interval (in minutes) at which expired insurances will be cleaned from the database.

Config.TargetIcon = "fa fa-clipboard" -- The icon used for the targeting box when interacting with insurance locations.
Config.ZoneLabel = "Seguros Médicos" -- The label displayed for the insurance interaction zone.

Config.PedModel = "s_m_m_doctor_01" -- The model used for the insurance NPCs.
Config.PedSpawnCheckInterval = 5000 -- The interval (in milliseconds) at which the script checks if insurance NPCs need to be spawned.
Config.PedInteractionDistance = 2.0 -- The distance at which players can interact with the insurance NPCs.

Config.BlipLabel = "Seguros Médicos" -- The label displayed for the blip on the map, indicating the location of medical insurance services.
Config.ShowBlip = true -- Enable or disable the display of the blip on the map. If 'true', the blip will be shown; if 'false', it will be hidden.
Config.BlipSprite = 408 -- The sprite ID for the blip, determining its appearance on the map.
Config.BlipScale = 0.8 -- The scale of the blip on the map.
Config.BlipColour = 0 -- The color of the blip on the map.

Config.NotificationDuration = "5000" -- The duration (in milliseconds) for which notifications are displayed.

Config.AutoRunSQL = true -- Enable or disable automatic integration of the SQL table needed for this script.
Config.AutoVersionChecker = true -- Enable or disable the automatic version checker. If 'true', it will check for updates and warn you if the script isn't up to date.

Config.EnableSellCommand = true
Config.CanSellInsuraceToHimself = true
Config.SellInsuraceRange = 5.0
Config.SellInsuraceMaxDays = 30
Config.EnableSellCommandToAllGrades = true
Config.ShowName = false -- Show the player's name when selling insurance.
Config.SellCommandJobs = {
	["ambulance"] = { 17, 18, 19 }, -- A -1 value would let every grade to access the command
}

Config.InsuranceTypes = {
	basic = { label = "Basic", price = 5000, duration = 1 }, -- Duration in days
	weekly = { label = "Weekly", price = 25000, duration = 7 },
	full = { label = "Full", price = 80000, duration = 30 },
	premium = { label = "Premium", price = 200000, duration = 90 },
}

Config.GiveInsuranceDocument = true -- Give players a physical insurance document item via ox_inventory
Config.InsuranceDocumentItem = "insurance_document" -- The item name registered in ox_inventory
