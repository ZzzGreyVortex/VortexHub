local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer

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
local flyBV = nil

-- UI Setup
local screenGui = Instance.new("ScreenGui", TargetGUI)
screenGui.Name = "VortexMenu"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 550, 0, 300)
mainFrame.Position = UDim2.new(0.5, -275, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

local openBtn = Instance.new("TextButton", screenGui)
openBtn.Size = UDim2.new(0, 50, 0, 50)
openBtn.Position = UDim2.new(0, 20, 0.5, -25)
openBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
openBtn.Text = "V"
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 25
openBtn.Visible = false
openBtn.Active = true
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 15)

-- Draggable Logic
local function makeDraggable(gui)
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then update(input) end
    end)
end
makeDraggable(mainFrame)
makeDraggable(openBtn)

-- Helpers
local function createBtn(text, pos, color, parent, size)
    local btn = Instance.new("TextButton", parent or mainFrame)
    btn.Size = size or UDim2.new(0, 160, 0, 35)
    btn.Position = pos or UDim2.new(0,0,0,0)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.TextColor3 = color
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    Instance.new("UICorner", btn)
    return btn
end

local function createInput(placeholder, pos)
    local box = Instance.new("TextBox", mainFrame)
    box.Size = UDim2.new(0, 160, 0, 35)
    box.Position = pos
    box.PlaceholderText = placeholder
    box.Text = ""
    box.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    box.TextColor3 = Color3.new(1, 1, 1)
    box.Font = Enum.Font.Gotham
    Instance.new("UICorner", box)
    return box
end

-- Layout Columns
local espBtn = createBtn("ESP: ON", UDim2.new(0.04, 0, 0.15, 0), Color3.fromRGB(0, 255, 120))
local flyBtn = createBtn("Fly: OFF", UDim2.new(0.04, 0, 0.35, 0), Color3.fromRGB(255, 60, 60))
local noclipBtn = createBtn("Noclip: OFF", UDim2.new(0.04, 0, 0.55, 0), Color3.fromRGB(255, 60, 60))

local walkInput = createInput("Walk Speed...", UDim2.new(0.35, 0, 0.15, 0))
local flyInput = createInput("Fly Speed...", UDim2.new(0.35, 0, 0.35, 0))
local applyBtn = createBtn("Apply Settings", UDim2.new(0.35, 0, 0.55, 0), Color3.new(1,1,1))

local pDropTitle = createBtn("Select Player ▽", UDim2.new(0.66, 0, 0.10, 0), Color3.new(1,1,1))
local pScroll = Instance.new("ScrollingFrame", mainFrame)
pScroll.Size = UDim2.new(0, 160, 0, 80)
pScroll.Position = UDim2.new(0.66, 0, 0.25, 0)
pScroll.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
pScroll.Visible = false
pScroll.BorderSizePixel = 0
Instance.new("UIListLayout", pScroll).Padding = UDim.new(0, 2)

local lDropTitle = createBtn("Locations ▽", UDim2.new(0.66, 0, 0.55, 0), Color3.new(1,1,1))
local lScroll = Instance.new("ScrollingFrame", mainFrame)
lScroll.Size = UDim2.new(0, 160, 0, 80)
lScroll.Position = UDim2.new(0.66, 0, 0.70, 0)
lScroll.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
lScroll.Visible = false
lScroll.BorderSizePixel = 0
Instance.new("UIListLayout", lScroll).Padding = UDim.new(0, 2)

-- Logic: Refreshing ESP & Lists
local function updatePlayerList()
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

