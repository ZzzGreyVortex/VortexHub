local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer

-- UI Safety Check
local function getSafeUI()
    local success, result = pcall(function()
        return (gethui and gethui()) or game:GetService("CoreGui") or Player:WaitForChild("PlayerGui")
    end)
    return success and result or Player:WaitForChild("PlayerGui")
end

local TargetGUI = getSafeUI()
if TargetGUI:FindFirstChild("VortexHub") then TargetGUI.VortexHub:Destroy() end

-- Default Settings
local farmingAuraEnabled = false
local antiFlipEnabled = false
local vehicleSpeedMultiplier = 0 -- 0 is stock, start with 1 or 2
local auraRange = 30
local walkSpeedValue = 16

-- Main GUI Setup
local screenGui = Instance.new("ScreenGui", TargetGUI)
screenGui.Name = "VortexHub"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 500, 0, 320)
mainFrame.Position = UDim2.new(0.5, -250, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
mainFrame.BorderSizePixel = 0
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

-- Navigation Header
local header = Instance.new("Frame", mainFrame)
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
Instance.new("UICorner", header)

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.Text = "VORTEX HUB | VEHICLE FARMING"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 14

-- UI Components
local function createBtn(text, pos, color, parent)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0, 140, 0, 38)
    btn.Position = pos
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.TextColor3 = color
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    Instance.new("UICorner", btn)
    return btn
end

local function createInput(placeholder, pos, parent)
    local box = Instance.new("TextBox", parent)
    box.Size = UDim2.new(0, 140, 0, 38)
    box.Position = pos
    box.PlaceholderText = placeholder
    box.Text = ""
    box.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    box.TextColor3 = Color3.new(1, 1, 1)
    box.Font = Enum.Font.Gotham
    Instance.new("UICorner", box)
    return box
end

-- Controls
local auraBtn = createBtn("Aura: OFF", UDim2.new(0.05, 0, 0.2, 0), Color3.fromRGB(255, 60, 60), mainFrame)
local flipBtn = createBtn("Anti-Flip: OFF", UDim2.new(0.05, 0, 0.38, 0), Color3.fromRGB(255, 60, 60), mainFrame)

local rangeInput = createInput("Aura Range (30)", UDim2.new(0.38, 0, 0.2, 0), mainFrame)
local speedInput = createInput("Speed Boost (0-5)", UDim2.new(0.38, 0, 0.38, 0), mainFrame)
local walkInput = createInput("WalkSpeed (16)", UDim2.new(0.38, 0, 0.56, 0), mainFrame)

local applyBtn = createBtn("APPLY SETTINGS", UDim2.new(0.7, 0, 0.2, 0), Color3.new(1, 1, 1), mainFrame)
applyBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)

---

-- [1] THE FARMING AURA (Pure Touch Method)
-- This sends "Touch" events to the game without moving or freezing the physics.
task.spawn(function()
    while task.wait(0.2) do
        if farmingAuraEnabled then
            local char = Player.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local seat = hum and hum.SeatPart
            
            if seat and seat:IsA("VehicleSeat") then
                local vehicle = seat:FindFirstAncestorOfClass("Model")
                if not vehicle then continue end

                -- Get all physical parts of the vehicle to use as "Plows"
                local vehicleParts = {}
                for _, p in pairs(vehicle:GetDescendants()) do
                    if p:IsA("BasePart") then table.insert(vehicleParts, p) end
                end

                -- Scan the workspace for farming tiles
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and (obj.Name:lower():find("dirt") or obj.Name:lower():find("tile") or obj.Name:lower():find("field")) then
                        local mag = (seat.Position - obj.Position).Magnitude
                        if mag <= auraRange then
                            -- Tell the game every part of our tractor is touching the dirt
                            for i = 1, #vehicleParts do
                                firetouchinterest(obj, vehicleParts[i], 0) -- Touch began
                                firetouchinterest(obj, vehicleParts[i], 1) -- Touch ended
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- [2] PHYSICS & SPEED (Heartbeat for Smoothness)
RunService.Heartbeat:Connect(function()
    local char = Player.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if hum then hum.WalkSpeed = walkSpeedValue end

    local seat = hum and hum.SeatPart
    if seat and seat:IsA("VehicleSeat") then
        -- Additive Speed (Doesn't break steering)
        if seat.Throttle ~= 0 then
            seat.AssemblyLinearVelocity = seat.AssemblyLinearVelocity + (seat.CFrame.LookVector * (seat.Throttle * vehicleSpeedMultiplier))
        end

        -- Anti-Flip (Only stabilizes Tilt/Roll, keeps Turning)
        if antiFlipEnabled then
            local velocity = seat.AssemblyAngularVelocity
            seat.AssemblyAngularVelocity = Vector3.new(0, velocity.Y, 0) -- Kill the flip rotation
            
            -- Gently force the tractor to stay upright
            local _, yRot, _ = seat.CFrame:ToEulerAnglesXYZ()
            seat.CFrame = seat.CFrame:Lerp(CFrame.new(seat.Position) * CFrame.Angles(0, yRot, 0), 0.1)
        end
    end
end)

---

-- Event Listeners
applyBtn.MouseButton1Click:Connect(function()
    auraRange = tonumber(rangeInput.Text) or 30
    vehicleSpeedMultiplier = tonumber(speedInput.Text) or 0
    walkSpeedValue = tonumber(walkInput.Text) or 16
end)

auraBtn.MouseButton1Click:Connect(function()
    farmingAuraEnabled = not farmingAuraEnabled
    auraBtn.Text = "Aura: " .. (farmingAuraEnabled and "ON" or "OFF")
    auraBtn.TextColor3 = farmingAuraEnabled and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)
end)

flipBtn.MouseButton1Click:Connect(function()
    antiFlipEnabled = not antiFlipEnabled
    flipBtn.Text = "Anti-Flip: " .. (antiFlipEnabled and "ON" or "OFF")
    flipBtn.TextColor3 = antiFlipEnabled and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)
end)

-- Draggable Logic
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
