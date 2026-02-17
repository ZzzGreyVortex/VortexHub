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

if TargetGUI:FindFirstChild("VortexMenu") then 
    TargetGUI.VortexMenu:Destroy() 
end

-- State Variables
local espEnabled = true
local flyEnabled = false
local noclipEnabled = false
local walkSpeedValue = 16
local flySpeedValue = 20 -- Lowered default to prevent flinging

-- UI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "VortexMenu"
screenGui.ResetOnSpawn = false
screenGui.Parent = TargetGUI

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 360) -- Slightly taller for more controls
mainFrame.Position = UDim2.new(0.1, 0, 0.5, -180)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 5)
titleBar.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

-- Dragging Logic
local dragging, dragInput, dragStart, startPos
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Button Helper
local function createBtn(text, pos, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.Position = pos
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = color
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    btn.Parent = mainFrame
    return btn
end

-- UI Elements
local espBtn = createBtn("ESP: ON", UDim2.new(0.05, 0, 0.05, 0), Color3.fromRGB(0, 255, 120))
local flyBtn = createBtn("Smooth Fly: OFF", UDim2.new(0.05, 0, 0.17, 0), Color3.fromRGB(255, 60, 60))
local noclipBtn = createBtn("Noclip: OFF", UDim2.new(0.05, 0, 0.29, 0), Color3.fromRGB(255, 60, 60))

-- Fly Speed Input
local flySpeedLabel = Instance.new("TextLabel", mainFrame)
flySpeedLabel.Size = UDim2.new(0.9, 0, 0, 20)
flySpeedLabel.Position = UDim2.new(0.05, 0, 0.42, 0)
flySpeedLabel.Text = "Fly Speed"
flySpeedLabel.TextColor3 = Color3.new(1,1,1)
flySpeedLabel.BackgroundTransparency = 1
flySpeedLabel.Font = Enum.Font.Gotham

local flyInput = Instance.new("TextBox")
flyInput.Size = UDim2.new(0.9, 0, 0, 30)
flyInput.Position = UDim2.new(0.05, 0, 0.48, 0)
flyInput.Text = "20"
flyInput.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
flyInput.TextColor3 = Color3.new(1, 1, 1)
flyInput.Parent = mainFrame
Instance.new("UICorner", flyInput)

-- Walk Speed Input
local walkSpeedLabel = flySpeedLabel:Clone()
walkSpeedLabel.Parent = mainFrame
walkSpeedLabel.Position = UDim2.new(0.05, 0, 0.60, 0)
walkSpeedLabel.Text = "Walk Speed"

local walkInput = flyInput:Clone()
walkInput.Parent = mainFrame
walkInput.Position = UDim2.new(0.05, 0, 0.66, 0)
walkInput.Text = "16"

local applyBtn = createBtn("Apply Settings", UDim2.new(0.05, 0, 0.82, 0), Color3.new(1, 1, 1))

-- Logic
espBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    espBtn.Text = espEnabled and "ESP: ON" or "ESP: OFF"
    espBtn.TextColor3 = espEnabled and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)
end)

flyBtn.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    flyBtn.Text = flyEnabled and "Smooth Fly: ON" or "Smooth Fly: OFF"
    flyBtn.TextColor3 = flyEnabled and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)
end)

noclipBtn.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    noclipBtn.Text = noclipEnabled and "Noclip: ON" or "Noclip: OFF"
    noclipBtn.TextColor3 = noclipEnabled and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)
end)

applyBtn.MouseButton1Click:Connect(function()
    walkSpeedValue = tonumber(walkInput.Text) or 16
    flySpeedValue = tonumber(flyInput.Text) or 20
end)

-- ESP Loop
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= Player and p.Character then
                    local hl = p.Character:FindFirstChild("VortexESP")
                    if espEnabled then
                        if not hl then
                            hl = Instance.new("Highlight", p.Character)
                            hl.Name = "VortexESP"
                            hl.FillColor = Color3.fromRGB(255, 0, 0)
                            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        end
                    elseif hl then hl:Destroy() end
                end
            end
        end)
    end
end)

-- Main Physics
RunService.Stepped:Connect(function(dt)
    local char = Player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end

    if noclipEnabled then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end

    if not flyEnabled then
        hum.WalkSpeed = walkSpeedValue
        hum.PlatformStand = false
    else
        hum.PlatformStand = true
        root.AssemblyLinearVelocity = Vector3.zero
        
        local moveDir = hum.MoveDirection
        local upDir = 0
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then upDir = 1 
        elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then upDir = -1 end
        
        -- Smooth gliding without flinging
        root.CFrame = root.CFrame + (moveDir * flySpeedValue * dt) + Vector3.new(0, upDir * flySpeedValue * dt, 0)
    end
end)
