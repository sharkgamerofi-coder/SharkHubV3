SHARK HUB ULTIMATE V3
    Compatible con: Madium, Ronix, Solara, Delta, Fluxus, Xeno, Velocity
    Funciones: Fly, Noclip, Aimbot (Click Derecho + Tecla E), Silent Aim, Rage Bot, ESP
    Abrir: RIGHT SHIFT
    Debug: 3 clics en el título
--]]
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualInput = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local playerGui = player:WaitForChild("PlayerGui")
-- Detectar executor (solo visual)
local executorName = "Unknown"
pcall(function()
    executorName = (syn and "Synapse") or (krnl and "KRNL") or (fluxus and "Fluxus") or
                   (delta and "Delta") or (velocity and "Velocity") or (ronix and "Ronix") or
                   (solara and "Solara") or (madium and "Madium") or (getexecutorname and getexecutorname()) or "Universal"
end)
-- Limpiar GUI anterior
local oldGui = playerGui:FindFirstChild("SharkHub")
if oldGui then oldGui:Destroy() end
--====================================================--
-- ESTADOS
--====================================================--
local state = {
    flyEnabled = false,
    flySpeed = 80,
    noclipEnabled = false,
    aimbotEnabled = false,
    aimbotEEnabled = false,
    aimbotFOV = 200,
    aimbotSmoothing = 0.25,
    aimPart = "Head",
    aimbotKey = "Click Derecho",
    aimbotKeyCode = Enum.UserInputType.MouseButton2,
    aimbotMode = "Holding",
    silentAimEnabled = false,
    ragebotEnabled = false,
    espEnabled = false,
    espMaxDistance = 300,
    espShowHealth = true,
    espShowLoadout = true,
    espShowDistance = true,
}
-- Variables del sistema
local flying = false
local rageCooldown = false
local cam = workspace.CurrentCamera
local aiming = false
local lockOn = false
local targetHead = nil
local originalCollisions = {}
local panelVisible = true
local espObjects = {}
local currentCategory = "Aimbot"
local currentCFrame = cam.CFrame
local fovCircle = nil
-- Opciones de dropdown
local aimKeyOptions = {"Click Derecho", "Click Izquierdo", "Tecla F", "Tecla C", "Tecla X", "Tecla Q", "Tecla E"}
local aimKeyMap = {
    ["Click Derecho"] = Enum.UserInputType.MouseButton2,
    ["Click Izquierdo"] = Enum.UserInputType.MouseButton1,
    ["Tecla F"] = Enum.KeyCode.F,
    ["Tecla C"] = Enum.KeyCode.C,
    ["Tecla X"] = Enum.KeyCode.X,
    ["Tecla Q"] = Enum.KeyCode.Q,
    ["Tecla E"] = Enum.KeyCode.E,
}
local aimPartOptions = {"Head", "HumanoidRootPart", "Random"}
local aimModeOptions = {"Holding", "One-Press"}
--====================================================--
-- UTILIDADES
--====================================================--
local function safeGetChar() return player.Character end
local function safeGetHum()
    local char = safeGetChar()
    return char and char:FindFirstChildOfClass("Humanoid")
end
local function safeGetRoot()
    local char = safeGetChar()
    return char and char:FindFirstChild("HumanoidRootPart")
end
local function getEnemyWeapon(character)
    for _, child in pairs(character:GetChildren()) do
        if child:IsA("Tool") then return child.Name end
    end
    return ""
end
local function getTargetPartWithPosition(character)
    local part = nil
    local pos = nil
   
    if state.aimPart == "Head" then
        part = character:FindFirstChild("Head")
        if part then pos = part.Position - Vector3.new(0, 0.15, 0) end
    elseif state.aimPart == "HumanoidRootPart" then
        part = character:FindFirstChild("HumanoidRootPart")
        if part then pos = part.Position end
    elseif state.aimPart == "Random" then
        local parts = {"Head", "HumanoidRootPart", "Torso", "UpperTorso"}
        for _, name in pairs(parts) do
            part = character:FindFirstChild(name)
            if part then break end
        end
        if part then pos = part.Position end
    end
   
    if not part then
        part = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
        if part then pos = part.Position end
    end
   
    return part, pos
