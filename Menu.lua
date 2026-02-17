local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer

-- Function to find a safe place for the UI
local function getSafeUI()
    if gethui then return gethui() end -- Modern executors
    local success, core = pcall(function() return game:GetService("CoreGui") end)
    if success and core then return core end
    return Player:WaitForChild("PlayerGui")
end

local TargetGUI = getSafeUI()

-- Cleanup existing menu
if TargetGUI:FindFirstChild("VortexMenu") then
    TargetGUI.VortexMenu:Destroy()
end

-- Variables
local espEnabled = true
local flyEnabled = false
local targetSpeed = 16

-- Create UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "VortexMenu"
screenGui.ResetOnSpawn = false
screenGui.Parent = TargetGUI

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 180, 0, 260)
mainFrame.Position = UDim2.new(0.1, 0, 0.5, -130)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

-- Title Bar
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
mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Button Creator
local function createBtn(text, pos, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.Position = pos
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = color
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = mainFrame
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    return btn
end

local espBtn = createBtn("ESP: ON", UDim2.new(0.05, 0, 0.1, 0), Color3.fromRGB(0, 255, 120))
local flyBtn = createBtn("Fly: OFF", UDim2.new(0.05, 0, 0.28, 0), Color3.fromRGB(255, 60, 60))

local speedInput = Instance.new("TextBox")
speedInput.Size = UDim2.new(0.9, 0, 0, 35)
speedInput.Position = UDim2.new(0.05, 0, 0.5, 0)
speedInput.PlaceholderText = "Speed..."
speedInput.Text = "16"
speedInput.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
speedInput.TextColor3 = Color3.new(1, 1, 1)
speedInput.Font = Enum.Font.Gotham
speedInput.Parent = mainFrame

local speedBtn = createBtn("Set Speed", UDim2.new(0.05, 0, 0.72, 0), Color3.new(1, 1, 1))

-- Button Functions
espBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    espBtn.Text = espEnabled and "ESP: ON" or "ESP: OFF"
    espBtn.TextColor3 = espEnabled and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)
end)

flyBtn.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    flyBtn.Text = flyEnabled and "Fly: ON" or "Fly: OFF"
    flyBtn.TextColor3 = flyEnabled and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)
    if not flyEnabled and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        Player.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    end
end)

speedBtn.MouseButton1Click:Connect(function()
    targetSpeed = tonumber(speedInput.Text) or 16
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
                            hl = Instance.new("Highlight")
                            hl.Name = "VortexESP"
                            hl.FillColor = Color3.fromRGB(255, 0, 0)
                            hl.OutlineTransparency = 0.5
                            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            hl.Parent = p.Character
                        end
                    elseif hl then
                        hl:Destroy()
                    end
                end
            end
        end)
    end
end)

-- Physics Loop
RunService.Heartbeat:Connect(function()
    local char = Player.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    
    if hum and hum.WalkSpeed ~= targetSpeed then
        hum.WalkSpeed = targetSpeed 
    end
    
    if flyEnabled and root then
        local currentVel = root.AssemblyLinearVelocity
        local newY = 0
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then newY = 50 end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then newY = -50 end
        root.AssemblyLinearVelocity = Vector3.new(currentVel.X, newY, currentVel.Z)
    end
end)
