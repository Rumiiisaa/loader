-- ╔══════════════════════════════════════╗
-- ║       RIDE A PET HUB v1.1.0         ║
-- ║     Powered by Ash-Libs UI Engine    ║
-- ║     Theme: Pet Vibrant (Orange/Blue) ║
-- ╚══════════════════════════════════════╝

local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Lighting           = game:GetService("Lighting")
local VirtualUser        = game:GetService("VirtualUser")
local ts                 = TweenService

local lp = Players.LocalPlayer

-- ══════════════════════════════════════
-- GAME DISPATCHER
-- ══════════════════════════════════════
-- Tambahkan project baru ke GAME_PROJECTS tanpa mengubah core UI.
-- Tambahkan mapping PlaceId / GameId untuk setiap game/project
local GAME_PROJECTS = {
    -- Default fallback untuk Ride a Pet jika ID belum diisi:
    ["DEFAULT"] = {
        Name = "Ride a Pet",
        Script = nil, -- nil = jalankan script lokal ini
    },
    -- Format project baru nanti:
    -- [1234567890] = {
    --     Name = "New Project Game",
    --     Script = "https://raw.githubusercontent.com/.../newgame.lua",
    -- },
}

local GAME_ID = game.GameId
local PLACE_ID = game.PlaceId
local CURRENT_PROJECT = GAME_PROJECTS[GAME_ID] or GAME_PROJECTS[PLACE_ID] or GAME_PROJECTS["DEFAULT"]
local success, productInfo = pcall(function()
    return game:GetService("MarketplaceService"):GetProductInfo(PLACE_ID)
end)
local DETECTED_GAME = (success and productInfo and productInfo.Name) or "Unknown Game"

if not CURRENT_PROJECT then
    warn(string.format("[Universal Hub] Game tidak didukung: %s (PlaceId: %d, GameId: %d)", DETECTED_GAME, PLACE_ID, GAME_ID))
    return
end

print(string.format("[Universal Hub] Game: %s (PlaceId: %d) -> Load Project: %s", DETECTED_GAME, PLACE_ID, CURRENT_PROJECT.Name))

-- Jika ada script terpisah, load string langsung dari link/file
if CURRENT_PROJECT.Script then
    if CURRENT_PROJECT.Script:find("^https?://") then
        loadstring(game:HttpGet(CURRENT_PROJECT.Script))()
    elseif readfile and isfile and isfile(CURRENT_PROJECT.Script) then
        loadstring(readfile(CURRENT_PROJECT.Script))()
    end
    return
end

local char = lp.Character
local hum  = char and char:FindFirstChildOfClass("Humanoid")
local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)

local function startFly() end
local function stopFly() end

local function updateChar(c)
    char = c
    hum  = c:WaitForChild("Humanoid", 5) or c:FindFirstChildOfClass("Humanoid")
    root = c:WaitForChild("HumanoidRootPart", 5) or c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart
end

if char then
    task.spawn(updateChar, char)
end
lp.CharacterAdded:Connect(updateChar)

-- ══════════════════════════════════════
-- SAFE DYNAMIC REMOTE RESOLVER
-- ══════════════════════════════════════
local REM_PATHS = {
    EggPickup        = {"ReplicatedStorage", "Remotes", "Game", "EggPickup"},
    Hatch            = {"ReplicatedStorage", "Remotes", "Game", "Hatch"},
    PetCollect       = {"ReplicatedStorage", "Remotes", "Game", "PetCollect"},
    EggPlaced        = {"ReplicatedStorage", "Remotes", "Game", "EggPlaced"},
    FeedPet          = {"ReplicatedStorage", "Remotes", "Game", "FeedPet"},
    Rebirth          = {"ReplicatedStorage", "Remotes", "Game", "Rebirth"},
    BuyWithCash      = {"ReplicatedStorage", "Remotes", "Game", "BuyWithCash"},
    SaveSatchelOrder = {"ReplicatedStorage", "Remotes", "Game", "SaveSatchelOrder"},
    ActivateRadar    = {"ReplicatedStorage", "Remotes", "Game", "ActivateRadar"},
    PlayerActivity   = {"ReplicatedStorage", "Remotes", "Game", "PlayerActivity"},
    RequestPlotEggs  = {"ReplicatedStorage", "Remotes", "Game", "RequestPlotEggs"},
    PlotUpgrades     = {"ReplicatedStorage", "Remotes", "Game", "Plot", "Upgrades"},
    PlotUpgradesAlt  = {"ReplicatedStorage", "Remotes", "Game", "Upgrades"},
    TeleportToPlot   = {"ReplicatedStorage", "Remotes", "Game", "TeleportToPlot"},
    DialogueSelect   = {"ReplicatedStorage", "Dialogue", "Remotes", "DialogueSelect"},
}

local REM_CACHE = {}
local function getRemote(name)
    if REM_CACHE[name] and REM_CACHE[name].Parent then
        return REM_CACHE[name]
    end
    local path = REM_PATHS[name]
    if not path then return nil end
    local cur = game
    for _, part in ipairs(path) do
        cur = cur:FindFirstChild(part)
        if not cur then return nil end
    end
    REM_CACHE[name] = cur
    return cur
end

local function safeFire(name, ...)
    local rem = getRemote(name)
    if not rem and name == "PlotUpgrades" then
        rem = getRemote("PlotUpgradesAlt")
    end
    if not rem then
        warn("[Ride a Pet] Remote tidak ditemukan:", name)
        return false
    end

    local args = {...}
    local ok, err = pcall(function()
        rem:FireServer(table.unpack(args))
    end)
    if not ok then
        warn("[Ride a Pet] FireServer gagal:", name, err)
        return false
    end
    return true
