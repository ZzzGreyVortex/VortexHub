local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer

-- UI Safety
local function getSafeUI()
    local success, result = pcall(function()
        return (gethui and gethui()) or game:GetService("CoreGui") or Player:WaitForChild("PlayerGui")
    end)
    return success and result or Player:WaitForChild("PlayerGui")
end

local TargetGUI = getSafeUI()
if TargetGUI:FindFirstChild("VortexHub") then TargetGUI.VortexHub:Destroy() end

-- State
local espEnabled, flyEnabled, noclipEnabled = false, false, false
local farmingAuraEnabled, antiFlipEnabled = false, false
local walkSpeed, flySpeed, vehicleBoost = 16, 50, 0
local auraRange = 40
local flyBV = nil

-- UI Setup
local screenGui = Instance.new("ScreenGui", TargetGUI)
screenGui.Name = "VortexHub"
screenGui.ResetOnSpawn = false

local main = Instance.new("Frame", screenGui)
main.Size = UDim2.new(0, 500, 0, 350)
main.Position = UDim2.new(0.5, -250, 0.5, -175)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Instance.new("UICorner", main)

local tabs = Instance.new("Frame", main)
tabs.Size = UDim2.new(1, 0, 0, 40)
tabs.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Instance.new("UICorner", tabs)

local combatPage = Instance.new("Frame", main)
combatPage.Size = UDim2.new(1, 0, 1, -40)
combatPage.Position = UDim2.new(0, 0, 0, 40)
combatPage.BackgroundTransparency = 1

local farmingPage = Instance.new("Frame", main)
farmingPage.Size = UDim2.new(1, 0, 1, -40)
farmingPage.Position = UDim2.new(0, 0, 0, 40)
farmingPage.BackgroundTransparency = 1
farmingPage.Visible = false

-- UI Helpers
local function createBtn(text, pos, page)
    local btn = Instance.new("TextButton", page)
    btn.Size = UDim2.new(0, 140, 0, 35)
    btn.Position = pos
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.TextColor3 = Color3.new(1, 0, 0)
    btn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", btn)
    return btn
end

local function createInput(placeholder, pos, page)
    local box = Instance.new("TextBox", page)
    box.Size = UDim2.new(0, 140, 0, 35)
    box.Position = pos
    box.PlaceholderText = placeholder
    box.Text = ""
    box.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    box.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", box)
    return box
end

-- Tab Switch Buttons
local cTab = Instance.new("TextButton", tabs)
cTab.Size = UDim2.new(0, 100, 1, 0)
cTab.Text = "Combat"
cTab.BackgroundTransparency = 1
cTab.TextColor3 = Color3.new(1, 1, 1)
cTab.MouseButton1Click:Connect(function() combatPage.Visible = true farmingPage.Visible = false end)

local fTab = Instance.new("TextButton", tabs)
fTab.Size = UDim2.new(0, 100, 1, 0)
fTab.Position = UDim2.new(0, 110, 0, 0)
fTab.Text = "Farming"
fTab.BackgroundTransparency = 1
fTab.TextColor3 = Color3.new(1, 1, 1)
fTab.MouseButton1Click:Connect(function() farmingPage.Visible = true combatPage.Visible = false end)

-- [Combat Page Elements]
local espBtn = createBtn("ESP: OFF", UDim2.new(0.05, 0, 0.1, 0), combatPage)
local flyBtn = createBtn("Fly: OFF", UDim2.new(0.05, 0, 0.3, 0), combatPage)
local walkIn = createInput("Walkspeed...", UDim2.new(0.4, 0, 0.1, 0), combatPage)
local applyC = createBtn("Apply Combat", UDim2.new(0.7, 0, 0.1, 0), combatPage)
applyC.TextColor3 = Color3.new(1,1,1)

