local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer

-- Clean up existing menu
local existing = CoreGui:FindFirstChild("VortexMenu")
if existing then existing:Destroy() end

-- State Variables
local espEnabled = true
local flyEnabled = false
local targetSpeed = 16

-- UI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "VortexMenu"
screenGui.Parent = CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 180, 0, 260)
mainFrame.Position = UDim2.new(0.1, 0, 0.5, -130)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

-- Dragging Logic
local dragging, dragInput, dragStart, startPos
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)
mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
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
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
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
    btn.Parent = mainFrame
    return btn
end

local espBtn = createBtn("ESP: ON", UDim2.new(0.05, 0, 0.1, 0), Color3.fromRGB(0, 255, 120))
local flyBtn = createBtn("Fly: OFF", UDim2.new(0.05, 0, 0.28, 0), Color3.fromRGB(255, 60, 60))

local speedInput = Instance.new("TextBox")
speedInput.Size = UDim2.new(0.9, 0, 0, 35)
speedInput.Position = UDim2.new(0.05, 0, 0.5, 0)
speedInput.PlaceholderText = "Speed..."
speedInput.Text = "16"
speedInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
speedInput.TextColor3 = Color3.new(1, 1, 1)
speedInput.Parent = mainFrame

local speedBtn = createBtn("Set Speed", UDim2.new(0.05, 0, 0.72, 0), Color3.new(1, 1, 1))

-- Button Click Events
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

speedBtn.MouseButton1Click:Connect(function()
    targetSpeed = tonumber(speedInput.Text) or 16
end)

-- ESP Function
task.spawn(function()
    while task.wait(0.5) do
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= Player and p.Character then
                local hl = p.Character:FindFirstChild("VortexESP")
                if espEnabled then
                    if not hl then
                        hl = Instance.new("Highlight")
                        hl.Name = "VortexESP"
                        hl.FillColor = Color3.fromRGB(255, 0, 0)
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = p.Character
                    end
                elseif hl then
                    hl:Destroy()
                end
            end
        end
    end
end)

-- Movement Function
RunService.Heartbeat:Connect(function()
    local char = Player.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    
    if hum then hum.WalkSpeed = targetSpeed end
    
    if flyEnabled and root then
        root.Velocity = Vector3.new(root.Velocity.X, 1.5, root.Velocity.Z)
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            root.Velocity = Vector3.new(root.Velocity.X, 50, root.Velocity.Z)
        elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            root.Velocity = Vector3.new(root.Velocity.X, -50, root.Velocity.Z)
        end
    end
end)
