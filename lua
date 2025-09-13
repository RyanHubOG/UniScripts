-- uniScript: All-in-One Mod Menu
-- EXPLOIT ONLY: getgc, setclipboard, Drawing

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ===== SETTINGS =====
local ModifierEnabled = false
local ESPEnabled = false
local ESPPlayers = true
local ESPTools = false
local AimlockEnabled = false
local FOVEnabled = true
local FOVRadius = 150
local FOVSliderValue = 70 -- default FOV
local LoopConnection = nil
local PlayerESP = {true}
local ToolESP = {}
local FOVCircle = true

-- ===== HELPER FUNCTIONS =====
local function findTablesWithS()
    local tables = {}
    for _, tbl in getgc(true) do
        if typeof(tbl) == "table" and rawget(tbl,"S") and typeof(rawget(tbl,"S"))=="number" then
            table.insert(tables,tbl)
        end
    end
    return tables
end

-- ===== MODIFIER =====
local function startModifier()
    if LoopConnection then LoopConnection:Disconnect() LoopConnection=nil end
    if not ModifierEnabled then return end
    local tables = findTablesWithS()
    LoopConnection = RunService.Heartbeat:Connect(function()
        for _,tbl in pairs(tables) do rawset(tbl,"S",100) end
    end)
end

local function stopModifier()
    if LoopConnection then LoopConnection:Disconnect() LoopConnection=nil end
end

-- ===== ESP =====
local settings = {
    Color = Color3.fromRGB(0, 255, 0), -- Changed text color to green
    Size = 15,
    Transparency = 1, -- 1 Visible - 0 Not Visible
    AutoScale = true
}

local space = game:GetService("Workspace")
local player = game:GetService("Players").LocalPlayer
local camera = space.CurrentCamera

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Blissful4992/ESPs/main/UniversalSkeleton.lua"))()

local Skeletons = {}

local function NewText(color, size, transparency)
    local text = Drawing.new("Text")
    text.Visible = false
    text.Text = ""
    text.Position = Vector2.new(0, 0)
    text.Color = color
    text.Size = size
    text.Center = true
    text.Transparency = transparency
    return text
end

local function CreateSkeleton(plr)
    local skeleton = Library:NewSkeleton(plr, true)
    skeleton.Size = 50 -- Super wide and large for maximum visibility
    skeleton.Static = true -- Ensures the skeleton stays still
    table.insert(Skeletons, skeleton)

    local nameTag = NewText(settings.Color, settings.Size, settings.Transparency)

    game:GetService("RunService").RenderStepped:Connect(function()
        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local HumanoidRootPart_Pos, OnScreen = camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
            if OnScreen then
                local distance = math.floor((player.Character.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).magnitude)
                nameTag.Text = string.format("%s [%d Studs]", plr.Name, distance)
                nameTag.Position = Vector2.new(HumanoidRootPart_Pos.X, HumanoidRootPart_Pos.Y - 50)
                nameTag.Visible = true
            else
                nameTag.Visible = false
            end
        else
            nameTag.Visible = false
        end
    end)
end

for _, plr in pairs(game.Players:GetPlayers()) do
    if plr.Name ~= player.Name then
        CreateSkeleton(plr)
    end
end

game.Players.PlayerAdded:Connect(function(plr)
    CreateSkeleton(plr)
end)

-- Lock skeletons in place and prevent movement
while true do
    for _, skeleton in pairs(Skeletons) do
        if skeleton.Part then
            skeleton.Part.Anchored = true -- Ensures the skeleton doesn't move
        end
    end
    wait(0.1)
end

-- ===== AIMLOCK =====
local mouse=LocalPlayer:GetMouse()
local function getClosestHead()
    local closestDist=math.huge
    local target=nil
    local mousePos=UserInputService:GetMouseLocation()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr~=LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health>0 then
            local head=plr.Character.Head
            local screenPos, onScreen=Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local dist=(Vector2.new(screenPos.X,screenPos.Y)-mousePos).Magnitude
                if dist<closestDist then
                    closestDist=dist
                    target=head
                end
            end
        end
    end
    return target
end

-- ===== FOV Circle / Player FOV =====
FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness=2 FOVCircle.Filled=false FOVCircle.Color=Color3.fromRGB(0,255,0) FOVCircle.NumSides=64 FOVCircle.Visible=true FOVCircle.ZIndex=2

RunService.RenderStepped:Connect(function()
    if ESPEnabled then pcall(updateESP) end
    if FOVEnabled then
        local mousePos=UserInputService:GetMouseLocation()
        FOVCircle.Position=mousePos
        FOVCircle.Radius=FOVRadius
        FOVCircle.Visible=true
    else
        FOVCircle.Visible=false
    end
end)

-- ===== UI =====
local GUI = Instance.new("ScreenGui",LocalPlayer:WaitForChild("PlayerGui"))
GUI.Name="uniScriptGUI"
GUI.ResetOnSpawn=false

local frame=Instance.new("Frame",GUI)
frame.Size=UDim2.new(0,300,0,300)
frame.Position=UDim2.new(0.5,-150,0.3,0)
frame.BackgroundColor3=Color3.fromRGB(35,35,35)
frame.BorderSizePixel=0
frame.Active=true

