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

-- Navigation
local tabContainer = Instance.new("Frame", mainFrame)
tabContainer.Size = UDim2.new(1, 0, 0, 45)
tabContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Instance.new("UICorner", tabContainer)

local combatPage = Instance.new("Frame", mainFrame)
combatPage.Size = UDim2.new(1, 0, 1, -45)
combatPage.Position = UDim2.new(0, 0, 0, 45)
combatPage.BackgroundTransparency = 1

local farmingPage = Instance.new("Frame", mainFrame)
farmingPage.Size = UDim2.new(1, 0, 1, -45)
farmingPage.Position = UDim2.new(0, 0, 0, 45)
farmingPage.BackgroundTransparency = 1
farmingPage.Visible = false

-- Tab Switching
local function createTabBtn(name, pos, page)
    local btn = Instance.new("TextButton", tabContainer)
    btn.Size = UDim2.new(0, 100, 1, 0)
    btn.Position = pos
    btn.Text = name
    btn.BackgroundColor3 = Color3.new(0,0,0)
    btn.BackgroundTransparency = 1
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.MouseButton1Click:Connect(function()
        combatPage.Visible = (page == combatPage)
        farmingPage.Visible = (page == farmingPage)
    end)
    return btn
end

createTabBtn("Combat", UDim2.new(0, 10, 0, 0), combatPage)
createTabBtn("Farming", UDim2.new(0, 120, 0, 0), farmingPage)

-- Helpers
local function createBtn(text, pos, color, parent)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0, 150, 0, 35)
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
    box.Size = UDim2.new(0, 150, 0, 35)
    box.Position = pos
    box.PlaceholderText = placeholder
    box.Text = ""
    box.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    box.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", box)
    return box
end

-- [COMBAT ELEMENTS]
local espBtn = createBtn("ESP: OFF", UDim2.new(0.05, 0, 0.1, 0), Color3.new(1,0,0), combatPage)
local flyBtn = createBtn("Fly: OFF", UDim2.new(0.05, 0, 0.3, 0), Color3.new(1,0,0), combatPage)
local noclipBtn = createBtn("Noclip: OFF", UDim2.new(0.05, 0, 0.5, 0), Color3.new(1,0,0), combatPage)
local walkInput = createInput("Walkspeed...", UDim2.new(0.4, 0, 0.1, 0), combatPage)
local flyInput = createInput("Fly Speed...", UDim2.new(0.4, 0, 0.3, 0), combatPage)

-- [FARMING ELEMENTS]
local auraBtn = createBtn("Aura: OFF", UDim2.new(0.05, 0, 0.1, 0), Color3.new(1,0,0), farmingPage)
local flipBtn = createBtn("Anti-Flip: OFF", UDim2.new(0.05, 0, 0.3, 0), Color3.new(1,0,0), farmingPage)
local rangeInput = createInput("Aura Range...", UDim2.new(0.4, 0, 0.1, 0), farmingPage)
local speedInput = createInput("Vehicle Boost...", UDim2.new(0.4, 0, 0.3, 0), farmingPage)
local applyFarming = createBtn("Apply Settings", UDim2.new(0.7, 0, 0.1, 0), Color3.new(1,1,1), farmingPage)

--- [LOGIC: FARMING AURA] ---
task.spawn(function()
    while task.wait(0.1) do
        if farmingAuraEnabled then
            local char = Player.Character
            local seat = char and char:FindFirstChild("Humanoid") and char.Humanoid.SeatPart
            if seat and seat:IsA("VehicleSeat") then
                local vehicle = seat:FindFirstAncestorOfClass("Model")
                
                -- Target the plow specifically
                local plowParts = {}
                for _, p in pairs(vehicle:GetDescendants()) do
                    if p:IsA("BasePart") and (p.Name:lower():find("plow") or p.Name:lower():find("tool") or p.Name:lower():find("blade")) then
                        table.insert(plowParts, p)
                    end
                end
                if #plowParts == 0 then table.insert(plowParts, seat) end

                -- Modern, lag-free overlap check
                local params = OverlapParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = {vehicle, char}
                
                local parts = workspace:GetPartBoundsInRadius(seat.Position, auraRange, params)
                for _, obj in pairs(parts) do
                    if obj.Name:lower():find("dirt") or obj.Name:lower():find("tile") or obj.Name:lower():find("field") then
                        for _, tool in pairs(plowParts) do
                            firetouchinterest(obj, tool, 0)
                            firetouchinterest(obj, tool, 1)
                        end
                    end
                end
            end
        end
    end
end)

--- [LOGIC: PHYSICS & COMBAT] ---
RunService.Stepped:Connect(function()
    local char = Player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hum = char.Humanoid
    local root = char.HumanoidRootPart

    hum.WalkSpeed = walkSpeedValue

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

    -- Noclip
    if noclipEnabled or flyEnabled then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end

    -- Fly
    if flyEnabled then
        hum.PlatformStand = true
        if not flyBV then flyBV = Instance.new("BodyVelocity", root) end
        flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        local moveDir = hum.MoveDirection
        local up = UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or (UserInputService:IsKeyDown(Enum.KeyCode.Q) and -1 or 0)
        flyBV.Velocity = (moveDir * flySpeedValue) + Vector3.new(0, up * flySpeedValue, 0)
    else
        if flyBV then flyBV:Destroy() flyBV = nil end
        hum.PlatformStand = false
    end
end)

-- Button Listeners
auraBtn.MouseButton1Click:Connect(function()
    farmingAuraEnabled = not farmingAuraEnabled
    auraBtn.Text = "Aura: " .. (farmingAuraEnabled and "ON" or "OFF")
    auraBtn.TextColor3 = farmingAuraEnabled and Color3.new(0,1,0) or Color3.new(1,0,0)
end)

flyBtn.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    flyBtn.Text = "Fly: " .. (flyEnabled and "ON" or "OFF")
    flyBtn.TextColor3 = flyEnabled and Color3.new(0,1,0) or Color3.new(1,0,0)
end)

noclipBtn.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    noclipBtn.Text = "Noclip: " .. (noclipEnabled and "ON" or "OFF")
    noclipBtn.TextColor3 = noclipEnabled and Color3.new(0,1,0) or Color3.new(1,0,0)
end)

flipBtn.MouseButton1Click:Connect(function()
    antiFlipEnabled = not antiFlipEnabled
    flipBtn.Text = "Anti-Flip: " .. (antiFlipEnabled and "ON" or "OFF")
    flipBtn.TextColor3 = antiFlipEnabled and Color3.new(0,1,0) or Color3.new(1,0,0)
end)

applyFarming.MouseButton1Click:Connect(function()
    auraRange = tonumber(rangeInput.Text) or 30
    vehicleBoost = tonumber(speedInput.Text) or 0
    walkSpeedValue = tonumber(walkInput.Text) or 16
    flySpeedValue = tonumber(flyInput.Text) or 50
end)

-- Simple Draggable UI
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