-- [Farming Page Elements]
local auraBtn = createBtn("Remote Aura: OFF", UDim2.new(0.05, 0, 0.1, 0), farmingPage)
local flipBtn = createBtn("Anti-Flip: OFF", UDim2.new(0.05, 0, 0.3, 0), farmingPage)
local rangeIn = createInput("Aura Range...", UDim2.new(0.4, 0, 0.1, 0), farmingPage)
local boostIn = createInput("Vehicle Boost...", UDim2.new(0.4, 0, 0.3, 0), farmingPage)
local applyF = createBtn("Apply Farming", UDim2.new(0.7, 0, 0.1, 0), farmingPage)
applyF.TextColor3 = Color3.new(1,1,1)

-- [1] REMOTE FARMING AURA
-- Bypasses physics. Directly tells the server to update tiles near you.
task.spawn(function()
    while task.wait(0.2) do
        if farmingAuraEnabled then
            local char = Player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then continue end
            
            -- Find field tiles near the player
            for _, folder in pairs(workspace:GetChildren()) do
                if folder.Name:find("Field") then
                    for _, tile in pairs(folder:GetChildren()) do
                        if tile:IsA("BasePart") then
                            local dist = (root.Position - tile.Position).Magnitude
                            if dist <= auraRange then
                                -- Target the UpdateTile remote used by FAF
                                local updateEvent = ReplicatedStorage:FindFirstChild("UpdateTile", true)
                                if updateEvent and updateEvent:IsA("RemoteEvent") then
                                    updateEvent:FireServer(tile)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- [2] MAIN LOOP (Physics, Combat, ESP)
RunService.Stepped:Connect(function()
    local char = Player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hum = char.Humanoid
    local root = char.HumanoidRootPart

    hum.WalkSpeed = walkSpeed

    -- Vehicle Logic
    local seat = hum.SeatPart
    if seat and seat:IsA("VehicleSeat") then
        if seat.Throttle ~= 0 then
            seat.AssemblyLinearVelocity += seat.CFrame.LookVector * (seat.Throttle * vehicleBoost)
        end
        if antiFlipEnabled then
            local yRot = seat.CFrame:ToEulerAnglesXYZ()
            seat.CFrame = CFrame.new(seat.Position) * CFrame.Angles(0, yRot, 0)
            seat.AssemblyAngularVelocity = Vector3.new(0, seat.AssemblyAngularVelocity.Y, 0)
        end
    end

    -- Fly / Noclip
    if flyEnabled then
        hum.PlatformStand = true
        if not flyBV then flyBV = Instance.new("BodyVelocity", root) end
        flyBV.MaxForce = Vector3.new(1,1,1) * math.huge
        local dir = hum.MoveDirection
        local up = UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or (UserInputService:IsKeyDown(Enum.KeyCode.Q) and -1 or 0)
        flyBV.Velocity = (dir * flySpeed) + Vector3.new(0, up * flySpeed, 0)
    else
        if flyBV then flyBV:Destroy() flyBV = nil end
        hum.PlatformStand = false
    end
end)

-- Event Handlers
applyC.MouseButton1Click:Connect(function()
    walkSpeed = tonumber(walkIn.Text) or 16
end)

applyF.MouseButton1Click:Connect(function()
    auraRange = tonumber(rangeIn.Text) or 40
    vehicleBoost = tonumber(speedInput.Text) or 0
end)

auraBtn.MouseButton1Click:Connect(function()
    farmingAuraEnabled = not farmingAuraEnabled
    auraBtn.Text = "Remote Aura: " .. (farmingAuraEnabled and "ON" or "OFF")
    auraBtn.TextColor3 = farmingAuraEnabled and Color3.new(0,1,0) or Color3.new(1,0,0)
end)

flyBtn.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    flyBtn.Text = "Fly: " .. (flyEnabled and "ON" or "OFF")
    flyBtn.TextColor3 = flyEnabled and Color3.new(0,1,0) or Color3.new(1,0,0)
end)

-- Draggable UI Logic
local dragging, dragStart, startPos
main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true dragStart = input.Position startPos = main.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
