-- Menu
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "AIMBOT & VISUAL | AKAiDOHub INGLÊS",
    SubTitle = "By AK",
    TabWidth = 80,
    Size = UDim2.fromOffset(400, 260),
    Acrylic = false, -- The blur may be detectable, setting this to false disables blur entirely
    Theme = "Amethyst",
    MinimizeKey = Enum.KeyCode.K -- Used when theres no MinimizeKeybind
})

local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false -- Impede que a GUI seja recriada no respawn
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

_G.HudBtn = false

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 100, 0, 30)
button.Position = UDim2.new(0, 70, 0, 25) -- Ajuste a posição conforme necessário
button.Text = "Open Menu"
button.TextColor3 = Color3.fromRGB(240, 240, 240)
button.BackgroundColor3 = Color3.fromRGB(60, 45, 80)
button.BorderSizePixel = 0
button.Parent = screenGui
button.Active = _G.HudBtn
button.Draggable = _G.HudBtn

local uicorner = Instance.new("UICorner")
uicorner.CornerRadius = UDim.new(0, 12) 
uicorner.Parent = button

local function simulateKeyPress()
    local UserInputService = game:GetService("UserInputService")
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Fluent.MinimizeKey then
        end
    end)
    
    -- Simula o clique da tecla K
    local VirtualInputManager = game:GetService("VirtualInputManager")
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.K, false, game)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.K, false, game)
end

button.MouseButton1Click:Connect(simulateKeyPress)

-- Tabs
local Tabs = {
    M = Window:AddTab({ Title = "Aimbot", Icon = "bot" }),
    H = Window:AddTab({ Title = "Hitbox", Icon = "box" }),
    V = Window:AddTab({ Title = "Visual", Icon = "terminal" }),
    C = Window:AddTab({ Title = "Crosshair", Icon = "crosshair" }),
    P = Window:AddTab({ Title = "Player", Icon = "user" }),
    S = Window:AddTab({ Title = "Settings", Icon = "sliders-horizontal" })
}

-- -- -- -- -- -- -- Scripts -- -- -- -- -- -- --

local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Plr = Players.LocalPlayer
local Clipon = false

-- -- -- -- -- -- -- ESPS -- -- -- -- -- -- --

--// Variables
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local cache = {}
local bones = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "LowerTorso"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"}
}

--// Settings
local ESP_SETTINGS = {
    BoxOutlineColor = Color3.new(0, 0, 0),
    BoxColor = Color3.new(128 / 255, 25 / 255, 25 / 255),
    NameColor = Color3.new(128 / 255, 25 / 255, 25 / 255),
    HealthOutlineColor = Color3.new(0, 0, 0),
    HealthHighColor = Color3.new(0, 1, 0),
    HealthLowColor = Color3.new(128 / 255, 25 / 255, 25 / 255),
    SkeletonColor = Color3.new(128 / 255, 25 / 255, 25 / 255),
    LineColor = Color3.new(128 / 255, 25 / 255, 25 / 255),
    Teamcheck = false,
    WallCheck = false,
    Enabled = true,
    ShowName = true,
    ShowBox = true,
    ShowHealth = true,
    ShowSkeletons = true,
    ShowLine = true,
    BoxType = "Corner", -- "2D" or "Corner"
}

local function create(class, properties)
    local drawing = Drawing.new(class)
    for property, value in pairs(properties) do
        drawing[property] = value
    end
    return drawing
end

local function createEsp(player)
    local esp = {
        boxOutline = create("Square", {
            Color = ESP_SETTINGS.BoxOutlineColor,
            Thickness = 3,
            Filled = false
        }),
        box = create("Square", {
            Color = ESP_SETTINGS.BoxColor,
            Thickness = 1,
            Filled = false
        }),
        name = create("Text", {
            Color = ESP_SETTINGS.NameColor,
            Outline = true,
            Center = true,
            Size = 13
        }),
        healthOutline = create("Line", {
            Thickness = 3,
            Color = ESP_SETTINGS.HealthOutlineColor
        }),
        health = create("Line", {
            Thickness = 1
        }),
        line = create("Line", {
            Thickness = 1,
            Color = ESP_SETTINGS.LineColor
        }),
        boxLines = {},
        skeletonLines = {}
    }
    cache[player] = esp
end

local function removeEsp(player)
    local esp = cache[player]
    if not esp then return end
    for _, drawing in pairs(esp) do
        if type(drawing) == "table" then
            for _, line in pairs(drawing) do
                line:Remove()
            end
        else
            drawing:Remove()
        end
    end
    cache[player] = nil
end

local function isPlayerBehindWall(player)
    local character = player.Character
    if not character then return false end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    local ray = Ray.new(camera.CFrame.Position, (rootPart.Position - camera.CFrame.Position).Unit * (rootPart.Position - camera.CFrame.Position).Magnitude)
    local hit, _ = workspace:FindPartOnRayWithIgnoreList(ray, {localPlayer.Character, character})
    return hit and hit:IsA("Part")
end

