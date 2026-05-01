-- // =============================================
-- // SHARK HUB V4 - PERMANENT UNLOCKER + GODMODE
-- // Versión Optimizada para Rivals - By Shark
-- // =============================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()

local allowedUsers = {"sharknjd", "ryusenkai7", "sharkalt_3"}
if not table.find(allowedUsers, player.Name) then 
    warn("🦈 Usuario no autorizado")
    return 
end

-- =============================================
-- ALMACENAMIENTO PERMANENTE
-- =============================================
local PermanentData = {
    unlockedWeapons = {},
    unlockedSkins = {},
    unlockedBattlePass = false,
}

local function savePermanentData()
    local success, err = pcall(function()
        writefile("SharkHub_PermanentData.json", HttpService:JSONEncode(PermanentData))
    end)
    if success then print("🦈 Datos guardados") end
end

local function loadPermanentData()
    local success, data = pcall(function()
        return readfile("SharkHub_PermanentData.json")
    end)
    if success and data then
        local decoded = HttpService:JSONDecode(data)
        for k, v in pairs(decoded) do PermanentData[k] = v end
        print("🦈 Datos cargados | Armas: " .. #PermanentData.unlockedWeapons)
    end
end
loadPermanentData()

-- =============================================
-- CONFIGURACIÓN
-- =============================================
local Config = {
    aimbot = false, silentAim = false, triggerbot = false,
    wallhack = false, showNames = true, showDistance = true, showHealth = true,
    fly = false, noclip = false, godmode = false, hitboxExpander = false,
    infiniteAmmo = false, noRecoil = false, rapidFire = false, autoShoot = false,
    unlockAllWeapons = false, unlockAllSkins = false, unlockBattlePass = false,
    autoFarm = false, farmMode = "Kills", autoClickDelay = 0.1,
    aimFOV = 120, aimSmooth = 0.25, flySpeed = 90, hitboxSize = 5,
    espColor = "Lime", espTracer = true, espBox = true,
}

local State = {
    connections = {}, espObjects = {}, flyBV = nil,
    originalHitboxSize = {}, godmodeActive = false, dragging = false,
    dragStart = nil, startPos = nil, currentTab = "Main"
}

-- =============================================
-- NOTIFICACIONES
-- =============================================
local function notify(msg, isError)
    local notif = Instance.new("TextLabel")
    notif.Size = UDim2.new(0, 320, 0, 40)
    notif.Position = UDim2.new(0.5, -160, 0, 10)
    notif.BackgroundColor3 = isError and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(0, 0, 0)
    notif.BackgroundTransparency = 0.2
    notif.TextColor3 = Color3.new(1, 1, 1)
    notif.Text = "🦈 " .. msg
    notif.Font = Enum.Font.GothamSemibold
    notif.TextSize = 13
    notif.Parent = player.PlayerGui
    Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 8)
    
    TweenService:Create(notif, TweenInfo.new(2, Enum.EasingStyle.Sine), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
    task.wait(2)
    notif:Destroy()
end

-- =============================================
-- PERMANENT UNLOCKER
-- =============================================
local function permanentlyUnlockWeapon(name)
    if not table.find(PermanentData.unlockedWeapons, name) then
        table.insert(PermanentData.unlockedWeapons, name)
        savePermanentData()
        notify("🔓 Arma desbloqueada: " .. name)
    end
end

local function permanentUnlockAll()
    pcall(function()
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            local name = obj.Name:lower()
            if Config.unlockAllWeapons and (name:find("weapon") or name:find("gun") or name:find("rivals")) then
                pcall(function()
                    if obj:FindFirstChild("Owned") then obj.Owned.Value = true end
                    if obj:FindFirstChild("Unlocked") then obj.Unlocked.Value = true end
                    permanentlyUnlockWeapon(obj.Name)
                end)
            end
            if Config.unlockAllSkins and (name:find("skin") or name:find("cosmetic") or name:find("camo")) then
                pcall(function() permanentlyUnlockWeapon("[Skin] " .. obj.Name) end)
            end
        end
        
        if Config.unlockBattlePass and not PermanentData.unlockedBattlePass then
            PermanentData.unlockedBattlePass = true
            savePermanentData()
            notify("🎫 Battle Pass desbloqueado permanentemente!")
        end
    end)
end

-- =============================================
-- GODMODE REAL
-- =============================================
local function setupGodmode()
    pcall(function()
        local char = player.Character
        if not char then return end
        local humanoid = char:FindFirstChild("Humanoid")
        
        if Config.godmode and not State.godmodeActive then
            State.godmodeActive = true
            humanoid.MaxHealth = 9e9
            humanoid.Health = 9e9
            humanoid.BreakJointsOnDeath = false
            
            local connection = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
                if humanoid.Health < humanoid.MaxHealth and Config.godmode then
                    humanoid.Health = humanoid.MaxHealth
                end
            end)
            table.insert(State.connections, connection)
            
            local damageConn = char:FindFirstChild("HumanoidRootPart").Touched:Connect(function(hit)
                if Config.godmode and hit:IsA("BasePart") and hit:FindFirstChild("Damage") then
                    humanoid.Health = humanoid.MaxHealth
                end
            end)
            table.insert(State.connections, damageConn)
            
            notify("🛡️ GODMODE ACTIVADO", false)
        elseif not Config.godmode and State.godmodeActive then
            State.godmodeActive = false
            for _, conn in ipairs(State.connections) do
                pcall(function() conn:Disconnect() end)
            end
            State.connections = {}
            if humanoid then humanoid.MaxHealth = 100 end
            notify("Godmode desactivado")
        end
    end)
