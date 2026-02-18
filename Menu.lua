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
local walkSpeedValue = 16
local flySpeedValue = 20
local vehicleSpeedValue = 50
local auraRange = 25
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

-- Header Tabs
local tabContainer = Instance.new("Frame", mainFrame)
tabContainer.Size = UDim2.new(1, 0, 0, 45)
tabContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
tabContainer.BorderSizePixel = 0
Instance.new("UICorner", tabContainer)

-- Pages
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

-- Elements
local espBtn = createBtn("ESP: ON", UDim2.new(0.04, 0, 0.1, 0), Color3.fromRGB(0, 255, 120), combatPage)
local flyBtn = createBtn("Fly: OFF", UDim2.new(0.04, 0, 0.3, 0), Color3.fromRGB(255, 60, 60), combatPage)
local noclipBtn = createBtn("Noclip: OFF", UDim2.new(0.04, 0, 0.5, 0), Color3.fromRGB(255, 60, 60), combatPage)
local walkInput = createInput("Walk Speed...", UDim2.new(0.35, 0, 0.1, 0), combatPage)
local flyInput = createInput("Fly Speed...", UDim2.new(0.35, 0, 0.3, 0), combatPage)
local applyBtn = createBtn("Apply Combat", UDim2.new(0.35, 0, 0.5, 0), Color3.new(1,1,1), combatPage)
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

local auraBtn = createBtn("Farming Aura: OFF", UDim2.new(0.04, 0, 0.1, 0), Color3.fromRGB(255, 60, 60), farmingPage)
local auraInput = createInput("Aura Range...", UDim2.new(0.04, 0, 0.3, 0), farmingPage)
local vSpeedInput = createInput("Vehicle Speed...", UDim2.new(0.35, 0, 0.1, 0), farmingPage)
local farmApply = createBtn("Apply Farming", UDim2.new(0.35, 0, 0.3, 0), Color3.new(1,1,1), farmingPage)

-- Advanced Farming Loop (CFrame Spoofing)
task.spawn(function()
    while task.wait(0.1) do
        if farmingAuraEnabled then
            local char = Player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local seat = char and char:FindFirstChild("Humanoid") and char.Humanoid.SeatPart
            
            if root and seat then
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and (obj.Name:lower():find("tile") or obj.Name:lower():find("dirt") or obj.Name:lower():find("field")) then
                        if (root.Position - obj.Position).Magnitude <= auraRange then
                            local originalCF = obj.CFrame
                            obj.CFrame = seat.CFrame 
                            firetouchinterest(obj, seat, 0)
                            task.wait()
                            firetouchinterest(obj, seat, 1)
                            obj.CFrame = originalCF
                        end
                    end
                end
            end
        end
    end
end)

-- Advanced Physics Loop (Vehicle Speed Injection)
RunService.Stepped:Connect(function()
    local char = Player.Character
    if not char or not char:FindFirstChild("Humanoid") then return end
    local hum = char.Humanoid
    local root = char:FindFirstChild("HumanoidRootPart")

    hum.WalkSpeed = walkSpeedValue

    -- Vehicle Force Speed
    if hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
        local seat = hum.SeatPart
        local bv = seat:FindFirstChild("VortexVelocity") or Instance.new("BodyVelocity", seat)
        bv.Name = "VortexVelocity"
        if seat.Throttle ~= 0 then
            bv.MaxForce = Vector3.new(math.huge, 0, math.huge)
            bv.Velocity = seat.CFrame.LookVector * (seat.Throttle * vehicleSpeedValue)
        else
            bv.MaxForce = Vector3.new(0, 0, 0)
        end
    end

    if noclipEnabled or flyEnabled then
        for _, part in pairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
    elseif root then
        root.CanCollide = true
    end

    if flyEnabled and root then
        hum.PlatformStand = true
        if not flyBV or flyBV.Parent ~= root then
            flyBV = Instance.new("BodyVelocity", root)
            flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        end
        local up = UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or (UserInputService:IsKeyDown(Enum.KeyCode.Q) and -1 or 0)
        flyBV.Velocity = (hum.MoveDirection * flySpeedValue) + Vector3.new(0, up * flySpeedValue, 0)
        root.Velocity = Vector3.new(0,0,0)
    elseif not flyEnabled and hum.PlatformStand then
        hum.PlatformStand = false
        if flyBV then flyBV:Destroy() flyBV = nil end
    end
end)

-- Connectors
applyBtn.MouseButton1Click:Connect(function()
    walkSpeedValue = tonumber(walkInput.Text) or 16
    flySpeedValue = tonumber(flyInput.Text) or 20
end)

farmApply.MouseButton1Click:Connect(function()
    auraRange = tonumber(auraInput.Text) or 25
    vehicleSpeedValue = tonumber(vSpeedInput.Text) or 50
end)

auraBtn.MouseButton1Click:Connect(function()
    farmingAuraEnabled = not farmingAuraEnabled
    auraBtn.Text = "Farming Aura: " .. (farmingAuraEnabled and "ON" or "OFF")
    auraBtn.TextColor3 = farmingAuraEnabled and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)
end)

-- UI Toggle and Draggables
local openBtn = Instance.new("TextButton", screenGui)
openBtn.Size = UDim2.new(0, 50, 0, 50)
openBtn.Position = UDim2.new(0, 20, 0.5, -25)
openBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
openBtn.Text = "V"
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 25
openBtn.Visible = false
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 15)

local hideBtn = createBtn("X", UDim2.new(0.93, 0, 0.02, 0), Color3.fromRGB(255, 60, 60), mainFrame, UDim2.new(0, 30, 0, 30))
hideBtn.BackgroundTransparency = 1
hideBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false openBtn.Visible = true end)
openBtn.MouseButton1Click:Connect(function() mainFrame.Visible = true openBtn.Visible = false end)

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