end

-- ══════════════════════════════════════
-- THEME: PET VIBRANT
-- ══════════════════════════════════════
local C = {
    BG        = Color3.fromRGB(15,  18,  26),
    SIDEBAR   = Color3.fromRGB(22,  27,  39),
    CARD      = Color3.fromRGB(30,  37,  54),
    ACCENT    = Color3.fromRGB(255, 140, 40),   -- Vibrant Orange
    ACCENT2   = Color3.fromRGB(60,  190, 255),  -- Sky Blue
    TEXT      = Color3.fromRGB(245, 248, 255),
    SUBTEXT   = Color3.fromRGB(130, 145, 175),
    TOG_ON    = Color3.fromRGB(255, 140, 40),
    TOG_OFF   = Color3.fromRGB(45,  54,  75),
    BORDER    = Color3.fromRGB(48,  60,  88),
    CLOSE     = Color3.fromRGB(245, 75,  75),
    SUCCESS   = Color3.fromRGB(50,  205, 120),
    DANGER    = Color3.fromRGB(245, 75,  75),
}

-- ══════════════════════════════════════
-- STATE
-- ══════════════════════════════════════
local STATE = {
    AutoFarm       = false,
    AutoBestEgg    = false,
    AutoReturnPlot = false,
    AutoPickup     = false,
    AutoPlace      = false,
    AutoHatch      = false,
    AutoRebirth    = false,
    EggESP         = false,
    PlayerESP      = false,
    Fly            = false,
    Noclip         = false,
    InfiniteJump   = false,
    AutoBestPet    = false,
    AutoFeed       = false,
    AutoSell       = false,
    AutoUpgrade    = false,
    AutoBuyFood    = false,
    AutoBuyGear    = false,
    AntiAFK        = false,
    FPSBoost       = false,
    InfiniteZoom   = false,

    WalkSpeed      = 16,
    JumpPower      = 50,
    FlySpeed       = 50,
    FoodName       = "Grass",
    GearName       = "Advanced Radar",
    FeedFood       = "Grass",
}

-- ══════════════════════════════════════
-- EGG LOOKUP TABLE & UTILITY
-- ══════════════════════════════════════
local EGG_LUCK = {
    ["Cherub Egg"]      = 1000000000000,
    ["Solaris Egg"]     = 300000000000,
    ["Blackhole Egg"]   = 100000000000,
    ["Galaxy Egg"]      = 1500000000,
    ["Aurora Egg"]      = 300000000,
    ["Soul Egg"]        = 7000000,
    ["Sinister Egg"]    = 3000000,
    ["Flaming Egg"]     = 1000000,
    ["Dominus Egg"]     = 700000,
    ["Asteroid Egg"]    = 500000,
    ["Skull Egg"]       = 250000,
    ["Crystal Egg"]     = 150000,
    ["Diamond Egg"]     = 90000,
    ["Golden Egg"]      = 30000,
    ["Glass Egg"]       = 10000,
    ["Ice Egg"]         = 3000,
    ["Slime Egg"]       = 1000,
    ["Flower Egg"]      = 750,
    ["Mushroom Egg"]    = 500,
    ["Leaf Egg"]        = 200,
    ["Stone Egg"]       = 100,
    ["Easter Egg"]      = 50,
    ["Cracked Egg"]     = 30,
    ["Brown Egg"]       = 5,
    ["White Egg"]       = 1,
}

local function getEggFolder()
    return workspace:FindFirstChild("RenderedEggs") or workspace:FindFirstChild("Eggs")
end

