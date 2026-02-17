local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer

-- Custom Saved Locations
local CustomLocations = {}

local function getSafeUI()
    local success, result = pcall(function()
        return gethui and gethui() or game:GetService("CoreGui") or Player:WaitForChild("PlayerGui")
    end)
    return success and result or Player:WaitForChild("PlayerGui")
end

local TargetGUI = getSafeUI()
if TargetGUI:FindFirstChild("VortexMenu") then TargetGUI.VortexMenu:Destroy() end

-- State Variables
local espEnabled = true
local flyEnabled = false
local noclipEnabled = false
local walkSpeedValue = 16
local flySpeedValue = 20
local pDropOpen = false
local lDropOpen = false

-- UI Setup
local screenGui = Instance.new("ScreenGui", TargetGUI)
screenGui.Name = "VortexMenu"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 200, 0, 580)
mainFrame.Position = UDim2.new(0.1, 0, 0.5, -290)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local openBtn = Instance.new("TextButton", screenGui)
openBtn.Size = UDim2.new(0, 50, 0, 50)
openBtn.Position = UDim2.new(0, 20, 0.5, -25)
openBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
openBtn.Text = "V"
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 25
openBtn.Visible = false
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 15)

-- Dragging Logic
local function makeDraggable(obj)
    local dragging, dragStart, startPos
    obj.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true dragStart = input.Position startPos = obj.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
end
makeDraggable(mainFrame)
makeDraggable(openBtn)

-- Close/Open Logic
local hideBtn = Instance.new("TextButton", mainFrame)
hideBtn.Size = UDim2.new(0, 30, 0, 30)
hideBtn.Position = UDim2.new(1, -35, 0, 5)
hideBtn.BackgroundTransparency = 1
hideBtn.Text = "X"
hideBtn.TextColor3 = Color3.fromRGB(255, 60, 60)
hideBtn.Font = Enum.Font.GothamBold
hideBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false openBtn.Visible = true end)
openBtn.MouseButton1Click:Connect(function() mainFrame.Visible = true openBtn.Visible = false end)

-- UI Helpers
local function createBtn(text, pos, color, parent)
    local btn = Instance.new("TextButton", parent or mainFrame)
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.Position = pos
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.TextColor3 = color
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    Instance.new("UICorner", btn)
    return btn
end

local function createInput(placeholder, pos)
    local box = Instance.new("TextBox", mainFrame)
    box.Size = UDim2.new(0.9, 0, 0, 30)
    box.Position = pos
    box.PlaceholderText = placeholder
    box.Text = ""
    box.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    box.TextColor3 = Color3.new(1, 1, 1)
    box.Font = Enum.Font.Gotham
    Instance.new("UICorner", box)
    return box
end

-- Toggles & Speed Inputs
local espBtn = createBtn("ESP: ON", UDim2.new(0.05, 0, 0.06, 0), Color3.fromRGB(0, 255, 120))
local flyBtn = createBtn("Fly: OFF", UDim2.new(0.05, 0, 0.12, 0), Color3.fromRGB(255, 60, 60))
local noclipBtn = createBtn("Noclip: OFF", UDim2.new(0.05, 0, 0.18, 0), Color3.fromRGB(255, 60, 60))

local walkInput = createInput("Walk Speed (16)...", UDim2.new(0.05, 0, 0.25, 0))
local flyInput = createInput("Fly Speed (20)...", UDim2.new(0.05, 0, 0.31, 0))
local applyBtn = createBtn("Apply Speeds", UDim2.new(0.05, 0, 0.37, 0), Color3.new(1,1,1))

-- PLAYER DROPDOWN
local pDropTitle = createBtn("Select Player ▽", UDim2.new(0.05, 0, 0.45, 0), Color3.new(1,1,1))
local pScroll = Instance.new("ScrollingFrame", mainFrame)
pScroll.Size = UDim2.new(0.9, 0, 0, 80)
pScroll.Position = UDim2.new(0.05, 0, 0.51, 0)
pScroll.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
pScroll.Visible = false
Instance.new("UIListLayout", pScroll).Padding = UDim.new(0, 5)