end
local function getClosestEnemy()
    local closest = nil
    local closestDist = state.aimbotFOV
    local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
   
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then
            local char = p.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local _, targetPos = getTargetPartWithPosition(char)
                if hum and hum.Health > 0 and targetPos then
                    local screenPos, onScreen = cam:WorldToScreenPoint(targetPos)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closest = {
                                player = p,
                                character = char,
                                position = targetPos,
                                humanoid = hum,
                            }
                        end
                    end
                end
            end
        end
    end
    return closest
end
local function findNearestHead()
    local closest = nil
    local closestDist = state.aimbotFOV
    local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
   
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local head = p.Character:FindFirstChild("Head")
            if head then
                local screenPos, onScreen = cam:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closest = head
                    end
                end
            end
        end
    end
    return closest
end
--====================================================--
-- AIMBOTS
--====================================================--
local function updateAimbot()
    if not state.aimbotEnabled or not aiming then return end
   
    local enemy = getClosestEnemy()
    if not enemy or not enemy.position then return end
   
    local newCFrame = CFrame.new(cam.CFrame.Position, enemy.position)
    local smooth = state.aimbotSmoothing
   
    if smooth > 0 then
        currentCFrame = currentCFrame:Lerp(newCFrame, smooth)
        cam.CFrame = currentCFrame
    else
        cam.CFrame = newCFrame
        currentCFrame = newCFrame
    end
end
local function updateAimbotE()
    if not state.aimbotEEnabled or not lockOn then return end
   
    if targetHead and targetHead.Parent then
        local targetPos = targetHead.Position - Vector3.new(0, 0.15, 0)
        local newCFrame = CFrame.new(cam.CFrame.Position, targetPos)
        local smooth = state.aimbotSmoothing
       
        if smooth > 0 then
            currentCFrame = currentCFrame:Lerp(newCFrame, smooth)
            cam.CFrame = currentCFrame
        else
            cam.CFrame = newCFrame
            currentCFrame = newCFrame
        end
    else
        targetHead = findNearestHead()
    end
end
local function updateSilentAim()
    if not state.silentAimEnabled then return end
   
    local enemy = getClosestEnemy()
    if not enemy or not enemy.character then return end
   
    local _, pos = getTargetPartWithPosition(enemy.character)
    if not pos then return end
   
    pcall(function()
        mouse.TargetFilter = enemy.character
        mouse.Hit = CFrame.new(pos)
    end)
end
local function updateRagebot()
    if not state.ragebotEnabled or rageCooldown then return end
   
    local enemy = getClosestEnemy()
    if not enemy or not enemy.position then return end
   
    rageCooldown = true
    local newCFrame = CFrame.new(cam.CFrame.Position, enemy.position)
    cam.CFrame = newCFrame
    currentCFrame = newCFrame
   
    task.wait(0.05)
    pcall(function()
        VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.05)
        VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end)
   
    task.wait(0.4)
    rageCooldown = false
end
--====================================================--
-- MOVIMIENTO
--====================================================--
local function updateFly()
    local root = safeGetRoot()
    if not root then return end
   
    if state.flyEnabled and not flying then
        flying = true
        local hum = safeGetHum()
        if hum then hum.PlatformStand = true end
        return
    end
   
    if not state.flyEnabled and flying then
        flying = false
        local hum = safeGetHum()
        if hum then hum.PlatformStand = false end
        return
    end
   
    if not state.flyEnabled then return end
   
    local move = Vector3.zero
    local camCF = workspace.CurrentCamera.CFrame
   
    if UIS:IsKeyDown(Enum.KeyCode.W) then move += camCF.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.S) then move -= camCF.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.A) then move -= camCF.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.D) then move += camCF.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0, 1, 0) end
   
    if move.Magnitude > 0 then
        root.AssemblyLinearVelocity = move.Unit * state.flySpeed
    else
        root.AssemblyLinearVelocity = Vector3.zero
    end
end
local function updateNoclip()
    local char = player.Character
    if not char then return end
   
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if state.noclipEnabled then
                if originalCollisions[part] == nil then
                    originalCollisions[part] = part.CanCollide
                end
                part.CanCollide = false
            else
                local orig = originalCollisions[part]
                if orig ~= nil then
                    part.CanCollide = orig
                end
            end
        end
    end
