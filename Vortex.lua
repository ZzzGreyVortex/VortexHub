local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer

local TargetGUI = (gethui and gethui()) or game:GetService("CoreGui") or Player:WaitForChild("PlayerGui")

-- Cleanup
if TargetGUI:FindFirstChild("VortexMenu") then TargetGUI.VortexMenu:Destroy() end

-- State
local flyEnabled = false
local noclipEnabled = false
local flySpeed = 50

-- UI Setup (Simplified for clarity)
local screenGui = Instance.new("ScreenGui", TargetGUI)
screenGui.Name = "VortexMenu"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 180, 0, 150)
mainFrame.Position = UDim2.new(0.1, 0, 0.5, -75)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true

-- Modern Dragging
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

-- Buttons
local function createBtn(text, pos, color)
    local btn = Instance.new("TextButton", mainFrame)
    btn.Size = UDim2.new(0.9, 0, 0, 40)
    btn.Position = pos
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = color
    btn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local flyBtn = createBtn("Smooth Fly: OFF", UDim2.new(0.05, 0, 0.1, 0), Color3.fromRGB(255, 60, 60))
local noclipBtn = createBtn("Noclip: OFF", UDim2.new(0.05, 0, 0.5, 0), Color3.fromRGB(255, 60, 60))

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

-- The Physics Engine (The Secret Sauce for Smoothness)
RunService.Stepped:Connect(function(dt)
    local char = Player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    -- NOCLIP LOGIC
    if noclipEnabled then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end

    -- SMOOTH FLY LOGIC
    if flyEnabled then
        -- Stop the humanoid from trying to walk/fall
        hum.PlatformStand = true
        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        
        -- Calculate movement direction
        local moveDir = hum.MoveDirection
        local upDir = 0
        
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then upDir = 1
        elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then upDir = -1 end
        
        -- Smoothly move the CFrame
        local targetCFrame = root.CFrame + (moveDir * flySpeed * dt) + Vector3.new(0, upDir * flySpeed * dt, 0)
        root.CFrame = targetCFrame
    else
        hum.PlatformStand = false
    end
end)