local function updateLocList()
    for _, child in pairs(lScroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    local added = {}
    local keywords = {"shop", "store", "spawn", "checkpoint", "npc", "zone", "area", "bank", "sell"}
    for _, obj in pairs(workspace:GetDescendants()) do
        if (obj:IsA("BasePart") or obj:IsA("SpawnLocation")) and not added[obj.Name] then
            for _, word in ipairs(keywords) do
                if obj.Name:lower():find(word) then
                    added[obj.Name] = true
                    local btn = createBtn(obj.Name, nil, Color3.fromRGB(0, 180, 255), lScroll, UDim2.new(1, 0, 0, 25))
                    btn.MouseButton1Click:Connect(function()
                        local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                        if root then root.CFrame = CFrame.new(obj.Position + Vector3.new(0, 3, 0)) end
                    end)
                end
            end
        end
    end
    lScroll.CanvasSize = UDim2.new(0, 0, 0, #lScroll:GetChildren() * 27)
end

-- FIXED ESP REFRESH LOOP
task.spawn(function()
    while task.wait(0.5) do
        if pDropOpen then updatePlayerList() end
        
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= Player then
                local char = p.Character
                if char then
                    local hl = char:FindFirstChild("VortexESP")
                    if espEnabled then
                        if not hl then
                            hl = Instance.new("Highlight")
                            hl.Name = "VortexESP"
                            hl.FillTransparency = 0.5
                            hl.OutlineTransparency = 0
                            hl.FillColor = Color3.fromRGB(255, 0, 0)
                            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                            hl.Parent = char
                        end
                    else
                        if hl then hl:Destroy() end
                    end
                end
            end
        end
    end
end)

-- Collision & State Handling
local function setCollisions(enabled)
    if Player.Character then
        for _, part in pairs(Player.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = enabled end
        end
    end
end

local function updateToggles()
    espBtn.Text = "ESP: " .. (espEnabled and "ON" or "OFF")
    espBtn.TextColor3 = espEnabled and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)
    flyBtn.Text = "Fly: " .. (flyEnabled and "ON" or "OFF")
    flyBtn.TextColor3 = flyEnabled and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)
    noclipBtn.Text = "Noclip: " .. (noclipEnabled and "ON" or "OFF")
    noclipBtn.TextColor3 = noclipEnabled and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)
    
    if not flyEnabled then
        if flyBV then flyBV:Destroy() flyBV = nil end
        if Player.Character and Player.Character:FindFirstChild("Humanoid") then Player.Character.Humanoid.PlatformStand = false end
    end
    if not noclipEnabled and not flyEnabled then setCollisions(true) end
end

espBtn.MouseButton1Click:Connect(function() espEnabled = not espEnabled updateToggles() end)
flyBtn.MouseButton1Click:Connect(function() flyEnabled = not flyEnabled updateToggles() end)
noclipBtn.MouseButton1Click:Connect(function() noclipEnabled = not noclipEnabled updateToggles() end)

-- Core Physics Loop
RunService.Heartbeat:Connect(function()
    local char = Player.Character
    if not (char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart")) then return end
    local hum = char.Humanoid
    local root = char.HumanoidRootPart

    if noclipEnabled or flyEnabled then
        for _, part in pairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
    end

    if flyEnabled then
        hum.PlatformStand = true
        if not flyBV or flyBV.Parent ~= root then
            flyBV = Instance.new("BodyVelocity", root)
            flyBV.Name = "VortexFly"
            flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge) 
        end
        local moveDir = hum.MoveDirection
        local up = UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or (UserInputService:IsKeyDown(Enum.KeyCode.Q) and -1 or 0)
        flyBV.Velocity = (moveDir * flySpeedValue) + Vector3.new(0, up * flySpeedValue, 0)
    else
        if hum.MoveDirection.Magnitude > 0 and walkSpeedValue > 16 then
            root.CFrame = root.CFrame + (hum.MoveDirection * (walkSpeedValue / 50))
        end
    end
end)

applyBtn.MouseButton1Click:Connect(function()
    walkSpeedValue = tonumber(walkInput.Text) or walkSpeedValue
    flySpeedValue = tonumber(flyInput.Text) or flySpeedValue
end)

pDropTitle.MouseButton1Click:Connect(function() pDropOpen = not pDropOpen pScroll.Visible = pDropOpen if pDropOpen then updatePlayerList() end end)
lDropTitle.MouseButton1Click:Connect(function() lDropOpen = not lDropOpen lScroll.Visible = lDropOpen if lDropOpen then updateLocList() end end)

local hideBtn_Main = createBtn("X", UDim2.new(0.93, 0, 0.02, 0), Color3.fromRGB(255, 60, 60), mainFrame, UDim2.new(0, 30, 0, 30))
hideBtn_Main.BackgroundTransparency = 1
hideBtn_Main.MouseButton1Click:Connect(function() mainFrame.Visible = false openBtn.Visible = true end)
openBtn.MouseButton1Click:Connect(function() mainFrame.Visible = true openBtn.Visible = false end)
