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
local walkSpeedValue = 16
local farmingAuraEnabled = false
local antiFlipEnabled = false
local vehicleSpeedMultiplier = 1 -- 1 is normal, 2 is double, etc.
local auraRange = 25

-- UI Setup
local screenGui = Instance.new("ScreenGui", TargetGUI)
screenGui.Name = "VortexHub"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 500, 0, 300)
mainFrame.Position = UDim2.new(0.5, -250, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
Instance.new("UICorner", mainFrame)

-- Tab System
local tabContainer = Instance.new("Frame", mainFrame)
tabContainer.Size = UDim2.new(1, 0, 0, 40)
tabContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Instance.new("UICorner", tabContainer)

local farmingPage = Instance.new("Frame", mainFrame)
farmingPage.Size = UDim2.new(1, 0, 1, -40)
farmingPage.Position = UDim2.new(0, 0, 0, 40)
farmingPage.BackgroundTransparency = 1

-- UI Helpers
local function createBtn(text, pos, color, parent)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0, 140, 0, 35)
    btn.Position = pos
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = color
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    Instance.new("UICorner", btn)
    return btn
end

local function createInput(placeholder, pos, parent)
    local box = Instance.new("TextBox", parent)
    box.Size = UDim2.new(0, 140, 0, 35)
    box.Position = pos
    box.PlaceholderText = placeholder
    box.Text = ""
    box.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    box.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", box)
    return box
end

-- Farming Elements
local auraBtn = createBtn("Farming Aura: OFF", UDim2.new(0.05, 0, 0.1, 0), Color3.fromRGB(255, 60, 60), farmingPage)
local flipBtn = createBtn("Anti-Flip: OFF", UDim2.new(0.05, 0, 0.3, 0), Color3.fromRGB(255, 60, 60), farmingPage)
local rangeInput = createInput("Range (25-100)", UDim2.new(0.38, 0, 0.1, 0), farmingPage)
local speedInput = createInput("Speed Multiplier", UDim2.new(0.38, 0, 0.3, 0), farmingPage)
local applyBtn = createBtn("Apply Settings", UDim2.new(0.7, 0, 0.1, 0), Color3.new(1,1,1), farmingPage)

-- [Logic: Finding the Tool Attachment]
local function getFarmingParts(vehicle)
    local parts = {}
    for _, item in pairs(vehicle:GetDescendants()) do
        if item:IsA("BasePart") then
            local name = item.Name:lower()
            -- Targeted search for farming tools
            if name:find("plow") or name:find("blade") or name:find("tool") or name:find("cultivator") or name:find("seeder") then
                table.insert(parts, item)
            end
        end
    end
    -- If no specific tool found, use the back of the vehicle
    if #parts == 0 then table.insert(parts, vehicle:FindFirstChild("VehicleSeat") or vehicle.PrimaryPart) end
    return parts
end

-- [Farming Aura Loop]
task.spawn(function()
    while task.wait(0.3) do
        if farmingAuraEnabled then
            local char = Player.Character
            local seat = char and char:FindFirstChild("Humanoid") and char.Humanoid.SeatPart
            
            if seat and seat:IsA("VehicleSeat") then
                local vehicle = seat:FindFirstAncestorOfClass("Model")
                local tools = getFarmingParts(vehicle)
                
                -- Optimization: Only check parts near the vehicle
                local region = Region3.new(seat.Position - Vector3.new(auraRange, 10, auraRange), seat.Position + Vector3.new(auraRange, 10, auraRange))
                local nearby = workspace:FindPartsInRegion3(region, nil, 100)
                
                for _, obj in pairs(nearby) do
                    if obj.Name:lower():find("dirt") or obj.Name:lower():find("tile") or obj.Name:lower():find("field") then
                        for _, toolPart in pairs(tools) do
                            firetouchinterest(obj, toolPart, 0)
                            firetouchinterest(obj, toolPart, 1)
                        end
                    end
                end
            end
        end
    end
end)

-- [Vehicle Physics Loop]
RunService.Heartbeat:Connect(function()
    local char = Player.Character
    local seat = char and char:FindFirstChild("Humanoid") and char.Humanoid.SeatPart
    
    if seat and seat:IsA("VehicleSeat") then
        -- Smooth Speed Boost (Adds to current momentum)
        if seat.Throttle ~= 0 then
            seat.AssemblyLinearVelocity = seat.AssemblyLinearVelocity + (seat.CFrame.LookVector * (seat.Throttle * vehicleSpeedMultiplier))
        end
        
        -- Anti-Flip (Locks X and Z rotation to keep tractor upright)
        if antiFlipEnabled then
            local x, y, z = seat.CFrame:ToEulerAnglesXYZ()
            seat.CFrame = CFrame.new(seat.Position) * CFrame.Angles(0, y, 0)
            seat.AssemblyAngularVelocity = Vector3.new(0, seat.AssemblyAngularVelocity.Y, 0)
        end
    end
end)

-- Interaction Connectors
applyBtn.MouseButton1Click:Connect(function()
    auraRange = tonumber(rangeInput.Text) or 25
    vehicleSpeedMultiplier = tonumber(speedInput.Text) or 1
end)

auraBtn.MouseButton1Click:Connect(function()
    farmingAuraEnabled = not farmingAuraEnabled
    auraBtn.Text = "Farming Aura: " .. (farmingAuraEnabled and "ON" or "OFF")
    auraBtn.TextColor3 = farmingAuraEnabled and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)
end)

flipBtn.MouseButton1Click:Connect(function()
    antiFlipEnabled = not antiFlipEnabled
    flipBtn.Text = "Anti-Flip: " .. (antiFlipEnabled and "ON" or "OFF")
    flipBtn.TextColor3 = antiFlipEnabled and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)
end)

-- Draggable Logic
local function makeDraggable(gui)
    local dragging, dragInput, dragStart, startPos
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true dragStart = input.Position startPos = gui.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end
makeDraggable(mainFrame)
