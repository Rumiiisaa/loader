-- Universal Game Loader
-- Template

local GAMES = {
    [124216119978534] = {
        name = "rideapet",
        url = "https://raw.githubusercontent.com/Rumiiisaa/loader/main/games/rideapet.lua"
    },

    [987654321] = {
        name = "Game 2",
        url = "https://raw.githubusercontent.com/USERNAME/REPOSITORY/main/games/game2.lua"
    },
}

local placeId = game.PlaceId
local gameInfo = GAMES[placeId]

-- Game tidak terdaftar
if not gameInfo then
    warn("[Loader] Game tidak didukung.")
    warn("[Loader] PlaceId:", placeId)
    return
end

print("[Loader] Detected:", gameInfo.name)
print("[Loader] PlaceId:", placeId)

-- Download script
local success, source = pcall(function()
    return game:HttpGet(gameInfo.url)
end)

if not success then
    warn("[Loader] Failed to download script.")
    warn(source)
    return
end

-- Compile script
local compileSuccess, scriptFunction = pcall(function()
    return loadstring(source)
end)

if not compileSuccess or not scriptFunction then
    warn("[Loader] Failed to compile script.")
    warn(scriptFunction)
    return
end

-- Execute
local executeSuccess, executeError = pcall(function()
    scriptFunction()
end)

if not executeSuccess then
    warn("[Loader] Script execution failed.")
    warn(executeError)
    return
end

print("[Loader] Successfully loaded:", gameInfo.name)