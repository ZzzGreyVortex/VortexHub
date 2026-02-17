local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer

-- Better UI detection for executors
local function getSafeUI()
    local success, result = pcall(function()
        return gethui and gethui() or game:GetService("CoreGui") or Player:WaitForChild("PlayerGui")
    end)
    return success and result or Player:WaitForChild("PlayerGui")
end

local TargetGUI = getSafeUI()

-- Cleanup existing
if TargetGUI:FindFirstChild("VortexMenu") then 
    TargetGUI.VortexMenu:Destroy() 
end

-- State
local flyEnabled = false
local noclipEnabled = false
local flySpeed = 50

-- UI Setup (Fixed Parenting)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "VortexMenu"
screenGui.ResetOnSpawn = false
screenGui.Parent = TargetGUI

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Size = UDim2.new(0, 180, 0, 150)
mainFrame.Position = UDim2.new(0.1, 0, 0.5, -75)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

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
    btn.Size = UDim2.new(0.9, 0, 0, 40)
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

local flyBtn = createBtn("Smooth Fly: OFF", UDim2.new(0.05, 0, 0.1, 0), Color3.fromRGB(255, 60, 60))
local noclipBtn = createBtn("Noclip: OFF", UDim2.new(0.05, 0, 0.5, 0), Color3.fromRGB(255, 60, 60))

-- Toggle Events
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

-- Physics Loop
RunService.Stepped:Connect(function(dt)
    local char = Player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    if noclipEnabled then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end

    if flyEnabled then
        hum.PlatformStand = true
        root.AssemblyLinearVelocity = Vector3.zero
        
        local moveDir = hum.MoveDirection
        local upDir = 0
        
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then upDir = 1
        elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then upDir = -1 end
        
        root.CFrame = root.CFrame + (moveDir * flySpeed * dt) + Vector3.new(0, upDir * flySpeed * dt, 0)
    else
        if hum.PlatformStand then hum.PlatformStand = false end
    end
end)