end

-- =============================================
-- HITBOX EXPANDER
-- =============================================
local function setupHitboxExpander()
    pcall(function()
        local char = player.Character
        if char and Config.hitboxExpander then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                if not State.originalHitboxSize[hrp] then
                    State.originalHitboxSize[hrp] = hrp.Size
                end
                hrp.Size = Vector3.new(Config.hitboxSize, Config.hitboxSize, Config.hitboxSize)
                hrp.Transparency = 0.4
            end
        elseif char then
            for part, original in pairs(State.originalHitboxSize) do
                if part and part.Parent then
                    part.Size = original
                    part.Transparency = 0
                end
            end
            State.originalHitboxSize = {}
        end
    end)
end

-- =============================================
-- WEAPON MODS
-- =============================================
local function applyWeaponMods()
    pcall(function()
        local char = player.Character
        if not char then return end
        
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                if Config.infiniteAmmo then
                    local ammo = tool:FindFirstChild("Ammo") or tool:FindFirstChild("CurrentAmmo") or tool:FindFirstChild("Bullets")
                    if ammo then
                        if ammo:IsA("NumberValue") then ammo.Value = 9999 end
                        if ammo:IsA("IntValue") then ammo.Value = 9999 end
                    end
                end
                
                if Config.rapidFire then
                    tool:FindFirstChild("AnimationController") and pcall(function()
                        tool.AnimationController:FindFirstChild("Fire").TimePosition = 0
                    end)
                end
            end
        end
    end)
end

-- =============================================
-- ESP MEJORADO
-- =============================================
local colorMap = {
    Lime = Color3.fromRGB(0, 255, 0), Red = Color3.fromRGB(255, 0, 0),
    Blue = Color3.fromRGB(0, 100, 255), Yellow = Color3.fromRGB(255, 255, 0),
    Pink = Color3.fromRGB(255, 0, 255)
}

local function getESPColor()
    return colorMap[Config.espColor] or colorMap.Lime
end

local function createESP(plr)
    if State.espObjects[plr] then return end
    State.espObjects[plr] = {
        Box = Drawing.new("Square"), Name = Drawing.new("Text"),
        Distance = Drawing.new("Text"), Health = Drawing.new("Square"),
        Tracer = Drawing.new("Line")
    }
    local esp = State.espObjects[plr]
    esp.Box.Thickness = 1.5; esp.Box.Filled = false
    esp.Name.Size = 12; esp.Name.Center = true; esp.Name.Outline = true
    esp.Distance.Size = 10; esp.Distance.Center = true
    esp.Health.Filled = true
    esp.Tracer.Thickness = 1
