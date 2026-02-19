local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer

-- Master Cleanup
local function getSafeUI()
    local success, result = pcall(function()
        return (gethui and gethui()) or game:GetService("CoreGui") or Player:WaitForChild("PlayerGui")
    end)
    return success and result or Player:WaitForChild("PlayerGui")
end

local TargetGUI = getSafeUI()
if TargetGUI:FindFirstChild("VortexHub") then 
    TargetGUI.VortexHub:Destroy() 
    task.wait(0.1)
end

-- State Variables
local isScriptActive = true 
local espEnabled = true
local flyEnabled = false
local noclipEnabled = false
local walkSpeedValue = 16
local flySpeedValue = 20
local vehiclePowerValue = 0 
local pDropOpen = false
local lDropOpen = false
local flyBV = nil

-- UI Setup
local screenGui = Instance.new("ScreenGui", TargetGUI)
screenGui.Name = "VortexHub"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 550, 0, 350)
mainFrame.Position = UDim2.new(0.5, -275, 0.5, -175)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

-- Header Bar
local tabContainer = Instance.new("Frame", mainFrame)
tabContainer.Size = UDim2.new(1, 0, 0, 45)
tabContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
tabContainer.BorderSizePixel = 0
Instance.new("UICorner", tabContainer)

-- UI Helpers
local function createBtn(text, pos, color, parent, size)
    local btn = Instance.new("TextButton", parent)
    btn.Size = size or UDim2.new(0, 160, 0, 35)
    btn.Position = pos or UDim2.new(0,0,0,0)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.TextColor3 = color
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    Instance.new("UICorner", btn)
    return btn
end

local function createInput(placeholder, pos, parent)
    local box = Instance.new("TextBox", parent)
    box.Size = UDim2.new(0, 160, 0, 35)
    box.Position = pos
    box.PlaceholderText = placeholder
    box.Text = ""
    box.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    box.TextColor3 = Color3.new(1, 1, 1)
    box.Font = Enum.Font.Gotham
    Instance.new("UICorner", box)
    return box
end

local function clearAllESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then
            local hl = p.Character:FindFirstChild("VortexESP")
            if hl then hl:Destroy() end
        end
    end
end

-- KILL SWITCH
local function terminateScript()
    isScriptActive = false
    espEnabled = false
    clearAllESP()
    
    local char = Player.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = 16 hum.PlatformStand = false end
        for _, part in pairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = true end end
    end
    
    if flyBV then flyBV:Destroy() end
    task.wait(0.1)
    clearAllESP()
    screenGui:Destroy()
end

-- Header Controls
local combatTabBtn = createBtn("Combat", UDim2.new(0, 10, 0, 7), Color3.fromRGB(0, 255, 120), tabContainer, UDim2.new(0, 90, 0, 30))
local farmingTabBtn = createBtn("Farming", UDim2.new(0, 105, 0, 7), Color3.new(1, 1, 1), tabContainer, UDim2.new(0, 90, 0, 30))
local exitBtn = createBtn("EXIT", UDim2.new(1, -110, 0, 7), Color3.fromRGB(255, 60, 60), tabContainer, UDim2.new(0, 60, 0, 30))
local hideBtn = createBtn("X", UDim2.new(1, -40, 0, 7), Color3.new(1,1,1), tabContainer, UDim2.new(0, 30, 0, 30))
hideBtn.BackgroundTransparency = 1
exitBtn.MouseButton1Click:Connect(terminateScript)

-- Pages
local combatPage = Instance.new("Frame", mainFrame)
combatPage.Size = UDim2.new(1, 0, 1, -45)
combatPage.Position = UDim2.new(0, 0, 0, 45)
combatPage.BackgroundTransparency = 1

local farmingPage = Instance.new("Frame", mainFrame)
farmingPage.Size = UDim2.new(1, 0, 1, -45)
farmingPage.Position = UDim2.new(0, 0, 0, 45)
farmingPage.BackgroundTransparency = 1
farmingPage.Visible = false

