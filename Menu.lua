local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer

-- Master Cleanup: Ensure no old versions are running
local function getSafeUI()
    local success, result = pcall(function()
        return (gethui and gethui()) or game:GetService("CoreGui") or Player:WaitForChild("PlayerGui")
    end)
    return success and result or Player:WaitForChild("PlayerGui")
end

local TargetGUI = getSafeUI()
if TargetGUI:FindFirstChild("VortexHub") then 
    TargetGUI.VortexHub:Destroy() 
    task.wait(0.1) -- Small delay to ensure memory is cleared
end

-- State Variables
local isScriptActive = true 
local espEnabled = true
local flyEnabled = false
local noclipEnabled = false
local walkSpeedValue = 16
local flySpeedValue = 20
local pDropOpen = false
local lDropOpen = false
local flyBV = nil

-- UI Setup
local screenGui = Instance.new("ScreenGui", TargetGUI)
screenGui.Name = "VortexHub"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 550, 0, 350)
mainFrame.Position = UDim2.new(0.5, -275, 0.5, -175)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

-- Header Bar (The persistent container)
local tabContainer = Instance.new("Frame", mainFrame)
tabContainer.Size = UDim2.new(1, 0, 0, 45)
tabContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
tabContainer.BorderSizePixel = 0
Instance.new("UICorner", tabContainer)

-- UI Helpers
local function createBtn(text, pos, color, parent, size)
    local btn = Instance.new("TextButton", parent)
    btn.Size = size or UDim2.new(0, 160, 0, 35)
    btn.Position = pos or UDim2.new(0,0,0,0)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.TextColor3 = color
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    Instance.new("UICorner", btn)
    return btn
end

-- KILL SWITCH FUNCTION
local function terminateScript()
    isScriptActive = false
    espEnabled = false
    flyEnabled = false
    noclipEnabled = false
    
    -- Clean ESP
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("VortexESP") then
            p.Character.VortexESP:Destroy()
        end
    end
    
    -- Reset Character
    local char = Player.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = 16 hum.PlatformStand = false end
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
    
    if flyBV then flyBV:Destroy() end
    screenGui:Destroy()
end

-- TOP BAR BUTTONS (These never disappear)
local combatTabBtn = createBtn("Combat", UDim2.new(0, 10, 0, 7), Color3.fromRGB(0, 255, 120), tabContainer, UDim2.new(0, 90, 0, 30))
local farmingTabBtn = createBtn("Farming", UDim2.new(0, 105, 0, 7), Color3.new(1, 1, 1), tabContainer, UDim2.new(0, 90, 0, 30))
local exitBtn = createBtn("EXIT", UDim2.new(1, -110, 0, 7), Color3.fromRGB(255, 60, 60), tabContainer, UDim2.new(0, 60, 0, 30))
local hideBtn = createBtn("X", UDim2.new(1, -40, 0, 7), Color3.new(1,1,1), tabContainer, UDim2.new(0, 30, 0, 30))
hideBtn.BackgroundTransparency = 1

exitBtn.MouseButton1Click:Connect(terminateScript)

-- Pages
local combatPage = Instance.new("Frame", mainFrame)
combatPage.Size = UDim2.new(1, 0, 1, -45)
combatPage.Position = UDim2.new(0, 0, 0, 45)
combatPage.BackgroundTransparency = 1

local farmingPage = Instance.new("Frame", mainFrame)
farmingPage.Size = UDim2.new(1, 0, 1, -45)
farmingPage.Position = UDim2.new(0, 0, 0, 45)
farmingPage.BackgroundTransparency = 1
farmingPage.Visible = false

-- Elements & Logic Connections
combatTabBtn.MouseButton1Click:Connect(function()
    combatPage.Visible = true farmingPage.Visible = false
    combatTabBtn.TextColor3 = Color3.fromRGB(0, 255, 120)
    farmingTabBtn.TextColor3 = Color3.new(1, 1, 1)
end)

farmingTabBtn.MouseButton1Click:Connect(function()
    combatPage.Visible = false farmingPage.Visible = true
    farmingTabBtn.TextColor3 = Color3.fromRGB(0, 255, 120)
    combatTabBtn.TextColor3 = Color3.new(1, 1, 1)
end)

-- Standard Buttons (Combat Page)
local espBtn = createBtn("ESP: ON", UDim2.new(0.04, 0, 0.1, 0), Color3.fromRGB(0, 255, 120), combatPage)
local flyBtn = createBtn("Fly: OFF", UDim2.new(0.04, 0, 0.3, 0), Color3.fromRGB(255, 60, 60), combatPage)
local noclipBtn = createBtn("Noclip: OFF", UDim2.new(0.04, 0, 0.5, 0), Color3.fromRGB(255, 60, 60), combatPage)

-- Main Physics Loop
RunService.Stepped:Connect(function()
    if not isScriptActive then return end
    local char = Player.Character
    if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") then
        local hum = char.Humanoid
        local root = char.HumanoidRootPart
        
        hum.WalkSpeed = walkSpeedValue
        if noclipEnabled or flyEnabled then
            for _, part in pairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
        else
            root.CanCollide = true
        end
        
        if flyEnabled then
            hum.PlatformStand = true
            if not flyBV or flyBV.Parent ~= root then
                flyBV = Instance.new("BodyVelocity", root)
                flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            end
            local up = UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or (UserInputService:IsKeyDown(Enum.KeyCode.Q) and -1 or 0)
            flyBV.Velocity = (hum.MoveDirection * flySpeedValue) + Vector3.new(0, up * flySpeedValue, 0)
            root.Velocity = Vector3.new(0,0,0)
        elseif hum.PlatformStand then
            hum.PlatformStand = false
        end
    end
end)

-- Minimize Button Logic
local openBtn = Instance.new("TextButton", screenGui)
openBtn.Size = UDim2.new(0, 50, 0, 50)
openBtn.Position = UDim2.new(0, 20, 0.5, -25)
openBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
openBtn.Text = "V"
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 25
openBtn.Visible = false
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 15)

hideBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false openBtn.Visible = true end)
openBtn.MouseButton1Click:Connect(function() mainFrame.Visible = true openBtn.Visible = false end)

-- Draggable
local function makeDraggable(gui)
    local dragging, dragInput, dragStart, startPos
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true dragStart = input.Position startPos = gui.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    gui.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
makeDraggable(mainFrame)
makeDraggable(openBtn)

-- Toggle Actions
espBtn.MouseButton1Click:Connect(function() 
    espEnabled = not espEnabled 
    espBtn.Text = "ESP: " .. (espEnabled and "ON" or "OFF")
    espBtn.TextColor3 = espEnabled and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)
end)

flyBtn.MouseButton1Click:Connect(function() 
    flyEnabled = not flyEnabled 
    flyBtn.Text = "Fly: " .. (flyEnabled and "ON" or "OFF")
    flyBtn.TextColor3 = flyEnabled and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)
    if not flyEnabled and flyBV then flyBV:Destroy() flyBV = nil end
end)

noclipBtn.MouseButton1Click:Connect(function() 
    noclipEnabled = not noclipEnabled 
    noclipBtn.Text = "Noclip: " .. (noclipEnabled and "ON" or "OFF")
    noclipBtn.TextColor3 = noclipEnabled and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)
end)