end
--====================================================--
-- ESP
--====================================================--
local function updateESP()
    if not state.espEnabled then
        for _, obj in pairs(espObjects) do
            pcall(function() obj:Destroy() end)
        end
        espObjects = {}
        return
    end
   
    local myRoot = safeGetRoot()
    if not myRoot then return end
   
    for *, p in pairs(Players:GetPlayers()) do
        if p ~= player then
            local char = p.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
                if hum and hum.Health > 0 and rootPart then
                    local dist = (myRoot.Position - rootPart.Position).Magnitude
                    if dist <= state.espMaxDistance then
                        local esp = espObjects[p]
                        if not esp then
                            local bill = Instance.new("BillboardGui")
                            bill.Name = "ESP*" .. p.Name
                            bill.Size = UDim2.new(0, 240, 0, 55)
                            bill.AlwaysOnTop = true
                            bill.Adornee = rootPart
                            bill.Parent = rootPart
                            bill.ResetOnSpawn = false
                           
                            local frame = Instance.new("Frame", bill)
                            frame.Size = UDim2.new(1, 0, 1, 0)
                            frame.BackgroundTransparency = 0.5
                            frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 5)
                           
                            local nameLbl = Instance.new("TextLabel", frame)
                            nameLbl.Size = UDim2.new(1, 0, 0.45, 0)
                            nameLbl.Position = UDim2.new(0, 0, 0, 0)
                            nameLbl.BackgroundTransparency = 1
                            nameLbl.Font = Enum.Font.GothamBold
                            nameLbl.TextSize = 12
                            nameLbl.TextXAlignment = Enum.TextXAlignment.Center
                           
                            local infoLbl = Instance.new("TextLabel", frame)
                            infoLbl.Size = UDim2.new(1, 0, 0.55, 0)
                            infoLbl.Position = UDim2.new(0, 0, 0.45, 0)
                            infoLbl.BackgroundTransparency = 1
                            infoLbl.Font = Enum.Font.Gotham
                            infoLbl.TextSize = 10
                            infoLbl.TextXAlignment = Enum.TextXAlignment.Center
                           
                            espObjects[p] = {billboard = bill, nameLabel = nameLbl, infoLabel = infoLbl}
                        end
                       
                        espObjects[p].billboard.Adornee = rootPart
                       
                        local hpPercent = hum.Health / hum.MaxHealth
                        local hpColor = Color3.fromRGB(255 - (255 * hpPercent), 255 * hpPercent, 0)
                       
                        local nameText = p.Name
                        if state.espShowHealth then
                            nameText = nameText .. " [" .. math.floor(hum.Health) .. " HP]"
                        end
                        espObjects[p].nameLabel.Text = nameText
                        espObjects[p].nameLabel.TextColor3 = hpColor
                       
                        local infoText = ""
                        if state.espShowDistance then infoText = math.floor(dist) .. "m" end
                        if state.espShowLoadout then
                            local weapon = getEnemyWeapon(char)
                            if weapon ~= "" then
                                infoText = infoText .. (infoText ~= "" and " | " or "") .. weapon
                            end
                        end
                        espObjects[p].infoLabel.Text = infoText ~= "" and infoText or "⚔️"
                    elseif espObjects[p] then
                        pcall(function() espObjects[p].billboard:Destroy() end)
                        espObjects[p] = nil
                    end
                elseif espObjects[p] then
                    pcall(function() espObjects[p].billboard:Destroy() end)
                    espObjects[p] = nil
                end
            elseif espObjects[p] then
                pcall(function() espObjects[p].billboard:Destroy() end)
                espObjects[p] = nil
            end
        end
    end
end
--====================================================--
-- FOV CIRCLE
--====================================================--
local function createFOVCircle()
    if fovCircle then fovCircle:Destroy() end
    if not state.aimbotEnabled and not state.aimbotEEnabled then return end
   
    fovCircle = Instance.new("Frame")
    fovCircle.Size = UDim2.new(0, state.aimbotFOV * 2, 0, state.aimbotFOV * 2)
    fovCircle.Position = UDim2.new(0.5, -state.aimbotFOV, 0.5, -state.aimbotFOV)
    fovCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    fovCircle.BackgroundTransparency = 0.9
    fovCircle.BorderSizePixel = 2
    fovCircle.BorderColor3 = Color3.fromRGB(0, 255, 0)
    fovCircle.Parent = playerGui
    Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(1, 0)