-- Combat UI
local espBtn = createBtn("ESP: ON", UDim2.new(0.04, 0, 0.1, 0), Color3.fromRGB(0, 255, 120), combatPage)
local flyBtn = createBtn("Fly: OFF", UDim2.new(0.04, 0, 0.3, 0), Color3.fromRGB(255, 60, 60), combatPage)
local noclipBtn = createBtn("Noclip: OFF", UDim2.new(0.04, 0, 0.5, 0), Color3.fromRGB(255, 60, 60), combatPage)
local walkInput = createInput("Walk Speed...", UDim2.new(0.35, 0, 0.1, 0), combatPage)
local flyInput = createInput("Fly Speed...", UDim2.new(0.35, 0, 0.3, 0), combatPage)
local applyBtn = createBtn("Apply Settings", UDim2.new(0.35, 0, 0.5, 0), Color3.new(1,1,1), combatPage)

-- Teleports moved back to Combat
local pDropTitle = createBtn("Select Player ▽", UDim2.new(0.66, 0, 0.05, 0), Color3.new(1,1,1), combatPage)
local pScroll = Instance.new("ScrollingFrame", combatPage)
pScroll.Size = UDim2.new(0, 160, 0, 80) pScroll.Position = UDim2.new(0.66, 0, 0.2, 0)
pScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 20) pScroll.Visible = false pScroll.BorderSizePixel = 0
Instance.new("UIListLayout", pScroll).Padding = UDim.new(0, 2)

local lDropTitle = createBtn("Locations ▽", UDim2.new(0.66, 0, 0.55, 0), Color3.new(1,1,1), combatPage)
local lScroll = Instance.new("ScrollingFrame", combatPage)
lScroll.Size = UDim2.new(0, 160, 0, 80) lScroll.Position = UDim2.new(0.66, 0, 0.7, 0)
lScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 20) lScroll.Visible = false lScroll.BorderSizePixel = 0
Instance.new("UIListLayout", lScroll).Padding = UDim.new(0, 2)

-- Farming UI
local vehLabel = Instance.new("TextLabel", farmingPage)
vehLabel.Size = UDim2.new(0, 200, 0, 30)
vehLabel.Position = UDim2.new(0.04, 0, 0.05, 0)
vehLabel.Text = "VEHICLE FORCE BOOST"
vehLabel.TextColor3 = Color3.new(1,1,1)
vehLabel.BackgroundTransparency = 1
vehLabel.Font = Enum.Font.GothamBold

local vehInput = createInput("Power (e.g. 100)...", UDim2.new(0.04, 0, 0.15, 0), farmingPage)
local vehApplyBtn = createBtn("Apply Power", UDim2.new(0.04, 0, 0.28, 0), Color3.fromRGB(0, 180, 255), farmingPage)

vehApplyBtn.MouseButton1Click:Connect(function()
    vehiclePowerValue = tonumber(vehInput.Text) or 0
end)

-- MAIN PHYSICS LOOP
RunService.Stepped:Connect(function()
    if not isScriptActive then return end
    local char = Player.Character
    if char and char:FindFirstChild("Humanoid") then
        local hum = char.Humanoid
        hum.WalkSpeed = walkSpeedValue
        
        -- UPDATED VEHICLE FORCE LOGIC
        if hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
            local seat = hum.SeatPart
            if vehiclePowerValue > 0 and seat.Throttle ~= 0 then
                local root = seat:FindFirstAncestorOfClass("Model") and seat:FindFirstAncestorOfClass("Model").PrimaryPart or seat
                root.AssemblyLinearVelocity = root.CFrame.LookVector * (seat.Throttle * vehiclePowerValue)
            end
        end

        -- Movement Mods
        if noclipEnabled or flyEnabled then
            for _, part in pairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
        elseif char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CanCollide = true
        end

        if flyEnabled and char:FindFirstChild("HumanoidRootPart") then
            hum.PlatformStand = true
            if not flyBV or flyBV.Parent ~= char.HumanoidRootPart then
                flyBV = Instance.new("BodyVelocity", char.HumanoidRootPart)
                flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            end
            local up = UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or (UserInputService:IsKeyDown(Enum.KeyCode.Q) and -1 or 0)
            flyBV.Velocity = (hum.MoveDirection * flySpeedValue) + Vector3.new(0, up * flySpeedValue, 0)
            char.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
        elseif hum.PlatformStand then
            hum.PlatformStand = false
            if flyBV then flyBV:Destroy() flyBV = nil end
        end
    end
end)

