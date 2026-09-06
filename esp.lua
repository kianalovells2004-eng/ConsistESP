-- esp.lua
-- ESP Module - Pure ESP logic, no UI dependencies.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local ESP = {
    Enabled = false,
    BoxEnabled = false,
    BoxFillEnabled = false,
    NameEnabled = false,
    ThreeDBoxEnabled = false,
    TracerLocalEnabled = false,
    TracerMouseEnabled = false,
    TracerTopEnabled = false,
    TracerBottomEnabled = false,
    DistanceEnabled = false,
    HealthBarEnabled = false,
    HealthTextEnabled = false,
    CustomNames = {},
    BoxColor = Color3.fromRGB(255, 255, 255),
    BoxFillColor = Color3.fromRGB(255, 255, 255),
    TextColor = Color3.fromRGB(255, 255, 255),
    TracerColor = Color3.fromRGB(255, 255, 255),
    Drawings = {}
}

local function newDrawing(type, properties)
    local drawing = Drawing.new(type)
    for prop, value in pairs(properties or {}) do
        drawing[prop] = value
    end
    drawing.Visible = false
    return drawing
end

local function createDrawings(player)
    local drawings = {
        Box = newDrawing("Square", { Color = ESP.BoxColor, Thickness = 1.5, Filled = false, Transparency = 1 }),
        BoxOutline = newDrawing("Square", { Color = Color3.fromRGB(0, 0, 0), Thickness = 1.5, Filled = false, Transparency = 0.5 }),
        BoxFill = newDrawing("Square", { Color = ESP.BoxFillColor, Thickness = 1, Filled = true, Transparency = 0.6 }),
        NameText = newDrawing("Text", { Color = ESP.TextColor, Size = 14, Center = true, Outline = true, OutlineColor = Color3.fromRGB(0, 0, 0), Font = Drawing.Fonts.UI, Transparency = 1 }),
        DistanceText = newDrawing("Text", { Color = ESP.TextColor, Size = 13, Center = true, Outline = true, OutlineColor = Color3.fromRGB(0, 0, 0), Font = Drawing.Fonts.UI, Transparency = 1 }),
        HealthBarBack = newDrawing("Square", { Color = Color3.fromRGB(0, 0, 0), Thickness = 1, Filled = true, Transparency = 0.6 }),
        HealthBarFill = newDrawing("Square", { Color = Color3.fromRGB(0, 255, 0), Thickness = 1, Filled = true, Transparency = 0.3 }),
        HealthText = newDrawing("Text", { Color = ESP.TextColor, Size = 13, Center = true, Outline = true, OutlineColor = Color3.fromRGB(0, 0, 0), Font = Drawing.Fonts.UI, Transparency = 1 }),
        ThreeDLines = {},
        ThreeDOutlines = {},
        TracerLocal = newDrawing("Line", { Color = ESP.TracerColor, Thickness = 1.5, Transparency = 1 }),
        TracerMouse = newDrawing("Line", { Color = ESP.TracerColor, Thickness = 1.5, Transparency = 1 }),
        TracerTop = newDrawing("Line", { Color = ESP.TracerColor, Thickness = 1.5, Transparency = 1 }),
        TracerBottom = newDrawing("Line", { Color = ESP.TracerColor, Thickness = 1.5, Transparency = 1 })
    }

    for i = 1, 12 do
        drawings.ThreeDOutlines[i] = newDrawing("Line", { Color = Color3.fromRGB(0, 0, 0), Thickness = 1.5, Transparency = 0.5 })
        drawings.ThreeDLines[i] = newDrawing("Line", { Color = ESP.TracerColor, Thickness = 1.2, Transparency = 1 })
    end

    return drawings
end