local function getEggKey(egg)
    if not egg then return nil end
    local attr = egg:GetAttribute("EggKey")
        or egg:GetAttribute("Key")
        or egg:GetAttribute("UUID")
        or egg:GetAttribute("Id")
    if attr then return tostring(attr) end
    if egg.Name:match("%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x") then
        return egg.Name
    end
    for _, d in ipairs(egg:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d:GetAttribute("EggKey") then
            return tostring(d:GetAttribute("EggKey"))
        end
        if d:IsA("StringValue") and (d.Name == "EggKey" or d.Name == "UUID" or d.Name == "Key") then
            return d.Value
        end
    end
    return nil
end

local function getEggLuckValue(egg)
    if EGG_LUCK[egg.Name] then
        return EGG_LUCK[egg.Name]
    end
    local luckAttr = egg:GetAttribute("Luck")
    if luckAttr and tonumber(luckAttr) then
        return tonumber(luckAttr)
    end
    local luckBB = egg:FindFirstChild("EggLuck", true)
    if luckBB then
        local t = luckBB:FindFirstChild("Luck", true) or luckBB:FindFirstChildWhichIsA("TextLabel", true)
        if t and t.Text then
            local raw = t.Text:gsub("%s+", ""):upper()
            local num = tonumber(raw:match("[%d%.]+")) or 0
            if raw:find("T") then return num * 1e12
            elseif raw:find("B") then return num * 1e9
            elseif raw:find("M") then return num * 1e6
            elseif raw:find("K") then return num * 1e3
            else return num end
        end
    end
    return 0
end

local function extractPetId(obj)
    local attr = obj:GetAttribute("PetId") or obj:GetAttribute("UUID") or obj:GetAttribute("Id")
    if attr then return tostring(attr) end
    local match = obj.Name:match("^Pet:(.+)$") or obj.Name:match("%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x")
    return match
end

-- ══════════════════════════════════════
-- CLEANUP OLD SCRIPT INSTANCES
-- ══════════════════════════════════════
if _G.RideAPetHubRunning then
    _G.RideAPetHubRunning = false
    task.wait(0.2)
end
_G.RideAPetHubRunning = true

local function isScriptRunning()
    return _G.RideAPetHubRunning == true
end

local function getMyPlot()
    local plots = workspace:FindFirstChild("Plots") or workspace:FindFirstChild("Ranches")
    if not plots then return nil end
    for _, plot in ipairs(plots:GetChildren()) do
        local owner = plot:GetAttribute("Owner") or plot:GetAttribute("OwnerId") or plot:GetAttribute("UserId")
        if owner and (tostring(owner) == tostring(lp.UserId) or tostring(owner) == lp.Name) then
            return plot
        end
        local ov = plot:FindFirstChild("Owner") or plot:FindFirstChild("Player")
        if ov and ov:IsA("ValueBase") and (tostring(ov.Value) == tostring(lp.UserId) or tostring(ov.Value) == lp.Name) then
            return plot
        end
        local bb = plot:FindFirstChildWhichIsA("BillboardGui", true)
        if bb then
            for _, t in ipairs(bb:GetDescendants()) do
                if t:IsA("TextLabel") and (t.Text:find("Your Ranch") or t.Text:find(lp.Name)) then
                    return plot
                end
            end
        end
    end
    return plots:GetChildren()[1]
end

-- ══════════════════════════════════════
-- FEATURE LOGIC
-- ══════════════════════════════════════

-- Simple ProximityPrompt Trigger
local function triggerPrompt(prompt)
    if not prompt then return false end
    local ok = false
    if fireproximityprompt then
        ok = pcall(function() fireproximityprompt(prompt) end)
    end
    if not ok then
        ok = pcall(function()
            prompt:InputHoldBegin()
            task.wait(math.max(prompt.HoldDuration, 0.5) + 0.1)
            prompt:InputHoldEnd()
        end)
    end
    print("[Ride a Pet] Prompt trigger:", ok, prompt:GetFullName())
    return ok
end

local isCarryingEgg = false
local isDelivering = false

-- Utility: Pickup Egg via ProximityPrompt + Teleport/CFrame + Safe Tween Return
local function pickupEgg(egg, returnToPlot)
    if not egg or not root or isDelivering then return false end
    local prompt = egg:FindFirstChildWhichIsA("ProximityPrompt", true)
    if not prompt then return false end

    isDelivering = true

    -- Simpan posisi plot: prioritaskan plot asli, fallback posisi saat ini sebelum TP
    local plot = getMyPlot()
    local targetCF = plot and CFrame.new(plot:GetPivot().Position + Vector3.new(0, 4, 0)) or root.CFrame

    local eggPos = egg:GetPivot().Position

    -- Teleport ke egg, lalu beri server waktu sinkronisasi sebelum pickup.
    root.CFrame = CFrame.new(eggPos + Vector3.new(0, 2.5, 0))
    task.wait(2.0)

    -- Trigger prompt setelah karakter stabil.
    triggerPrompt(prompt)

    -- Tunggu egg benar-benar masuk tangan.
    task.wait(2.0)
    isCarryingEgg = true

    -- Tunggu sebentar agar Return to Plot bisa dinyalakan setelah Auto Best Egg.
    -- Egg tetap dikunci; Auto Best Egg tidak mencari target lain.
    local waitUntil = os.clock() + 6
    while not STATE.AutoReturnPlot and STATE.AutoBestEgg and os.clock() < waitUntil do
        task.wait(0.1)
    end

    local shouldReturn = STATE.AutoReturnPlot == true
    print("[Ride a Pet] Return state: AutoReturnPlot =", tostring(STATE.AutoReturnPlot))

    -- Jika return to plot aktif
    if shouldReturn then
        STATE.Noclip = true
        if _G.ToggleSetters and _G.ToggleSetters.Noclip then
            _G.ToggleSetters.Noclip(true)
        end
        task.wait(0.1)

        if targetCF and root then
            local dist = (root.Position - targetCF.Position).Magnitude
            print("[Ride a Pet] Tween balik ke plot. Jarak:", math.floor(dist), "studs")
            if dist > 8 then
                -- Antisipasi "your egg was returned":
                -- 1. Jangan ubah Anchored! Biarkan physics berjalan normal di mata server.
                -- 2. Matikan residual physics momentum agar server tidak mendeteksi desync drastis.
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero

                -- Kecepatan stabil (~110 studs/s)
                local duration = math.clamp(dist / 110, 1.2, 7.0)
                local tweenObj = ts:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = targetCF})
                tweenObj:Play()
                tweenObj.Completed:Wait()

                root.CFrame = targetCF
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                print("[Ride a Pet] Sampai di plot via Tween!")
                task.wait(0.3)
            end
        end

        if not STATE.AutoReturnPlot then
            STATE.Noclip = false
            if _G.ToggleSetters and _G.ToggleSetters.Noclip then
                _G.ToggleSetters.Noclip(false)
            end
        end

        task.wait(0.2)
        isCarryingEgg = false
        isDelivering = false
    else
        isDelivering = false
    end

    return true
end