-- ESP and List Updates
task.spawn(function()
    while task.wait(0.5) do
        if not isScriptActive then break end
        
        if pDropOpen and combatPage.Visible then
            for _, child in pairs(pScroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= Player then
                    local btn = createBtn(p.DisplayName, nil, Color3.new(1,1,1), pScroll, UDim2.new(1, 0, 0, 25))
                    btn.MouseButton1Click:Connect(function()
                        local myRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                        local targetRoot = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                        if myRoot and targetRoot then myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3) end
                    end)
                end
            end
            pScroll.CanvasSize = UDim2.new(0, 0, 0, #pScroll:GetChildren() * 27)
        end
        
        if espEnabled and isScriptActive then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= Player and p.Character and not p.Character:FindFirstChild("VortexESP") then
                    local hl = Instance.new("Highlight", p.Character)
                    hl.Name = "VortexESP"
                    hl.FillTransparency = 0.5
                    hl.FillColor = Color3.fromRGB(255, 0, 0)
                end
            end
        end
    end
end)

-- Event Connections
applyBtn.MouseButton1Click:Connect(function()
    walkSpeedValue = tonumber(walkInput.Text) or 16
    flySpeedValue = tonumber(flyInput.Text) or 20
end)

combatTabBtn.MouseButton1Click:Connect(function()
    combatPage.Visible = true farmingPage.Visible = false
    combatTabBtn.TextColor3 = Color3.fromRGB(0, 255, 120)
    farmingTabBtn.TextColor3 = Color3.new(1, 1, 1)
end)

farmingTabBtn.MouseButton1Click:Connect(function()
    farmingPage.Visible = true combatPage.Visible = false
    farmingTabBtn.TextColor3 = Color3.fromRGB(0, 180, 255)
    combatTabBtn.TextColor3 = Color3.new(1, 1, 1)
end)

espBtn.MouseButton1Click:Connect(function() 
    espEnabled = not espEnabled 
    espBtn.Text = "ESP: " .. (espEnabled and "ON" or "OFF")
    espBtn.TextColor3 = espEnabled and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)
    if not espEnabled then clearAllESP() end
end)

flyBtn.MouseButton1Click:Connect(function() 
    flyEnabled = not flyEnabled 
    flyBtn.Text = "Fly: " .. (flyEnabled and "ON" or "OFF")
    flyBtn.TextColor3 = flyEnabled and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)
end)

noclipBtn.MouseButton1Click:Connect(function() 
    noclipEnabled = not noclipEnabled 
    noclipBtn.Text = "Noclip: " .. (noclipEnabled and "ON" or "OFF")
    noclipBtn.TextColor3 = noclipEnabled and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)
end)

pDropTitle.MouseButton1Click:Connect(function() pDropOpen = not pDropOpen pScroll.Visible = pDropOpen end)
lDropTitle.MouseButton1Click:Connect(function()
    lDropOpen = not lDropOpen
    lScroll.Visible = lDropOpen
    if lDropOpen then
        for _, child in pairs(lScroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
        local added = {}
        for _, obj in pairs(workspace:GetDescendants()) do
            if (obj:IsA("BasePart") or obj:IsA("SpawnLocation")) and not added[obj.Name] then
                local n = obj.Name:lower()
                if n:find("shop") or n:find("store") or n:find("spawn") or n:find("bank") or n:find("npc") then
                    added[obj.Name] = true
                    local btn = createBtn(obj.Name, nil, Color3.fromRGB(0, 180, 255), lScroll, UDim2.new(1, 0, 0, 25))
                    btn.MouseButton1Click:Connect(function()
                        local myRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                        if myRoot then myRoot.CFrame = obj.CFrame + Vector3.new(0, 3, 0) end
                    end)
                end
            end
        end
    end
end)

-- Minimize Functionality
local openBtn = Instance.new("TextButton", screenGui)
openBtn.Size = UDim2.new(0, 50, 0, 50)
openBtn.Position = UDim2.new(0, 20, 0.5, -25)
openBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
openBtn.Text = "V"
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 25
openBtn.Visible = false
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 15)

hideBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false openBtn.Visible = true end)
openBtn.MouseButton1Click:Connect(function() mainFrame.Visible = true openBtn.Visible = false end)

-- Draggable logic
local function makeDraggable(gui)
    local dragging, dragInput, dragStart, startPos
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true dragStart = input.Position startPos = gui.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    gui.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
makeDraggable(mainFrame)
makeDraggable(openBtn)