local function updateEsp()
    for player, esp in pairs(cache) do
        local character, team = player.Character, player.Team
        if character and (not ESP_SETTINGS.Teamcheck or (team and team ~= localPlayer.Team)) then
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            local head = character:FindFirstChild("Head")
            local humanoid = character:FindFirstChild("Humanoid")
            local isBehindWall = ESP_SETTINGS.WallCheck and isPlayerBehindWall(player)
            local shouldShow = not isBehindWall and ESP_SETTINGS.Enabled
            if rootPart and head and humanoid and shouldShow then
                local position, onScreen = camera:WorldToViewportPoint(rootPart.Position)
                if onScreen then
                    local hrp2D = camera:WorldToViewportPoint(rootPart.Position)
                    local charSize = (camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0)).Y - camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, 2.6, 0)).Y) / 2
                    local boxSize = Vector2.new(math.floor(charSize * 1.8), math.floor(charSize * 1.9))
                    local boxPosition = Vector2.new(math.floor(hrp2D.X - charSize * 1.8 / 2), math.floor(hrp2D.Y - charSize * 1.6 / 2))
                    
                    if ESP_SETTINGS.ShowName and ESP_SETTINGS.Enabled then
                        esp.name.Visible = true
                        esp.name.Text = string.lower(player.Name)
                        esp.name.Position = Vector2.new(boxSize.X / 2 + boxPosition.X, boxPosition.Y - 16)
                        esp.name.Color = ESP_SETTINGS.NameColor
                    else
                        esp.name.Visible = false
                    end
                    
                    if ESP_SETTINGS.ShowBox and ESP_SETTINGS.Enabled then
                        if ESP_SETTINGS.BoxType == "2D" then
                            esp.boxOutline.Size = boxSize
                            esp.boxOutline.Position = boxPosition
                            esp.box.Size = boxSize
                            esp.box.Position = boxPosition
                            esp.box.Color = ESP_SETTINGS.BoxColor
                            esp.box.Visible = true
                            esp.boxOutline.Visible = true
                            for _, line in ipairs(esp.boxLines) do
                                line.Visible = false
                            end
                        elseif ESP_SETTINGS.BoxType == "Corner" then
                            -- Corner box implementation
                            local lineW = (boxSize.X / 5)
                            local lineH = (boxSize.Y / 6)
                            local lineT = 1
                            if #esp.boxLines == 0 then
                                for i = 1, 8 do
                                    local boxLine = create("Line", { Thickness = 1, Color = ESP_SETTINGS.BoxColor, Transparency = 1 })
                                    esp.boxLines[#esp.boxLines + 1] = boxLine
                                end
                            end
                            local boxLines = esp.boxLines
                            -- top left
                            boxLines[1].From = Vector2.new(boxPosition.X - lineT, boxPosition.Y - lineT)
                            boxLines[1].To = Vector2.new(boxPosition.X + lineW, boxPosition.Y - lineT)
                            boxLines[2].From = Vector2.new(boxPosition.X - lineT, boxPosition.Y - lineT)
                            boxLines[2].To = Vector2.new(boxPosition.X - lineT, boxPosition.Y + lineH)
                            -- top right
                            boxLines[3].From = Vector2.new(boxPosition.X + boxSize.X - lineW, boxPosition.Y - lineT)
                            boxLines[3].To = Vector2.new(boxPosition.X + boxSize.X + lineT, boxPosition.Y - lineT)
                            boxLines[4].From = Vector2.new(boxPosition.X + boxSize.X + lineT, boxPosition.Y - lineT)
                            boxLines[4].To = Vector2.new(boxPosition.X + boxSize.X + lineT, boxPosition.Y + lineH)
                            -- bottom left
                            boxLines[5].From = Vector2.new(boxPosition.X - lineT, boxPosition.Y + boxSize.Y - lineH)
                            boxLines[5].To = Vector2.new(boxPosition.X - lineT, boxPosition.Y + boxSize.Y + lineT)
                            boxLines[6].From = Vector2.new(boxPosition.X - lineT, boxPosition.Y + boxSize.Y + lineT)
                            boxLines[6].To = Vector2.new(boxPosition.X + lineW, boxPosition.Y + boxSize.Y + lineT)
                            -- bottom right
                            boxLines[7].From = Vector2.new(boxPosition.X + boxSize.X - lineW, boxPosition.Y + boxSize.Y + lineT)
                            boxLines[7].To = Vector2.new(boxPosition.X + boxSize.X + lineT, boxPosition.Y + boxSize.Y + lineT)
                            boxLines[8].From = Vector2.new(boxPosition.X + boxSize.X + lineT, boxPosition.Y + boxSize.Y - lineH)
                            boxLines[8].To = Vector2.new(boxPosition.X + boxSize.X + lineT, boxPosition.Y + boxSize.Y + lineT)
                            for _, line in ipairs(boxLines) do
                                line.Visible = true
                            end
                            esp.box.Visible = false
                            esp.boxOutline.Visible = false
                        end
                    else
                        esp.box.Visible = false
                        esp.boxOutline.Visible = false
                        for _, line in ipairs(esp.boxLines) do
                            line.Visible = false
                        end
                    end
                    
                    if ESP_SETTINGS.ShowHealth and ESP_SETTINGS.Enabled then
                        esp.healthOutline.Visible = true
                        esp.health.Visible = true
                        local healthPercentage = humanoid.Health / humanoid.MaxHealth
                        esp.healthOutline.From = Vector2.new(boxPosition.X - 6, boxPosition.Y + boxSize.Y)
                        esp.healthOutline.To = Vector2.new(esp.healthOutline.From.X, esp.healthOutline.From.Y - boxSize.Y)
                        esp.health.From = Vector2.new((boxPosition.X - 5), boxPosition.Y + boxSize.Y)
                        esp.health.To = Vector2.new(esp.health.From.X, esp.health.From.Y - healthPercentage * boxSize.Y)
                        esp.health.Color = ESP_SETTINGS.HealthLowColor:Lerp(ESP_SETTINGS.HealthHighColor, healthPercentage)
                    else
                        esp.healthOutline.Visible = false
                        esp.health.Visible = false
                    end
                    
                    if ESP_SETTINGS.ShowSkeletons and ESP_SETTINGS.Enabled then
                        if #esp.skeletonLines == 0 then
                            for _, bonePair in ipairs(bones) do
                                local parentBone, childBone = bonePair[1], bonePair[2]
                                if character:FindFirstChild(parentBone) and character:FindFirstChild(childBone) then
                                    local skeletonLine = create("Line", { Thickness = 1, Color = ESP_SETTINGS.SkeletonColor, Transparency = 1 })
                                    table.insert(esp.skeletonLines, {skeletonLine, parentBone, childBone})
                                end
                            end
                        end
                        for _, lineData in ipairs(esp.skeletonLines) do
                            local skeletonLine = lineData[1]
                            local parentBone, childBone = lineData[2], lineData[3]
                            if character:FindFirstChild(parentBone) and character:FindFirstChild(childBone) then
                                local parentPosition = camera:WorldToViewportPoint(character[parentBone].Position)
                                local childPosition = camera:WorldToViewportPoint(character[childBone].Position)
                                skeletonLine.From = Vector2.new(parentPosition.X, parentPosition.Y)
                                skeletonLine.To = Vector2.new(childPosition.X, childPosition.Y)
                                skeletonLine.Color = ESP_SETTINGS.SkeletonColor
                                skeletonLine.Visible = true
                            else
                                skeletonLine.Visible = false
                            end
                        end
                    else
                        for _, lineData in ipairs(esp.skeletonLines) do
                            lineData[1].Visible = false
                        end
                    end

                    if ESP_SETTINGS.ShowLine and ESP_SETTINGS.Enabled then
                        esp.line.Visible = true
                        esp.line.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                        esp.line.To = Vector2.new(hrp2D.X, hrp2D.Y)
                        esp.line.Color = ESP_SETTINGS.LineColor
                    else
                        esp.line.Visible = false
                    end
                else
                    esp.box.Visible = false
                    esp.boxOutline.Visible = false
                    esp.name.Visible = false
                    esp.healthOutline.Visible = false
                    esp.health.Visible = false
                    esp.line.Visible = false
                    for _, line in ipairs(esp.boxLines) do
                        line.Visible = false
                    end
                    for _, lineData in ipairs(esp.skeletonLines) do
                        lineData[1].Visible = false
                    end
                end
            else
                esp.box.Visible = false
                esp.boxOutline.Visible = false
                esp.name.Visible = false
                esp.healthOutline.Visible = false
                esp.health.Visible = false
                esp.line.Visible = false
                for _, line in ipairs(esp.boxLines) do
                    line.Visible = false
                end
                for _, lineData in ipairs(esp.skeletonLines) do
                    lineData[1].Visible = false
                end
            end
        else
            esp.box.Visible = false
            esp.boxOutline.Visible = false
            esp.name.Visible = false
            esp.healthOutline.Visible = false
            esp.health.Visible = false
            esp.line.Visible = false
            for _, line in ipairs(esp.boxLines) do
                line.Visible = false
            end
            for _, lineData in ipairs(esp.skeletonLines) do
                lineData[1].Visible = false
            end
        end
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= localPlayer then
        createEsp(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= localPlayer then
        createEsp(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeEsp(player)
end)

RunService.RenderStepped:Connect(updateEsp)

-- -- -- -- -- -- -- AIMBOT -- -- -- -- -- -- --

local Cam = workspace.CurrentCamera
local hotkey = true

_G.Aimbot = true
_G.AimbotButton = false
_G.TeamCheck = true
_G.Part = "Head"

_G.SafePlayer = nil

_G.Fov = true
_G.FovPreencher = true
_G.FovRadius = 50
_G.FovColor = Color3.new(128/255, 25/255, 25/255)
_G.FovAlertColor = Color3.new(240/255, 240/255, 240/255) -- Cor de alerta
_G.FovColorChangeEnabled = true -- Variável para ativar/desativar a mudança de cor

_G.WallCheck = true  -- Ativar/Desativar o WallCheck

_G.Crossahair = true
_G.Preencher = true
_G.CrosshairColor2 = Color3.new(128/255, 25/255, 25/255)
_G.CrosshairRadius = 2
_G.CrosshairTrans = 1

local FovCircle = Drawing.new("Circle")
FovCircle.Visible = _G.Fov
FovCircle.Thickness = 2
FovCircle.Color = _G.FovColor
FovCircle.Filled = _G.FovPreencher
FovCircle.Radius = _G.FovRadius
FovCircle.Position = Cam.ViewportSize / 2
FovCircle.Transparency = 1

local Croshair = Drawing.new("Circle")
Croshair.Visible = _G.Crossahair
Croshair.Thickness = 2
Croshair.Color = _G.CrosshairColor2
Croshair.Filled = _G.Preencher
Croshair.Radius = _G.CrosshairRadius
Croshair.Position = Cam.ViewportSize / 2
Croshair.Transparency = _G.CrosshairTrans

function lookAt(target, eye)
    Cam.CFrame = CFrame.new(target, eye)
end

function isPlayerVisible(player)
    if not _G.WallCheck then
        return true
    end

    local startPos = Cam.CFrame.p
    local endPos = player.Character[_G.Part].Position
    local direction = (endPos - startPos).unit * (endPos - startPos).magnitude
    local ray = Ray.new(startPos, direction)
    local ignoreList = {game.Players.LocalPlayer.Character}

    local hitPart, hitPos = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
    
    return hitPart == nil or hitPart:IsDescendantOf(player.Character) -- Retorna true se não houver obstruções
end

function getClosestVisiblePlayer(trg_part)
    local nearest = nil
    local last = math.huge
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer and player.Name ~= _G.SafePlayer and player.Character and player.Character:FindFirstChild(trg_part) then
            local ePos, vis = workspace.CurrentCamera:WorldToViewportPoint(player.Character[trg_part].Position)
            local AccPos = Vector2.new(ePos.x, ePos.y)
            local mousePos = Vector2.new(workspace.CurrentCamera.ViewportSize.x / 2, workspace.CurrentCamera.ViewportSize.y / 2)
            local distance = (AccPos - mousePos).magnitude
            if distance < last and vis and hotkey and distance < 400 then
                if distance < _G.FovRadius then
                    -- Adicionado: verificação de equipe
                    if _G.TeamCheck and player.Team ~= game.Players.LocalPlayer.Team then
                        if isPlayerVisible(player) then -- Verifica se o jogador está visível
                            last = distance
                            nearest = player
                        end
                    elseif not _G.TeamCheck then
                        if isPlayerVisible(player) then -- Verifica se o jogador está visível
                            last = distance
                            nearest = player
                        end
                    end
                end
            end
        end
    end
    return nearest
end

game:GetService("RunService").RenderStepped:Connect(function()
    local closest = getClosestVisiblePlayer(_G.Part)
    
    if closest and closest.Character:FindFirstChild(_G.Part) then
        if _G.FovColorChangeEnabled and isPlayerVisible(closest) then
            -- Quando um jogador é detectado dentro do FOV
            FovCircle.Color = _G.FovAlertColor  -- Muda para a cor de alerta

            -- Retorna à cor original após um pequeno delay
            wait(0.1)  -- Tempo que a cor ficará mudada
            FovCircle.Color = _G.FovColor  -- Retorna à cor original
        end
    else
        FovCircle.Color = _G.FovColor  -- Mantém a cor original se não houver jogadores
    end

    if _G.Aimbot and closest and closest.Character:FindFirstChild(_G.Part) then
        lookAt(Cam.CFrame.p, closest.Character:FindFirstChild(_G.Part).Position)
    end
end)

-- -- -- -- -- -- -- AIMBOT BUTTON -- -- -- -- -- -- --

local Gui = Instance.new("ScreenGui")
Gui.ResetOnSpawn = false
Gui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

_G.HudBt = false

local buttonAimbot = Instance.new("TextButton")
buttonAimbot.Size = UDim2.new(0, 69, 0, 69)
buttonAimbot.Position = UDim2.new(0, 170, 0, -25)
buttonAimbot.Text = "Aimbot Off"
buttonAimbot.Visible = true
buttonAimbot.TextColor3 = Color3.fromRGB(240, 240, 240)
buttonAimbot.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
buttonAimbot.BorderSizePixel = 0
buttonAimbot.Parent = Gui
buttonAimbot.Active = _G.HudBt
buttonAimbot.Draggable = _G.HudBt

local Aim = Instance.new("UICorner")
Aim.CornerRadius = UDim.new(0, 12)
Aim.Parent = buttonAimbot

local isAimbotOn = false

local function Aimbot()
    if isAimbotOn == true then
        buttonAimbot.Text = "Aimbot On"
        _G.Aimbot = true
    else
        buttonAimbot.Text = "Aimbot Off"
        _G.Aimbot = false
    end
    isAimbotOn = not isAimbotOn
end

buttonAimbot.MouseButton1Click:Connect(Aimbot)

-- -- -- -- -- -- -- CROSSHAIR + -- -- -- -- -- -- --     

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local Typing = false

local ViewportSize_ = Camera.ViewportSize / 2
local Axis_X, Axis_Y = ViewportSize_.X, ViewportSize_.Y

local HorizontalLine = Drawing.new("Line")
local VerticalLine = Drawing.new("Line")

_G.ToMouse = true   -- If set to true then the crosshair will be positioned to your mouse cursor's position. If set to false it will be positioned to the center of your screen.

_G.CrosshairVisible = true   -- If set to true then the crosshair would be visible and vice versa.
_G.CrosshairSize = 20   -- The size of the crosshair.
_G.CrosshairThickness = 1   -- The thickness of the crosshair.
_G.CrosshairColor = Color3.fromRGB(0, 255, 0)   -- The color of the crosshair
_G.CrosshairTransparency = 1   -- The transparency of the crosshair.

RunService.RenderStepped:Connect(function()
    local Real_Size = _G.CrosshairSize / 2

    HorizontalLine.Color = _G.CrosshairColor
    HorizontalLine.Thickness = _G.CrosshairThickness
    HorizontalLine.Visible = _G.CrosshairVisible
    HorizontalLine.Transparency = _G.CrosshairTransparency
    
    VerticalLine.Color = _G.CrosshairColor
    VerticalLine.Thickness = _G.CrosshairThickness
    VerticalLine.Visible = _G.CrosshairVisible
    VerticalLine.Transparency = _G.CrosshairTransparency
    
    if _G.ToMouse == true then
        HorizontalLine.From = Vector2.new(UserInputService:GetMouseLocation().X - Real_Size, UserInputService:GetMouseLocation().Y)
        HorizontalLine.To = Vector2.new(UserInputService:GetMouseLocation().X + Real_Size, UserInputService:GetMouseLocation().Y)
        
        VerticalLine.From = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y - Real_Size)
        VerticalLine.To = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y + Real_Size)
    elseif _G.ToMouse == false then
        HorizontalLine.From = Vector2.new(Axis_X - Real_Size, Axis_Y)
        HorizontalLine.To = Vector2.new(Axis_X + Real_Size, Axis_Y)
    
        VerticalLine.From = Vector2.new(Axis_X, Axis_Y - Real_Size)
        VerticalLine.To = Vector2.new(Axis_X, Axis_Y + Real_Size)
    end
end)