-- Auto Best Egg
task.spawn(function()
    while isScriptRunning() do
        task.wait(1)
        if STATE.AutoBestEgg and root and not isCarryingEgg and not isDelivering then
            -- Jika Return to Plot ON tapi Noclip belum, sinkronkan dulu
            if STATE.AutoReturnPlot and not STATE.Noclip then
                if _G.ToggleSetters and _G.ToggleSetters.Noclip then
                    _G.ToggleSetters.Noclip(true)
                end
            end
            local eggs = getEggFolder()
            if eggs and #eggs:GetChildren() > 0 then
                local bestEgg = nil
                local highestLuck = -1
                for _, egg in ipairs(eggs:GetChildren()) do
                    local luck = getEggLuckValue(egg)
                    if luck > highestLuck then
                        highestLuck = luck
                        bestEgg = egg
                    end
                end
                if bestEgg then
                    print(string.format("[Ride a Pet] Teleport & Pickup Best Egg: %s (Luck: %s)", bestEgg.Name, tostring(highestLuck)))
                    pickupEgg(bestEgg, STATE.AutoReturnPlot)
                end
            end
        end
    end
end)

-- Auto Pickup (Semua Egg)
task.spawn(function()
    while isScriptRunning() do
        task.wait(0.5)
        if STATE.AutoPickup and root and not isDelivering then
            local eggs = getEggFolder()
            local eggList = eggs and eggs:GetChildren() or {}
            if #eggList > 0 then
                for i, egg in ipairs(eggList) do
                    if not STATE.AutoPickup then break end
                    local isLast = (i == #eggList)
                    pickupEgg(egg, isLast and STATE.AutoReturnPlot)
                    task.wait(0.2)
                end
            end
        end
    end
end)

-- Auto Hatch
task.spawn(function()
    while isScriptRunning() do
        task.wait(1)
        if STATE.AutoHatch then
            local eggs = getEggFolder()
            if eggs then
                for _, egg in ipairs(eggs:GetChildren()) do
                    if not STATE.AutoHatch then break end
                    local key = getEggKey(egg)
                    if key then
                        safeFire("Hatch", { EggKey = key })
                        task.wait(0.12)
                    end
                end
            end
        end
    end
end)

-- Auto Place (EggPlaced)
local PLACE_OFFSET = 6
task.spawn(function()
    local slotIndex = 0
    while isScriptRunning() do
        task.wait(1.5)
        if STATE.AutoPlace then
            local plot = getMyPlot()
            if plot and root then
                local base = plot:GetPivot().Position
                local col = slotIndex % 5
                local row = math.floor(slotIndex / 5)
                local pos = Vector3.new(
                    base.X + (col - 2) * PLACE_OFFSET,
                    base.Y + 2,
                    base.Z + (row - 2) * PLACE_OFFSET
                )
                safeFire("EggPlaced", { PlantPosition = pos })
                slotIndex = (slotIndex + 1) % 25
            end
        end
    end
end)

-- Auto Collect Pet
task.spawn(function()
    while isScriptRunning() do
        task.wait(0.8)
        if STATE.AutoFarm then
            local plot = getMyPlot()
            if plot then
                for _, pet in ipairs(plot:GetDescendants()) do
                    if not STATE.AutoFarm then break end
                    local petId = extractPetId(pet)
                    if petId then
                        safeFire("PetCollect", petId)
                        task.wait(0.08)
                    end
                end
            end
        end
    end
end)

-- Auto Rebirth
task.spawn(function()
    while isScriptRunning() do
        task.wait(5)
        if STATE.AutoRebirth then
            safeFire("Rebirth")
        end
    end
end)

-- Auto Feed Pet
task.spawn(function()
    while isScriptRunning() do
        task.wait(2)
        if STATE.AutoFeed then
            local plot = getMyPlot()
            if plot then
                for _, pet in ipairs(plot:GetDescendants()) do
                    if not STATE.AutoFeed then break end
                    local petId = extractPetId(pet)
                    if petId then
                        safeFire("FeedPet", petId, STATE.FeedFood)
                        task.wait(0.12)
                    end
                end
            end
        end
    end
end)

-- Auto Sell All
task.spawn(function()
    while isScriptRunning() do
        task.wait(5)
        if STATE.AutoSell then
            local stall = workspace:FindFirstChild("Stalls")
            local richie = stall and stall:FindFirstChild("Sell") and stall.Sell:FindFirstChild("Richie")
            if richie then
                safeFire("DialogueSelect", richie, "I would like to sell my pets")
            end
        end
    end
end)

-- Auto Upgrade Plot
task.spawn(function()
    while isScriptRunning() do
        task.wait(10)
        if STATE.AutoUpgrade then
            safeFire("PlotUpgrades")
        end
    end
end)

-- Auto Buy Food
task.spawn(function()
    while isScriptRunning() do
        task.wait(10)
        if STATE.AutoBuyFood then
            safeFire("BuyWithCash", "Food", STATE.FoodName)
        end
    end
end)

-- Auto Buy Gear
task.spawn(function()
    while isScriptRunning() do
        task.wait(10)
        if STATE.AutoBuyGear then
            safeFire("BuyWithCash", "Gears", STATE.GearName)
        end
    end
end)

-- Anti-AFK
task.spawn(function()
    while isScriptRunning() do
        task.wait(30)
        if STATE.AntiAFK then
            safeFire("PlayerActivity")
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end
end)

-- FPS Boost
local function applyFPSBoost(on)
    pcall(function()
        Lighting.GlobalShadows = not on
        Lighting.FogEnd = on and 9e9 or 10000
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
                v.Enabled = not on
            end
        end
    end)
end

-- Infinite Zoom
local function applyInfZoom(on)
    pcall(function()
        lp.CameraMaxZoomDistance = on and 100000 or 128
        lp.CameraMinZoomDistance = on and 0 or 0.5
    end)
end

-- WalkSpeed / JumpPower
task.spawn(function()
    while isScriptRunning() do
        task.wait(0.15)
        if hum and hum.Parent then
            if hum.WalkSpeed ~= STATE.WalkSpeed then
                hum.WalkSpeed = STATE.WalkSpeed
            end
            if hum.UseJumpPower then
                if hum.JumpPower ~= STATE.JumpPower then
                    hum.JumpPower = STATE.JumpPower
                end
            else
                hum.JumpHeight = STATE.JumpPower / 7
            end
        end
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if STATE.InfiniteJump and hum and hum.Parent then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Fly
local flyBV, flyAtt
stopFly = function()
    pcall(function()
        RunService:UnbindFromRenderStep("FlyStep")
        if flyBV then flyBV:Destroy() flyBV = nil end
        if flyAtt then flyAtt:Destroy() flyAtt = nil end
    end)
    if hum and hum.Parent then
        hum.PlatformStand = false
    end
end

startFly = function()
    stopFly()
    if not root or not root.Parent then return end

    local att = Instance.new("Attachment")
    att.Name = "RAPFlyAtt"
    att.Parent = root

    local bv = Instance.new("LinearVelocity")
    bv.Name = "RAPFlyBV"
    bv.Attachment0 = att
    bv.MaxForce = 999999
    bv.VectorVelocity = Vector3.zero
    bv.Parent = root

    flyAtt = att
    flyBV  = bv

    if hum and hum.Parent then
        hum.PlatformStand = true
    end

    RunService:BindToRenderStep("FlyStep", 200, function()
        if not STATE.Fly or not root or not root.Parent or not flyBV or not flyBV.Parent then
            stopFly()
            return
        end
        local cam = workspace.CurrentCamera
        if not cam then return end
        local cf  = cam.CFrame
        local vel = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vel = vel - Vector3.yAxis end
        flyBV.VectorVelocity = vel * STATE.FlySpeed
    end)
end

-- Noclip
RunService:BindToRenderStep("NoclipStep", 200, function()
    if not STATE.Noclip or not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end)

-- ESP Tracker
local eggESPMap = {}
local playerESPMap = {}

local function clearEggESP()
    for egg, bb in pairs(eggESPMap) do
        pcall(function() bb:Destroy() end)
    end
    eggESPMap = {}
end

local function clearPlayerESP()
    for plr, bb in pairs(playerESPMap) do
        pcall(function() bb:Destroy() end)
    end
    playerESPMap = {}
end

task.spawn(function()
    while isScriptRunning() do
        task.wait(0.5)
        -- EGG ESP
        if STATE.EggESP then
            local eggs = getEggFolder()
            local activeEggs = {}
            if eggs then
                for _, egg in ipairs(eggs:GetChildren()) do
                    activeEggs[egg] = true
                    local bb = eggESPMap[egg]
                    local part = egg:FindFirstChildWhichIsA("BasePart") or egg.PrimaryPart
                    if part then
                        local dist = root and math.floor((root.Position - part.Position).Magnitude) or 0
                        local luck = getEggLuckValue(egg)
                        local luckStr = luck > 0 and (" | Luck: " .. luck) or ""
                        if not bb or not bb.Parent then
                            bb = Instance.new("BillboardGui")
                            bb.Name = "RAPEggESP"
                            bb.Size = UDim2.new(0, 110, 0, 32)
                            bb.AlwaysOnTop = true
                            bb.StudsOffset = Vector3.new(0, 3, 0)
                            bb.Adornee = part
                            bb.Parent = egg

                            local lbl = Instance.new("TextLabel")
                            lbl.Name = "Text"
                            lbl.Size = UDim2.new(1, 0, 1, 0)
                            lbl.BackgroundTransparency = 1
                            lbl.TextColor3 = C.ACCENT
                            lbl.Font = Enum.Font.GothamBold
                            lbl.TextSize = 12
                            lbl.Parent = bb
                            eggESPMap[egg] = bb
                        end
                        local lbl = bb:FindFirstChild("Text")
                        if lbl then
                            lbl.Text = "🥚 " .. egg.Name .. luckStr .. "\n[" .. dist .. "m]"
                        end
                    end
                end
            end
            for egg, bb in pairs(eggESPMap) do
                if not activeEggs[egg] or not egg.Parent then
                    pcall(function() bb:Destroy() end)
                    eggESPMap[egg] = nil
                end
            end
        else
            if next(eggESPMap) ~= nil then clearEggESP() end
        end

        -- PLAYER ESP
        if STATE.PlayerESP then
            local activePlayers = {}
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp and plr.Character then
                    activePlayers[plr] = true
                    local pRoot = plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character.PrimaryPart
                    if pRoot then
                        local bb = playerESPMap[plr]
                        local dist = root and math.floor((root.Position - pRoot.Position).Magnitude) or 0
                        if not bb or not bb.Parent then
                            bb = Instance.new("BillboardGui")
                            bb.Name = "RAPPlrESP"
                            bb.Size = UDim2.new(0, 100, 0, 30)
                            bb.AlwaysOnTop = true
                            bb.StudsOffset = Vector3.new(0, 3.5, 0)
                            bb.Adornee = pRoot
                            bb.Parent = plr.Character

                            local lbl = Instance.new("TextLabel")
                            lbl.Name = "Text"
                            lbl.Size = UDim2.new(1, 0, 1, 0)
                            lbl.BackgroundTransparency = 1
                            lbl.TextColor3 = C.ACCENT2
                            lbl.Font = Enum.Font.GothamBold
                            lbl.TextSize = 12
                            lbl.Parent = bb
                            playerESPMap[plr] = bb
                        end
                        local lbl = bb:FindFirstChild("Text")
                        if lbl then
                            lbl.Text = plr.DisplayName .. "\n[" .. dist .. "m]"
                        end
                    end
                end
            end
            for plr, bb in pairs(playerESPMap) do
                if not activePlayers[plr] or not plr.Parent or not plr.Character or not plr.Character.Parent then
                    pcall(function() bb:Destroy() end)
                    playerESPMap[plr] = nil
                end
            end
        else
            if next(playerESPMap) ~= nil then clearPlayerESP() end
        end
    end
end)

-- ══════════════════════════════════════
-- INTRO / LOADING ANIMATION
-- ══════════════════════════════════════
local function playIntroAnimation()
    local parentTarget = lp:FindFirstChild("PlayerGui")
    pcall(function()
        if syn and syn.protect_gui then
            parentTarget = game:GetService("CoreGui")
        end
    end)
    if not parentTarget then parentTarget = lp:WaitForChild("PlayerGui", 5) end
    if not parentTarget then return end

    local splashGui = Instance.new("ScreenGui")
    splashGui.Name = "RAPIntroSplash"
    splashGui.ResetOnSpawn = false
    splashGui.IgnoreGuiInset = true
    splashGui.DisplayOrder = 9999
    splashGui.Parent = parentTarget

    -- Backdrop
    local backdrop = Instance.new("Frame")
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.fromRGB(8, 10, 15)
    backdrop.BackgroundTransparency = 1
    backdrop.BorderSizePixel = 0
    backdrop.Parent = splashGui

    -- Splash Card (Centered)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 380, 0, 170)
    card.Position = UDim2.new(0.5, -190, 0.5, -60)
    card.BackgroundColor3 = C.CARD
    card.BackgroundTransparency = 1
    card.BorderSizePixel = 0
    card.Parent = splashGui

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 14)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = C.ACCENT
    cardStroke.Thickness = 1.5
    cardStroke.Transparency = 1
    cardStroke.Parent = card

    -- Glow / Top Line Accent
    local glowLine = Instance.new("Frame")
    glowLine.Size = UDim2.new(0, 0, 0, 3)
    glowLine.Position = UDim2.new(0.5, 0, 0, 0)
    glowLine.BackgroundColor3 = C.ACCENT
    glowLine.BorderSizePixel = 0
    glowLine.Parent = card

    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(0, 2)
    glowCorner.Parent = glowLine

    -- Title Label
    local title = Instance.new("TextLabel")
    title.Text = "🐾  " .. (CURRENT_PROJECT and CURRENT_PROJECT.Name:upper() or "RIDE A PET") .. " HUB"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextColor3 = C.TEXT
    title.TextTransparency = 1
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 32)
    title.Position = UDim2.new(0, 0, 0, 20)
    title.Parent = card

    -- Subtitle / Status
    local status = Instance.new("TextLabel")
    status.Text = "Initializing modules & remotes..."
    status.Font = Enum.Font.Gotham
    status.TextSize = 12
    status.TextColor3 = C.SUBTEXT
    status.TextTransparency = 1
    status.BackgroundTransparency = 1
    status.Size = UDim2.new(1, 0, 0, 20)
    status.Position = UDim2.new(0, 0, 0, 56)
    status.Parent = card

    -- Progress Bar Track
    local barTrack = Instance.new("Frame")
    barTrack.Size = UDim2.new(0, 300, 0, 6)
    barTrack.Position = UDim2.new(0.5, -150, 0, 95)
    barTrack.BackgroundColor3 = C.TOG_OFF
    barTrack.BackgroundTransparency = 1
    barTrack.BorderSizePixel = 0
    barTrack.Parent = card

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(0, 3)
    trackCorner.Parent = barTrack

    -- Progress Bar Fill
    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = C.ACCENT
    barFill.BorderSizePixel = 0
    barFill.Parent = barTrack

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
    fillCorner.Parent = barFill

    -- Version / Credits
    local verLabel = Instance.new("TextLabel")
    verLabel.Text = "Pet Vibrant Edition • Ash-Libs"
    verLabel.Font = Enum.Font.Gotham
    verLabel.TextSize = 10
    verLabel.TextColor3 = C.ACCENT2
    verLabel.TextTransparency = 1
    verLabel.BackgroundTransparency = 1
    verLabel.Size = UDim2.new(1, 0, 0, 20)
    verLabel.Position = UDim2.new(0, 0, 0, 125)
    verLabel.Parent = card

    -- ANIMATION SEQUENCE
    -- 1. Pop & Fade in
    TweenService:Create(backdrop, TweenInfo.new(0.35), {BackgroundTransparency = 0.45}):Play()
    TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -190, 0.5, -85),
        BackgroundTransparency = 0
    }):Play()
    TweenService:Create(cardStroke, TweenInfo.new(0.35), {Transparency = 0}):Play()
    TweenService:Create(title, TweenInfo.new(0.35), {TextTransparency = 0}):Play()
    TweenService:Create(status, TweenInfo.new(0.35), {TextTransparency = 0}):Play()
    TweenService:Create(verLabel, TweenInfo.new(0.35), {TextTransparency = 0.2}):Play()
    TweenService:Create(barTrack, TweenInfo.new(0.35), {BackgroundTransparency = 0}):Play()
    TweenService:Create(glowLine, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, 0, 0, 3),
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()

    task.wait(0.4)

    -- 2. Step 1: Resolving Remotes
    status.Text = "Connecting Remotes & Game Cache..."
    TweenService:Create(barFill, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0.45, 0, 1, 0)
    }):Play()
    task.wait(0.45)

    -- 3. Step 2: Loading Ash-Libs
    status.Text = "Building Pet Vibrant Dashboard..."
    TweenService:Create(barFill, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0.85, 0, 1, 0),
        BackgroundColor3 = C.ACCENT2
    }):Play()
    task.wait(0.45)

    -- 4. Step 3: Complete
    status.Text = "Ready! Welcome."
    TweenService:Create(barFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = C.SUCCESS
    }):Play()
    task.wait(0.3)

    -- 5. Fade out & cleanup
    local fadeTime = 0.35
    TweenService:Create(backdrop, TweenInfo.new(fadeTime), {BackgroundTransparency = 1}):Play()
    TweenService:Create(card, TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, -190, 0.5, -110),
        BackgroundTransparency = 1
    }):Play()
    TweenService:Create(cardStroke, TweenInfo.new(fadeTime), {Transparency = 1}):Play()
    TweenService:Create(glowLine, TweenInfo.new(fadeTime), {BackgroundTransparency = 1}):Play()
    TweenService:Create(title, TweenInfo.new(fadeTime), {TextTransparency = 1}):Play()
    TweenService:Create(status, TweenInfo.new(fadeTime), {TextTransparency = 1}):Play()
    TweenService:Create(verLabel, TweenInfo.new(fadeTime), {TextTransparency = 1}):Play()
    TweenService:Create(barTrack, TweenInfo.new(fadeTime), {BackgroundTransparency = 1}):Play()
    TweenService:Create(barFill, TweenInfo.new(fadeTime), {BackgroundTransparency = 1}):Play()

    task.wait(fadeTime + 0.05)
    splashGui:Destroy()
