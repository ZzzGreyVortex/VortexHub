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

-- Toggles with Visual Fixes
local espBtn = createBtn("ESP: ON", UDim2.new(0.05, 0, 0.07, 0), Color3.fromRGB(0, 255, 120))
local flyBtn = createBtn("Fly: OFF", UDim2.new(0.05, 0, 0.13, 0), Color3.fromRGB(255, 60, 60))
local noclipBtn = createBtn("Noclip: OFF", UDim2.new(0.05, 0, 0.19, 0), Color3.fromRGB(255, 60, 60))

local walkInput = createInput("Walk Speed...", UDim2.new(0.05, 0, 0.26, 0))
local flyInput = createInput("Fly Speed...", UDim2.new(0.05, 0, 0.32, 0))
local applyBtn = createBtn("Apply Settings", UDim2.new(0.05, 0, 0.38, 0), Color3.new(1,1,1))

local pDropTitle = createBtn("Select Player ▽", UDim2.new(0.05, 0, 0.46, 0), Color3.new(1,1,1))
local pScroll = Instance.new("ScrollingFrame", mainFrame)
pScroll.Size = UDim2.new(0.9, 0, 0, 80)
pScroll.Position = UDim2.new(0.05, 0, 0.52, 0)
pScroll.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
pScroll.Visible = false
Instance.new("UIListLayout", pScroll).Padding = UDim.new(0, 2)

local lDropTitle = createBtn("Game Locations ▽", UDim2.new(0.05, 0, 0.68, 0), Color3.new(1,1,1))
local lScroll = Instance.new("ScrollingFrame", mainFrame)
lScroll.Size = UDim2.new(0.9, 0, 0, 100)
lScroll.Position = UDim2.new(0.05, 0, 0.74, 0)
lScroll.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
lScroll.Visible = false
Instance.new("UIListLayout", lScroll).Padding = UDim.new(0, 2)

-- Function: Refresh Player List
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

-- Refresh Loops (ESP & Player List)
task.spawn(function()
    while task.wait(1) do
        -- Constantly update player list if dropdown is open
        if pDropOpen then updatePlayerList() end
        
        -- ESP Logic
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= Player and p.Character then
                local hl = p.Character:FindFirstChild("VortexESP")
                if espEnabled then
                    if not hl then
                        hl = Instance.new("Highlight")
                        hl.Name = "VortexESP"
                        hl.FillColor = Color3.new(1, 0, 0)
                        hl.FillTransparency = 0.5
                        hl.Parent = p.Character
                    end
                elseif hl then
                    hl:Destroy()
                end
            end
        end
    end
end)

-- Button Toggle Logic (Visuals)
local function updateToggles()
    espBtn.Text = "ESP: " .. (espEnabled and "ON" or "OFF")
    espBtn.TextColor3 = espEnabled and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)

    flyBtn.Text = "Fly: " .. (flyEnabled and "ON" or "OFF")
    flyBtn.TextColor3 = flyEnabled and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)

    noclipBtn.Text = "Noclip: " .. (noclipEnabled and "ON" or "OFF")
    noclipBtn.TextColor3 = noclipEnabled and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)
end

espBtn.MouseButton1Click:Connect(function() espEnabled = not espEnabled updateToggles() end)
flyBtn.MouseButton1Click:Connect(function() flyEnabled = not flyEnabled updateToggles() end)
noclipBtn.MouseButton1Click:Connect(function() noclipEnabled = not noclipEnabled updateToggles() end)

-- Physics
RunService.Heartbeat:Connect(function()
    local char = Player.Character
    if not (char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart")) then return end
    
    local hum = char.Humanoid
    local root = char.HumanoidRootPart

    if noclipEnabled or flyEnabled then
        for _, part in pairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
    end

    if not flyEnabled then
        if hum.MoveDirection.Magnitude > 0 then
            root.CFrame = root.CFrame + (hum.MoveDirection * (walkSpeedValue / 50))
        end
    else
        hum.PlatformStand = true
        local up = UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or (UserInputService:IsKeyDown(Enum.KeyCode.Q) and -1 or 0)
        root.Velocity = (hum.MoveDirection * flySpeedValue) + Vector3.new(0, up * flySpeedValue, 0)
    end
end)

-- Apply Speeds
applyBtn.MouseButton1Click:Connect(function()
    walkSpeedValue = tonumber(walkInput.Text) or walkSpeedValue
    flySpeedValue = tonumber(flyInput.Text) or flySpeedValue
end)

-- Dropdowns
pDropTitle.MouseButton1Click:Connect(function() pDropOpen = not pDropOpen pScroll.Visible = pDropOpen if pDropOpen then updatePlayerList() end end)
lDropTitle.MouseButton1Click:Connect(function() lDropOpen = not lDropOpen lScroll.Visible = lDropOpen end)

-- UI Visibility
local hideBtn_Main = createBtn("X", UDim2.new(0.8, 0, 0.01, 0), Color3.fromRGB(255, 60, 60))
hideBtn_Main.BackgroundTransparency = 1
hideBtn_Main.MouseButton1Click:Connect(function() mainFrame.Visible = false openBtn.Visible = true end)
openBtn.MouseButton1Click:Connect(function() mainFrame.Visible = true openBtn.Visible = false end)