UserInputService.TextBoxFocused:Connect(function()
    Typing = true
end)

UserInputService.TextBoxFocusReleased:Connect(function()
    Typing = false
end)

-- -- -- -- -- -- -- HITBOX -- -- -- -- -- -- --

_G.Hitbox = true
_G.HitboxRGB = true
_G.HitboxTeam = true
_G.HitboxRGBTime = 0.3
_G.HitboxSize = 20
_G.HitboxTransparency = 0.7
_G.PartHitbox = "HumanoidRootPart"
_G.HitboxColor = Color3.fromRGB(128, 25, 25)

local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer
local Teams = game:GetService('Teams')

local function isEnemy(player)
    if not _G.HitboxTeam or not Teams:GetTeams() then
        return true -- Se HitboxTeam não estiver ativo, todos são considerados inimigos
    end

    -- Verifica se o jogador pertence a uma equipe diferente
    return player.Team ~= LocalPlayer.Team
end

local function updateHitbox(player, size, transparency, color, material, canCollide)
    pcall(function()
        if player.Character and player.Character:FindFirstChild(_G.PartHitbox) then
            local part = player.Character[_G.PartHitbox]
            part.Size = size
            part.Transparency = transparency
            part.BrickColor = BrickColor.new(color)
            part.Material = material
            part.CanCollide = canCollide
        end
    end)
end

local function onPlayerAdded(player)
    player.CharacterAdded:Connect(function(character)
        -- Aguarda até que o personagem tenha a parte da hitbox
        character:WaitForChild(_G.PartHitbox)
        -- Atualiza a hitbox quando o personagem é adicionado
        if player ~= LocalPlayer and _G.Hitbox and isEnemy(player) then
            updateHitbox(player, Vector3.new(_G.HitboxSize, _G.HitboxSize, _G.HitboxSize), _G.HitboxTransparency, _G.HitboxColor, "Neon", false)
        else
            updateHitbox(player, Vector3.new(2, 2, 2), 1, _G.HitboxColor, "Plastic", true)
        end
    end)
end