end
local function updateFOVCircle()
    if fovCircle and (state.aimbotEnabled or state.aimbotEEnabled) then
        fovCircle.Size = UDim2.new(0, state.aimbotFOV * 2, 0, state.aimbotFOV * 2)
        fovCircle.Position = UDim2.new(0.5, -state.aimbotFOV, 0.5, -state.aimbotFOV)
    elseif fovCircle and not state.aimbotEnabled and not state.aimbotEEnabled then
        fovCircle:Destroy()
        fovCircle = nil
    end
end
--====================================================--
-- CONTROLES
--====================================================--
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
   
    -- Aimbot normal
    local isKey = false
    if typeof(state.aimbotKeyCode) == "EnumItem" then
        if state.aimbotKeyCode.EnumType == Enum.UserInputType then
            isKey = input.UserInputType == state.aimbotKeyCode
        else
            isKey = input.KeyCode == state.aimbotKeyCode
        end
    end
   
    if isKey and state.aimbotEnabled then
        if state.aimbotMode == "Holding" then
            aiming = true
        else
            state.aimbotActive = not state.aimbotActive
            aiming = state.aimbotActive
        end
    end
   
    -- Aimbot tecla E
    if input.KeyCode == Enum.KeyCode.E and state.aimbotEEnabled then
        lockOn = true
        targetHead = findNearestHead()
    end
   
    -- Abrir panel
    if input.KeyCode == Enum.KeyCode.RightShift then
        panelVisible = not panelVisible
        mainPanel.Visible = panelVisible
        floatingButton.Visible = not panelVisible
    end
end)
UIS.InputEnded:Connect(function(input, gp)
    if gp then return end
   
    local isKey = false
    if typeof(state.aimbotKeyCode) == "EnumItem" then
        if state.aimbotKeyCode.EnumType == Enum.UserInputType then
            isKey = input.UserInputType == state.aimbotKeyCode
        else
            isKey = input.KeyCode == state.aimbotKeyCode
        end
    end
   
    if isKey and state.aimbotMode == "Holding" then
        aiming = false
    end
   
    if input.KeyCode == Enum.KeyCode.E and state.aimbotEEnabled then
        lockOn = false
        targetHead = nil
    end
end)
--====================================================--
-- DESACTIVAR TODO
--====================================================--
local function disableAll()
    state.flyEnabled = false
    state.noclipEnabled = false
    state.aimbotEnabled = false
    state.aimbotEEnabled = false
    state.silentAimEnabled = false
    state.ragebotEnabled = false
    state.espEnabled = false
    aiming = false
    lockOn = false
    targetHead = nil
   
    if fovCircle then fovCircle:Destroy(); fovCircle = nil end
   
    if flying then
        flying = false
        local hum = safeGetHum()
        if hum then hum.PlatformStand = false end
    end
   
    for part, orig in pairs(originalCollisions) do
        if part and part.Parent then
            part.CanCollide = orig
        end
    end
    originalCollisions = {}
   
    for _, obj in pairs(espObjects) do
        pcall(function() obj.billboard:Destroy() end)
    end
    espObjects = {}
   
    pcall(function() mouse.TargetFilter = nil end)