-- Toggle functions
function ESP:ToggleBox(state) self.BoxEnabled = state if not state then for _, drawings in pairs(self.Drawings) do drawings.Box.Visible = false drawings.BoxOutline.Visible = false end end end
function ESP:ToggleBoxFill(state) self.BoxFillEnabled = state if not state then for _, drawings in pairs(self.Drawings) do drawings.BoxFill.Visible = false end end end
function ESP:ToggleName(state) self.NameEnabled = state if not state then for _, drawings in pairs(self.Drawings) do drawings.NameText.Visible = false end end end
function ESP:Toggle3DBox(state) self.ThreeDBoxEnabled = state if not state then for _, drawings in pairs(self.Drawings) do for i = 1, 12 do drawings.ThreeDLines[i].Visible = false drawings.ThreeDOutlines[i].Visible = false end end end end
function ESP:ToggleTracerLocal(state) self.TracerLocalEnabled = state if not state then for _, drawings in pairs(self.Drawings) do drawings.TracerLocal.Visible = false end end end
function ESP:ToggleTracerMouse(state) self.TracerMouseEnabled = state if not state then for _, drawings in pairs(self.Drawings) do drawings.TracerMouse.Visible = false end end end
function ESP:ToggleTracerTop(state) self.TracerTopEnabled = state if not state then for _, drawings in pairs(self.Drawings) do drawings.TracerTop.Visible = false end end end
function ESP:ToggleTracerBottom(state) self.TracerBottomEnabled = state if not state then for _, drawings in pairs(self.Drawings) do drawings.TracerBottom.Visible = false end end end
function ESP:ToggleDistance(state) self.DistanceEnabled = state if not state then for _, drawings in pairs(self.Drawings) do drawings.DistanceText.Visible = false end end end
function ESP:ToggleHealthBar(state) self.HealthBarEnabled = state if not state then for _, drawings in pairs(self.Drawings) do drawings.HealthBarBack.Visible = false drawings.HealthBarFill.Visible = false end end end
function ESP:ToggleHealthText(state) self.HealthTextEnabled = state if not state then for _, drawings in pairs(self.Drawings) do drawings.HealthText.Visible = false end end end

function ESP:SetCustomName(playerName, text) self.CustomNames[playerName] = text end
function ESP:ClearCustomName(playerName) self.CustomNames[playerName] = nil end

function ESP:SetBoxColor(color) self.BoxColor = color for _, drawings in pairs(self.Drawings) do drawings.Box.Color = color end end
function ESP:SetBoxFillColor(color) self.BoxFillColor = color for _, drawings in pairs(self.Drawings) do drawings.BoxFill.Color = color end end
function ESP:SetTextColor(color) self.TextColor = color for _, drawings in pairs(self.Drawings) do drawings.NameText.Color = color drawings.DistanceText.Color = color drawings.HealthText.Color = color end end
function ESP:SetTracerColor(color) self.TracerColor = color for _, drawings in pairs(self.Drawings) do drawings.TracerLocal.Color = color drawings.TracerMouse.Color = color drawings.TracerTop.Color = color drawings.TracerBottom.Color = color for i = 1, 12 do drawings.ThreeDLines[i].Color = color end end end

function ESP:Toggle(state)
    self.Enabled = state
    self:ToggleBox(state)
    self:ToggleBoxFill(state)
    self:ToggleName(state)
    self:Toggle3DBox(state)
    self:ToggleTracerLocal(state)
    self:ToggleTracerMouse(state)
    self:ToggleTracerTop(state)
    self:ToggleTracerBottom(state)
    self:ToggleDistance(state)
    self:ToggleHealthBar(state)
    self:ToggleHealthText(state)
end

function ESP:Unload()
    self:Toggle(false)
    for _, drawings in pairs(self.Drawings) do
        for _, drawing in pairs(drawings) do
            if typeof(drawing) == "table" then
                for _, d in ipairs(drawing) do d:Remove() end
            elseif typeof(drawing) ~= "nil" then
                drawing:Remove()
            end
        end
    end
    self.Drawings = {}
end

