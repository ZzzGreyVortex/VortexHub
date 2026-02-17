local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer

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
local flyBV = nil

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
local function createBtn(text, pos, color, parent)
    local btn = Instance.new("TextButton", parent or mainFrame)
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.Position = pos or UDim2.new(0,0,0,0)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.TextColor3 = color
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
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

-- Toggles
local espBtn = createBtn("ESP: ON", UDim2.new(0.05, 0, 0.07, 0), Color3.fromRGB(0, 255, 120))
local flyBtn = createBtn("Fly: OFF", UDim2.new(0.05, 0, 0.13, 0), Color3.fromRGB(255, 60, 60))
local noclipBtn = createBtn("Noclip: OFF", UDim2.new(0.05, 0, 0.19, 0), Color3.fromRGB(255, 60, 60))

local walkInput = createInput("Walk Speed...", UDim2.new(0.05, 0, 0.26, 0))
local flyInput = createInput("Fly Speed...", UDim2.new(0.05, 0, 0.32, 0))
local applyBtn = createBtn("Apply Settings", UDim2.new(0.05, 0, 0.38, 0), Color3.new(1,1,1))

-- Dropdowns
local pDropTitle = createBtn("Select Player ▽", UDim2.new(0.05, 0, 0.46, 0), Color3.new(1,1,1))
local pScroll = Instance.new("ScrollingFrame", mainFrame)
pScroll.Size = UDim2.new(0.9, 0, 0, 80)
pScroll.Position = UDim2.new(0.05, 0, 0.52, 0)
pScroll.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
pScroll.Visible = false
pScroll.BorderSizePixel = 0
Instance.new("UIListLayout", pScroll).Padding = UDim.new(0, 2)

local lDropTitle = createBtn("Game Locations ▽", UDim2.new(0.05, 0, 0.68, 0), Color3.new(1,1,1))
local lScroll = Instance.new("ScrollingFrame", mainFrame)
lScroll.Size = UDim2.new(0.9, 0, 0, 100)
lScroll.Position = UDim2.new(0.05, 0, 0.74, 0)
lScroll.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
lScroll.Visible = false
lScroll.BorderSizePixel = 0
Instance.new("UIListLayout", lScroll).Padding = UDim.new(0, 2)

local function updatePlayerList()
    for _, child in pairs(pScroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Player then
            local btn = createBtn(p.DisplayName, nil, Color3.new(1,1,1), pScroll)
            btn.Size = UDim2.new(1, 0, 0, 25)
            btn.MouseButton1Click:Connect(function()
                local myRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                local targetRoot = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                if myRoot and targetRoot then
                    myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
                end
            end)
        end
    end
    pScroll.CanvasSize = UDim2.new(0, 0, 0, #pScroll:GetChildren() * 27)
end

-- Main Loops (ESP + List)
task.spawn(function()
    while task.wait(0.5) do
        if pDropOpen then updatePlayerList() end
        
        -- ESP Logic
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local espBox = p.Character:FindFirstChild("VortexBox")
                if espEnabled then
                    if not espBox then
                        espBox = Instance.new("BoxHandleAdornment")
                        espBox.Name = "VortexBox"
                        espBox.Parent = p.Character
                        espBox.Adornee = p.Character
                        espBox.AlwaysOnTop = true
                        espBox.ZIndex = 5
                        espBox.Size = p.Character:GetExtentsSize()
                        espBox.Color3 = Color3.new(1, 0, 0)
                        espBox.Transparency = 0.5
                    else
                        espBox.Size = p.Character:GetExtentsSize()
                        espBox.Adornee = p.Character
                    end
                elseif espBox then
                    espBox:Destroy()
                end
            end
        end
    end
end)

-- Toggle & Physics Logic
local function toggleCollisions(enable)
    if Player.Character then
        for _, part in pairs(Player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = enable
            end
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
    
    -- Cleanup Fly
    if not flyEnabled then
        if flyBV then flyBV:Destroy() flyBV = nil end
        if Player.Character and Player.Character:FindFirstChild("Humanoid") then
            Player.Character.Humanoid.PlatformStand = false
        end
    end

    -- Cleanup Noclip (Collision Fix)
    if not noclipEnabled and not flyEnabled then
        toggleCollisions(true) -- Force collisions ON when disabled
    end
end

espBtn.MouseButton1Click:Connect(function() espEnabled = not espEnabled updateToggles() end)
flyBtn.MouseButton1Click:Connect(function() flyEnabled = not flyEnabled updateToggles() end)
noclipBtn.MouseButton1Click:Connect(function() noclipEnabled = not noclipEnabled updateToggles() end)

-- Physics Loop
RunService.Heartbeat:Connect(function()
    local char = Player.Character
    if not (char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart")) then return end
    
    local hum = char.Humanoid
    local root = char.HumanoidRootPart

    -- Noclip (Active)
    if noclipEnabled or flyEnabled then
        for _, part in pairs(char:GetDescendants()) do 
            if part:IsA("BasePart") then part.CanCollide = false end 
        end
    end

    -- Fly Logic
    if flyEnabled then
        hum.PlatformStand = true
        
        if not flyBV or flyBV.Parent ~= root then
            flyBV = Instance.new("BodyVelocity")
            flyBV.Name = "FlyVelocity"
            flyBV.Parent = root
            -- FIX: Infinite Force prevents falling
            flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge) 
        end
        
        local flyDir = hum.MoveDirection
        local up = UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or (UserInputService:IsKeyDown(Enum.KeyCode.Q) and -1 or 0)
        
        flyBV.Velocity = (flyDir * flySpeedValue) + Vector3.new(0, up * flySpeedValue, 0)
    else
        -- WalkSpeed Logic
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
lDropTitle.MouseButton1Click:Connect(function() lDropOpen = not lDropOpen lScroll.Visible = lDropOpen end)

local hideBtn_Main = createBtn("X", UDim2.new(0.8, 0, 0.01, 0), Color3.fromRGB(255, 60, 60))
hideBtn_Main.BackgroundTransparency = 1
hideBtn_Main.MouseButton1Click:Connect(function() mainFrame.Visible = false openBtn.Visible = true end)
openBtn.MouseButton1Click:Connect(function() mainFrame.Visible = true openBtn.Visible = false end)