end

local function updateESP()
    if not Config.wallhack then
        for _, esp in pairs(State.espObjects) do
            for _, obj in pairs(esp) do obj.Visible = false end
        end
        return
    end
    
    local viewport = camera.ViewportSize
    local center = Vector2.new(viewport.X/2, viewport.Y/2)
    local espColor = getESPColor()
    
    for plr, esp in pairs(State.espObjects) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local root = plr.Character.HumanoidRootPart
            local humanoid = plr.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local pos, onScreen = camera:WorldToViewportPoint(root.Position)
                
                if onScreen then
                    local top = camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3.2, 0))
                    local bottom = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2.8, 0))
                    local height = bottom.Y - top.Y
                    local width = height * 0.6
                    local x = pos.X - width/2
                    local y = top.Y
                    
                    if Config.espBox then
                        esp.Box.Size = Vector2.new(width, height)
                        esp.Box.Position = Vector2.new(x, y)
                        esp.Box.Color = espColor
                        esp.Box.Visible = true
                    end
                    
                    if Config.espTracer then
                        esp.Tracer.From = center
                        esp.Tracer.To = Vector2.new(pos.X, pos.Y)
                        esp.Tracer.Color = espColor
                        esp.Tracer.Visible = true
                    end
                    
                    if Config.showNames then
                        esp.Name.Text = plr.Name
                        esp.Name.Position = Vector2.new(pos.X, y - 18)
                        esp.Name.Color = espColor
                        esp.Name.Visible = true
                    end
                    
                    if Config.showDistance then
                        local dist = math.floor((player.Character.HumanoidRootPart.Position - root.Position).Magnitude)
                        esp.Distance.Text = dist .. "m"
                        esp.Distance.Position = Vector2.new(pos.X, y + height + 6)
                        esp.Distance.Color = Color3.new(1, 1, 1)
                        esp.Distance.Visible = true
                    end
                    
                    if Config.showHealth then
                        local healthPercent = humanoid.Health / humanoid.MaxHealth
                        esp.Health.Size = Vector2.new(3.5, height * healthPercent)
                        esp.Health.Position = Vector2.new(x - 9, y + height - (height * healthPercent))
                        esp.Health.Color = Color3.fromRGB(255, 255 * (1 - healthPercent), 80)
                        esp.Health.Visible = true
                    end
                else
                    for _, obj in pairs(esp) do obj.Visible = false end
                end
            else
                for _, obj in pairs(esp) do obj.Visible = false end
            end
        end
    end
end

-- =============================================
-- AIMBOT + KILL ALL
-- =============================================
local function getClosestTarget()
    local closest, minDist = nil, Config.aimFOV
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local root = p.Character.HumanoidRootPart
            local humanoid = p.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local screenPos, onScreen = camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closest = root
                    end
                end
            end
        end
    end
    return closest
end

-- Kill All (Tecla X)
UIS.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.X then
        local killed = 0
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("Humanoid") then
                local humanoid = p.Character.Humanoid
                if humanoid.Health > 0 then
                    humanoid.Health = 0
                    killed = killed + 1
                end
            end
        end
        notify("💀 Eliminados: " .. killed .. " jugadores")
    end
    
    -- Fly toggle (Shift + F)
    if input.KeyCode == Enum.KeyCode.F and UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
        Config.fly = not Config.fly
        notify("✈️ Fly: " .. (Config.fly and "ON" or "OFF"))
    end
end)

-- =============================================
-- FLY SYSTEM
-- =============================================
local function setupFly()
    pcall(function()
        local char = player.Character
        if char and Config.fly then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local humanoid = char:FindFirstChild("Humanoid")
            if hrp and humanoid then
                humanoid.PlatformStand = true
                if not State.flyBV then
                    State.flyBV = Instance.new("BodyVelocity")
                    State.flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                end
                State.flyBV.Parent = hrp
                
                local moveDir = Vector3.new()
                if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camera.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camera.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camera.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camera.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
                
                State.flyBV.Velocity = moveDir.Unit * Config.flySpeed
            end
        elseif char and State.flyBV then
            State.flyBV:Destroy()
            State.flyBV = nil
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then humanoid.PlatformStand = false end
        end
    end)
