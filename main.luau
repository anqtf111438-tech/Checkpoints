-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local localPlayer = Players.LocalPlayer

-- Parent GUI safely (Executor / Studio compatibility)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DualCheckpointGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

if gethui then
    screenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(screenGui)
    screenGui.Parent = CoreGui
else
    pcall(function() screenGui.Parent = CoreGui end)
    if not screenGui.Parent then
        screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
    end
end

-- Dragging logic helper for container frames
local function enableDragging(frame)
    local dragging = false
    local dragInput, dragStart, startPos

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Helper for styled UI buttons
local function createButton(parent, name, text, position)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(0, 135, 0, 50)
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
    button.BackgroundTransparency = 0.2
    button.Text = text
    button.TextColor3 = Color3.fromRGB(80, 80, 80)
    button.TextSize = 15
    button.Font = Enum.Font.SourceSans
    button.AutoButtonColor = true
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(160, 160, 160)
    stroke.Thickness = 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = button

    return button
end

-- Connects actions to fire on press DOWN rather than release
local function bindInstantPress(button, callback)
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            callback()
        end
    end)
end

-- Factory to create isolated Checkpoint GUI instances
local function createCheckpointInstance(frameName, position, setText, tpText)
    local frame = Instance.new("Frame")
    frame.Name = frameName
    frame.Size = UDim2.new(0, 290, 0, 50)
    frame.AnchorPoint = Vector2.new(0.5, 0)
    frame.Position = position
    frame.BackgroundTransparency = 1
    frame.Active = true
    frame.Parent = screenGui

    enableDragging(frame)

    local setBtn = createButton(frame, "SetCheckpointBtn", setText, UDim2.new(0, 0, 0, 0))
    local tpBtn = createButton(frame, "TPBtn", tpText, UDim2.new(0, 155, 0, 0))

    -- Independent stored CFrame for this specific GUI
    local savedCFrame = nil

    -- Ultra-fast checkpoint save logic (Instant on screen touch/click down)
    bindInstantPress(setBtn, function()
        local character = localPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")

        if rootPart then
            savedCFrame = rootPart.CFrame
            setBtn.Text = "Saved!"
            task.delay(0.4, function()
                setBtn.Text = setText
            end)
        end
    end)

    -- Ultra-fast teleport logic
    bindInstantPress(tpBtn, function()
        if not savedCFrame then return end

        local character = localPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")

        if rootPart then
            rootPart.CFrame = savedCFrame
            rootPart.AssemblyLinearVelocity = Vector3.zero
            rootPart.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

-- Create Top Checkpoint GUI (Flush at top edge)
createCheckpointInstance(
    "TopCheckpointContainer",
    UDim2.new(0.5, 0, 0, 5),
    "Set Checkpoint 1",
    "TP 1"
)

-- Create Bottom Checkpoint GUI
createCheckpointInstance(
    "BottomCheckpointContainer",
    UDim2.new(0.5, 0, 0.8, 0),
    "Set Checkpoint 2",
    "TP 2"
)
