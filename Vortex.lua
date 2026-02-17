-- Configuration
local DEFAULT_SPEED = 16
local menu_name = "UniversalCheatMenu_Fixed"

-- Services
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

-- Clean up any old versions of the script
if CoreGui:FindFirstChild(menu_name) then
    CoreGui[menu_name]:Destroy()
end

-- State
local visualsEnabled = true
local targetSpeed = DEFAULT_SPEED

-- 1. Create the UI Container
local mainGui = Instance.new("ScreenGui")
mainGui.Name = menu_name
mainGui.ResetOnSpawn = false
mainGui.Parent = CoreGui

-- 2. Create Draggable Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 180, 0, 180)
mainFrame.Position = UDim2.new(0.05, 0, 0.4, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 2
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = mainGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "Multi-Hack"
title.TextColor3 = Color3.new(1, 1, 1)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.Parent = mainFrame

-- 3. Visuals (ESP) Button
local espBtn = Instance.new("TextButton")
espBtn.Size = UDim2.new(0.9, 0, 0, 35)
espBtn.Position = UDim2.new(0.05, 0, 0.25, 0)
espBtn.Text = "Visuals: ON"
espBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
espBtn.TextColor3 = Color3.new(1, 1, 1)
espBtn.Parent = mainFrame

-- 4. Speed Inputs
local speedInput = Instance.new("TextBox")
speedInput.Size = UDim2.new(0.9, 0, 0, 30)
speedInput.Position = UDim2.new(0.05, 0, 0.5, 0)
speedInput.PlaceholderText = "Enter Speed..."
speedInput.Text = ""
speedInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
speedInput.TextColor3 = Color3.new(1, 1, 1)
speedInput.Parent = mainFrame

local setSpeedBtn = Instance.new("TextButton")
setSpeedBtn.Size = UDim2.new(0.9, 0, 0, 30)
setSpeedBtn.Position = UDim2.new(0.05, 0, 0.75, 0)
setSpeedBtn.Text = "Apply Speed"
setSpeedBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 150)
setSpeedBtn.TextColor3 = Color3.new(1, 1, 1)
setSpeedBtn.Parent = mainFrame

-----------------------------------------------------------
-- LOGIC: SPEED LOOP
-----------------------------------------------------------
setSpeedBtn.MouseButton1Click:Connect(function()
    local val = tonumber(speedInput.Text)
    if val then
        targetSpeed = val
    end
end)

-- This loop ensures your speed stays set even after dying/respawning
RunService.RenderStepped:Connect(function()
    local char = Player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed ~= targetSpeed then
            hum.WalkSpeed = targetSpeed
        end
    end
end)

-----------------------------------------------------------
-- LOGIC: VISUALS (ESP)
-----------------------------------------------------------
local function applyVisuals(char)
    if not char or Players:GetPlayerFromCharacter(char) == Player then return end
    
    -- Highlight
    local h = char:FindFirstChild("ESP_High") or Instance.new("Highlight", char)
    h.Name = "ESP_High"
    h.Enabled = visualsEnabled
    h.FillColor = Color3.new(1, 0, 0)
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    -- NameTag
    local head = char:WaitForChild("Head", 5)
    if head and not char:FindFirstChild("ESP_Tag") then
        local bg = Instance.new("BillboardGui", char)
        bg.Name = "ESP_Tag"
        bg.Size = UDim2.new(4, 0, 1, 0)
        bg.AlwaysOnTop = true
        bg.StudsOffset = Vector3.new(0, 3, 0)
        local tl = Instance.new("TextLabel", bg)
        tl.Size = UDim2.new(1, 0, 1, 0)
        tl.BackgroundTransparency = 1
        tl.Text = Players:GetPlayerFromCharacter(char).Name
        tl.TextColor3 = Color3.new(1, 1, 1)
        tl.TextScaled = true
    end
    
    if char:FindFirstChild("ESP_Tag") then 
        char.ESP_Tag.Enabled = visualsEnabled 
    end
end

espBtn.MouseButton1Click:Connect(function()
    visualsEnabled = not visualsEnabled
    espBtn.Text = visualsEnabled and "Visuals: ON" or "Visuals: OFF"
    espBtn.BackgroundColor3 = visualsEnabled and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(180, 50, 50)
    
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then applyVisuals(p.Character) end
    end
end)

Players.PlayerAdded:Connect(function(p) 
    p.CharacterAdded:Connect(applyVisuals) 
end)

for _, p in pairs(Players:GetPlayers()) do 
    if p.Character then 
        applyVisuals(p.Character) 
    end 
end