end

-- =============================================
-- AUTO FARM
-- =============================================
local function autoFarm()
    if not Config.autoFarm then return end
    
    pcall(function()
        local closest = nil
        local minDist = 60
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local humanoid = p.Character:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    local dist = (player.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closest = p
                    end
                end
            end
        end
        if closest then
            mouse.Hit = CFrame.new(closest.Character.HumanoidRootPart.Position)
            if Config.autoShoot then
                mouse1press()
                task.wait(Config.autoClickDelay)
                mouse1release()
            end
        end
    end)
end

-- =============================================
-- GUI MOVIBLE Y REDIMENSIONABLE
-- =============================================
local gui = Instance.new("ScreenGui")
gui.Name = "SharkHubV4"
gui.ResetOnSpawn = false
gui.Parent = player.PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 380, 0, 520)
mainFrame.Position = UDim2.new(0.5, -190, 0.5, -260)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BackgroundTransparency = 0.08
mainFrame.Parent = gui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", mainFrame).Thickness = 1

-- Barra de título (para mover la ventana)
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
titleBar.Parent = mainFrame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.7, 0, 1, 0)
title.BackgroundTransparency = 1
title.Text = "🦈 SHARK HUB V4"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Position = UDim2.new(0.02, 0, 0, 0)
title.Parent = titleBar

-- Botones de ventana
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -80, 0, 5)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
minimizeBtn.Text = "−"
minimizeBtn.TextColor3 = Color3.new(1, 1, 1)
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 20
minimizeBtn.Parent = titleBar
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(1, 0)

local resizeBtn = Instance.new("TextButton")
resizeBtn.Size = UDim2.new(0, 30, 0, 30)
resizeBtn.Position = UDim2.new(1, -40, 0, 5)
resizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
resizeBtn.Text = "□"
resizeBtn.TextColor3 = Color3.new(1, 1, 1)
resizeBtn.Font = Enum.Font.GothamBold
resizeBtn.TextSize = 20
resizeBtn.Parent = titleBar
Instance.new("UICorner", resizeBtn).CornerRadius = UDim.new(1, 0)

-- Pestañas
local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(1, 0, 0, 35)
tabFrame.Position = UDim2.new(0, 0, 0, 40)
tabFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
tabFrame.Parent = mainFrame

local tabs = {"Main", "ESP", "Weapons", "Settings"}
local tabButtons = {}

for i, tabName in ipairs(tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.25, 0, 1, 0)
    btn.Position = UDim2.new((i-1)*0.25, 0, 0, 0)
    btn.BackgroundColor3 = i == 1 and Color3.fromRGB(0, 120, 200) or Color3.fromRGB(40, 40, 50)
    btn.Text = tabName
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.Parent = tabFrame
    tabButtons[tabName] = btn
end

-- Contenedor de contenido
local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Size = UDim2.new(1, 0, 1, -75)
contentFrame.Position = UDim2.new(0, 0, 0, 75)
contentFrame.BackgroundTransparency = 1
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
contentFrame.ScrollBarThickness = 4
contentFrame.Parent = mainFrame

