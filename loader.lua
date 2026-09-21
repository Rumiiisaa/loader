local GAMES = {
    [124216119978534] = {
        name = "rideapet",
        url = "https://raw.githubusercontent.com/Rumiiisaa/loader/main/games/rideapet.lua"
    }
}

local currentData = GAMES[game.PlaceId]

if not currentData then
    warn("[Loader] Game belum terdaftar. PlaceId:", game.PlaceId)
    return
end

print("[Loader] Menjalankan:", currentData.name)

-- Ambil script dengan bypass CDN cache
local fetchOk, scriptContent = pcall(function()
    return game:HttpGet(currentData.url .. "?t=" .. tick())
end)

if not fetchOk or #scriptContent < 10 then
    warn("[Loader] Gagal mengunduh file script!")
    warn(scriptContent)
    return
end

-- Compile script
local compileOk, executable = pcall(function()
    return loadstring(scriptContent, currentData.name)
end)

if not compileOk or type(executable) ~= "function" then
    warn("[Loader] Gagal compile kode:")
    warn(executable)
    return
end

-- Jalankan di thread terpisah agar tidak freeze
task.spawn(function()
    local runOk, runErr = pcall(executable)
    if not runOk then
        warn("[Loader] Error runtime saat script berjalan:")
        warn(runErr)
    else
        print("[Loader] Sukses dieksekusi penuh:", currentData.name)
    end
end)