end
--====================================================--
-- MAIN LOOP
--====================================================--
RunService.RenderStepped:Connect(function()
    pcall(function()
        updateFly()
        updateNoclip()
        updateAimbot()
        updateAimbotE()
        updateSilentAim()
        updateRagebot()
        updateESP()
        updateFOVCircle()
    end)
end)
player.CharacterAdded:Connect(function()
    task.wait(0.5)
    flying = false
    rageCooldown = false
    aiming = false
    lockOn = false
    targetHead = nil
    originalCollisions = {}
    currentCFrame = cam.CFrame
end)
--====================================================--
-- UI
--====================================================--
local gui = Instance.new("ScreenGui")
gui.Name = "SharkHub"
gui.ResetOnSpawn = false
gui.Parent = playerGui
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
-- Botón flotante
local floatingButton = Instance.new("TextButton")
floatingButton.Size = UDim2.new(0, 50, 0, 50)
floatingButton.Position = UDim2.new(0.5, -25, 0.02, 0)
floatingButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
floatingButton.Text = "S"
floatingButton.TextColor3 = Color3.fromRGB(255, 255, 255)
floatingButton.TextSize = 28
floatingButton.Font = Enum.Font.GothamBold
floatingButton.Parent = gui
Instance.new("UICorner", floatingButton).CornerRadius = UDim.new(1, 0)
floatingButton.Visible = false
-- Panel principal
local mainPanel = Instance.new("Frame")
mainPanel.Size = UDim2.new(0, 580, 0, 520)
mainPanel.Position = UDim2.new(0.5, -290, 0.5, -260)
mainPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
mainPanel.BackgroundTransparency = 0.05
mainPanel.BorderSizePixel = 0
mainPanel.Visible = true
mainPanel.Parent = gui
Instance.new("UICorner", mainPanel).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", mainPanel)
stroke.Color = Color3.fromRGB(0, 150, 255)
stroke.Thickness = 1.5
-- Barra de título
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainPanel
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)
local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -90, 1, 0)
titleText.Position = UDim2.new(0, 20, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "🦈 SHARK HUB ULTIMATE | " .. executorName
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 18
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar
-- Botones
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 35, 0, 35)
minBtn.Position = UDim2.new(1, -80, 0, 7.5)
minBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
minBtn.Text = "−"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.TextSize = 20
minBtn.Font = Enum.Font.GothamBold
minBtn.Parent = titleBar
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 8)
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 35, 0, 35)
closeBtn.Position = UDim2.new(1, -40, 0, 7.5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
-- Menú lateral
local menuPanel = Instance.new("Frame")
menuPanel.Size = UDim2.new(0, 150, 1, -50)
menuPanel.Position = UDim2.new(0, 0, 0, 50)
menuPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
menuPanel.BorderSizePixel = 0
menuPanel.Parent = mainPanel
local menuLayout = Instance.new("UIListLayout")
menuLayout.SortOrder = Enum.SortOrder.LayoutOrder
menuLayout.Padding = UDim.new(0, 12)
menuLayout.Parent = menuPanel
local menuPadding = Instance.new("UIPadding")
menuPadding.PaddingTop = UDim.new(0, 20)
menuPadding.PaddingLeft = UDim.new(0, 12)
menuPadding.PaddingRight = UDim.new(0, 12)
menuPadding.Parent = menuPanel
-- Contenido derecho
local contentPanel = Instance.new("ScrollingFrame")
contentPanel.Size = UDim2.new(1, -165, 1, -50)
contentPanel.Position = UDim2.new(0, 155, 0, 50)
contentPanel.BackgroundTransparency = 1
contentPanel.ScrollBarThickness = 5
contentPanel.ScrollBarImageColor3 = Color3.fromRGB(0, 150, 255)
contentPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
contentPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
contentPanel.Parent = mainPanel
local contentLayout = Instance.new("UIListLayout")
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 15)
contentLayout.Parent = contentPanel
local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0, 20)
contentPadding.PaddingLeft = UDim.new(0, 15)
contentPadding.PaddingRight = UDim.new(0, 15)
contentPadding.PaddingBottom = UDim.new(0, 20)
contentPadding.Parent = contentPanel
--====================================================--
-- UI FUNCTIONS
--====================================================--
local function clearContent()
    for _, child in pairs(contentPanel:GetChildren()) do
        if child ~= contentLayout and child ~= contentPadding then
            child:Destroy()
        end
    end
