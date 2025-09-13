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
local function createText()
    local t = Drawing.new("Text")
    t.Size=16 t.Center=true t.Outline=true t.Visible=true t.ZIndex=2
    return t
end

local function createBox()
    local b = Drawing.new("Square")
    b.Thickness=2 b.Filled=false b.Visible=true b.ZIndex=2
    return b
end

local function worldToViewport(pos)
    local screenPoint, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPoint.X, screenPoint.Y), onScreen
end

local function addPlayerESP(plr)
    if PlayerESP[plr] then return end
    local text = createText()
    local box = createBox()
    PlayerESP[plr] = {plr=plr, box=box, text=text}
end

local function removePlayerESP(plr)
    if PlayerESP[plr] then
        pcall(function() PlayerESP[plr].box:Remove() end)
        pcall(function() PlayerESP[plr].text:Remove() end)
        PlayerESP[plr]=nil
    end
end

local function addToolESP(inst)
    if ToolESP[inst] then return end
    local text = createText()
    text.Text = inst.Name
    ToolESP[inst]={inst=inst,text=text}
end

local function removeToolESP(inst)
    if ToolESP[inst] then
        pcall(function() ToolESP[inst].text:Remove() end)
        ToolESP[inst]=nil
    end
end

local function updateESP()
    if not ESPEnabled then return end
    -- Player ESP
    if ESPPlayers then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr~=LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                addPlayerESP(plr)
                local data=PlayerESP[plr]
                local hrp=plr.Character.HumanoidRootPart
                local topPos=hrp.Position+Vector3.new(0,2,0)
                local botPos=hrp.Position-Vector3.new(0,1,0)
                local top2D, topOn=worldToViewport(topPos)
                local bot2D, botOn=worldToViewport(botPos)
                if topOn and botOn then
                    local height=math.abs(top2D.Y-bot2D.Y)
                    local width=math.clamp(height*0.5,20,120)
                    data.box.Size=Vector2.new(width,height)
                    data.box.Position=top2D-Vector2.new(width/2,0)
                    data.box.Visible=true
                    data.text.Position=top2D-Vector2.new(0,12)
                    data.text.Text=plr.Name
                    data.text.Visible=true
                else
                    data.box.Visible=false
                    data.text.Visible=false
                end
            else
                removePlayerESP(plr)
            end
        end
    end
    -- Tool ESP
    if ESPTools then
        for _, inst in pairs(workspace:GetDescendants()) do
            if (inst:IsA("Tool") or inst:IsA("Model")) and inst.PrimaryPart then
                addToolESP(inst)
                local data=ToolESP[inst]
                local p2D, onScreen=worldToViewport(inst.PrimaryPart.Position)
                if onScreen then
                    data.text.Position=p2D
                    data.text.Visible=true
                else
                    data.text.Visible=false
                end
            end
        end
        for inst,_ in pairs(ToolESP) do
            if not inst:IsDescendantOf(game) then removeToolESP(inst) end
        end
    end
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