local function Hitbox()
    game:GetService('RunService').RenderStepped:Connect(function()
        for _, player in next, Players:GetPlayers() do
            if player ~= LocalPlayer and player.Character then
                if _G.Hitbox and isEnemy(player) then
                    -- Modifica a hitbox apenas para jogadores adversários
                    updateHitbox(player, Vector3.new(_G.HitboxSize, _G.HitboxSize, _G.HitboxSize), _G.HitboxTransparency, _G.HitboxColor, "Neon", false)
                else
                    -- Modifica a hitbox para todos quando o Aimbot está desativado
                    updateHitbox(player, Vector3.new(2, 2, 2), 1, _G.HitboxColor, "Plastic", true)
                end
            end
        end
    end)
end

-- Conectar a função onPlayerAdded para jogadores que entram
Players.PlayerAdded:Connect(onPlayerAdded)

-- Conectar os jogadores que já estão no jogo
for _, player in next, Players:GetPlayers() do
    onPlayerAdded(player)
end

Hitbox()

local function HitboxRGB()
    while _G.HitboxRGB == true do
        wait(_G.HitboxRGBTime)
            _G.HitboxColor = Color3.fromRGB(255, 0, 0)
        wait(_G.HitboxRGBTime)
            _G.HitboxColor = Color3.fromRGB(0, 255, 0)
        wait(_G.HitboxRGBTime)
            _G.HitboxColor = Color3.fromRGB(0, 0, 255)
    end
end

-- -- -- -- -- -- -- Chams -- -- -- -- -- -- --


local FillColor = Color3.fromRGB(128, 25, 25)
local DepthMode = "AlwaysOnTop"
local FillTransparency = 0.5
local OutlineColor = Color3.fromRGB(255, 255, 255)
local OutlineTransparency = 0

local CoreGui = game:FindService("CoreGui")
local Players = game:FindService("Players")
local lp = Players.LocalPlayer
local connections = {}

local Storage = Instance.new("Folder")
Storage.Parent = CoreGui
Storage.Name = "Highlight_Storage"

_G.HighlightEnabled = true -- Variável de ativação

local function Highlight(plr)
    if not _G.HighlightEnabled then return end -- Verifica se o destaque está ativado

    local Highlight = Instance.new("Highlight")
    Highlight.Name = plr.Name
    Highlight.FillColor = FillColor
    Highlight.DepthMode = DepthMode
    Highlight.FillTransparency = FillTransparency
    Highlight.OutlineColor = OutlineColor
    Highlight.OutlineTransparency = OutlineTransparency
    Highlight.Parent = Storage
    
    local plrchar = plr.Character
    if plrchar then
        Highlight.Adornee = plrchar
    end

    connections[plr] = plr.CharacterAdded:Connect(function(char)
        Highlight.Adornee = char
    end)
end

Players.PlayerAdded:Connect(Highlight)
for i, v in next, Players:GetPlayers() do
    Highlight(v)
end

Players.PlayerRemoving:Connect(function(plr)
    local plrname = plr.Name
    if Storage:FindFirstChild(plrname) then
        Storage[plrname]:Destroy()
    end
    if connections[plr] then
        connections[plr]:Disconnect()
    end
end)

-- Adicionando uma função para ativar/desativar o Highlight dinamicamente
function ToggleHighlight(state)
    _G.HighlightEnabled = state
    if not state then
        for i, v in pairs(Storage:GetChildren()) do
            v:Destroy()
        end
        for plr, conn in pairs(connections) do
            conn:Disconnect()
        end
        connections = {}
    else
        for i, v in next, Players:GetPlayers() do
            Highlight(v)
        end
    end
end
-- -- -- -- -- -- -- Scripts -- -- -- -- -- -- --

local Toggle = Tabs.M:AddToggle("MyToggle", {
    Title = "Aimbot",
    Description = "And a function that automatically positions the player's aim towards the head .",
    Default = false,
    Callback = function(Value)
        _G.Aimbot = not _G.Aimbot
    end
})

local Toggle = Tabs.M:AddToggle("aimbotb", {
    Title = "Aimbot Button",
    Description = "Adds an on-screen button to activate and deactivate Aimbot.",
    Default = false,
    Callback = function(Value)
        buttonAimbot.Visible = not buttonAimbot.Visible
    end
})

local Toggle = Tabs.M:AddToggle("team", {
    Title = " Aimbot Team Check",
    Description = "Activates a system that makes the Aimbot only target players on the anniversary team.",
    Default = false,
    Callback = function(Value)
        _G.TeamCheck = not _G.TeamCheck
    end
})

local Toggle = Tabs.M:AddToggle("Wallcheck", {
    Title = " Wallcheck Aimbot",
    Description = "Activates a system where the Aimbot will only focus on visible players.",
    Default = false,
    Callback = function(Value)
        _G.WallCheck = not _G.WallCheck
    end
})

local blabla = Tabs.M:AddSection("Fov Section")

local Toggle = Tabs.M:AddToggle("fov", {
    Title = "Aim Fov",
    Description = "Adds a circle to the middle of the screen if a player enters and the Aimbot will target that player.",
    Default = false,
    Callback = function(Value)
        FovCircle.Visible = not FovCircle.Visible
    end
})

local Toggle = Tabs.M:AddToggle("fovcam", {
    Title = "Fov Alert",
    Description = "Activates a warning system for the fov.",
    Default = false,
    Callback = function(Value)
        _G.FovColorChangeEnabled = Value
    end
})

local blabla = Tabs.M:AddSection("Aimbot Settings")

local Toggle = Tabs.M:AddToggle("hudbutton", {
    Title = "Change Hud Aimbot Button",
    Description = "Change the hud of the button to activate the Aimbot.",
    Default = false,
    Callback = function(Value)
        if Value == true then
            buttonAimbot.Active = true
            buttonAimbot.Draggable = true
        else
            buttonAimbot.Active = false
            buttonAimbot.Draggable = false
        end
    end
})

local Dropdown = Tabs.M:AddDropdown("dropdown", {
    Title = "Aimbot Auto-Aim",
    Values = {"Head", "Body"},
    Description = "Choose where Aimbot will focus.",
    Multi = false,
    Default = "Head",
    Callback = function(Value)
        if Value == "Head" then
            _G.Part = "Head"
        elseif Value == "Body" then
            _G.Part = "HumanoidRootPart"
        end
    end
})

function getPlayerNamesAimbot()
    local PL = {}
    for _, player in pairs(game.Players:GetPlayers()) do
        table.insert(PL, player.Name)
    end
    return PL
end

local PlayersAimbot = getPlayerNamesAimbot()

local Dropdown = Tabs.M:AddDropdown("dropdown", {
    Title = "Select Safe Player",
    Values = PlayersAimbot,
    Description = "Choose players so the aimbot doesn't aim.",
    Multi = false,
    Default = 1,
    Callback = function(Value)
        _G.SafePlayer = Value
    end
})

local function UpAimbot()
    local PlayersAimbot = getPlayerNamesAimbot()
    Dropdown:SetValues(PlayersAimbot)
end

Tabs.M:AddButton({
    Title = "Update Aimbot Players",
    Description = "Update the player list",
    Callback = function()
        UpAimbot()
    end
})

local blabla = Tabs.M:AddSection("Aim Fov Settings")

local Toggle = Tabs.M:AddToggle("jd", {
    Title = "Fill Fov",
    Description = "Choose whether the fov will be filled or just an empty circle.",
    Default = false,
    Callback = function(Value)
        FovCircle.Filled = Value
    end
})

local Trans = Tabs.M:AddDropdown("hr", {
    Title = "Fov Transparency",
    Values = {"0", "0.1", "0.2", "0.3", "0.4", "0.5", "0.6", "0.7", "0.8", "0.9", "1"}, 
    Multi = false,
    Default = "0.7",
    Callback = function(Value)
        if Value == "0" then
            FovCircle.Transparency = 0
        elseif Value == "0.1" then
            FovCircle.Transparency = 0.1
        elseif Value == "0.2" then
            FovCircle.Transparency = 0.2
        elseif Value == "0.3" then
            FovCircle.Transparency = 0.3
        elseif Value == "0.4" then
            FovCircle.Transparency = 0.4
        elseif Value == "0.5" then
            FovCircle.Transparency = 0.5
        elseif Value == "0.6" then
            FovCircle.Transparency = 0.6
        elseif Value == "0.7" then
            FovCircle.Transparency = 0.7
        elseif Value == "0.8" then
            FovCircle.Transparency = 0.8
        elseif Value == "0.9" then
            FovCircle.Transparency = 0.9
        elseif Value == "1" then
            FovCircle.Transparency = 1
        end
    end
})