end
local function createSection(title)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, 38)
    section.BackgroundColor3 = Color3.fromRGB(0, 80, 150)
    section.Parent = contentPanel
    Instance.new("UICorner", section).CornerRadius = UDim.new(0, 6)
   
    local txt = Instance.new("TextLabel", section)
    txt.Size = UDim2.new(1, -15, 1, 0)
    txt.Position = UDim2.new(0, 15, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = title
    txt.TextColor3 = Color3.fromRGB(255, 255, 255)
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 14
    txt.TextXAlignment = Enum.TextXAlignment.Left
end
local function createToggle(text, stateName, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 45)
    btn.BackgroundColor3 = state[stateName] and (color or Color3.fromRGB(0, 120, 180)) or Color3.fromRGB(40, 40, 60)
    btn.Text = (state[stateName] and "✅ " or "⬜ ") .. text
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = contentPanel
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
   
    btn.MouseButton1Click:Connect(function()
        state[stateName] = not state[stateName]
        btn.BackgroundColor3 = state[stateName] and (color or Color3.fromRGB(0, 120, 180)) or Color3.fromRGB(40, 40, 60)
        btn.Text = (state[stateName] and "✅ " or "⬜ ") .. text
        if stateName == "aimbotEnabled" or stateName == "aimbotEEnabled" then
            createFOVCircle()
        end
    end)
end
local function createSlider(text, stateName, minVal, maxVal, step, suffix)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 75)
    container.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    container.Parent = contentPanel
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
   
    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(1, -10, 0, 25)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. string.format("%.1f", state[stateName]) .. suffix
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
   
    local minus = Instance.new("TextButton", container)
    minus.Size = UDim2.new(0, 50, 0, 32)
    minus.Position = UDim2.new(0, 10, 1, -42)
    minus.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
    minus.Text = "-"
    minus.TextColor3 = Color3.fromRGB(255, 100, 100)
    minus.Font = Enum.Font.GothamBold
    minus.TextSize = 20
   
    local plus = Instance.new("TextButton", container)
    plus.Size = UDim2.new(0, 50, 0, 32)
    plus.Position = UDim2.new(1, -60, 1, -42)
    plus.BackgroundColor3 = Color3.fromRGB(30, 80, 30)
    plus.Text = "+"
    plus.TextColor3 = Color3.fromRGB(100, 255, 100)
    plus.Font = Enum.Font.GothamBold
    plus.TextSize = 20
   
    local function update()
        label.Text = text .. ": " .. string.format("%.1f", state[stateName]) .. suffix
        if stateName == "aimbotFOV" then updateFOVCircle() end
    end
   
    minus.MouseButton1Click:Connect(function()
        state[stateName] = math.max(minVal, state[stateName] - step)
        update()
    end)
    plus.MouseButton1Click:Connect(function()
        state[stateName] = math.min(maxVal, state[stateName] + step)
        update()
    end)
end
local function createDropdown(text, stateName, options)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 45)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    btn.Text = "📁 " .. text .. ": " .. state[stateName]
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = contentPanel
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
   
    local dropdown = Instance.new("Frame")
    dropdown.Size = UDim2.new(1, 0, 0, #options * 38)
    dropdown.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    dropdown.Visible = false
    dropdown.Parent = contentPanel
    dropdown.ZIndex = 10
   
    local dl = Instance.new("UIListLayout")
    dl.SortOrder = Enum.SortOrder.LayoutOrder
    dl.Parent = dropdown
   
    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton", dropdown)
        optBtn.Size = UDim2.new(1, 0, 0, 38)
        optBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        optBtn.Text = " " .. opt
        optBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextSize = 12
        optBtn.TextXAlignment = Enum.TextXAlignment.Left
        optBtn.LayoutOrder = i
       
        optBtn.MouseButton1Click:Connect(function()
            state[stateName] = opt
            btn.Text = "📁 " .. text .. ": " .. opt
            dropdown.Visible = false
            if stateName == "aimbotKey" and aimKeyMap[opt] then
                state.aimbotKeyCode = aimKeyMap[opt]
            end
        end)
    end
   
    btn.MouseButton1Click:Connect(function()
        dropdown.Visible = not dropdown.Visible
        dropdown.LayoutOrder = btn.LayoutOrder + 0.5
    end)
end
--====================================================--
-- CONSTRUIR UI
--====================================================--
local function refreshContent()
    clearContent()
   
    if currentCategory == "Aimbot" then
        createSection("🎯 AIMBOT")
        createToggle("Aimbot (Click Derecho)", "aimbotEnabled", Color3.fromRGB(200, 50, 50))
        createToggle("Aimbot (Tecla E - Lock-on)", "aimbotEEnabled", Color3.fromRGB(100, 200, 100))
        createSlider("FOV", "aim