-- =============================================
-- FUNCIÓN PARA CREAR BOTONES
-- =============================================
local function createToggle(parent, y, text, configKey, desc)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 38)
    btn.Position = UDim2.new(0.05, 0, 0, y)
    btn.BackgroundColor3 = Config[configKey] and Color3.fromRGB(0, 160, 90) or Color3.fromRGB(50, 50, 70)
    btn.Text = (Config[configKey] and "✅ " or "⬜ ") .. text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    if desc then
        local tooltip = Instance.new("TextLabel")
        tooltip.Size = UDim2.new(1, 0, 0, 20)
        tooltip.Position = UDim2.new(0, 0, 1, 2)
        tooltip.BackgroundTransparency = 1
        tooltip.Text = desc
        tooltip.TextColor3 = Color3.fromRGB(150, 150, 150)
        tooltip.Font = Enum.Font.Gotham
        tooltip.TextSize = 10
        tooltip.Parent = btn
    end
    
    btn.MouseButton1Click:Connect(function()
        Config[configKey] = not Config[configKey]
        btn.BackgroundColor3 = Config[configKey] and Color3.fromRGB(0, 160, 90) or Color3.fromRGB(50, 50, 70)
        btn.Text = (Config[configKey] and "✅ " or "⬜ ") .. text
        notify(text .. ": " .. (Config[configKey] and "ON" or "OFF"))
    end)
    
    return btn
end

