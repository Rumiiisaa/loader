local GAMES = {
    [124216119978534] = {
        name = "rideapet",
        url = "https://raw.githubusercontent.com/Rumiiisaa/loader/refs/heads/main/games/rideapet.lua"
    },
    [118805555015549] = {
        name = "forge",
        url = "https://raw.githubusercontent.com/Rumiiisaa/loader/refs/heads/main/games/forge.lua"
    }
}

local currentData = GAMES[game.PlaceId]

if not currentData then
    warn(string.format("[Universal Loader] Unsupported Game. PlaceId: %s | GameId: %s", tostring(game.PlaceId), tostring(game.GameId)))
    return
end

print(string.format("[Universal Loader] Target Detected: %s (PlaceId: %s)", currentData.name, tostring(game.PlaceId)))

-- Fetch script with CDN cache-busting
local fetchOk, scriptContent = pcall(function()
    return game:HttpGet(currentData.url .. "?t=" .. tick())
end)

if not fetchOk or #scriptContent < 10 then
    warn("[Universal Loader] Failed to download script payload from GitHub!")
    warn(tostring(scriptContent))
    return
end

-- Compile script payload
local compileOk, executable = pcall(function()
    return loadstring(scriptContent, currentData.name)
end)

if not compileOk or type(executable) ~= "function" then
    warn("[Universal Loader] Failed to compile script:")
    warn(tostring(executable))
    return
end

-- Execute in isolated thread to prevent main thread blocking
task.spawn(function()
    local runOk, runErr = pcall(executable)
    if not runOk then
        warn("[Universal Loader] Runtime exception encountered:")
        warn(tostring(runErr))
    else
        print(string.format("[Universal Loader] Successfully launched: %s", currentData.name))
    end
end)
