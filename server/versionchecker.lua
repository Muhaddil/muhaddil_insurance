local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version')
local resourceRepo = 'Muhaddil/muhaddil_insurance'
local githubApiUrl = 'https://api.github.com/repos/' .. resourceRepo .. '/releases/latest'

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

local updateCronExpression = getCronExpression(30)
lib.cron.new(updateCronExpression, function()
    if isUpdateAvailable then
        displayVersionData()
    end
end)