end

playIntroAnimation()

-- ══════════════════════════════════════
-- GUI BUILD (Ash-Libs Library)
-- ══════════════════════════════════════
local GUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/BloodLetters/Ash-Libs/refs/heads/main/source.lua"))()

GUI:CreateMain({
    Name = "RideAPetHub",
    title = "RIDE A PET HUB",
    ToggleUI = "RightShift",
    WindowIcon = "paw-print",
    WindowWidth = 800,
    WindowHeight = 560,
    Theme = {
        Background      = C.BG,
        Secondary       = C.CARD,
        Accent          = C.ACCENT,
        AccentSecondary = C.ACCENT2,
        Text            = C.TEXT,
        TextSecondary   = C.SUBTEXT,
        Border          = C.BORDER,
        NavBackground   = C.SIDEBAR,
        Surface         = C.CARD,
        SurfaceVariant  = C.SIDEBAR,
        Success         = C.SUCCESS,
        Warning         = Color3.fromRGB(255, 189, 46),
        Error           = C.DANGER,
    },
    Blur = {
        Enable = false,
        value = 0.2
    },
    Config = {
        Enabled = false,
    }
})

-- Global Registry untuk Sinkronisasi Setter Antar-Tab
if not _G.ToggleSetters then _G.ToggleSetters = {} end

