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
local flySpeedValue = 10 -- Started very low to prevent flinging

-- UI Setup
local screenGui = Instance.new("ScreenGui", TargetGUI)
screenGui.Name = "VortexMenu"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 200, 0, 320)
mainFrame.Position = UDim2.new(0.1, 0, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true

-- Dragging Logic
local dragging, dragInput, dragStart, startPos
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

-- UI Components
local function createBtn(text, pos, color)
    local btn = Instance.new("TextButton", mainFrame)
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.Position = pos
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = color
    btn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", btn)
    return btn
end

local espBtn = createBtn("ESP: ON", UDim2.new(0.05, 0, 0.05, 0), Color3.fromRGB(0, 255, 120))
local flyBtn = createBtn("Fly: OFF", UDim2.new(0.05, 0, 0.18, 0), Color3.fromRGB(255, 60, 60))
local noclipBtn = createBtn("Noclip: OFF", UDim2.new(0.05, 0, 0.31, 0), Color3.fromRGB(255, 60, 60))

local flyInput = Instance.new("TextBox", mainFrame)
flyInput.Size = UDim2.new(0.9, 0, 0, 35)
flyInput.Position = UDim2.new(0.05, 0, 0.48, 0)
flyInput.PlaceholderText = "Fly Speed (Try 10)..."
flyInput.Text = "10"
flyInput.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
flyInput.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", flyInput)

local walkInput = flyInput:Clone()
walkInput.Parent = mainFrame
walkInput.Position = UDim2.new(0.05, 0, 0.62, 0)
walkInput.PlaceholderText = "Walk Speed..."
walkInput.Text = "16"

local applyBtn = createBtn("Apply Settings", UDim2.new(0.05, 0, 0.80, 0), Color3.new(1, 1, 1))

-- Logic Connections
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

applyBtn.MouseButton1Click:Connect(function()
    flySpeedValue = tonumber(flyInput.Text) or 10
    walkSpeedValue = tonumber(walkInput.Text) or 16
end)

-- Main Loop
RunService.Stepped:Connect(function(dt)
    local char = Player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end

    -- Noclip (Always on for Fly to prevent flinging)
    if noclipEnabled or flyEnabled then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end

    if not flyEnabled then
        hum.WalkSpeed = walkSpeedValue
        hum.PlatformStand = false
    else
        hum.PlatformStand = true
        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        
        local moveDir = hum.MoveDirection
        local upDir = 0
        
        -- Controls: Space = Up, Q = Down (Shift removed)
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then upDir = 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then upDir = -1 end
        
        -- Apply position change
        local targetPos = (moveDir * flySpeedValue * dt) + Vector3.new(0, upDir * flySpeedValue * dt, 0)
        root.CFrame = root.CFrame + targetPos
    end
end)