local Dropdown = Tabs.M:AddDropdown("precisão", {
    Title = "Aimbot Accuracy",
    Values = {"25", "35", "50", "70", "100"},
    Multi = false,
    Default = "50",
    Callback = function(Value)
        if Value == "25" then
            _G.FovRadius = 25
            FovCircle.Radius = 25
        elseif Value == "35" then
            _G.FovRadius = 35
            FovCircle.Radius = 36
        elseif Value == "50" then
            _G.FovRadius = 50
            FovCircle.Radius = 50
        elseif Value == "70" then
            _G.FovRadius = 70
            FovCircle.Radius = 70
        elseif Value == "100" then
            _G.FovRadius = 100
            FovCircle.Radius = 100
        end
    end
})

local Colorpicker = Tabs.M:AddColorpicker("Colorpicker", {
        Title = "Aim Fov Color",
        Default = Color3.fromRGB(128, 25, 25)
    })
    Colorpicker:OnChanged(function()
        _G.FovColor = Colorpicker.Value
        FovCircle.Color = Colorpicker.Value
    end)
    
    

local partHit = Tabs.H:AddDropdown("partHit", {
    Title = "Hitbox Parties",
    Values = {"Body", "Head"}, 
    Multi = false,
    Default = "Body",
    Callback = function(Value)
        _G.PartHitbox = (Value == "Body") and "HumanoidRootPart" or "Head"
    end
})

local Toggle = Tabs.H:AddToggle("hitbox", {
    Title = "Hitbox",
    Description = "Allows you to increase players' hitbox and can kill them through walls.",
    Default = false,
    Callback = function(Value)
        _G.Hitbox = Value
    end
})

local Toggle = Tabs.H:AddToggle("Hteam", {
    Title = " Hitbox Team Check",
    Description = "Activates a system that makes the Hitbox only target players on the anniversary team.",
    Default = false,
    Callback = function(Value)
        _G.HitboxTeam = not _G.HitboxTeam
    end
})

local HitboxSettings = Tabs.H:AddSection("Hitbox Settings")

local SizeSlider = Tabs.H:AddSlider("Size", {
    Title = "Hitbox Size",
    Description = "Allows you to change the size of players' hitbox.",
    Default = 20,
    Min = 10,
    Max = 150,
    Rounding = 1,
    Callback = function(Value)
        _G.HitboxSize = Value
    end
})

local Trans = Tabs.H:AddDropdown("Trans", {
    Title = "Hitbox Transparency",
    Values = {"0", "0.1", "0.2", "0.3", "0.4", "0.5", "0.6", "0.7", "0.8", "0.9", "1"}, 
    Multi = false,
    Default = "0.7",
    Callback = function(Value)
        if Value == "0" then
            _G.HitboxTransparency = 0
        elseif Value == "0.1" then
            _G.HitboxTransparency = 0.1
        elseif Value == "0.2" then
            _G.HitboxTransparency = 0.2
        elseif Value == "0.3" then
            _G.HitboxTransparency = 0.3
        elseif Value == "0.4" then
            _G.HitboxTransparency = 0.4
        elseif Value == "0.5" then
            _G.HitboxTransparency = 0.5
        elseif Value == "0.6" then
            _G.HitboxTransparency = 0.6
        elseif Value == "0.7" then
            _G.HitboxTransparency = 0.7
        elseif Value == "0.8" then
            _G.HitboxTransparency = 0.8
        elseif Value == "0.9" then
            _G.HitboxTransparency = 0.9
        elseif Value == "1" then
            _G.HitboxTransparency = 1
        end
    end
})

local ColorpickerHitb = Tabs.H:AddColorpicker("ColorpickerHitb", {
    Title = "Hitbox Color",
    Description = "Change the hitbox color at any time.",
    Default = Color3.fromRGB(128, 25, 25)
})

ColorpickerHitb:OnChanged(function(Color)
    _G.HitboxColor = Color
end)

local Toggle = Tabs.H:AddToggle("urue", {
    Title = "Hitbox Rgb",
    Description = "Makes the hitbox flash in Red, Green and Blue colors.",
    Default = false,
    Callback = function(Value)
        if Value == true then
            _G.HitboxRGB = true
            HitboxRGB()
        else
            _G.HitboxRGB = false
            _G.HitboxColor = Color3.fromRGB(128, 25, 25)
        end
    end
})
    
local Toggle = Tabs.V:AddToggle("TeamChek", {
    Title = "Esps Team Check All",
    Description = "Activates a system that allows ESP to show players from the anniversary team",
    Default = false,
    Callback = function(Value)
      ESP_SETTINGS.Teamcheck = Value
    end
})
   
local Toggle = Tabs.V:AddToggle("Wallcheck", {
    Title = "Esps Wall Check All",
    Description = "Activates a system that only shows players.",
    Default = false,
    Callback = function(Value)
      ESP_SETTINGS.WallCheck = Value
    end
})

ESP_SETTINGS.Enabled = true

-- -- -- -- UI Elements -- -- -- --

local Visual = Tabs.V:AddSection("Visual Settings")

local Toggle = Tabs.V:AddToggle("Show Box", {
    Title = "Show Box",
    Description = "Adds a box around the players.",
    Default = false,
    Callback = function(value)
        ESP_SETTINGS.ShowBox = value
    end
})

local Toggle = Tabs.V:AddToggle("Show Health", {
    Title = "Show Health",
    Description = "Adds a health bar next to players.",
    Default = false,
    Callback = function(value)
        ESP_SETTINGS.ShowHealth = value
    end
})

local Toggle = Tabs.V:AddToggle("Show Skeletons", {
    Title = "Show Skeletons",
    Description = "Adds a skeleton of the players.",
    Default = false,
    Callback = function(value)
        ESP_SETTINGS.ShowSkeletons = value
    end
})

local Toggle = Tabs.V:AddToggle("Show Line", {
    Title = "Show Line",
    Description = "Adds a line from the bottom center of the screen to each player.",
    Default = false,
    Callback = function(value)
        ESP_SETTINGS.ShowLine = value
    end
})

local Toggle = Tabs.V:AddToggle("Show Name", {
    Title = "Show Name",
    Description = "Adds a small text above the players head.",
    Default = false,
    Callback = function(value)
        ESP_SETTINGS.ShowName = value
    end
})

local Toggle = Tabs.V:AddToggle("Show Chams", {
    Title = "Show Chams",
    Description = "Adds a glow around players.",
    Default = false,
    Callback = function(Value)
        if Value == true then
            ToggleHighlight(true)
        else
            ToggleHighlight(false)
        end
    end
})

local EspSettings = Tabs.V:AddSection("Esp Settings")

_G.RgbEspAll = true
_G.RgbEspAllSpeed = 0.3

local function RgbEspAll()
      while _G.RgbEspAll == true do
            wait(_G.RgbEspAllSpeed)
      ESP_SETTINGS.BoxColor = Color3.fromRGB(255, 0, 0)
      ESP_SETTINGS.HealthLowColor = Color3.fromRGB(255, 0, 0)
      ESP_SETTINGS.HealthHighColor = Color3.fromRGB(255, 0, 0)
      ESP_SETTINGS.SkeletonColor = Color3.fromRGB(255, 0, 0)
      ESP_SETTINGS.LineColor = Color3.fromRGB(255, 0, 0)
      ESP_SETTINGS.NameColor = Color3.fromRGB(255, 0, 0)
            wait(_G.RgbEspAllSpeed)
      ESP_SETTINGS.BoxColor = Color3.fromRGB(0, 255, 0)
      ESP_SETTINGS.HealthLowColor = Color3.fromRGB(0, 255, 0)
      ESP_SETTINGS.HealthHighColor = Color3.fromRGB(0, 255, 0)
      ESP_SETTINGS.SkeletonColor = Color3.fromRGB(0, 255, 0)
      ESP_SETTINGS.LineColor = Color3.fromRGB(0, 255, 0)
      ESP_SETTINGS.NameColor = Color3.fromRGB(0, 255, 0)
            wait(_G.RgbEspAllSpeed)
      ESP_SETTINGS.BoxColor = Color3.fromRGB(0, 0, 255)
      ESP_SETTINGS.HealthLowColor = Color3.fromRGB(0, 0, 255)
      ESP_SETTINGS.HealthHighColor = Color3.fromRGB(0, 0, 255)
      ESP_SETTINGS.SkeletonColor = Color3.fromRGB(0, 0, 255)
      ESP_SETTINGS.LineColor = Color3.fromRGB(0, 0, 255)
      ESP_SETTINGS.NameColor = Color3.fromRGB(0, 0, 255)
      end
