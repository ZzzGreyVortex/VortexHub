local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local PlayerGui = Player:WaitForChild("PlayerGui")



-- State tracking

local visualsEnabled = true



-- 1. Create the UI

local screenGui = Instance.new("ScreenGui")

screenGui.Name = "VisualsMenu"

screenGui.ResetOnSpawn = false

screenGui.Parent = PlayerGui



local toggleButton = Instance.new("TextButton")

toggleButton.Size = UDim2.new(0, 150, 0, 45)

toggleButton.Position = UDim2.new(0, 20, 0.5, -22) 

toggleButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)

toggleButton.Text = "Visuals: ON"

toggleButton.TextColor3 = Color3.fromRGB(0, 255, 120)

toggleButton.Font = Enum.Font.GothamBold

toggleButton.TextSize = 18

toggleButton.Parent = screenGui



-- 2. Logic to set visibility

local function setVisualState(character, state)

    local highlight = character:FindFirstChild("PlayerHighlight")

    local nameTag = character:FindFirstChild("NameTagGui")



    if highlight then highlight.Enabled = state end

    if nameTag then nameTag.Enabled = state end

end



-- 3. Logic to create visuals

local function applyPlayerVisuals(character)

    if not character then return end

    local otherPlayer = Players:GetPlayerFromCharacter(character)

    if not otherPlayer or otherPlayer == Player then return end



    -- Highlight setup

    local highlight = character:FindFirstChild("PlayerHighlight")

    if not highlight then

        highlight = Instance.new("Highlight")

        highlight.Name = "PlayerHighlight"

        highlight.FillColor = Color3.fromRGB(255, 0, 0)

        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)

        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

        highlight.Parent = character

    end



    -- Name Tag setup

    local head = character:WaitForChild("Head", 5)

    if head and not character:FindFirstChild("NameTagGui") then

        local billboard = Instance.new("BillboardGui")

        billboard.Name = "NameTagGui"

        billboard.Size = UDim2.new(4, 0, 1, 0) 

        billboard.StudsOffset = Vector3.new(0, 2.5, 0)

        billboard.AlwaysOnTop = true

        billboard.MaxDistance = 150

        

        local label = Instance.new("TextLabel")

        label.Parent = billboard

        label.Size = UDim2.new(1, 0, 1, 0)

        label.BackgroundTransparency = 1

        label.Text = otherPlayer.DisplayName

        label.TextColor3 = Color3.fromRGB(255, 255, 255)

        label.TextStrokeTransparency = 0.3

        label.TextScaled = true

        label.Font = Enum.Font.GothamMedium



        billboard.Parent = character

    end



    -- Set initial state

    setVisualState(character, visualsEnabled)

end



-- 4. Toggle Connection

toggleButton.MouseButton1Click:Connect(function()

    visualsEnabled = not visualsEnabled

    

    if visualsEnabled then

        toggleButton.Text = "Visuals: ON"

        toggleButton.TextColor3 = Color3.fromRGB(0, 255, 120)

    else

        toggleButton.Text = "Visuals: OFF"

        toggleButton.TextColor3 = Color3.fromRGB(255, 60, 60)

    end



    for _, p in pairs(Players:GetPlayers()) do

        if p.Character then

            setVisualState(p.Character, visualsEnabled)

        end

    end

end)



-- 5. Start for everyone

Players.PlayerAdded:Connect(function(p)

    p.CharacterAdded:Connect(applyPlayerVisuals)

end)



for _, p in pairs(Players:GetPlayers()) do

    if p.Character then applyPlayerVisuals(p.Character) end

end
