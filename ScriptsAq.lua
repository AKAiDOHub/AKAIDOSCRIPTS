
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
    TeamColor = Color3.new(128 / 255, 25 / 255, 25 / 255),
    HealthOutlineColor = Color3.new(0, 0, 0),
    HealthHighColor = Color3.new(0, 1, 0),
    HealthLowColor = Color3.new(128 / 255, 25 / 255, 25 / 255),
    SkeletonColor = Color3.new(128 / 255, 25 / 255, 25 / 255),
    LineColor = Color3.new(128 / 255, 25 / 255, 25 / 255),
    Teamcheck = false,
    WallCheck = false,
    Enabled = true,
    ShowName = false,
    ShowTeam = false,
    ShowBox = false,
    ShowHealth = false,
    ShowSkeletons = false,
    ShowLine = false,
    BoxType = "Corner", -- "2D" or "Corner"
    HealthBarPosition = "Left", -- "Left/Esquerda", "Right/Direita", "Top", "Bottom"
    LineFromPosition = "Top", -- "Left", "Right", "Top", "Bottom", "Center"
    NamePosition = "Top", -- "Top" or "Bottom"
    TeamPosition = "Bottom" -- "Top" or "Bottom"
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
        team = create("Text", {
            Color = ESP_SETTINGS.TeamColor,
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
                    
                    -- Determine team text
                    local teamText = team and team.Name or "Sem time"
                    
                    -- ESP Name and Team Position Logic
                    local nameOffset = (ESP_SETTINGS.NamePosition == "Top") and -16 or boxSize.Y + 16
                    local teamOffset = (ESP_SETTINGS.TeamPosition == "Top") and -16 or boxSize.Y + 16
                    
                    -- If both Name and Team are set to the same position, adjust their offsets
                    if ESP_SETTINGS.NamePosition == ESP_SETTINGS.TeamPosition then
                        if ESP_SETTINGS.NamePosition == "Top" then
                            nameOffset = -32
                            teamOffset = -16
                        else
                            nameOffset = boxSize.Y + 16
                            teamOffset = boxSize.Y + 32
                        end
                    end
                    
                    if ESP_SETTINGS.ShowName and ESP_SETTINGS.Enabled then
                        esp.name.Visible = true
                        esp.name.Text = string.lower(player.Name)
                        esp.name.Position = Vector2.new(boxSize.X / 2 + boxPosition.X, boxPosition.Y + nameOffset)
                        esp.name.Color = ESP_SETTINGS.NameColor
                    else
                        esp.name.Visible = false
                    end
                    
                    if ESP_SETTINGS.ShowTeam and ESP_SETTINGS.Enabled then
                        esp.team.Visible = true
                        esp.team.Text = teamText
                        esp.team.Position = Vector2.new(boxSize.X / 2 + boxPosition.X, boxPosition.Y + teamOffset)
                        esp.team.Color = ESP_SETTINGS.TeamColor
                    else
                        esp.team.Visible = false
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
                                line.Color = ESP_SETTINGS.BoxColor -- Atualizar a cor aqui
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
                        local from, to

                        if ESP_SETTINGS.HealthBarPosition == "Left" then
                            from = Vector2.new(boxPosition.X - 6, boxPosition.Y + boxSize.Y)
                            to = Vector2.new(from.X, from.Y - boxSize.Y)
                            esp.healthOutline.From = from
                            esp.healthOutline.To = to
                            esp.health.From = Vector2.new((boxPosition.X - 5), boxPosition.Y + boxSize.Y)
                            esp.health.To = Vector2.new(esp.health.From.X, esp.health.From.Y - healthPercentage * boxSize.Y)
                        elseif ESP_SETTINGS.HealthBarPosition == "Right" then
                            from = Vector2.new(boxPosition.X + boxSize.X + 6, boxPosition.Y + boxSize.Y)
                            to = Vector2.new(from.X, from.Y - boxSize.Y)
                            esp.healthOutline.From = from
                            esp.healthOutline.To = to
                            esp.health.From = Vector2.new((boxPosition.X + boxSize.X + 5), boxPosition.Y + boxSize.Y)
                            esp.health.To = Vector2.new(esp.health.From.X, esp.health.From.Y - healthPercentage * boxSize.Y)
                        elseif ESP_SETTINGS.HealthBarPosition == "Top" then
                            from = Vector2.new(boxPosition.X, boxPosition.Y - 6)
                            to = Vector2.new(boxPosition.X + boxSize.X, from.Y)
                            esp.healthOutline.From = from
                            esp.healthOutline.To = to
                            esp.health.From = Vector2.new(boxPosition.X, (boxPosition.Y - 5))
                            esp.health.To = Vector2.new(boxPosition.X + healthPercentage * boxSize.X, esp.health.From.Y)
                        elseif ESP_SETTINGS.HealthBarPosition == "Bottom" then
                            from = Vector2.new(boxPosition.X, boxPosition.Y + boxSize.Y + 6)
                            to = Vector2.new(boxPosition.X + boxSize.X, from.Y)
                            esp.healthOutline.From = from
                            esp.healthOutline.To = to
                            esp.health.From = Vector2.new(boxPosition.X, (boxPosition.Y + boxSize.Y + 5))
                            esp.health.To = Vector2.new(boxPosition.X + healthPercentage * boxSize.X, esp.health.From.Y)
                        end

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
                        local lineFrom

                        if ESP_SETTINGS.LineFromPosition == "Left" then
                            lineFrom = Vector2.new(0, camera.ViewportSize.Y / 2)
                        elseif ESP_SETTINGS.LineFromPosition == "Right" then
                            lineFrom = Vector2.new(camera.ViewportSize.X, camera.ViewportSize.Y / 2)
                        elseif ESP_SETTINGS.LineFromPosition == "Top" then
                            lineFrom = Vector2.new(camera.ViewportSize.X / 2, 0)
                        elseif ESP_SETTINGS.LineFromPosition == "Bottom" then
                            lineFrom = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                        elseif ESP_SETTINGS.LineFromPosition == "Center" then
                            lineFrom = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                        end

                        esp.line.From = lineFrom
                        esp.line.To = Vector2.new(hrp2D.X, hrp2D.Y)
                        esp.line.Color = ESP_SETTINGS.LineColor
                    else
                        esp.line.Visible = false
                    end
                else
                    esp.box.Visible = false
                    esp.boxOutline.Visible = false
                    esp.name.Visible = false
                    esp.team.Visible = false
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
                esp.team.Visible = false
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
            esp.team.Visible = false
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

_G.Aimbot = false
_G.AimbotButton = false
_G.TeamCheck = false
_G.TeamCheckType = "Enemies" -- Pode ser "All", "Friends" ou "Enemies"
_G.Part = "Head"

_G.SafePlayer = nil

_G.Fov = false
_G.FovPreencher = false
_G.FovRadius = 50
_G.FovColor = Color3.new(128/255, 25/255, 25/255)
_G.FovAlertColor = Color3.new(240/255, 240/255, 240/255) -- Cor de alerta
_G.FovColorChangeEnabled = true -- Variável para ativar/desativar a mudança de cor

_G.WallCheck = false  -- Ativar/Desativar o WallCheck

_G.Crossahair = false
_G.Preencher = false
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
buttonAimbot.Visible = false
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

-- -- -- -- -- -- -- HITBOX -- -- -- -- -- -- --

_G.Hitbox = false
_G.HitboxRGB = false
_G.HitboxTeam = false
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


local function G()
    local red = math.random(0, 255)
    local green = math.random(0, 255)
    local blue = math.random(0, 255)
    return Color3.fromRGB(red, green, blue)
end

local function HitboxRGB()
    while _G.HitboxRGB == true do
        wait(_G.HitboxRGBTime)
        local randomColor = G()
        _G.HitboxColor = randomColor
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

_G.HighlightEnabled = false -- Variável de ativação

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