end

local Toggle = Tabs.V:AddToggle("rgball", {
    Title = "Rgb All Esp",
    Description = "Adds a glow around players.",
    Default = false,
    Callback = function(Value)
        _G.RgbEspAll = Value
        RgbEspAll()
    end
})

local Trans = Tabs.V:AddDropdown("CTrans", {
    Title = "Rgb Speed",
    Values = {"0", "0.1", "0.2", "0.3", "0.4", "0.5", "0.6", "0.7", "0.8", "0.9", "1"},
    Multi = false,
    Default = _G.RgbEspAllSpeed,
    Callback = function(Value)
        if Value == "0" then
            _G.RgbEspAllSpeed = 0
        elseif Value == "0.1" then
            _G.RgbEspAllSpeed = 0.1
        elseif Value == "0.2" then
            _G.RgbEspAllSpeed = 0.2
        elseif Value == "0.3" then
            _G.RgbEspAllSpeed = 0.3
        elseif Value == "0.4" then
            _G.RgbEspAllSpeed = 0.4
        elseif Value == "0.5" then
            _G.RgbEspAllSpeed = 0.5
        elseif Value == "0.6" then
            _G.RgbEspAllSpeed = 0.6
        elseif Value == "0.7" then
            _G.RgbEspAllSpeed = 0.7
        elseif Value == "0.8" then
            _G.RgbEspAllSpeed = 0.8
        elseif Value == "0.9" then
            _G.RgbEspAllSpeed = 0.9
        elseif Value == "1" then
            _G.RgbEspAllSpeed = 1
        end
    end
})

local BoxTypeDropdown = Tabs.V:AddDropdown("BoxType", {
    Title = "Box Type",
    Values = {"Corner", "2D"},
    Description = "Box types",
    Default = ESP_SETTINGS.BoxType,
    Callback = function(value)
      ESP_SETTINGS.BoxType = value
        -- Ensure only one type of box is visible at a time
        for _, esp in pairs(cache) do
            if value == "2D" then
                esp.box.Visible = ESP_SETTINGS.ShowBox
                esp.boxOutline.Visible = ESP_SETTINGS.ShowBox
                for _, line in ipairs(esp.boxLines) do
                    line.Visible = false
                end
            elseif value == "Corner" then
                for _, line in ipairs(esp.boxLines) do
                    line.Visible = ESP_SETTINGS.ShowBox
                end
                esp.box.Visible = false
                esp.boxOutline.Visible = false
            end
        end
    end
})

local EspBoxColor = Tabs.V:AddColorpicker("BoxColor", {
    Title = "Box Color",
    Description = "Change the color of the esp.",
    Default = ESP_SETTINGS.BoxColor,
    Callback = function(color)
        ESP_SETTINGS.BoxColor = color
    end
})

local HealthLowColor = Tabs.V:AddColorpicker("HealthLowColor", {
    Title = "Health Low Color",
    Description = "Change the color of the esp.",
    Default = ESP_SETTINGS.HealthLowColor,
    Callback = function(color)
        ESP_SETTINGS.HealthLowColor = color
    end
})

local HealthHighColor = Tabs.V:AddColorpicker("HealthHighColor", {
    Title = "Health High Color",
    Description = "Change the color of the esp.",
    Default = ESP_SETTINGS.HealthHighColor,
    Callback = function(color)
        ESP_SETTINGS.HealthHighColor = color
    end
})

local SkeletonColor = Tabs.V:AddColorpicker("SkeletonColor", {
    Title = "Skeleton Color",
    Description = "Change the color of the esp.",
    Default = ESP_SETTINGS.SkeletonColor,
    Callback = function(color)
        ESP_SETTINGS.SkeletonColor = color
    end
})

local LineColor = Tabs.V:AddColorpicker("LineColor", {
    Title = "Line Color",
    Description = "Change the color of the esp.",
    Default = ESP_SETTINGS.LineColor,
    Callback = function(color)
        ESP_SETTINGS.LineColor = color
    end
})

local NameColor = Tabs.V:AddColorpicker("NameColor", {
    Title = "Name Color",
    Description = "Change the color of the esp.",
    Default = ESP_SETTINGS.NameColor,
    Callback = function(color)
        ESP_SETTINGS.NameColor = color
    end
})

local gj = Tabs.C:AddToggle("Cros", {
    Title = "Crosshair •",
    Description = "Adds a small circle acting as a crosshair.",
    Default = false,
    Callback = function(Value)
        Croshair.Visible = not Croshair.Visible
    end 
})

local Toggle = Tabs.C:AddToggle("Cross", {
    Title = "Crosshair +", 
    Description = "Adds a small plus function as a crosshair.",
    Default = false,
    Callback = function(Value)
        _G.CrosshairVisible = Value
    end
})

local blabla = Tabs.C:AddSection("Crosshair Point Settings")

local Toggle = Tabs.C:AddToggle("Cros", {
    Title = "To fill in Crosshair",
    Description = "Allows the player to choose whether they prefer the filled crosshair or just a border.",
    Default = false,
    Callback = function(Value)
        Croshair.Filled = not Croshair.Filled
    end 
})

local Trans = Tabs.C:AddDropdown("CTrans", {
    Title = "Crosshair Transparency",
    Values = {"0", "0.1", "0.2", "0.3", "0.4", "0.5", "0.6", "0.7", "0.8", "0.9", "1"}, 
    Multi = false,
    Default = "1",
    Callback = function(Value)
        if Value == "0" then
            Croshair.Transparency = 0
        elseif Value == "0.1" then
            Croshair.Transparency = 0.1
        elseif Value == "0.2" then
            Croshair.Transparency = 0.2
        elseif Value == "0.3" then
            Croshair.Transparency = 0.3
        elseif Value == "0.4" then
            Croshair.Transparency = 0.4
        elseif Value == "0.5" then
            Croshair.Transparency = 0.5
        elseif Value == "0.6" then
            Croshair.Transparency = 0.6
        elseif Value == "0.7" then
            Croshair.Transparency = 0.7
        elseif Value == "0.8" then
            Croshair.Transparency = 0.8
        elseif Value == "0.9" then
            Croshair.Transparency = 0.9
        elseif Value == "1" then
            Croshair.Transparency = 1
        end
    end
})

local Slider = Tabs.C:AddSlider("CrosZ", {
    Title = "Crosshair Size",
    Description = "Change crosshair size at any time",
    Default = 2,
    Min = 1,
    Max = 20,
    Rounding = 1,
    Callback = function(Value)
        Croshair.Radius = Value
    end
})

local ColorpickerHH = Tabs.C:AddColorpicker("ColorpickerHH", {
    Title = "Crosshair Color •",
    Description = "Change crosshair color.",
    Default = Color3.fromRGB(128, 25, 25)
})
ColorpickerHH:OnChanged(function()
    Croshair.Color = ColorpickerHH.Value
end)

_G.RGBPonto = true
_G.RGBTime = 0.3

local function RGBPonto()
    while _G.RGBPonto == true do
        wait(_G.RGBTime)
            Croshair.Color = Color3.fromRGB(255, 0, 0)
        wait(_G.RGBTime)
            Croshair.Color = Color3.fromRGB(0, 255, 0)
        wait(_G.RGBTime)
            Croshair.Color = Color3.fromRGB(0, 0, 255)
    end
end

local Toggle = Tabs.C:AddToggle("k", {
    Title = "Crosshair RGB",
    Description = "Let the crosshair blink Red, Green and Blue.",
    Default = false,
    Callback = function(Value)
        if Value == true then
            _G.RGBPonto = true
            RGBPonto()
        else
            _G.RGBPonto = false
            Croshair.Color = Color3.fromRGB(128, 25, 25)
        end
    end
})

