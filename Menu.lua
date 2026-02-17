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
local dropdownOpen = false

-- UI Setup (Increased height for dropdown)
local screenGui = Instance.new("ScreenGui", TargetGUI)
screenGui.Name = "VortexMenu"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 200, 0, 400)
mainFrame.Position = UDim2.new(0.1, 0, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true

-- Dragging Logic
local dragging, dragStart, startPos
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true dragStart = input.Position startPos = mainFrame.Position end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

-- UI Components Helper
local function createBtn(text, pos, color, parent)
    local btn = Instance.new("TextButton", parent or mainFrame)
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.Position = pos
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.TextColor3 = color
    btn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", btn)
    return btn
end

-- Core Buttons
local espBtn = createBtn("ESP: ON", UDim2.new(0.05, 0, 0.05, 0), Color3.fromRGB(0, 255, 120))
local flyBtn = createBtn("Fly: OFF", UDim2.new(0.05, 0, 0.15, 0), Color3.fromRGB(255, 60, 60))
local noclipBtn = createBtn("Noclip: OFF", UDim2.new(0.05, 0, 0.25, 0), Color3.fromRGB(255, 60, 60))

-- Dropdown Container
local dropdownFrame = Instance.new("Frame", mainFrame)
dropdownFrame.Size = UDim2.new(0.9, 0, 0, 35)
dropdownFrame.Position = UDim2.new(0.05, 0, 0.38, 0)
dropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Instance.new("UICorner", dropdownFrame)

local dropdownTitle = Instance.new("TextButton", dropdownFrame)
dropdownTitle.Size = UDim2.new(1, 0, 1, 0)
dropdownTitle.BackgroundTransparency = 1
dropdownTitle.Text = "Select Player ▽"
dropdownTitle.TextColor3 = Color3.new(1, 1, 1)
dropdownTitle.Font = Enum.Font.GothamBold

local playerScroll = Instance.new("ScrollingFrame", mainFrame)
playerScroll.Size = UDim2.new(0.9, 0, 0, 150)
playerScroll.Position = UDim2.new(0.05, 0, 0.47, 0)
playerScroll.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
playerScroll.Visible = false
playerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
playerScroll.ScrollBarThickness = 4
Instance.new("UIListLayout", playerScroll).Padding = UDim.new(0, 5)

-- Dropdown Logic
local function updatePlayerList()
    for _, child in pairs(playerScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Player then
            local pBtn = Instance.new("TextButton", playerScroll)
            pBtn.Size = UDim2.new(1, -10, 0, 30)
            pBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            pBtn.Text = p.DisplayName
            pBtn.TextColor3 = Color3.new(1, 1, 1)
            pBtn.Font = Enum.Font.Gotham
            Instance.new("UICorner", pBtn)
            
            pBtn.MouseButton1Click:Connect(function()
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    Player.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                    dropdownOpen = false
                    playerScroll.Visible = false
                end
            end)
        end
    end
    playerScroll.CanvasSize = UDim2.new(0, 0, 0, #Players:GetPlayers() * 35)
end

dropdownTitle.MouseButton1Click:Connect(function()
    dropdownOpen = not dropdownOpen
    playerScroll.Visible = dropdownOpen
    if dropdownOpen then updatePlayerList() end
end)

-- Velocity Control Setup
local bv = Instance.new("BodyVelocity")
bv.Velocity = Vector3.new(0,0,0)
bv.MaxForce = Vector3.new(0,0,0)

-- Main Physics & Loops (ESP and Fly)
RunService.Stepped:Connect(function()
    local char = Player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end

    if noclipEnabled or flyEnabled then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end

    if not flyEnabled then
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

-- Simple ESP Loop
task.spawn(function()
    while task.wait(0.5) do
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= Player and p.Character then
                local hl = p.Character:FindFirstChild("VortexESP")
                if espEnabled then
                    if not hl then
                        hl = Instance.new("Highlight", p.Character)
                        hl.Name = "VortexESP"
                        hl.FillColor = Color3.fromRGB(255, 0, 0)
                    end
                elseif hl then hl:Destroy() end
            end
        end
    end
end)

-- Button Toggles
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