local function makeToggle(tab, text, stateKey, callback)
    local togObj = GUI:CreateToggle({
        parent = tab,
        text = text,
        default = STATE[stateKey] or false,
        flag = stateKey,
        callback = function(state)
            STATE[stateKey] = state
            if callback then callback(state) end
        end
    })
    _G.ToggleSetters[stateKey] = function(val)
        togObj:Set(val)
    end
    return togObj
end

-- TAB 1: FARM
local farmTab = GUI:CreateTab("FARM", "egg-fried")

GUI:CreateSection({ parent = farmTab, text = "AUTO FARM" })

makeToggle(farmTab, "Auto Farm", "AutoFarm")

makeToggle(farmTab, "Auto Best Egg", "AutoBestEgg", function(on)
    if not on then
        isCarryingEgg = false
    end
end)

makeToggle(farmTab, "Return to Plot", "AutoReturnPlot", function(on)
    if _G.ToggleSetters and _G.ToggleSetters.Noclip then
        _G.ToggleSetters.Noclip(on)
    else
        STATE.Noclip = on
    end
end)

makeToggle(farmTab, "Auto Pickup", "AutoPickup")
makeToggle(farmTab, "Auto Place", "AutoPlace")
makeToggle(farmTab, "Auto Hatch", "AutoHatch")
makeToggle(farmTab, "Auto Rebirth", "AutoRebirth")

