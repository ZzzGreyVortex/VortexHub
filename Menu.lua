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

-- UI Setup
local screenGui = Instance.new("ScreenGui", TargetGUI)
screenGui.Name = "VortexMenu"
screenGui.ResetOnSpawn = false

-- MAIN FRAME
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 200, 0, 460)
mainFrame.Position = UDim2.new(0.1, 0, 0.5, -230)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

-- FLOATING SQUIRCLE (The Open Button)
local openBtn = Instance.new("TextButton", screenGui)
openBtn.Name = "VortexOpen"
openBtn.Size = UDim2.new(0, 50, 0, 50)
openBtn.Position = UDim2.new(0, 20, 0.5, -25)
openBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
openBtn.Text = "V"
openBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 25
openBtn.Visible = false -- Starts hidden because menu is open
local squircleCorner = Instance.new("UICorner", openBtn)
squircleCorner.CornerRadius = UDim.new(0, 15) -- Squircle shape

-- Dragging for both Menu and Squircle
local function makeDraggable(obj)
    local dragging, dragStart, startPos
    obj.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true dragStart = input.Position startPos = obj.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
end
makeDraggable(mainFrame)
makeDraggable(openBtn)

-- HIDE BUTTON (In Main Frame)
local hideBtn = Instance.new("TextButton", mainFrame)
hideBtn.Size = UDim2.new(0, 30, 0, 30)
hideBtn.Position = UDim2.new(1, -35, 0, 5)
hideBtn.BackgroundTransparency = 1
hideBtn.Text = "X"
hideBtn.TextColor3 = Color3.fromRGB(255, 60, 60)
hideBtn.Font = Enum.Font.GothamBold
hideBtn.TextSize = 18

hideBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    openBtn.Visible = true
end)

openBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = true
    openBtn.Visible = false
end)

-- UI Components Helper
local function createBtn(text, pos, color, parent)
    local btn = Instance.new("TextButton", parent or mainFrame)
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.Position = pos
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.TextColor3 = color
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    Instance.new("UICorner", btn)
    return btn
end

-- Toggles & Inputs (Same as before)
local espBtn = createBtn("ESP: ON", UDim2.new(0.05, 0, 0.08, 0), Color3.fromRGB(0, 255, 120))
local flyBtn = createBtn("Fly: OFF", UDim2.new(0.05, 0, 0.16, 0), Color3.fromRGB(255, 60, 60))
local noclipBtn = createBtn("Noclip: OFF", UDim2.new(0.05, 0, 0.24, 0), Color3.fromRGB(255, 60, 60))

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

local walkInput = createInput("Walk Speed (16)...", UDim2.new(0.05, 0, 0.34, 0))
local flyInput = createInput("Fly Speed (20)...", UDim2.new(0.05, 0, 0.42, 0))
local applyBtn = createBtn("Apply Speeds", UDim2.new(0.05, 0, 0.50, 0), Color3.new(1,1,1))

-- Dropdown
local dropdownFrame = Instance.new("Frame", mainFrame)
dropdownFrame.Size = UDim2.new(0.9, 0, 0, 30)
dropdownFrame.Position = UDim2.new(0.05, 0, 0.60, 0)
dropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Instance.new("UICorner", dropdownFrame)

local dropdownTitle = Instance.new("TextButton", dropdownFrame)
dropdownTitle.Size = UDim2.new(1, 0, 1, 0)
dropdownTitle.BackgroundTransparency = 1
dropdownTitle.Text = "Select Player ▽"
dropdownTitle.TextColor3 = Color3.new(1, 1, 1)
dropdownTitle.Font = Enum.Font.GothamBold

local playerScroll = Instance.new("ScrollingFrame", mainFrame)
playerScroll.Size = UDim2.new(0.9, 0, 0, 120)
playerScroll.Position = UDim2.new(0.05, 0, 0.68, 0)
playerScroll.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
playerScroll.Visible = false
playerScroll.ScrollBarThickness = 2
Instance.new("UIListLayout", playerScroll).Padding = UDim.new(0, 5)

-- Logic: Speeds & Teleport
applyBtn.MouseButton1Click:Connect(function()
    walkSpeedValue = tonumber(walkInput.Text) or 16
    flySpeedValue = tonumber(flyInput.Text) or 20
end)

local function updatePlayerList()
    for _, child in pairs(playerScroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Player then
            local pBtn = Instance.new("TextButton", playerScroll)
            pBtn.Size = UDim2.new(1, -5, 0, 25)
            pBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            pBtn.Text = p.DisplayName
            pBtn.TextColor3 = Color3.new(1, 1, 1)
            pBtn.Font = Enum.Font.Gotham
            Instance.new("UICorner", pBtn)
            pBtn.MouseButton1Click:Connect(function()
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    Player.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                end
            end)
        end
    end
    playerScroll.CanvasSize = UDim2.new(0, 0, 0, #Players:GetPlayers() * 30)
end

dropdownTitle.MouseButton1Click:Connect(function()
    dropdownOpen = not dropdownOpen
    playerScroll.Visible = dropdownOpen
    if dropdownOpen then updatePlayerList() end
end)

-- Loops & Physics
local bv = Instance.new("BodyVelocity")
bv.Velocity = Vector3.new(0,0,0)
bv.MaxForce = Vector3.new(0,0,0)

RunService.Stepped:Connect(function()
    local char = Player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end

    if noclipEnabled or flyEnabled then
        for _, part in pairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
    end

    if not flyEnabled then
        hum.WalkSpeed = walkSpeedValue
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

task.spawn(function()
    while task.wait(0.5) do
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= Player and p.Character then
                local hl = p.Character:FindFirstChild("VortexESP")
                if espEnabled then
                    if not hl then hl = Instance.new("Highlight", p.Character) hl.Name = "VortexESP" hl.FillColor = Color3.fromRGB(255, 0, 0) end
                elseif hl then hl:Destroy() end
            end
        end
    end
end)

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
