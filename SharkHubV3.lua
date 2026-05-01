local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualInput = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local cam = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

-- Solo usuarios autorizados
local allowed = {"sharknjd", "ryusenkai7", "sharkalt_3"}
local isAllowed = false
for _, name in ipairs(allowed) do
    if player.Name == name then isAllowed = true break end
end
if not isAllowed then return end

-- Estados
local state = {
    aimbot = false,
    silentAim = false,
    triggerbot = false,
    ragebot = false,
    wallhack = false,
    fly = false,
    noclip = false,
    noRecoil = false,
    rapidFire = false,
    infAmmo = false,
    unlockWeapons = false,
    unlockSkins = false,
    maxBattlePass = false,
    
    aimFOV = 180,
    aimSmooth = 0.22,
    flySpeed = 90,
}

local aiming = false
local currentCF = cam.CFrame
local espCache = {}

print("🦈 SharkHub cargado | Usuario autorizado")

-- ==================== FUNCIONES ====================
local function getClosestTarget()
    local closest, minDist = nil, state.aimFOV
    local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            local part = p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and part then
                local pos, onScreen = cam:WorldToScreenPoint(part.Position)
                if onScreen then
                    local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if d < minDist then
                        minDist = d
                        closest = part
                    end
                end
            end
        end
    end
    return closest
end

local function updateAimbot()
    if not state.aimbot or not aiming then return end
    local target = getClosestTarget()
    if target then
        local newCF = CFrame.new(cam.CFrame.Position, target.Position)
        currentCF = currentCF:Lerp(newCF, state.aimSmooth)
        cam.CFrame = currentCF
    end
end

local function updateSilentAim()
    if not state.silentAim then return end
    local target = getClosestTarget()
    if target then
        pcall(function()
            mouse.TargetFilter = target.Parent
            mouse.Hit = CFrame.new(target.Position)
        end)
    end
end

local function updateTriggerbot()
    if not state.triggerbot then return end
    local target = getClosestTarget()
    if target and mouse.Target and mouse.Target.Parent == target.Parent then
        pcall(function()
            VirtualInput:SendMouseButtonEvent(0,0,0,true,game,0)
            task.wait(0.03)
            VirtualInput:SendMouseButtonEvent(0,0,0,false,game,0)
        end)
    end
end

local function updateESP()
    if not state.wallhack then
        for _, v in pairs(espCache) do pcall(function() v:Destroy() end) end
        espCache = {}
        return
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Head")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
                if not espCache[p] then
                    local bill = Instance.new("BillboardGui")
                    bill.AlwaysOnTop = true
                    bill.Size = UDim2.new(0, 200, 0, 50)
                    bill.Adornee = root
                    bill.Parent = root

                    local label = Instance.new("TextLabel", bill)
                    label.BackgroundTransparency = 1
                    label.TextColor3 = Color3.fromRGB(0, 255, 140)
                    label.TextStrokeTransparency = 0.5
                    label.Font = Enum.Font.GothamBold
                    label.TextSize = 14
                    label.Size = UDim2.new(1,0,1,0)
                    espCache[p] = bill
                end

                local dist = player.Character and player.Character:FindFirstChild("HumanoidRootPart") and 
                            (player.Character.HumanoidRootPart.Position - root.Position).Magnitude or 0

                espCache[p].TextLabel.Text = string.format("%s\n%.0fm | %d HP", p.Name, dist, hum.Health)
            end
        end
    end
end

local function updateFly()
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if state.fly then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = true end

        local move = Vector3.zero
        local cf = cam.CFrame
        if UIS:IsKeyDown(Enum.KeyCode.W) then move += cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then move -= cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then move -= cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then move += cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end

        root.AssemblyLinearVelocity = move.Unit * state.flySpeed
    end
end

-- ==================== GUI - SharkHub ====================
local gui = Instance.new("ScreenGui")
gui.Name = "SharkHub"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 680, 0, 520)
mainFrame.Position = UDim2.new(0.5, -340, 0.5, -260)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
mainFrame.Parent = gui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 60)
titleBar.BackgroundColor3 = Color3.fromRGB(0, 110, 255)
titleBar.Parent = mainFrame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 16)

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, 0, 1, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "🦈 SharkHub"
titleText.TextColor3 = Color3.new(1,1,1)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 22
titleText.Parent = titleBar

local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Size = UDim2.new(1, -20, 1, -80)
contentFrame.Position = UDim2.new(0, 10, 0, 70)
contentFrame.BackgroundTransparency = 1
contentFrame.ScrollBarThickness = 6
contentFrame.Parent = mainFrame

local function createToggle(text, key)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 48)
    btn.BackgroundColor3 = state[key] and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(45, 45, 65)
    btn.Text = (state[key] and "✅ " or "⬜ ") .. text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 15
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = contentFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

    btn.MouseButton1Click:Connect(function()
        state[key] = not state[key]
        btn.BackgroundColor3 = state[key] and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(45, 45, 65)
        btn.Text = (state[key] and "✅ " or "⬜ ") .. text
    end)
end

-- Tabs
local function loadTab(tab)
    for _, child in pairs(contentFrame:GetChildren()) do child:Destroy() end

    if tab == "Combat" then
        createToggle("Aimbot (Tecla E)", "aimbot")
        createToggle("Silent Aim", "silentAim")
        createToggle("Trigger Bot", "triggerbot")
        createToggle("Rage Bot", "ragebot")

    elseif tab == "Visuals" then
        createToggle("Wallhack / ESP", "wallhack")

    elseif tab == "Movement" then
        createToggle("Fly", "fly")
        createToggle("Noclip", "noclip")

    elseif tab == "Unlockers" then
        createToggle("Unlock All Weapons", "unlockWeapons")
        createToggle("Unlock Skins", "unlockSkins")
        createToggle("Max Battle Pass", "maxBattlePass")
        createToggle("No Recoil + Rapid Fire", "noRecoil")
        createToggle("Infinite Ammo", "infAmmo")
    end
end

local tabList = {"Combat", "Visuals", "Movement", "Unlockers"}
for i, tabName in ipairs(tabList) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 155, 0, 40)
    btn.Position = UDim2.new(0, 20 + (i-1)*165, 0, 12)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    btn.Text = tabName
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15
    btn.Parent = mainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(function()
        loadTab(tabName)
    end)
end

loadTab("Combat")

-- Controles
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        mainFrame.Visible = not mainFrame.Visible
    end
    if input.KeyCode == Enum.KeyCode.E then
        aiming = not aiming
    end
end)

-- Main Loop
RunService.RenderStepped:Connect(function()
    pcall(function()
        updateAimbot()
        updateSilentAim()
        updateTriggerbot()
        updateESP()
        if state.fly then updateFly() end
    end)
end)

print("✅ SharkHub cargado correctamente")