local Trans = Tabs.C:AddDropdown("CTrans", {
    Title = "Rgb Speed",
    Values = {"0", "0.1", "0.2", "0.3", "0.4", "0.5", "0.6", "0.7", "0.8", "0.9", "1"},
    Multi = false,
    Default = _G.RGBTime,
    Callback = function(Value)
        if Value == "0" then
            _G.RGBTime = 0
        elseif Value == "0.1" then
            _G.RGBTime = 0.1
        elseif Value == "0.2" then
            _G.RGBTime = 0.2
        elseif Value == "0.3" then
            _G.RGBTime = 0.3
        elseif Value == "0.4" then
            _G.RGBTime = 0.4
        elseif Value == "0.5" then
            _G.RGBTime = 0.5
        elseif Value == "0.6" then
            _G.RGBTime = 0.6
        elseif Value == "0.7" then
            _G.RGBTime = 0.7
        elseif Value == "0.8" then
            _G.RGBTime = 0.8
        elseif Value == "0.9" then
            _G.RGBTime = 0.9
        elseif Value == "1" then
            _G.RGBTime = 1
        end
    end
})

local blabla = Tabs.C:AddSection("Crosshair Cross Settings")

local Trans = Tabs.C:AddDropdown("CTrans", {
    Title = "Crosshair Transparency",
    Values = {"0", "0.1", "0.2", "0.3", "0.4", "0.5", "0.6", "0.7", "0.8", "0.9", "1"}, 
    Multi = false,
    Default = "1",
    Callback = function(Value)
        if Value == "0" then
            _G.CrosshairTransparency = 0
        elseif Value == "0.1" then
            _G.CrosshairTransparency = 0.1
        elseif Value == "0.2" then
            _G.CrosshairTransparency = 0.2
        elseif Value == "0.3" then
            _G.CrosshairTransparency = 0.3
        elseif Value == "0.4" then
            _G.CrosshairTransparency = 0.4
        elseif Value == "0.5" then
            _G.CrosshairTransparency = 0.5
        elseif Value == "0.6" then
            _G.CrosshairTransparency = 0.6
        elseif Value == "0.7" then
            _G.CrosshairTransparency = 0.7
        elseif Value == "0.8" then
            _G.CrosshairTransparency = 0.8
        elseif Value == "0.9" then
            _G.CrosshairTransparency = 0.9
        elseif Value == "1" then
            _G.CrosshairTransparency = 1
        end
    end
})

local Slider = Tabs.C:AddSlider("CrosZ", {
    Title = "Crosshair Size",
    Description = "Change crosshair size at any time",
    Default = 2,
    Min = 1,
    Max = 20,
    Rounding = 1,
    Callback = function(Value)
        _G.CrosshairSize = Value
    end
})

local ColorpickerMM = Tabs.C:AddColorpicker("ColorpickerMM", {
    Title = "Crosshair Color +",
    Description = "Change crosshair color.",
    Default = Color3.fromRGB(128, 25, 25)
})
ColorpickerMM:OnChanged(function()
    _G.CrosshairColor = ColorpickerMM.Value
end)


speeds = 1
local speaker = game:GetService("Players").LocalPlayer
local chr = game.Players.LocalPlayer.Character
local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
nowe = false