GUI:CreateSection({ parent = farmTab, text = "REQUEST" })

GUI:CreateButton({
    parent = farmTab,
    text = "Request Plot Eggs",
    callback = function()
        safeFire("RequestPlotEggs", false)
        GUI:CreateNotify({ title = "Request", description = "Requested plot eggs" })
    end
})

-- TAB 2: ESP
local espTab = GUI:CreateTab("ESP", "scan-eye")

GUI:CreateSection({ parent = espTab, text = "ESP SETTINGS" })

makeToggle(espTab, "Egg ESP", "EggESP")
makeToggle(espTab, "Player ESP", "PlayerESP")

-- TAB 3: MOVEMENT
local moveTab = GUI:CreateTab("MOVEMENT", "move-3d")

GUI:CreateSection({ parent = moveTab, text = "MOVEMENT" })

makeToggle(moveTab, "Fly", "Fly", function(on)
    if on then startFly() else stopFly() end
end)

makeToggle(moveTab, "Noclip", "Noclip")
makeToggle(moveTab, "Infinite Jump", "InfiniteJump")

GUI:CreateSection({ parent = moveTab, text = "STATS" })

GUI:CreateSlider({
    parent = moveTab,
    text = "WalkSpeed",
    min = 1,
    max = 250,
    default = STATE.WalkSpeed,
    flag = "WalkSpeed",
    callback = function(value)
        STATE.WalkSpeed = math.floor(value)
    end
})

