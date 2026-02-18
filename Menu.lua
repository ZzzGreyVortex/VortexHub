local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer

local function getSafeUI()
    local success, result = pcall(function()
        return (gethui and gethui()) or game:GetService("CoreGui") or Player:WaitForChild("PlayerGui")
    end)
    return success and result or Player:WaitForChild("PlayerGui")
end

local TargetGUI = getSafeUI()
if TargetGUI:FindFirstChild("VortexHub") then TargetGUI.VortexHub:Destroy() end

-- State Variables
local espEnabled = false
local flyEnabled = false
local noclipEnabled = false
local farmingAuraEnabled = false
local antiFlipEnabled = false
local walkSpeedValue = 16
local flySpeedValue = 50
local vehicleBoost = 0
local auraRange = 30
local flyBV = nil

-- UI Setup
local screenGui = Instance.new("ScreenGui", TargetGUI)
screenGui.Name = "VortexHub"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 550, 0, 350)
mainFrame.Position = UDim2.new(0.5, -275, 0.5, -175)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Instance.new("UICorner", mainFrame)

-- Navigation Tabs
local tabContainer = Instance.new("Frame", mainFrame)
tabContainer.Size = UDim2.new(1, 0, 0, 45)
tabContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Instance.new("UICorner", tabContainer)

local combatPage = Instance.new("Frame", mainFrame)
combatPage.Size = UDim2.new(1, 0, 1, -45)
combatPage.Position = UDim2.new(0, 0, 0, 45)
combatPage.BackgroundTransparency = 1
combatPage.Visible = true

local farmingPage = Instance.new("Frame", mainFrame)
farmingPage.Size = UDim2.new(1, 0, 1, -45)
farmingPage.Position = UDim2.new(0, 0, 0, 45)
farmingPage.BackgroundTransparency = 1
farmingPage.Visible = false

local function createTabBtn(name, pos, targetPage)
    local btn = Instance.new("TextButton", tabContainer)
    btn.Size = UDim2.new(0, 100, 1, 0)
    btn.Position = pos
    btn.Text = name
    btn.BackgroundTransparency = 1
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.MouseButton1Click:Connect(function()
        combatPage.Visible = (targetPage == combatPage)
        farmingPage.Visible = (targetPage == farmingPage)
    end)
    return btn
end

createTabBtn("Combat", UDim2.new(0, 10, 0, 0), combatPage)
createTabBtn("Farming", UDim2.new(0, 120, 0, 0), farmingPage)

-- Helpers
local function createBtn(text, pos, color, parent)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0, 160, 0, 35)
    btn.Position = pos
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.TextColor3 = color
    btn.Font = Enum.Font.GothamBold
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
    Instance.new("UICorner", box)
    return box
end

-- [COMBAT PAGE]
local espBtn = createBtn("ESP: OFF", UDim2.new(0.05, 0, 0.1, 0), Color3.new(1, 0, 0), combatPage)
local flyBtn = createBtn("Fly: OFF", UDim2.new(0.05, 0, 0.3, 0), Color3.new(1, 0, 0), combatPage)
local noclipBtn = createBtn("Noclip: OFF", UDim2.new(0.05, 0, 0.5, 0), Color3.new(1, 0, 0), combatPage)
local walkInput = createInput("Walkspeed...", UDim2.new(0.4, 0, 0.1, 0), combatPage)
local flyInput = createInput("Fly Speed...", UDim2.new(0.4, 0, 0.3, 0), combatPage)
local applyCombat = createBtn("Apply Combat", UDim2.new(0.4, 0, 0.5, 0), Color3.new(1, 1, 1), combatPage)

-- [FARMING PAGE]
local auraBtn = createBtn("Aura: OFF", UDim2.new(0.05, 0, 0.1, 0), Color3.new(1, 0, 0), farmingPage)
local flipBtn = createBtn("Anti-Flip: OFF", UDim2.new(0.05, 0, 0.3, 0), Color3.new(1, 0, 0), farmingPage)
local rangeInput = createInput("Aura Range...", UDim2.new(0.4, 0, 0.1, 0), farmingPage)
local speedInput = createInput("Vehicle Boost...", UDim2.new(0.4, 0, 0.3, 0), farmingPage)
local applyFarming = createBtn("Apply Farming", UDim2.new(0.4, 0, 0.5, 0), Color3.new(1, 1, 1), farmingPage)