local function getCharacterBounds(character)
    local min = Vector3.new(math.huge, math.huge, math.huge)
    local max = Vector3.new(-math.huge, -math.huge, -math.huge)
    local foundPart = false
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            foundPart = true
            local partMin = part.Position - part.Size / 2
            local partMax = part.Position + part.Size / 2
            min = Vector3.new(math.min(min.X, partMin.X), math.min(min.Y, partMin.Y), math.min(min.Z, partMin.Z))
            max = Vector3.new(math.max(max.X, partMax.X), math.max(max.Y, partMax.Y), math.max(max.Z, partMax.Z))
        end
    end
    if not foundPart then return nil end
    return min, max
end

local function worldToScreen(worldPos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

local function update3DLines(drawings, corners)
    local edges = {{1,2},{2,4},{4,3},{3,1},{5,6},{6,8},{8,7},{7,5},{1,5},{2,6},{3,7},{4,8}}
    for i, edge in ipairs(edges) do
        local from, to = corners[edge[1]], corners[edge[2]]
        drawings.ThreeDOutlines[i].From = from
        drawings.ThreeDOutlines[i].To = to
        drawings.ThreeDOutlines[i].Visible = true
        drawings.ThreeDLines[i].From = from
        drawings.ThreeDLines[i].To = to
        drawings.ThreeDLines[i].Visible = true
    end
end

local function getTargetScreenPos(character)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil, false end
    return worldToScreen(rootPart.Position)
end

RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        local isValid = character and humanoid and humanoid.Health > 0 and rootPart
        local shouldDrawAny = (ESP.BoxEnabled or ESP.BoxFillEnabled or ESP.NameEnabled or ESP.ThreeDBoxEnabled
            or ESP.TracerLocalEnabled or ESP.TracerMouseEnabled or ESP.TracerTopEnabled or ESP.TracerBottomEnabled
            or ESP.DistanceEnabled or ESP.HealthBarEnabled or ESP.HealthTextEnabled) and isValid

        local drawings = ESP.Drawings[player]
        if not drawings then
            drawings = createDrawings(player)
            ESP.Drawings[player] = drawings
        end

        if not shouldDrawAny then
            drawings.Box.Visible = false
            drawings.BoxOutline.Visible = false
            drawings.BoxFill.Visible = false
            drawings.NameText.Visible = false
            drawings.DistanceText.Visible = false
            drawings.HealthBarBack.Visible = false
            drawings.HealthBarFill.Visible = false
            drawings.HealthText.Visible = false
            for i = 1, 12 do
                drawings.ThreeDLines[i].Visible = false
                drawings.ThreeDOutlines[i].Visible = false
            end
            drawings.TracerLocal.Visible = false
            drawings.TracerMouse.Visible = false
            drawings.TracerTop.Visible = false
            drawings.TracerBottom.Visible = false
            continue
        end

        local min, max = getCharacterBounds(character)
        if not min or not max then
            -- hide all drawings and continue
            drawings.Box.Visible = false
            drawings.BoxOutline.Visible = false
            drawings.BoxFill.Visible = false
            drawings.NameText.Visible = false
            drawings.DistanceText.Visible = false
            drawings.HealthBarBack.Visible = false
            drawings.HealthBarFill.Visible = false
            drawings.HealthText.Visible = false
            for i = 1, 12 do
                drawings.ThreeDLines[i].Visible = false
                drawings.ThreeDOutlines[i].Visible = false
            end
            drawings.TracerLocal.Visible = false
            drawings.TracerMouse.Visible = false
            drawings.TracerTop.Visible = false
            drawings.TracerBottom.Visible = false
            continue
        end

        local corners3D = {
            Vector3.new(min.X, min.Y, min.Z), Vector3.new(min.X, min.Y, max.Z),
            Vector3.new(min.X, max.Y, min.Z), Vector3.new(min.X, max.Y, max.Z),
            Vector3.new(max.X, min.Y, min.Z), Vector3.new(max.X, min.Y, max.Z),
            Vector3.new(max.X, max.Y, min.Z), Vector3.new(max.X, max.Y, max.Z)
        }

        local screenCorners = {}
        local anyOnScreen = false
        for i, corner in ipairs(corners3D) do
            local screenPos, onScreen = worldToScreen(corner)
            screenCorners[i] = screenPos
            if onScreen then anyOnScreen = true end
        end

        if not anyOnScreen then
            -- hide all drawings and continue
            drawings.Box.Visible = false
            drawings.BoxOutline.Visible = false
            drawings.BoxFill.Visible = false
            drawings.NameText.Visible = false
            drawings.DistanceText.Visible = false
            drawings.HealthBarBack.Visible = false
            drawings.HealthBarFill.Visible = false
            drawings.HealthText.Visible = false
            for i = 1, 12 do
                drawings.ThreeDLines[i].Visible = false
                drawings.ThreeDOutlines[i].Visible = false
            end
            drawings.TracerLocal.Visible = false
            drawings.TracerMouse.Visible = false
            drawings.TracerTop.Visible = false
            drawings.TracerBottom.Visible = false
            continue
        end

        local screenMin = Vector2.new(math.huge, math.huge)
        local screenMax = Vector2.new(-math.huge, -math.huge)
        for _, corner in ipairs(screenCorners) do
            screenMin = Vector2.new(math.min(screenMin.X, corner.X), math.min(screenMin.Y, corner.Y))
            screenMax = Vector2.new(math.max(screenMax.X, corner.X), math.max(screenMax.Y, corner.Y))
        end

        -- Box ESP
        if ESP.BoxEnabled then
            local boxSize = Vector2.new(screenMax.X - screenMin.X, screenMax.Y - screenMin.Y)
            drawings.Box.Size = boxSize
            drawings.Box.Position = screenMin
            drawings.Box.Visible = true
            drawings.BoxOutline.Size = boxSize + Vector2.new(2, 2)
            drawings.BoxOutline.Position = screenMin - Vector2.new(1, 1)
            drawings.BoxOutline.Visible = true
        else
            drawings.Box.Visible = false
            drawings.BoxOutline.Visible = false
        end

        -- Box Fill
        if ESP.BoxFillEnabled then
            drawings.BoxFill.Size = Vector2.new(screenMax.X - screenMin.X, screenMax.Y - screenMin.Y)
            drawings.BoxFill.Position = screenMin
            drawings.BoxFill.Visible = true
        else
            drawings.BoxFill.Visible = false
        end

        -- Name
        if ESP.NameEnabled then
            local name = ESP.CustomNames[player.Name] or player.Name
            drawings.NameText.Text = name
            drawings.NameText.Position = Vector2.new((screenMin.X + screenMax.X) / 2, screenMin.Y - 5 - drawings.NameText.TextBounds.Y / 2)
            drawings.NameText.Visible = true
        else
            drawings.NameText.Visible = false
        end

        -- Distance
        if ESP.DistanceEnabled then
            local dist = math.floor((Camera.CFrame.Position - rootPart.Position).Magnitude)
            drawings.DistanceText.Text = dist .. "m"
            drawings.DistanceText.Position = Vector2.new((screenMin.X + screenMax.X) / 2, screenMax.Y + 4 + drawings.DistanceText.TextBounds.Y / 2)
            drawings.DistanceText.Visible = true
        else
            drawings.DistanceText.Visible = false
        end

        -- Health
        if ESP.HealthBarEnabled or ESP.HealthTextEnabled then
            local hp = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
            local barWidth = 3
            local barHeight = screenMax.Y - screenMin.Y
            local barX = screenMin.X - barWidth - 5

            if ESP.HealthBarEnabled then
                drawings.HealthBarBack.Size = Vector2.new(barWidth, barHeight)
                drawings.HealthBarBack.Position = Vector2.new(barX, screenMin.Y)
                drawings.HealthBarBack.Visible = true

                local fillHeight = barHeight * hp
                drawings.HealthBarFill.Size = Vector2.new(barWidth, fillHeight)
                drawings.HealthBarFill.Position = Vector2.new(barX, screenMax.Y - fillHeight)
                drawings.HealthBarFill.Color = Color3.fromRGB(255 - 255 * hp, 255 * hp, 0)
                drawings.HealthBarFill.Visible = true
            else
                drawings.HealthBarBack.Visible = false
                drawings.HealthBarFill.Visible = false
            end

            if ESP.HealthTextEnabled then
                drawings.HealthText.Text = "[" .. math.floor(humanoid.Health) .. "]"
                drawings.HealthText.Position = Vector2.new(barX - 6 - drawings.HealthText.TextBounds.X / 2, (screenMin.Y + screenMax.Y) / 2)
                drawings.HealthText.Visible = true
            else
                drawings.HealthText.Visible = false
            end
        else
            drawings.HealthBarBack.Visible = false
            drawings.HealthBarFill.Visible = false
            drawings.HealthText.Visible = false
        end

        -- 3D Box
        if ESP.ThreeDBoxEnabled then
            update3DLines(drawings, screenCorners)
        else
            for i = 1, 12 do
                drawings.ThreeDLines[i].Visible = false
                drawings.ThreeDOutlines[i].Visible = false
            end
        end

        -- Tracers
        local targetScreen, targetOnScreen = getTargetScreenPos(character)
        if targetScreen and targetOnScreen then
            if ESP.TracerLocalEnabled then
                local localChar = LocalPlayer.Character
                local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
                if localRoot then
                    local localScreen = worldToScreen(localRoot.Position)
                    if localScreen then
                        drawings.TracerLocal.From = localScreen
                        drawings.TracerLocal.To = targetScreen
                        drawings.TracerLocal.Visible = true
                    else
                        drawings.TracerLocal.Visible = false
                    end
                else
                    drawings.TracerLocal.Visible = false
                end
            else
                drawings.TracerLocal.Visible = false
            end

            if ESP.TracerMouseEnabled then
                drawings.TracerMouse.From = Vector2.new(mousePos.X, mousePos.Y)
                drawings.TracerMouse.To = targetScreen
                drawings.TracerMouse.Visible = true
            else
                drawings.TracerMouse.Visible = false
            end

            if ESP.TracerTopEnabled then
                drawings.TracerTop.From = Vector2.new(Camera.ViewportSize.X / 2, 0)
                drawings.TracerTop.To = targetScreen
                drawings.TracerTop.Visible = true
            else
                drawings.TracerTop.Visible = false
            end

            if ESP.TracerBottomEnabled then
                drawings.TracerBottom.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                drawings.TracerBottom.To = targetScreen
                drawings.TracerBottom.Visible = true
            else
                drawings.TracerBottom.Visible = false
            end
        else
            drawings.TracerLocal.Visible = false
            drawings.TracerMouse.Visible = false
            drawings.TracerTop.Visible = false
            drawings.TracerBottom.Visible = false
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    local drawings = ESP.Drawings[player]
    if drawings then
        drawings.Box:Remove()
        drawings.BoxOutline:Remove()
        drawings.BoxFill:Remove()
        drawings.NameText:Remove()
        drawings.DistanceText:Remove()
        drawings.HealthBarBack:Remove()
        drawings.HealthBarFill:Remove()
        drawings.HealthText:Remove()
        for i = 1, 12 do
            drawings.ThreeDLines[i]:Remove()
            drawings.ThreeDOutlines[i]:Remove()
        end
        drawings.TracerLocal:Remove()
        drawings.TracerMouse:Remove()
        drawings.TracerTop:Remove()
        drawings.TracerBottom:Remove()
        ESP.Drawings[player] = nil
    end
end)

return ESP