GUI:CreateSlider({
    parent = moveTab,
    text = "JumpPower",
    min = 1,
    max = 500,
    default = STATE.JumpPower,
    flag = "JumpPower",
    callback = function(value)
        STATE.JumpPower = math.floor(value)
    end
})

GUI:CreateSlider({
    parent = moveTab,
    text = "Fly Speed",
    min = 10,
    max = 300,
    default = STATE.FlySpeed,
    flag = "FlySpeed",
    callback = function(value)
        STATE.FlySpeed = math.floor(value)
    end
})

GUI:CreateSection({ parent = moveTab, text = "TELEPORT" })

GUI:CreateButton({
    parent = moveTab,
    text = "Teleport ke Plot Saya",
    callback = function()
        safeFire("TeleportToPlot")
        GUI:CreateNotify({ title = "Teleport", description = "Teleport ke plot" })
    end
})

-- TAB 4: PET
local petTab = GUI:CreateTab("PET", "paw-print")

GUI:CreateSection({ parent = petTab, text = "PET MANAGEMENT" })

makeToggle(petTab, "Auto Collect", "AutoFarm")
makeToggle(petTab, "Auto Feed", "AutoFeed")
makeToggle(petTab, "Auto Sell", "AutoSell")
makeToggle(petTab, "Auto Upgrade", "AutoUpgrade")

GUI:CreateSection({ parent = petTab, text = "FEED CONFIG" })

GUI:CreateInput({
    parent = petTab,
    text = "Food Name",
    placeholder = "cth: Grass",
    flag = "FeedFood",
    callback = function(text)
        STATE.FeedFood = text
    end
})

GUI:CreateSection({ parent = petTab, text = "MANUAL" })

GUI:CreateButton({
    parent = petTab,
    text = "Collect Semua Pet",
    callback = function()
        local plot = getMyPlot()
        if plot then
            for _, pet in ipairs(plot:GetDescendants()) do
                local id = extractPetId(pet)
                if id then safeFire("PetCollect", id) end
            end
            GUI:CreateNotify({ title = "Collect", description = "Collect selesai" })
        else
            GUI:CreateNotify({ title = "Error", description = "Plot tidak ditemukan" })
        end
    end
})

GUI:CreateButton({
    parent = petTab,
    text = "Jual Semua Pet Sekarang",
    callback = function()
        local stall = workspace:FindFirstChild("Stalls")
        local richie = stall and stall:FindFirstChild("Sell") and stall.Sell:FindFirstChild("Richie")
        if richie then
            safeFire("DialogueSelect", richie, "I would like to sell my pets")
            GUI:CreateNotify({ title = "Sell", description = "Sell all pets" })
        end
    end
})

-- TAB 5: SHOP
local shopTab = GUI:CreateTab("SHOP", "shopping-cart")

GUI:CreateSection({ parent = shopTab, text = "AUTO BUY" })

makeToggle(shopTab, "Auto Buy Food", "AutoBuyFood")

GUI:CreateInput({
    parent = shopTab,
    text = "Food Item",
    placeholder = "cth: Grass",
    flag = "FoodName",
    callback = function(text)
        STATE.FoodName = text
    end
})

makeToggle(shopTab, "Auto Buy Gear", "AutoBuyGear")

GUI:CreateInput({
    parent = shopTab,
    text = "Gear Item",
    placeholder = "cth: Advanced Radar",
    flag = "GearName",
    callback = function(text)
        STATE.GearName = text
    end
})

GUI:CreateSection({ parent = shopTab, text = "MANUAL BUY" })

GUI:CreateButton({
    parent = shopTab,
    text = "Beli Food Sekarang",
    callback = function()
        safeFire("BuyWithCash", "Food", STATE.FoodName)
        GUI:CreateNotify({ title = "Shop", description = "Buy Food: " .. STATE.FoodName })
    end
})

GUI:CreateButton({
    parent = shopTab,
    text = "Beli Gear Sekarang",
    callback = function()
        safeFire("BuyWithCash", "Gears", STATE.GearName)
        GUI:CreateNotify({ title = "Shop", description = "Buy Gear: " .. STATE.GearName })
    end
})

GUI:CreateButton({
    parent = shopTab,
    text = "Aktifkan Radar",
    callback = function()
        safeFire("ActivateRadar")
        GUI:CreateNotify({ title = "Radar", description = "Radar activated" })
    end
})

-- TAB 6: MISC
local miscTab = GUI:CreateTab("MISC", "settings-2")

GUI:CreateSection({ parent = miscTab, text = "UTILITY" })

makeToggle(miscTab, "Anti-AFK", "AntiAFK")
makeToggle(miscTab, "FPS Boost", "FPSBoost", function(on)
    applyFPSBoost(on)
end)
makeToggle(miscTab, "Infinite Zoom", "InfiniteZoom", function(on)
    applyInfZoom(on)
end)

GUI:CreateSection({ parent = miscTab, text = "KEYBIND" })

GUI:CreateParagraph({
    parent = miscTab,
    title = "Keybind Info",
    text = "Fly: WASD + Space (naik) + LCtrl (turun)\nToggle GUI: Tekan tombol RightShift"
})