-- LOCATION DROPDOWN
local lDropTitle = createBtn("Game Locations ▽", UDim2.new(0.05, 0, 0.67, 0), Color3.new(1,1,1))
local savePosBtn = createBtn("Save Current Pos", UDim2.new(0.05, 0, 0.73, 0), Color3.fromRGB(255, 200, 0))
local lScroll = Instance.new("ScrollingFrame", mainFrame)
lScroll.Size = UDim2.new(0.9, 0, 0, 100)
lScroll.Position = UDim2.new(0.05, 0, 0.79, 0)
lScroll.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
lScroll.Visible = false
Instance.new("UIListLayout", lScroll).Padding = UDim.new(0, 5)

-- LOGIC: Speeds
applyBtn.MouseButton1Click:Connect(function()
    walkSpeedValue = tonumber(walkInput.Text) or 16
    flySpeedValue = tonumber(flyInput.Text) or 20
end)

-- LOGIC: Auto-Location Scanner
local function getGameLocations()
    local found = {}
    -- Add Spawn Points
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("SpawnLocation") then
            found[obj.Name or "Spawn"] = obj.Position + Vector3.new(0, 5, 0)
        elseif obj:IsA("Model") and (obj.Name:lower():find("shop") or obj.Name:lower():find("teleport")) then
            local root = obj:FindFirstChildWhichIsA("BasePart")
            if root then found[obj.Name] = root.Position end
        end
    end
    -- Add Custom saved ones
    for name, pos in pairs(CustomLocations) do found["[Saved] "..name] = pos end
    return found
end

local function updateLocList()
    for _, child in pairs(lScroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    local locs = getGameLocations()
    for name, pos in pairs(locs) do
        local btn = createBtn(name, UDim2.new(0, 0, 0, 0), Color3.fromRGB(0, 180, 255), lScroll)
        btn.MouseButton1Click:Connect(function()
            if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                Player.Character.HumanoidRootPart.CFrame = CFrame.new(pos)
            end
        end)
    end
    lScroll.CanvasSize = UDim2.new(0,0,0, #lScroll:GetChildren() * 35)
end

savePosBtn.MouseButton1Click:Connect(function()
    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        local name = "Loc "..(#CustomLocations + 1)
        CustomLocations[name] = Player.Character.HumanoidRootPart.Position
        updateLocList()
    end
end)

-- LOGIC: Standard Loops
local bv = Instance.new("BodyVelocity")
RunService.Stepped:Connect(function()
    local char = Player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end

    if noclipEnabled or flyEnabled then
        for _, part in pairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
    end

    if not flyEnabled then
        hum.WalkSpeed = walkSpeedValue
        hum.PlatformStand = false
        bv.Parent = nil
    else
        hum.PlatformStand = true
        bv.Parent = root
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        local moveDir = hum.MoveDirection
        local upDir = 0
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then upDir = 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then upDir = -1 end
        bv.Velocity = (moveDir * flySpeedValue) + Vector3.new(0, upDir * flySpeedValue, 0)
    end
end)

-- Handlers for Player list & ESP (existing logic)
pDropTitle.MouseButton1Click:Connect(function()
    pDropOpen = not pDropOpen
    pScroll.Visible = pDropOpen
end)

lDropTitle.MouseButton1Click:Connect(function()
    lDropOpen = not lDropOpen
    lScroll.Visible = lDropOpen
    if lDropOpen then updateLocList() end
end)

espBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    espBtn.Text = espEnabled and "ESP: ON" or "ESP: OFF"
    espBtn.TextColor3 = espEnabled and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)
end)

flyBtn.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    flyBtn.Text = flyEnabled and "Fly: ON" or "Fly: OFF"
    flyBtn.TextColor3 = flyEnabled and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)
end)

noclipBtn.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    noclipBtn.Text = noclipEnabled and "Noclip: ON" or "Noclip: OFF"
    noclipBtn.TextColor3 = noclipEnabled and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)
end)