local function createSlider(parent, y, text, configKey, minVal, maxVal, step, desc)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.9, 0, 0, 55)
    frame.Position = UDim2.new(0.05, 0, 0, y)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    frame.BackgroundTransparency = 0.5
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. tostring(Config[configKey])
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.Parent = frame
    
    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(1, -20, 0, 4)
    slider.Position = UDim2.new(0, 10, 0, 30)
    slider.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
    slider.Parent = frame
    Instance.new("UICorner", slider).CornerRadius = UDim.new(1, 0)
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((Config[configKey] - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
    fill.Parent = slider
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    
    local handle = Instance.new("TextButton")
    handle.Size = UDim2.new(0, 12, 0, 12)
    handle.Position = UDim2.new((Config[configKey] - minVal) / (maxVal - minVal), -6, 0.5, -6)
    handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    handle.Text = ""
    handle.Parent = slider
    Instance.new("UICorner", handle).CornerRadius = UDim.new(1, 0)
    
    local dragging = false
    handle.MouseButton1Down:Connect(function()
        dragging = true
        while dragging and handle.Parent do
            local mouseX = mouse.X - slider.AbsolutePosition.X
            local percent = math.clamp(mouseX / slider.AbsoluteSize.X, 0, 1)
            local newVal = minVal + (maxVal - minVal) * percent
            newVal = math.floor(newVal / step) * step
            Config[configKey] = math.clamp(newVal, minVal, maxVal)
            fill.Size = UDim2.new(percent, 0, 1, 0)
            handle.Position = UDim2.new(percent, -6, 0.5, -6)
            label.Text = text .. ": " .. tostring(Config[configKey])
            task.wait()
        end
    end)
    
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    return frame
end

-- =============================================
-- CONTENIDO DE PESTAÑAS
-- =============================================
local function switchTab(tabName)
    for _, btn in pairs(tabButtons) do
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    end
    tabButtons[tabName].BackgroundColor3 = Color3.fromRGB(0, 120, 200)
    
    for _, child in ipairs(contentFrame:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local y = 5
    
    if tabName == "Main" then
        createToggle(contentFrame, y, "🔫 AIMBOT (Click derecho)", "aimbot", "Apunta automáticamente")
        y = y + 45
        createToggle(contentFrame, y, "🎯 TRIGGER BOT", "triggerbot", "Dispara al ver enemigo")
        y = y + 45
        createToggle(contentFrame, y, "🛡️ GODMODE", "godmode", "Invencible")
        y = y + 45
        createToggle(contentFrame, y, "📏 HITBOX EXPANDER", "hitboxExpander", "Aumenta hitbox")
        y = y + 45
        createToggle(contentFrame, y, "🤖 AUTO FARM", "autoFarm", "Farmea kills")
        y = y + 45
        createToggle(contentFrame, y, "⚡ AUTO SHOOT", "autoShoot", "Dispara automático")
        y = y + 45
        createSlider(contentFrame, y, "Fly Speed", "flySpeed", 30, 200, 5, "Velocidad de vuelo")
        y = y + 65
        createSlider(contentFrame, y, "Auto Click Delay", "autoClickDelay", 0.05, 0.5, 0.05, "Delay entre disparos")
        contentFrame.CanvasSize = UDim2.new(0, 0, 0, y + 10)
        
    elseif tabName == "ESP" then
        createToggle(contentFrame, y, "👁️ WALLHACK", "wallhack")
        y = y + 45
        createToggle(contentFrame, y, "📛 MOSTRAR NOMBRES", "showNames")
        y = y + 45
        createToggle(contentFrame, y, "📏 MOSTRAR DISTANCIA", "showDistance")
        y = y + 45
        createToggle(contentFrame, y, "❤️ MOSTRAR VIDA", "showHealth")
        y = y + 45
        createToggle(contentFrame, y, "📦 MOSTRAR CAJA", "espBox")
        y = y + 45
        createToggle(contentFrame, y, "🔍 MOSTRAR TRAZADOR", "espTracer")
        y = y + 45
        
        -- Selector de color
        local colorFrame = Instance.new("Frame")
        colorFrame.Size = UDim2.new(0.9, 0, 0, 40)
        colorFrame.Position = UDim2.new(0.05, 0, 0, y)
        colorFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        colorFrame.Parent = contentFrame
        Instance.new("UICorner", colorFrame).CornerRadius = UDim.new(0, 6)
        
        local colorLabel = Instance.new("TextLabel")
        colorLabel.Size = UDim2.new(0.4, 0, 1, 0)
        colorLabel.BackgroundTransparency = 1
        colorLabel.Text = "🎨 ESP Color:"
        colorLabel.TextColor3 = Color3.new(1, 1, 1)
        colorLabel.Font = Enum.Font.Gotham
        colorLabel.TextSize = 12
        colorLabel.Parent = colorFrame
        
        local colorDropdown = Instance.new("TextButton")
        colorDropdown.Size = UDim2.new(0.5, 0, 0.7, 0)
        colorDropdown.Position = UDim2.new(0.48, 0, 0.15, 0)
        colorDropdown.BackgroundColor3 = getESPColor()
        colorDropdown.Text = Config.espColor
        colorDropdown.TextColor3 = Color3.new(1, 1, 1)
        colorDropdown.Font = Enum.Font.GothamSemibold
        colorDropdown.TextSize = 12
        colorDropdown.Parent = colorFrame
        Instance.new("UICorner", colorDropdown).CornerRadius = UDim.new(0, 5)
        
        colorDropdown.MouseButton1Click:Connect(function()
            local colors = {"Lime", "Red", "Blue", "Yellow", "Pink"}
            local currentIndex = table.find(colors, Config.espColor) or 1
            local nextIndex = currentIndex % #colors + 1
            Config.espColor = colors[nextIndex]
            colorDropdown.Text = Config.espColor
            colorDropdown.BackgroundColor3 = getESPColor()
        end)
        
        y = y + 50
        createSlider(contentFrame, y, "Aimbot FOV", "aimFOV", 50, 300, 10, "Campo de visión del aimbot")
        contentFrame.CanvasSize = UDim2.new(0, 0, 0, y + 70)
        
    elseif tabName == "Weapons" then
        createToggle(contentFrame, y, "🔓 UNLOCK ALL WEAPONS", "unlockAllWeapons", "Desbloquea permanentemente")
        y = y + 45
        createToggle(contentFrame, y, "🎨 UNLOCK ALL SKINS", "unlockAllSkins")
        y = y + 45
        createToggle(contentFrame, y, "🎫 UNLOCK BATTLE PASS", "unlockBattlePass")
        y = y + 45
        createToggle(contentFrame, y, "💎 INFINITE AMMO", "infiniteAmmo")
        y = y + 45
        createToggle(contentFrame, y, "🔫 NO RECOIL", "noRecoil")
        y = y + 45
        createToggle(contentFrame, y, "⚡ RAPID FIRE", "rapidFire")
        contentFrame.CanvasSize = UDim2.new(0, 0, 0, y + 20)
        
    elseif tabName == "Settings" then
        local infoFrame = Instance.new("TextLabel")
        infoFrame.Size = UDim2.new(0.9, 0, 0, 100)
        infoFrame.Position = UDim2.new(0.05, 0, 0