-- Tabs
local Tabs={"Combat","Misc","UI"}
local tabButtons={}
local tabContents={}
for i,name in pairs(Tabs) do
    local btn=Instance.new("TextButton",frame)
    btn.Size=UDim2.new(0,90,0,30)
    btn.Position=UDim2.new(0.05+(i-1)*0.32,0,0,0)
    btn.Text=name
    btn.Font=Enum.Font.SourceSansBold
    btn.TextSize=16
    tabButtons[name]=btn

    local content=Instance.new("Frame",frame)
    content.Size=UDim2.new(1,0,1,-40)
    content.Position=UDim2.new(0,0,0,40)
    content.Visible=(i==1)
    tabContents[name]=content

    btn.MouseButton1Click:Connect(function()
        for _,f in pairs(tabContents) do f.Visible=false end
        content.Visible=true
    end)
end

-- ===== Combat Tab =====
local combat=tabContents["Combat"]
local modBtn=Instance.new("TextButton",combat)
modBtn.Size=UDim2.new(0,120,0,30) modBtn.Position=UDim2.new(0.05,0,0.05,0)
modBtn.Text="Modifier: OFF"
modBtn.MouseButton1Click:Connect(function()
    ModifierEnabled=not ModifierEnabled
    modBtn.Text="Modifier: "..(ModifierEnabled and "ON" or "OFF")
    if ModifierEnabled then startModifier() else stopModifier() end
end)

local aimBtn=Instance.new("TextButton",combat)
aimBtn.Size=UDim2.new(0,120,0,30) aimBtn.Position=UDim2.new(0.55,0,0.05,0)
aimBtn.Text="Aimlock: OFF"
aimBtn.MouseButton1Click:Connect(function()
    AimlockEnabled=not AimlockEnabled
    aimBtn.Text="Aimlock: "..(AimlockEnabled and "ON" or "OFF")
end)

-- ===== Misc Tab =====
local misc=tabContents["Misc"]
local espBtn=Instance.new("TextButton",misc)
espBtn.Size=UDim2.new(0,120,0,30) espBtn.Position=UDim2.new(0.05,0,0.05,0)
espBtn.Text="ESP: OFF"
espBtn.MouseButton1Click:Connect(function()
    ESPEnabled=not ESPEnabled
    espBtn.Text="ESP: "..(ESPEnabled and "ON" or "OFF")
end)

-- FOV Slider
local fovSliderFrame=Instance.new("Frame",misc)
fovSliderFrame.Size=UDim2.new(0,200,0,20) fovSliderFrame.Position=UDim2.new(0.05,0,0.25,0)
fovSliderFrame.BackgroundColor3=Color3.fromRGB(60,60,60)
local sliderFill=Instance.new("Frame",fovSliderFrame)
sliderFill.Size=UDim2.new((FOVSliderValue-70)/50,0,1,0)
sliderFill.BackgroundColor3=Color3.fromRGB(0,255,0)

local dragging=false
fovSliderFrame.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end
end)
fovSliderFrame.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
        local mouseX=input.Position.X
        local sliderX=math.clamp(mouseX-fovSliderFrame.AbsolutePosition.X,0,fovSliderFrame.AbsoluteSize.X)
        sliderFill.Size=UDim2.new(sliderX/fovSliderFrame.AbsoluteSize.X,0,1,0)
        FOVSliderValue=70+(sliderX/fovSliderFrame.AbsoluteSize.X)*50
        workspace.CurrentCamera.FieldOfView=FOVSliderValue
        FOVRadius=FOVSliderValue -- optional: sync circle
    end
end)

-- Copy Discord
local copyBtn=Instance.new("TextButton",misc)
copyBtn.Size=UDim2.new(0,120,0,30) copyBtn.Position=UDim2.new(0.05,0,0.55,0)
copyBtn.Text="Copy Discord"
copyBtn.MouseButton1Click:Connect(function()
    if setclipboard then pcall(function() setclipboard("https://discord.gg/b6fKAnYqtU") end)
    copyBtn.Text="Copied!"
    task.delay(1.5,function() copyBtn.Text="Copy Discord" end)
end)

-- ===== Draggable UI & Open/Close =====
local drag, dragInput, dragStart, startPos
local function update(input)
    local delta=input.Position-dragStart
    frame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
end
frame.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 then
        drag=true dragStart=input.Position startPos=frame.Position
        input.Changed:Connect(function()
            if input.UserInputState==Enum.UserInputState.End then drag=false end
        end)
    end
end)
frame.InputChanged:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseMovement then dragInput=input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input==dragInput and drag then update(input) end
end)

-- Alt key toggle
UserInputService.InputBegan:Connect(function(input,gp)
    if input.KeyCode==Enum.KeyCode.LeftAlt then
        frame.Visible=not frame.Visible
    end
end)

-- ===== RESPAWN HANDLING =====
local function onCharacterAdded(char)
    local hum=char:FindFirstChildWhichIsA("Humanoid") or char:WaitForChild("Humanoid")
    local diedConn
    diedConn=hum.Died:Connect(function()
        stopModifier()
        for plr,_ in pairs(PlayerESP) do removePlayerESP(plr) end
        for inst,_ in pairs(ToolESP) do removeToolESP(inst) end
        if diedConn then diedConn:Disconnect() diedConn=nil end
    end)
    task.delay(0.5,function()
        if ModifierEnabled then startModifier() end
        if ESPEnabled then RunService.RenderStepped:Connect(updateESP) end
    end)
end

if LocalPlayer.Character then onCharacterAdded(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

-- ===== Aimlock Trigger =====
UserInputService.InputBegan:Connect(function(input,gp)
    if input.UserInputType==Enum.UserInputType.MouseButton2 and AimlockEnabled then
        local head=getClosestHead()
        if head then
            -- Set weapon aim/projectile to head.Position here
            -- You can integrate this into your weapon firing logic
        end
    end
end)