local Toggle = Tabs.P:AddToggle("Fly", {
    Title = "Fly",
    Description = "Fly, Allows the player using the script to fly as if he were a map administrator.",
    Default = false,
    Callback = function(Value)
	if Value == true then
		nowe = true

	    for i = 1, speeds do
			spawn(function()

				local hb = game:GetService("RunService").Heartbeat	


				tpwalking = true
				local chr = game.Players.LocalPlayer.Character
				local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
				while tpwalking and hb:Wait() and chr and hum and hum.Parent do
					if hum.MoveDirection.Magnitude > 0 then
						chr:TranslateBy(hum.MoveDirection)
					end
				end

			end)
	    end
		game.Players.LocalPlayer.Character.Animate.Disabled = true
		local Char = game.Players.LocalPlayer.Character
		local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")

		for i,v in next, Hum:GetPlayingAnimationTracks() do
			v:AdjustSpeed(0)
		end
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,false)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying,false)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall,false)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,false)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed,false)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics,false)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding,false)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running,false)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics,false)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,false)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics,false)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming,false)
		speaker.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
	else 
		nowe = false

		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,true)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown,true)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying,true)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall,true)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,true)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,true)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed,true)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics,true)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding,true)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,true)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running,true)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics,true)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,true)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics,true)
		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming,true)
		speaker.Character.Humanoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
    end
    
	if game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid").RigType == Enum.HumanoidRigType.R6 then
	
		local plr = game.Players.LocalPlayer
		local torso = plr.Character.Torso
		local flying = true
		local deb = true
		local ctrl = {f = 0, b = 0, l = 0, r = 0}
		local lastctrl = {f = 0, b = 0, l = 0, r = 0}
		local maxspeed = 50
		local speed = 0

		local bg = Instance.new("BodyGyro", torso)
		bg.P = 9e4
		bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
		bg.cframe = torso.CFrame
		local bv = Instance.new("BodyVelocity", torso)
		bv.velocity = Vector3.new(0,0.1,0)
		bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
		if nowe == true then
			plr.Character.Humanoid.PlatformStand = true
		end
		while nowe == true or game:GetService("Players").LocalPlayer.Character.Humanoid.Health == 0 do
			game:GetService("RunService").RenderStepped:Wait()

			if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
				speed = speed+.5+(speed/maxspeed)
				if speed > maxspeed then
					speed = maxspeed
				end
			elseif not (ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0) and speed ~= 0 then
				speed = speed-1
				if speed < 0 then
					speed = 0
				end
			end
			if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
				bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (ctrl.f+ctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(ctrl.l+ctrl.r,(ctrl.f+ctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed
				lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
			elseif (ctrl.l + ctrl.r) == 0 and (ctrl.f + ctrl.b) == 0 and speed ~= 0 then
				bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (lastctrl.f+lastctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(lastctrl.l+lastctrl.r,(lastctrl.f+lastctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed
			else
				bv.velocity = Vector3.new(0,0,0)
			end
			--	game.Players.LocalPlayer.Character.Animate.Disabled = true
			bg.cframe = game.Workspace.CurrentCamera.CoordinateFrame * CFrame.Angles(-math.rad((ctrl.f+ctrl.b)*50*speed/maxspeed),0,0)
		end
		ctrl = {f = 0, b = 0, l = 0, r = 0}
		lastctrl = {f = 0, b = 0, l = 0, r = 0}
		speed = 0
		bg:Destroy()
		bv:Destroy()
		plr.Character.Humanoid.PlatformStand = false
		game.Players.LocalPlayer.Character.Animate.Disabled = false
		tpwalking = false
	else
		local plr = game.Players.LocalPlayer
		local UpperTorso = plr.Character.UpperTorso
		local flying = true
		local deb = true
		local ctrl = {f = 0, b = 0, l = 0, r = 0}
		local lastctrl = {f = 0, b = 0, l = 0, r = 0}
		local maxspeed = 50
		local speed = 0


		local bg = Instance.new("BodyGyro", UpperTorso)
		bg.P = 9e4
		bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
		bg.cframe = UpperTorso.CFrame
		local bv = Instance.new("BodyVelocity", UpperTorso)
		bv.velocity = Vector3.new(0,0.1,0)
		bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
		if nowe == true then
			plr.Character.Humanoid.PlatformStand = true
		end
		while nowe == true or game:GetService("Players").LocalPlayer.Character.Humanoid.Health == 0 do
			wait()

			if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
				speed = speed+.5+(speed/maxspeed)
				if speed > maxspeed then
					speed = maxspeed
				end
			elseif not (ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0) and speed ~= 0 then
				speed = speed-1
				if speed < 0 then
					speed = 0
				end
			end
			if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
				bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (ctrl.f+ctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(ctrl.l+ctrl.r,(ctrl.f+ctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed
				lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
			elseif (ctrl.l + ctrl.r) == 0 and (ctrl.f + ctrl.b) == 0 and speed ~= 0 then
				bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (lastctrl.f+lastctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(lastctrl.l+lastctrl.r,(lastctrl.f+lastctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed
			else
				bv.velocity = Vector3.new(0,0,0)
			end

			bg.cframe = game.Workspace.CurrentCamera.CoordinateFrame * CFrame.Angles(-math.rad((ctrl.f+ctrl.b)*50*speed/maxspeed),0,0)
		end
		ctrl = {f = 0, b = 0, l = 0, r = 0}
		lastctrl = {f = 0, b = 0, l = 0, r = 0}
		speed = 0
		bg:Destroy()
		bv:Destroy()
		plr.Character.Humanoid.PlatformStand = false
		game.Players.LocalPlayer.Character.Animate.Disabled = false
		tpwalking = false
    end
    end
})

game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function(char)
	wait(0.7)
	game.Players.LocalPlayer.Character.Humanoid.PlatformStand = false
	game.Players.LocalPlayer.Character.Animate.Disabled = false

end)

local SpeedFly = Tabs.P:AddSlider("SpeedFly", {
    Title = "Fly Speed",
    Description = "Change the speed of the Fly",
    Default = 1,
    Min = 1,
    Max = 30,
    Rounding = 1, 
    Callback = function(Value)
        speeds = Value
        if nowe == true then
            tpwalking = false
            for i = 1, speeds do
                spawn(function()
                    local hb = game:GetService("RunService").Heartbeat
                    tpwalking = true
                    local chr = game.Players.LocalPlayer.Character
                    local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
                    while tpwalking and hb:Wait() and chr and hum and hum.Parent do
                        if hum.MoveDirection.Magnitude > 0 then
                            chr:TranslateBy(hum.MoveDirection)
                        end
                    end
                end)
            end
        end
    end
})

local infiniteJumpEnabled = false

game:GetService("UserInputService").JumpRequest:Connect(function()
    if infiniteJumpEnabled then
        game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

local Toggle = Tabs.P:AddToggle("Jump", {
    Title = "Infinite Jump",
    Description = "When activated, it will be possible to jump infinitely.",
    Default = false,
    Callback = function(Value)
        if Value == true then
            infiniteJumpEnabled = true 
        else
            infiniteJumpEnabled = false
        end
    end
})

local Toggle = Tabs.P:AddToggle("Noclip", {
    Title = "Wallhack",
    Description = "Allows the player to pass through any wall, [CAUTION RISK OF LIMB/CROSS THE GROUND].",
    Default = false,
    Callback = function(Value)
        if Value == true then
            Clipon = true
            Stepped = game:GetService("RunService").Stepped:Connect(function()
			if not Clipon == false then
				for a, b in pairs(Workspace:GetChildren()) do
                if b.Name == Plr.Name then
                for i, v in pairs(Workspace[Plr.Name]:GetChildren()) do
                if v:IsA("BasePart") then
                v.CanCollide = false
                end end end end
			else
				Stepped:Disconnect()
			end
		    end)
        else
            Clipon = false
        end
    end
})

local function getPlayerNames()
    local playerNames = {}
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        table.insert(playerNames, player.Name)
    end
    return playerNames
end

local TpPl = Tabs.P:AddDropdown("TpPl", {
    Title = "Teleports to players",
    Description = "Select players for instant teleports to them",
    Values = getPlayerNames(), -- Adiciona os nomes dos jogadores aqui
    Multi = false,
    Default = 1,
    Callback = function(Value) -- Callback para a função de teleporte
        local player = game:GetService("Players"):FindFirstChild(Value)
    if player then
        local character = player.Character
        if character then
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                -- Teleporta o jogador para a posição do HumanoidRootPart
                game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = humanoidRootPart.CFrame
            end
        end
    end
    end
})

local function updatePlayerNamesDropdown()
    local playerNames = getPlayerNames()
    TpPl:SetValues(playerNames)
end

_G.SpeedHack = true
_G.SpeedHackSp = 16

local function SpeedHack()
    while _G.SpeedHack == true do
        wait(0.5)
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = _G.SpeedHackSp
    end
end

local Toggle = Tabs.P:AddToggle("j", {
    Title = "Speed Hack",
    Description = "Activates the speed hack.",
    Default = false,
    Callback = function(Value)
        _G.SpeedHack = Value
        SpeedHack()
    end
})

local Slider = Tabs.P:AddSlider("speed", {
      Title = "Speed Hack",
      Description = "Allows you to modify the player's speed.",
      Default = 16,
      Min = 16,
      Max = 250,
      Rounding = 1,
      Callback = function(Value)
            _G.SpeedHackSp = Value
      end
})

_G.JumpHack = true
_G.JumpHackF = 50

local function JumpHack()
    while _G.JumpHack == true do
        wait(0.5)
            game.Players.LocalPlayer.Character.Humanoid.JumpPower = _G.JumpHackF
    end
end

local Toggle = Tabs.P:AddToggle("j", {
    Title = "Jump Hack",
    Description = "Activates the jump hack.",
    Default = false,
    Callback = function(Value)
        _G.JumpHack = Value
        JumpHack()
    end
})
    
local Slider = Tabs.P:AddSlider("jump", {
        Title = "Jump Hack",
        Description = "Allows you to modify the strength of the player's jump.",
        Default = 50,
        Min = 50,
        Max = 250,
        Rounding = 1,
        Callback = function(Value)
            _G.JumpHackF = Value
        end
    })
    
Tabs.P:AddButton({
    Title = "Update Players",
    Description = "Update the player list",
    Callback = function()
        updatePlayerNamesDropdown()
    end
})

_G.TemaRGB = false
_G.TemaTime = 0.3

local function TemaRGB()
    while _G.TemaRGB == true do
        wait(_G.TemaTime)
            Fluent:SetTheme("Rose")
        wait(_G.TemaTime)
            Fluent:SetTheme("Aqua")
        wait(_G.TemaTime)
            Fluent:SetTheme("Amethyst")
    end
end

local f = Tabs.S:AddDropdown("kk", {
    Title = "Theme",
    Description = "",
    Values = {"Amethyst", "Aqua", "Dark", "Darker", "Light", "Rose"},
    Multi = false,
    Default = "Amethyst",
    Callback = function(Value)
        if Value == "Amethyst" then
            button.TextColor3 = Color3.fromRGB(240, 240, 240)
            button.BackgroundColor3 = Color3.fromRGB(60, 45, 80)
            Fluent:SetTheme(Value)
        elseif Value == "Aqua" then
            button.TextColor3 = Color3.fromRGB(240, 240, 240)
            button.BackgroundColor3 = Color3.fromRGB(60, 120, 120)
            Fluent:SetTheme(Value)
        elseif Value == "Dark" then
            button.TextColor3 = Color3.fromRGB(240, 240, 240)
            button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            Fluent:SetTheme(Value)
        elseif Value == "Darker" then
            button.TextColor3 = Color3.fromRGB(240, 240, 240)
            button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            Fluent:SetTheme(Value)
        elseif Value == "Light" then
            button.TextColor3 = Color3.fromRGB(0, 0, 0)
            button.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
            Fluent:SetTheme(Value)
        elseif Value == "Rose" then
            button.TextColor3 = Color3.fromRGB(240, 240, 240)
            button.BackgroundColor3 = Color3.fromRGB(180, 55, 90)
            Fluent:SetTheme(Value)
        end
    end
})

local f = Tabs.S:AddToggle("rbgtema", {
    Title = "Theme RGB",
    Description = "Make the menu background blink in Rgb.",
    Default = false,
    Callback = function(Value)
        if Value == true then
            _G.TemaRGB = true
            TemaRGB()
        else
            _G.TemaRGB = false
            Fluent:SetTheme("Amethyst")
        end
    end
})

local f = Tabs.S:AddToggle("TransparentToggle", {
    Title = "Transparency",
    Description = "Makes the interface transparent.",
    Default = false,
    Callback = function(Value)
        Fluent:ToggleTransparency(Value)
    end
})

local f = Tabs.S:AddToggle("opam", {
    Title = "Change Hud Button Open",
    Description = "Change the open menu button to anywhere.",
    Default = false,
    Callback = function(Value)
        button.Active = Value
        button.Draggable = Value
    end
})

return ESP_SETTINGS
