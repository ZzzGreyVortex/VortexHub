local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer

-- TELEPORT LOCATIONS (Add yours here!)
local Locations = {
    ["Spawn"] = Vector3.new(0, 10, 0),
    ["Shop"] = Vector3.new(100, 5, 100),
    ["Arena"] = Vector3.new(-250, 10, 50),
}

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
local playerDropdownOpen = false
local locDropdownOpen = false

-- UI Setup
local screenGui = Instance.new("ScreenGui", TargetGUI)
screenGui.Name = "VortexMenu"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 200, 0, 550) -- Increased height for extra dropdown
mainFrame.Position = UDim2.new(0.1, 0, 0.5, -275)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

-- Open Button (Squircle)
local openBtn = Instance.new("TextButton", screenGui)
openBtn.Size = UDim2.new(0, 50, 0, 50)
openBtn.Position = UDim2.new(0, 20, 0.5, -25)
openBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
openBtn.Text = "V"
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 25
openBtn.Visible = false
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 15)

-- Draggable Logic
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

-- Toggle Menu Visibility
local hideBtn = Instance.new("TextButton", mainFrame)
hideBtn.Size = UDim2.new(0, 30, 0, 30)
hideBtn.Position = UDim2.new(1, -35, 0, 5)
hideBtn.BackgroundTransparency = 1
hideBtn.Text = "X"
hideBtn.TextColor3 = Color3.fromRGB(255, 60, 60)
hideBtn.Font = Enum.Font.GothamBold
hideBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false openBtn.Visible = true end)
openBtn.MouseButton1Click:Connect(function() mainFrame.Visible = true openBtn.Visible = false end)

-- UI Helper functions
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

-- Toggles/Inputs
local espBtn = createBtn("ESP: ON", UDim2.new(0.05, 0, 0.06, 0), Color3.fromRGB(0, 255, 120))
local flyBtn = createBtn("Fly: OFF", UDim2.new(0.05, 0, 0.13, 0), Color3.fromRGB(255, 60, 60))
local noclipBtn = createBtn("Noclip: OFF", UDim2.new(0.05, 0, 0.20, 0), Color3.fromRGB(255, 60, 60))

-- PLAYER DROPDOWN
local pDropTitle = createBtn("Select Player ▽", UDim2.new(0.05, 0, 0.28, 0), Color3.new(1,1,1))
local pScroll = Instance.new("ScrollingFrame", mainFrame)
pScroll.Size = UDim2.new(0.9, 0, 0, 100)
pScroll.Position = UDim2.new(0.05, 0, 0.34, 0)
pScroll.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
pScroll.Visible = false
Instance.new("UIListLayout", pScroll).Padding = UDim.new(0, 5)

-- LOCATION DROPDOWN (NEW)
local lDropTitle = createBtn("Select Location ▽", UDim2.new(0.05, 0, 0.54, 0), Color3.new(1,1,1))
local lScroll = Instance.new("ScrollingFrame", mainFrame)
lScroll.Size = UDim2.new(0.9, 0, 0, 100)
lScroll.Position = UDim2.new(0.05, 0, 0.60, 0)
lScroll.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
lScroll.Visible = false
Instance.new("UIListLayout", lScroll).Padding = UDim.new(0, 5)

-- Player List Logic
local function updatePlayerList()
    for _, child in pairs(pScroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Player then
            local btn = createBtn(p.DisplayName, UDim2.new(0, 0, 0, 0), Color3.new(1,1,1), pScroll)
            btn.MouseButton1Click:Connect(function()
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    Player.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                end
            end)
        end
    end
end

-- Location List Logic
local function updateLocList()
    for _, child in pairs(lScroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    for name, pos in pairs(Locations) do
        local btn = createBtn(name, UDim2.new(0, 0, 0, 0), Color3.fromRGB(0, 180, 255), lScroll)
        btn.MouseButton1Click:Connect(function()
            if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                Player.Character.HumanoidRootPart.CFrame = CFrame.new(pos)
            end
        end)
    end
end

pDropTitle.MouseButton1Click:Connect(function()
    playerDropdownOpen = not playerDropdownOpen
    pScroll.Visible = playerDropdownOpen
    if playerDropdownOpen then updatePlayerList() end
end)

lDropTitle.MouseButton1Click:Connect(function()
    locDropdownOpen = not locDropdownOpen
    lScroll.Visible = locDropdownOpen
    if locDropdownOpen then updateLocList() end
end)

-- Standard loops (ESP, Noclip, Fly) remain unchanged...
RunService.Stepped:Connect(function()
    local char = Player.Character
    if not (char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart")) then return end
    
    if noclipEnabled or flyEnabled then
        for _, part in pairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
    end
end)