-- [ESP Logic]
local function updateESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local root = p.Character.HumanoidRootPart
            local highlight = root:FindFirstChild("VortexESP") or Instance.new("Highlight", root)
            highlight.Name = "VortexESP"
            highlight.Enabled = espEnabled
            highlight.FillColor = Color3.new(1, 0, 0)
        end
    end
end

-- [Farming Aura Logic]
task.spawn(function()
    while task.wait(0.15) do
        if farmingAuraEnabled then
            local char = Player.Character
            local seat = char and char:FindFirstChild("Humanoid") and char.Humanoid.SeatPart
            if seat and seat:IsA("VehicleSeat") then
                local vehicle = seat:FindFirstAncestorOfClass("Model")
                local parts = workspace:GetPartBoundsInRadius(seat.Position, auraRange)
                for _, obj in pairs(parts) do
                    if obj.Name:lower():find("dirt") or obj.Name:lower():find("tile") then
                        firetouchinterest(obj, seat, 0)
                        firetouchinterest(obj, seat, 1)
                    end
                end
            end
        end
    end
end)

-- [Main Physics Loop]
RunService.Stepped:Connect(function()
    local char = Player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hum = char.Humanoid
    local root = char.HumanoidRootPart

    hum.WalkSpeed = walkSpeedValue
    if espEnabled then updateESP() end

    -- Vehicle Physics
    if hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
        local seat = hum.SeatPart
        if seat.Throttle ~= 0 then
            seat.AssemblyLinearVelocity += seat.CFrame.LookVector * (seat.Throttle * vehicleBoost)
        end
        if antiFlipEnabled then
            local x, y, z = seat.CFrame:ToEulerAnglesXYZ()
            seat.CFrame = CFrame.new(seat.Position) * CFrame.Angles(0, y, 0)
            seat.AssemblyAngularVelocity = Vector3.new(0, seat.AssemblyAngularVelocity.Y, 0)
        end
    end

    -- Noclip / Fly
    if noclipEnabled or flyEnabled then
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end

    if flyEnabled then
        hum.PlatformStand = true
        if not flyBV then flyBV = Instance.new("BodyVelocity", root) end
        flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        local dir = hum.MoveDirection
        local up = UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or (UserInputService:IsKeyDown(Enum.KeyCode.Q) and -1 or 0)
        flyBV.Velocity = (dir * flySpeedValue) + Vector3.new(0, up * flySpeedValue, 0)
    else
        if flyBV then flyBV:Destroy() flyBV = nil end
        hum.PlatformStand = false
    end
end)

-- Button Listeners
espBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    espBtn.Text = "ESP: " .. (espEnabled and "ON" or "OFF")
    espBtn.TextColor3 = espEnabled and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
end)

flyBtn.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    flyBtn.Text = "Fly: " .. (flyEnabled and "ON" or "OFF")
    flyBtn.TextColor3 = flyEnabled and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
end)

noclipBtn.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    noclipBtn.Text = "Noclip: " .. (noclipEnabled and "ON" or "OFF")
    noclipBtn.TextColor3 = noclipEnabled and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
end)

auraBtn.MouseButton1Click:Connect(function()
    farmingAuraEnabled = not farmingAuraEnabled
    auraBtn.Text = "Aura: " .. (farmingAuraEnabled and "ON" or "OFF")
    auraBtn.TextColor3 = farmingAuraEnabled and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
end)

flipBtn.MouseButton1Click:Connect(function()
    antiFlipEnabled = not antiFlipEnabled
    flipBtn.Text = "Anti-Flip: " .. (antiFlipEnabled and "ON" or "OFF")
    flipBtn.TextColor3 = antiFlipEnabled and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
end)

applyCombat.MouseButton1Click:Connect(function()
    walkSpeedValue = tonumber(walkInput.Text) or 16
    flySpeedValue = tonumber(flyInput.Text) or 50
end)

applyFarming.MouseButton1Click:Connect(function()
    auraRange = tonumber(rangeInput.Text) or 30
    vehicleBoost = tonumber(speedInput.Text) or 0
end)

-- Simple Drag
local dragging, dragInput, dragStart, startPos
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true dragStart = input.Position startPos = mainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
