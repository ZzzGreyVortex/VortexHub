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
local espEnabled = true
local flyEnabled = false
local noclipEnabled = false
local farmingAuraEnabled = false
local antiFlipEnabled = false
local walkSpeedValue = 16
local flySpeedValue = 20
local vehicleSpeedValue = 50
local auraRange = 25

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

-- Header Tabs
local tabContainer = Instance.new("Frame", mainFrame)
tabContainer.Size = UDim2.new(1, 0, 0, 45)
tabContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
tabContainer.BorderSizePixel = 0
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

local function createTabBtn(name, pos)
    local btn = Instance.new("TextButton", tabContainer)
    btn.Size = UDim2.new(0, 100, 1, 0)
    btn.Position = pos
    btn.Text = name
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    return btn
end

local combatTabBtn = createTabBtn("Combat", UDim2.new(0, 10, 0, 0))
local farmingTabBtn = createTabBtn("Farming", UDim2.new(0, 120, 0, 0))
combatTabBtn.TextColor3 = Color3.fromRGB(0, 255, 120)

combatTabBtn.MouseButton1Click:Connect(function()
    combatPage.Visible = true farmingPage.Visible = false
    combatTabBtn.TextColor3 = Color3.fromRGB(0, 255, 120)
    farmingTabBtn.TextColor3 = Color3.new(1, 1, 1)
end)
farmingTabBtn.MouseButton1Click:Connect(function()
    combatPage.Visible = false farmingPage.Visible = true
    farmingTabBtn.TextColor3 = Color3.fromRGB(0, 255, 120)
    combatTabBtn.TextColor3 = Color3.new(1, 1, 1)
end)

-- Helpers
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

-- UI Elements
local espBtn = createBtn("ESP: ON", UDim2.new(0.04, 0, 0.1, 0), Color3.fromRGB(0, 255, 120), combatPage)
local flyBtn = createBtn("Fly: OFF", UDim2.new(0.04, 0, 0.3, 0), Color3.fromRGB(255, 60, 60), combatPage)
local noclipBtn = createBtn("Noclip: OFF", UDim2.new(0.04, 0, 0.5, 0), Color3.fromRGB(255, 60, 60), combatPage)
local walkInput = createInput("Walk Speed...", UDim2.new(0.35, 0, 0.1, 0), combatPage)
local applyCombat = createBtn("Apply Combat", UDim2.new(0.35, 0, 0.3, 0), Color3.new(1,1,1), combatPage)

local auraBtn = createBtn("Farming Aura: OFF", UDim2.new(0.04, 0, 0.1, 0), Color3.fromRGB(255, 60, 60), farmingPage)
local flipBtn = createBtn("Anti-Flip: OFF", UDim2.new(0.04, 0, 0.3, 0), Color3.fromRGB(255, 60, 60), farmingPage)
local auraInput = createInput("Aura Range...", UDim2.new(0.04, 0, 0.5, 0), farmingPage)
local vSpeedInput = createInput("Vehicle Boost...", UDim2.new(0.35, 0, 0.1, 0), farmingPage)
local farmApply = createBtn("Apply Farming", UDim2.new(0.35, 0, 0.3, 0), Color3.new(1,1,1), farmingPage)

-- Logic: Find the Plow Tool
local function getPlowPart(vehicle)
    for _, mod in pairs(vehicle:GetDescendants()) do
        if mod:IsA("Model") and (mod.Name:lower():find("plow") or mod.Name:lower():find("cultivator") or mod.Name:lower():find("seeder")) then
            return mod:FindFirstChildWhichIsA("BasePart") or mod:FindFirstChild("Handle")
        end
    end
    return vehicle:FindFirstChild("VehicleSeat") or vehicle:FindFirstChildWhichIsA("BasePart")
end

-- Optimized Farming Loop
task.spawn(function()
    while task.wait(0.2) do
        if farmingAuraEnabled then
            local char = Player.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local seat = hum and hum.SeatPart
            local vehicle = seat and seat:FindFirstAncestorOfClass("Model")
            
            if vehicle then
                local plowPart = getPlowPart(vehicle)
                local region = Region3.new(plowPart.Position - Vector3.new(auraRange, 5, auraRange), plowPart.Position + Vector3.new(auraRange, 5, auraRange))
                local nearby = workspace:FindPartsInRegion3(region, nil, 50)

                for _, obj in pairs(nearby) do
                    if obj.Name:lower():find("tile") or obj.Name:lower():find("dirt") or obj.Name:lower():find("field") then
                        local oldCF = obj.CFrame
                        obj.CFrame = plowPart.CFrame -- Teleport dirt TO the plow
                        firetouchinterest(obj, plowPart, 0)
                        task.wait()
                        firetouchinterest(obj, plowPart, 1)
                        obj.CFrame = oldCF
                    end
                end
            end
        end
    end
end)

-- Physics Loop
RunService.Stepped:Connect(function()
    local char = Player.Character
    if not char or not char:FindFirstChild("Humanoid") then return end
    local hum = char.Humanoid
    hum.WalkSpeed = walkSpeedValue

    if hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
        local seat = hum.SeatPart
        -- Vehicle Speed
        if seat.Throttle ~= 0 then
            seat.AssemblyLinearVelocity = seat.CFrame.LookVector * (seat.Throttle * vehicleSpeedValue)
        end
        -- Anti-Flip
        if antiFlipEnabled then
            seat.AssemblyAngularVelocity = Vector3.new(0, seat.AssemblyAngularVelocity.Y, 0)
            local rX, rY, rZ = seat.CFrame:ToEulerAnglesXYZ()
            seat.CFrame = CFrame.new(seat.Position) * CFrame.Angles(0, rY, 0)
        end
    end
end)

-- Toggles
farmApply.MouseButton1Click:Connect(function()
    auraRange = tonumber(auraInput.Text) or 25
    vehicleSpeedValue = tonumber(vSpeedInput.Text) or 50
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

applyCombat.MouseButton1Click:Connect(function()
    walkSpeedValue = tonumber(walkInput.Text) or 16
end)

-- UI Toggle
local openBtn = Instance.new("TextButton", screenGui)
openBtn.Size = UDim2.new(0, 50, 0, 50)
openBtn.Position = UDim2.new(0, 20, 0.5, -25)
openBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
openBtn.Text = "V"
openBtn.Visible = false
Instance.new("UICorner", openBtn)

local hideBtn = createBtn("X", UDim2.new(0.93, 0, 0.02, 0), Color3.fromRGB(255, 60, 60), mainFrame, UDim2.new(0, 30, 0, 30))
hideBtn.BackgroundTransparency = 1
hideBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false openBtn.Visible = true end)
openBtn.MouseButton1Click:Connect(function() mainFrame.Visible = true openBtn.Visible = false end)

-- Draggable
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
