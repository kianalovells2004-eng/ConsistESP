-- esp.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local math_min, math_max, math_floor, math_huge = math.min, math.max, math.floor, math.huge
local Vector2_new, Vector3_new = Vector2.new, Vector3.new

local STREAK_SEGMENTS = 4

-- 3D box edges (used for both 3D box drawing and near-plane clipping)
local EDGES_3D = {
    {1,2},{2,4},{4,3},{3,1},
    {5,6},{6,8},{8,7},{7,5},
    {1,5},{2,6},{3,7},{4,8}
}

-- Font: Inconsolata with Monospace fallback
local ESP_FONT
do
    local ok, font = pcall(function()
        return Drawing.Fonts.Inconsolata
    end)
    ESP_FONT = (ok and font) or Drawing.Fonts.Monospace
end

local NEAR_PLANE_DIST = 0.5

local ESP = {
    Enabled = false,
    BoxEnabled = false,
    CornerBoxEnabled = false,
    BoxFillEnabled = false,
    BoxStreakEnabled = false,
    StreakSpeed = 1,
    TeamCheckEnabled = false,
    TeamColorEnabled = false,
    NameEnabled = false,
    DisplayNameEnabled = false,
    ItemEnabled = false,
    HostileEnabled = false,
    ForcefieldEnabled = false,
    TeamIndicatorEnabled = false,
    ThreeDBoxEnabled = false,
    BodyTracerEnabled = false,
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
    StreakColor = Color3.fromRGB(0, 255, 255),
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

local HEALTH_COLOR_FULL      = Color3.fromRGB(0, 255, 0)
local HEALTH_COLOR_MIDYELLOW = Color3.fromRGB(255, 255, 0)
local HEALTH_COLOR_ORANGE    = Color3.fromRGB(255, 185, 0)
local HEALTH_COLOR_RED       = Color3.fromRGB(255, 50, 50)

local function lerp(a, b, t) return a + (b - a) * t end
local function lerpColor(c1, c2, t) return Color3.new(lerp(c1.R, c2.R, t), lerp(c1.G, c2.G, t), lerp(c1.B, c2.B, t)) end

local function getHealthColor(hp)
    if hp >= 0.70 then return lerpColor(HEALTH_COLOR_MIDYELLOW, HEALTH_COLOR_FULL, (hp - 0.70) / 0.30)
    elseif hp >= 0.65 then return HEALTH_COLOR_MIDYELLOW
    elseif hp >= 0.50 then return lerpColor(HEALTH_COLOR_ORANGE, HEALTH_COLOR_MIDYELLOW, (hp - 0.50) / 0.15)
    elseif hp >= 0.45 then return HEALTH_COLOR_ORANGE
    elseif hp >= 0.15 then return lerpColor(HEALTH_COLOR_RED, HEALTH_COLOR_ORANGE, (hp - 0.15) / 0.30)
    else return HEALTH_COLOR_RED end
end

local function createDrawings(player)
    local font = ESP_FONT
    local drawings = {
        Box = newDrawing("Square", { Color = ESP.BoxColor, Thickness = 1.5, Filled = false, Transparency = 1 }),
        BoxOutline = newDrawing("Square", { Color = Color3.fromRGB(0, 0, 0), Thickness = 1.5, Filled = false, Transparency = 0.5 }),
        BoxFill = newDrawing("Square", { Color = ESP.BoxFillColor, Thickness = 1, Filled = true, Transparency = 0.6 }),
        NameText = newDrawing("Text", { Color = ESP.TextColor, Size = 14, Center = true, Outline = true, OutlineColor = Color3.fromRGB(0, 0, 0), Font = font, Transparency = 1 }),
        HostileText = newDrawing("Text", { Color = Color3.fromRGB(255, 50, 50), Size = 13, Center = true, Outline = true, OutlineColor = Color3.fromRGB(0, 0, 0), Font = font, Transparency = 1 }),
        ForcefieldText = newDrawing("Text", { Color = HEALTH_COLOR_ORANGE, Size = 13, Center = true, Outline = true, OutlineColor = Color3.fromRGB(0, 0, 0), Font = font, Transparency = 1 }),
        ItemText = newDrawing("Text", { Color = ESP.TextColor, Size = 13, Center = true, Outline = true, OutlineColor = Color3.fromRGB(0, 0, 0), Font = font, Transparency = 1 }),
        TeamText = newDrawing("Text", { Color = ESP.TextColor, Size = 13, Center = true, Outline = true, OutlineColor = Color3.fromRGB(0, 0, 0), Font = font, Transparency = 1 }),
        DistanceText = newDrawing("Text", { Color = ESP.TextColor, Size = 13, Center = true, Outline = true, OutlineColor = Color3.fromRGB(0, 0, 0), Font = font, Transparency = 1 }),
        HealthBarOutline = newDrawing("Square", { Color = Color3.fromRGB(0, 0, 0), Thickness = 1.5, Filled = false, Transparency = 0.5 }),
        HealthBarBack = newDrawing("Square", { Color = Color3.fromRGB(0, 0, 0), Thickness = 1, Filled = true, Transparency = 0.6 }),
        HealthBarFill = newDrawing("Square", { Color = HEALTH_COLOR_FULL, Thickness = 1, Filled = true, Transparency = 0.3 }),
        HealthText = newDrawing("Text", { Color = ESP.TextColor, Size = 13, Center = true, Outline = true, OutlineColor = Color3.fromRGB(0, 0, 0), Font = font, Transparency = 1 }),
        ThreeDLines = {},
        ThreeDOutlines = {},
        CornerLines = {},
        CornerOutlines = {},
        BodyTracer = newDrawing("Line", { Color = ESP.TracerColor, Thickness = 1.5, Transparency = 1 }),
        TracerMouse = newDrawing("Line", { Color = ESP.TracerColor, Thickness = 1.5, Transparency = 1 }),
        TracerTop = newDrawing("Line", { Color = ESP.TracerColor, Thickness = 1.5, Transparency = 1 }),
        TracerBottom = newDrawing("Line", { Color = ESP.TracerColor, Thickness = 1.5, Transparency = 1 }),
        BoxStreaks = {}
    }

    for i = 1, 12 do
        drawings.ThreeDOutlines[i] = newDrawing("Line", { Color = Color3.fromRGB(0, 0, 0), Thickness = 1.5, Transparency = 0.5 })
        drawings.ThreeDLines[i] = newDrawing("Line", { Color = ESP.TracerColor, Thickness = 1.2, Transparency = 1 })
    end

    for i = 1, 8 do
        drawings.CornerOutlines[i] = newDrawing("Line", { Color = Color3.fromRGB(0, 0, 0), Thickness = 3, Transparency = 0.5 })
        drawings.CornerLines[i] = newDrawing("Line", { Color = ESP.BoxColor, Thickness = 1.5, Transparency = 1 })
    end

    for i = 1, STREAK_SEGMENTS do
        drawings.BoxStreaks[i] = newDrawing("Line", { Color = ESP.StreakColor, Thickness = 1.0, Transparency = 1 })
    end

    return drawings
end

local function hideAllDrawings(drawings)
    drawings.Box.Visible = false
    drawings.BoxOutline.Visible = false
    drawings.BoxFill.Visible = false
    drawings.NameText.Visible = false
    drawings.HostileText.Visible = false
    drawings.ForcefieldText.Visible = false
    drawings.ItemText.Visible = false
    drawings.TeamText.Visible = false
    drawings.DistanceText.Visible = false
    drawings.HealthBarOutline.Visible = false
    drawings.HealthBarBack.Visible = false
    drawings.HealthBarFill.Visible = false
    drawings.HealthText.Visible = false
    for i = 1, 12 do
        drawings.ThreeDLines[i].Visible = false
        drawings.ThreeDOutlines[i].Visible = false
    end
    for i = 1, 8 do
        drawings.CornerLines[i].Visible = false
        drawings.CornerOutlines[i].Visible = false
    end
    drawings.BodyTracer.Visible = false
    drawings.TracerMouse.Visible = false
    drawings.TracerTop.Visible = false
    drawings.TracerBottom.Visible = false
    for i = 1, STREAK_SEGMENTS do
        drawings.BoxStreaks[i].Visible = false
    end
end

function ESP:Toggle(state)
    self.Enabled = state
    if not state then
        for _, drawings in pairs(self.Drawings) do
            hideAllDrawings(drawings)
        end
    end
end

function ESP:ToggleBox(state)
    self.BoxEnabled = state
    if not state then
        self.BoxFillEnabled = false
        self.BoxStreakEnabled = false
        for _, drawings in pairs(self.Drawings) do
            drawings.Box.Visible = false
            drawings.BoxOutline.Visible = false
            drawings.BoxFill.Visible = false
            for _, s in ipairs(drawings.BoxStreaks) do s.Visible = false end
        end
    end
end

function ESP:ToggleBoxStreak(state)
    if state and not self.BoxEnabled then
        self.BoxStreakEnabled = false
        return
    end
    self.BoxStreakEnabled = state
    if not state then
        for _, d in pairs(self.Drawings) do
            for _, s in ipairs(d.BoxStreaks) do s.Visible = false end
        end
    end
end

function ESP:ToggleCornerBox(state)
    self.CornerBoxEnabled = state
    if not state then
        for _, drawings in pairs(self.Drawings) do
            for i = 1, 8 do
                drawings.CornerLines[i].Visible = false
                drawings.CornerOutlines[i].Visible = false
            end
        end
    end
end

function ESP:ToggleBoxFill(state)
    if state and not self.BoxEnabled then
        self.BoxFillEnabled = false
        return
    end
    self.BoxFillEnabled = state
    if not state then
        for _, drawings in pairs(self.Drawings) do
            drawings.BoxFill.Visible = false
        end
    end
end

function ESP:ToggleTeamCheck(state) self.TeamCheckEnabled = state end
function ESP:ToggleTeamColor(state) self.TeamColorEnabled = state end

function ESP:ToggleName(state)
    self.NameEnabled = state
    if not state and not self.DisplayNameEnabled then
        for _, d in pairs(self.Drawings) do d.NameText.Visible = false end
    end
end

function ESP:ToggleDisplayName(state)
    self.DisplayNameEnabled = state
    if not state and not self.NameEnabled then
        for _, d in pairs(self.Drawings) do d.NameText.Visible = false end
    end
end

function ESP:ToggleHostile(state)
    self.HostileEnabled = state
    if not state then
        for _, d in pairs(self.Drawings) do
            d.HostileText.Visible = false
        end
    end
end

function ESP:ToggleForcefield(state)
    self.ForcefieldEnabled = state
    if not state then
        for _, d in pairs(self.Drawings) do
            d.ForcefieldText.Visible = false
        end
    end
end

function ESP:ToggleItem(state) self.ItemEnabled = state if not state then for _, d in pairs(self.Drawings) do d.ItemText.Visible = false end end end
function ESP:ToggleTeamIndicator(state) self.TeamIndicatorEnabled = state if not state then for _, d in pairs(self.Drawings) do d.TeamText.Visible = false end end end
function ESP:Toggle3DBox(state) self.ThreeDBoxEnabled = state if not state then for _, d in pairs(self.Drawings) do for i = 1, 12 do d.ThreeDLines[i].Visible = false d.ThreeDOutlines[i].Visible = false end end end end
function ESP:ToggleBodyTracer(state) self.BodyTracerEnabled = state if not state then for _, d in pairs(self.Drawings) do d.BodyTracer.Visible = false end end end
function ESP:ToggleTracerMouse(state) self.TracerMouseEnabled = state if not state then for _, d in pairs(self.Drawings) do d.TracerMouse.Visible = false end end end
function ESP:ToggleTracerTop(state) self.TracerTopEnabled = state if not state then for _, d in pairs(self.Drawings) do d.TracerTop.Visible = false end end end
function ESP:ToggleTracerBottom(state) self.TracerBottomEnabled = state if not state then for _, d in pairs(self.Drawings) do d.TracerBottom.Visible = false end end end
function ESP:ToggleDistance(state) self.DistanceEnabled = state if not state then for _, d in pairs(self.Drawings) do d.DistanceText.Visible = false end end end
function ESP:ToggleHealthBar(state) self.HealthBarEnabled = state if not state then for _, d in pairs(self.Drawings) do d.HealthBarOutline.Visible = false d.HealthBarBack.Visible = false d.HealthBarFill.Visible = false end end end
function ESP:ToggleHealthText(state) self.HealthTextEnabled = state if not state then for _, d in pairs(self.Drawings) do d.HealthText.Visible = false end end end

function ESP:SetCustomName(playerName, text) self.CustomNames[playerName] = text end
function ESP:ClearCustomName(playerName) self.CustomNames[playerName] = nil end

function ESP:SetBoxColor(color) self.BoxColor = color for _, d in pairs(self.Drawings) do d.Box.Color = color for i=1,8 do d.CornerLines[i].Color = color end end end
function ESP:SetBoxFillColor(color) self.BoxFillColor = color for _, d in pairs(self.Drawings) do d.BoxFill.Color = color end end
function ESP:SetTextColor(color) self.TextColor = color for _, d in pairs(self.Drawings) do d.NameText.Color = color d.ItemText.Color = color d.TeamText.Color = color d.DistanceText.Color = color end end
function ESP:SetTracerColor(color) self.TracerColor = color for _, d in pairs(self.Drawings) do d.BodyTracer.Color = color d.TracerMouse.Color = color d.TracerTop.Color = color d.TracerBottom.Color = color for i = 1, 12 do d.ThreeDLines[i].Color = color end end end
function ESP:SetStreakColor(color) self.StreakColor = color for _, d in pairs(self.Drawings) do for _, s in ipairs(d.BoxStreaks) do s.Color = color end end end
function ESP:SetStreakSpeed(speed) self.StreakSpeed = speed end

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

-- FIX: Rotation-aware character bounds
-- Computes the actual world-space AABB using each part's CFrame and Size,
-- correctly handling rotated parts instead of treating them as axis-aligned.
local function getCharacterBounds(character)
    local min, max
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            local cf = part.CFrame
            local hs = part.Size * 0.5
            -- Transform all 8 corners of the part's local bounding box into world space
            local corners = {
                cf * Vector3_new(-hs.X, -hs.Y, -hs.Z),
                cf * Vector3_new(-hs.X, -hs.Y,  hs.Z),
                cf * Vector3_new(-hs.X,  hs.Y, -hs.Z),
                cf * Vector3_new(-hs.X,  hs.Y,  hs.Z),
                cf * Vector3_new( hs.X, -hs.Y, -hs.Z),
                cf * Vector3_new( hs.X, -hs.Y,  hs.Z),
                cf * Vector3_new( hs.X,  hs.Y, -hs.Z),
                cf * Vector3_new( hs.X,  hs.Y,  hs.Z)
            }
            for _, corner in ipairs(corners) do
                if min then
                    min = Vector3_new(math_min(min.X, corner.X), math_min(min.Y, corner.Y), math_min(min.Z, corner.Z))
                    max = Vector3_new(math_max(max.X, corner.X), math_max(max.Y, corner.Y), math_max(max.Z, corner.Z))
                else
                    min = corner
                    max = corner
                end
            end
        end
    end
    return min, max
end

local function worldToScreen(worldPos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
    return Vector2_new(screenPos.X, screenPos.Y), onScreen
end

-- FIX: Near-plane clipping for behind-camera projection
-- Instead of projecting all 8 corners blindly (which produces garbage when
-- corners are behind the camera), we:
--   1. Only project corners that are in front of the near plane
--   2. For edges that cross the near plane, compute the intersection point
--      and project that instead
-- This prevents giant/inverted/flickering boxes near the camera plane.
local function computeScreenBounds(worldCorners)
    local camCF = Camera.CFrame
    local camPos = camCF.Position
    local camLook = camCF.LookVector

    local screenCorners = {}
    local cornerInFront = {}
    local anyInFront = false
    local points = {}

    -- Phase 1: Project all in-front corners
    for i, corner in ipairs(worldCorners) do
        local z = (corner - camPos):Dot(camLook)
        local inFront = z >= NEAR_PLANE_DIST
        cornerInFront[i] = inFront

        if inFront then
            anyInFront = true
            local sp = worldToScreen(corner)
            screenCorners[i] = sp
            points[#points + 1] = sp
        else
            screenCorners[i] = nil
        end
    end

    if not anyInFront then
        return nil, nil, screenCorners, cornerInFront, false
    end

    -- Phase 2: Clip edges that cross the near plane
    for _, edge in ipairs(EDGES_3D) do
        local p1 = worldCorners[edge[1]]
        local p2 = worldCorners[edge[2]]
        local d1 = (p1 - camPos):Dot(camLook) - NEAR_PLANE_DIST
        local d2 = (p2 - camPos):Dot(camLook) - NEAR_PLANE_DIST

        -- Only clip if the edge crosses the near plane
        if (d1 >= 0) ~= (d2 >= 0) then
            local denom = d1 - d2
            if math.abs(denom) > 1e-6 then
                local t = d1 / denom
                local clipP = p1 + (p2 - p1) * t
                local sp = worldToScreen(clipP)
                points[#points + 1] = sp
            end
        end
    end

    if #points == 0 then
        return nil, nil, screenCorners, cornerInFront, false
    end

    -- Compute 2D AABB from all projected points
    local sMin = points[1]
    local sMax = points[1]
    for i = 2, #points do
        local c = points[i]
        sMin = Vector2_new(math_min(sMin.X, c.X), math_min(sMin.Y, c.Y))
        sMax = Vector2_new(math_max(sMax.X, c.X), math_max(sMax.Y, c.Y))
    end

    return sMin, sMax, screenCorners, cornerInFront, true
end

-- FIX: 3D box lines now handle behind-camera corners
-- Lines with a behind-camera endpoint are hidden instead of drawn with
-- garbage projected coordinates.
local function update3DLines(drawings, screenCorners, cornerInFront, color)
    for i = 1, 12 do
        local edge = EDGES_3D[i]
        local idx1, idx2 = edge[1], edge[2]

        if cornerInFront[idx1] and cornerInFront[idx2]
           and screenCorners[idx1] and screenCorners[idx2] then
            local from = screenCorners[idx1]
            local to = screenCorners[idx2]
            drawings.ThreeDOutlines[i].From = from
            drawings.ThreeDOutlines[i].To = to
            drawings.ThreeDOutlines[i].Visible = true
            drawings.ThreeDLines[i].From = from
            drawings.ThreeDLines[i].To = to
            drawings.ThreeDLines[i].Color = color
            drawings.ThreeDLines[i].Visible = true
        else
            drawings.ThreeDOutlines[i].Visible = false
            drawings.ThreeDLines[i].Visible = false
        end
    end
end

local function updateCornerBox(drawings, screenMin, screenMax, boxColor)
    local w = screenMax.X - screenMin.X
    local h = screenMax.Y - screenMin.Y
    -- Minimum corner length so corners don't disappear at extreme distances
    local cornerLen = math.max(2, math_min(w, h) * 0.25)
    local tl = screenMin
    local tr = Vector2_new(screenMax.X, screenMin.Y)
    local bl = Vector2_new(screenMin.X, screenMax.Y)
    local br = screenMax

    local positions = {
        {From = tl, To = tl + Vector2_new(cornerLen, 0)},
        {From = tl, To = tl + Vector2_new(0, cornerLen)},
        {From = tr, To = tr - Vector2_new(cornerLen, 0)},
        {From = tr, To = tr + Vector2_new(0, cornerLen)},
        {From = bl, To = bl + Vector2_new(cornerLen, 0)},
        {From = bl, To = bl - Vector2_new(0, cornerLen)},
        {From = br, To = br - Vector2_new(cornerLen, 0)},
        {From = br, To = br - Vector2_new(0, cornerLen)}
    }

    for i = 1, 8 do
        local pos = positions[i]
        local outline = drawings.CornerOutlines[i]
        outline.From = pos.From
        outline.To = pos.To
        outline.Visible = true

        local line = drawings.CornerLines[i]
        line.From = pos.From
        line.To = pos.To
        line.Color = boxColor
        line.Visible = true
    end
end

local function getTargetScreenPos(character)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil, false end
    return worldToScreen(rootPart.Position)
end

local function getStreakPoints(startDist, length, w, h, screenMin, screenMax)
    local P = 2 * (w + h)
    local function mapPoint(p)
        p = p % P
        if p < w then return Vector2_new(screenMin.X + p, screenMin.Y) end
        p = p - w
        if p < h then return Vector2_new(screenMax.X, screenMin.Y + p) end
        p = p - h
        if p < w then return Vector2_new(screenMax.X - p, screenMax.Y) end
        p = p - w
        return Vector2_new(screenMin.X, screenMax.Y - p)
    end

    local points = { mapPoint(startDist) }
    local d = startDist % P
    local remaining = length
    local safety = 0

    local c1, c2, c3 = w, w + h, 2 * w + h

    while remaining > 0.05 and safety < 4 do
        safety = safety + 1
        local nextCorner = P
        if c1 > d + 0.05 and c1 < nextCorner then nextCorner = c1 end
        if c2 > d + 0.05 and c2 < nextCorner then nextCorner = c2 end
        if c3 > d + 0.05 and c3 < nextCorner then nextCorner = c3 end

        local toCorner = nextCorner - d
        if remaining <= toCorner then
            points[#points + 1] = mapPoint(d + remaining)
            remaining = 0
        else
            points[#points + 1] = mapPoint(nextCorner)
            remaining = remaining - toCorner
            d = nextCorner % P
        end
    end
    return points
end

-- FIX: Lowered minimum from 11 to 6 so distance scaling actually works
-- At 1000m (scale 0.4): 14*0.4=5.6→6, 13*0.4=5.2→6
-- Previously everything was forced to 11px, making distant ESP look huge
local function getTextSize(baseSize, scale)
    return math.max(6, math_floor(baseSize * scale))
end

-- 20-minute cache clearing for performance
task.spawn(function()
    while true do
        task.wait(1200)
        pcall(function()
            collectgarbage("collect")
        end)
    end
end)

RunService.RenderStepped:Connect(function()
    if not ESP.Enabled then return end

    -- FIX: Update camera reference every frame to handle camera changes
    Camera = Workspace.CurrentCamera
    if not Camera then return end

    local clock = os.clock()
    -- FIX: Subtract GUI inset so mouse position matches WorldToViewportPoint coordinates
    local guiInset = GuiService:GetGuiInset()
    local mousePos = UserInputService:GetMouseLocation() - guiInset
    local camPos = Camera.CFrame.Position
    local viewportSize = Camera.ViewportSize
    local localTeam = LocalPlayer.Team

    local boxOn = ESP.BoxEnabled
    local fillOn = ESP.BoxFillEnabled
    local streakOn = ESP.BoxStreakEnabled
    local streakSpeed = ESP.StreakSpeed
    local useTeamColor = ESP.TeamColorEnabled

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        if ESP.TeamCheckEnabled and localTeam and player.Team == localTeam then
            local drawings = ESP.Drawings[player]
            if drawings then hideAllDrawings(drawings) end
            continue
        end

        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        local isValid = character and humanoid and humanoid.Health > 0 and rootPart
        local shouldDrawAny = (boxOn or ESP.CornerBoxEnabled or fillOn or streakOn or ESP.NameEnabled or ESP.DisplayNameEnabled or ESP.ItemEnabled or ESP.HostileEnabled or ESP.ForcefieldEnabled or ESP.TeamIndicatorEnabled or ESP.ThreeDBoxEnabled
            or ESP.BodyTracerEnabled or ESP.TracerMouseEnabled or ESP.TracerTopEnabled or ESP.TracerBottomEnabled
            or ESP.DistanceEnabled or ESP.HealthBarEnabled or ESP.HealthTextEnabled) and isValid

        local drawings = ESP.Drawings[player]
        if not shouldDrawAny then
            if drawings then hideAllDrawings(drawings) end
            continue
        end

        if not drawings then
            drawings = createDrawings(player)
            ESP.Drawings[player] = drawings
        end

        local min, max = getCharacterBounds(character)
        if not min or not max then
            hideAllDrawings(drawings)
            continue
        end

        -- Build 8 world-space corners of the AABB
        local worldCorners = {
            Vector3_new(min.X, min.Y, min.Z), Vector3_new(min.X, min.Y, max.Z),
            Vector3_new(min.X, max.Y, min.Z), Vector3_new(min.X, max.Y, max.Z),
            Vector3_new(max.X, min.Y, min.Z), Vector3_new(max.X, min.Y, max.Z),
            Vector3_new(max.X, max.Y, min.Z), Vector3_new(max.X, max.Y, max.Z)
        }

        -- FIX: Use near-plane clipping to compute screen bounds
        -- This prevents giant/flickering boxes when corners are behind the camera
        local screenMin, screenMax, screenCorners, cornerInFront, anyVisible = computeScreenBounds(worldCorners)

        if not anyVisible or not screenMin then
            hideAllDrawings(drawings)
            continue
        end

        -- Safety: hide if bounds are unreasonably large (camera inside or extremely close to box)
        local boundsW = screenMax.X - screenMin.X
        local boundsH = screenMax.Y - screenMin.Y
        if boundsW > viewportSize.X * 10 or boundsH > viewportSize.Y * 10 then
            hideAllDrawings(drawings)
            continue
        end

        -- Distance & Scaling Logic (400m to 1000m)
        local dist = math_floor((camPos - rootPart.Position).Magnitude)
        local scale = 1
        if dist > 400 then
            scale = math.max(0.4, 1 - ((dist - 400) / 600) * 0.6)
        end

        -- Team Color Logic
        local pColor = ESP.TextColor
        local pBoxColor = ESP.BoxColor
        local pTracerColor = ESP.TracerColor

        if useTeamColor and player.Team then
            local tColor = player.Team.TeamColor.Color
            pColor = tColor
            pBoxColor = tColor
            pTracerColor = tColor
        end

        if boxOn then
            local boxSize = Vector2_new(screenMax.X - screenMin.X, screenMax.Y - screenMin.Y)
            drawings.Box.Size = boxSize
            drawings.Box.Position = screenMin
            drawings.Box.Color = pBoxColor
            drawings.Box.Visible = true
            drawings.BoxOutline.Size = boxSize + Vector2_new(2, 2)
            drawings.BoxOutline.Position = screenMin - Vector2_new(1, 1)
            drawings.BoxOutline.Visible = true

            if streakOn then
                local w = boxSize.X
                local h = boxSize.Y
                local P = 2 * (w + h)

                if w > 0.5 and h > 0.5 then
                    local t = (clock * 0.1 * streakSpeed) % 1
                    local startDist = t * P

                    local streakLen = math.min(math.clamp(P * 0.1, 15, 40), P * 0.4)

                    local points = getStreakPoints(startDist, streakLen, w, h, screenMin, screenMax)
                    local segments = #points - 1

                    for i = 1, STREAK_SEGMENTS do
                        local line = drawings.BoxStreaks[i]
                        if i <= segments then
                            local a, b = points[i], points[i + 1]
                            line.From = a
                            line.To = b
                            line.Visible = true
                        else
                            line.Visible = false
                        end
                    end
                else
                    for i = 1, STREAK_SEGMENTS do
                        drawings.BoxStreaks[i].Visible = false
                    end
                end
            else
                for i = 1, STREAK_SEGMENTS do
                    drawings.BoxStreaks[i].Visible = false
                end
            end
        else
            drawings.Box.Visible = false
            drawings.BoxOutline.Visible = false
            for i = 1, STREAK_SEGMENTS do
                drawings.BoxStreaks[i].Visible = false
            end
        end

        if ESP.CornerBoxEnabled then
            updateCornerBox(drawings, screenMin, screenMax, pBoxColor)
        else
            for i = 1, 8 do
                drawings.CornerLines[i].Visible = false
                drawings.CornerOutlines[i].Visible = false
            end
        end

        if fillOn and boxOn then
            drawings.BoxFill.Size = Vector2_new(screenMax.X - screenMin.X, screenMax.Y - screenMin.Y)
            drawings.BoxFill.Position = screenMin
            drawings.BoxFill.Visible = true
        else
            drawings.BoxFill.Visible = false
        end

        if ESP.NameEnabled or ESP.DisplayNameEnabled then
            local name = ESP.CustomNames[player.Name]
            if not name then
                if ESP.DisplayNameEnabled then
                    name = player.DisplayName
                else
                    name = player.Name
                end
            end
            drawings.NameText.Size = getTextSize(14, scale)
            drawings.NameText.Text = name

            -- Moving Purple Gradient Effect
            local t = (math.sin(clock * 1.5) + 1) / 2
            drawings.NameText.Color = lerpColor(Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 0, 255), t)

            local nameY = screenMin.Y - 5 * scale - drawings.NameText.TextBounds.Y / 2

            drawings.NameText.Position = Vector2_new((screenMin.X + screenMax.X) * 0.5, nameY)
            drawings.NameText.Visible = true
        else
            drawings.NameText.Visible = false
        end

        -- Right-side Text Stacking Logic (Hostile -> Forcefield -> Item -> Team -> Distance)
        local rightX = screenMax.X + 4 * scale
        local centerY = (screenMin.Y + screenMax.Y) * 0.5
        -- FIX: Minimum gap so text stacking doesn't crowd at small scales
        local gap = math.max(1, 4 * scale)
        local itemsToStack = {}

        -- Hostile Indicator (Top)
        if ESP.HostileEnabled then
            local isHostile = character:GetAttribute("Hostile") == true or player:GetAttribute("Hostile") == true
            if isHostile then
                drawings.HostileText.Size = getTextSize(13, scale)
                drawings.HostileText.Text = "Hostile"
                drawings.HostileText.Visible = true
                table.insert(itemsToStack, drawings.HostileText)
            else
                drawings.HostileText.Visible = false
            end
        else
            drawings.HostileText.Visible = false
        end

        -- Forcefield Indicator (Above Tool)
        if ESP.ForcefieldEnabled then
            local hasForcefield = character:FindFirstChildOfClass("ForceField")
            if hasForcefield then
                drawings.ForcefieldText.Size = getTextSize(13, scale)
                drawings.ForcefieldText.Text = "Forcefield"
                drawings.ForcefieldText.Visible = true
                table.insert(itemsToStack, drawings.ForcefieldText)
            else
                drawings.ForcefieldText.Visible = false
            end
        else
            drawings.ForcefieldText.Visible = false
        end

        if ESP.ItemEnabled then
            local toolNames = {}
            for _, child in ipairs(character:GetChildren()) do
                if child:IsA("Tool") then
                    toolNames[#toolNames + 1] = child.Name
                end
            end
            if #toolNames > 0 then
                drawings.ItemText.Size = getTextSize(13, scale)
                drawings.ItemText.Text = table.concat(toolNames, ", ")
                drawings.ItemText.Color = pColor
                drawings.ItemText.Visible = true
                table.insert(itemsToStack, drawings.ItemText)
            else
                drawings.ItemText.Visible = false
            end
        else
            drawings.ItemText.Visible = false
        end

        if ESP.TeamIndicatorEnabled then
            local team = player.Team
            if team then
                drawings.TeamText.Text = team.Name
                -- Make team indicator ALWAYS the color of the team
                drawings.TeamText.Color = team.TeamColor.Color
            else
                drawings.TeamText.Text = "Neutral"
                drawings.TeamText.Color = Color3.fromRGB(255, 255, 255)
            end
            drawings.TeamText.Size = getTextSize(13, scale)
            drawings.TeamText.Visible = true
            table.insert(itemsToStack, drawings.TeamText)
        else
            drawings.TeamText.Visible = false
        end

        if ESP.DistanceEnabled then
            drawings.DistanceText.Size = getTextSize(13, scale)
            drawings.DistanceText.Text = dist .. "m"
            drawings.DistanceText.Color = pColor
            drawings.DistanceText.Visible = true
            table.insert(itemsToStack, drawings.DistanceText)
        else
            drawings.DistanceText.Visible = false
        end

        -- Calculate total height of the stack
        local totalHeight = 0
        for _, textObj in ipairs(itemsToStack) do
            totalHeight = totalHeight + textObj.TextBounds.Y
        end
        totalHeight = totalHeight + gap * (#itemsToStack - 1)

        -- Start Y so that the stack is vertically centered on the right side
        local currentY = centerY - totalHeight * 0.5
        for _, textObj in ipairs(itemsToStack) do
            local boundsY = textObj.TextBounds.Y
            textObj.Position = Vector2_new(rightX + textObj.TextBounds.X * 0.5, currentY + boundsY * 0.5)
            currentY = currentY + boundsY + gap
        end

        if ESP.HealthBarEnabled or ESP.HealthTextEnabled then
            local hp = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
            -- FIX: Minimum bar width so health bar doesn't disappear at long distances
            local barWidth = math.max(2, 3 * scale)
            local barHeight = screenMax.Y - screenMin.Y
            local barX = screenMin.X - barWidth - 5 * scale

            if ESP.HealthBarEnabled then
                drawings.HealthBarOutline.Size = Vector2_new(barWidth, barHeight) + Vector2_new(2, 2)
                drawings.HealthBarOutline.Position = Vector2_new(barX, screenMin.Y) - Vector2_new(1, 1)
                drawings.HealthBarOutline.Visible = true

                drawings.HealthBarBack.Size = Vector2_new(barWidth, barHeight)
                drawings.HealthBarBack.Position = Vector2_new(barX, screenMin.Y)
                drawings.HealthBarBack.Visible = true

                local fillHeight = barHeight * hp
                drawings.HealthBarFill.Size = Vector2_new(barWidth, fillHeight)
                drawings.HealthBarFill.Position = Vector2_new(barX, screenMax.Y - fillHeight)
                drawings.HealthBarFill.Color = getHealthColor(hp)
                drawings.HealthBarFill.Visible = true
            else
                drawings.HealthBarOutline.Visible = false
                drawings.HealthBarBack.Visible = false
                drawings.HealthBarFill.Visible = false
            end

            if ESP.HealthTextEnabled then
                drawings.HealthText.Size = getTextSize(13, scale)
                drawings.HealthText.Text = "[" .. math_floor(humanoid.Health) .. "]"
                drawings.HealthText.Color = getHealthColor(hp)
                local textBounds = drawings.HealthText.TextBounds
                -- FIX: Health text is now vertically centered with the health bar
                -- instead of being at the top of the box
                local barCenterY = (screenMin.Y + screenMax.Y) * 0.5
                drawings.HealthText.Position = Vector2_new(
                    barX - textBounds.X * 0.5 - 4 * scale,
                    barCenterY
                )
                drawings.HealthText.Visible = true
            else
                drawings.HealthText.Visible = false
            end
        else
            drawings.HealthBarOutline.Visible = false
            drawings.HealthBarBack.Visible = false
            drawings.HealthBarFill.Visible = false
            drawings.HealthText.Visible = false
        end

        if ESP.ThreeDBoxEnabled then
            update3DLines(drawings, screenCorners, cornerInFront, pTracerColor)
        else
            for i = 1, 12 do
                drawings.ThreeDLines[i].Visible = false
                drawings.ThreeDOutlines[i].Visible = false
            end
        end

        local targetScreen, targetOnScreen = getTargetScreenPos(character)
        if targetScreen and targetOnScreen then
            if ESP.BodyTracerEnabled then
                local localChar = LocalPlayer.Character
                local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
                if localRoot then
                    local localScreen = worldToScreen(localRoot.Position)
                    if localScreen then
                        drawings.BodyTracer.From = localScreen
                        drawings.BodyTracer.To = targetScreen
                        drawings.BodyTracer.Color = pTracerColor
                        drawings.BodyTracer.Visible = true
                    else
                        drawings.BodyTracer.Visible = false
                    end
                else
                    drawings.BodyTracer.Visible = false
                end
            else
                drawings.BodyTracer.Visible = false
            end

            if ESP.TracerMouseEnabled then
                drawings.TracerMouse.From = Vector2_new(mousePos.X, mousePos.Y)
                drawings.TracerMouse.To = targetScreen
                drawings.TracerMouse.Color = pTracerColor
                drawings.TracerMouse.Visible = true
            else
                drawings.TracerMouse.Visible = false
            end

            if ESP.TracerTopEnabled then
                drawings.TracerTop.From = Vector2_new(viewportSize.X * 0.5, 0)
                drawings.TracerTop.To = targetScreen
                drawings.TracerTop.Color = pTracerColor
                drawings.TracerTop.Visible = true
            else
                drawings.TracerTop.Visible = false
            end

            if ESP.TracerBottomEnabled then
                drawings.TracerBottom.From = Vector2_new(viewportSize.X * 0.5, viewportSize.Y)
                drawings.TracerBottom.To = targetScreen
                drawings.TracerBottom.Color = pTracerColor
                drawings.TracerBottom.Visible = true
            else
                drawings.TracerBottom.Visible = false
            end
        else
            drawings.BodyTracer.Visible = false
            drawings.TracerMouse.Visible = false
            drawings.TracerTop.Visible = false
            drawings.TracerBottom.Visible = false
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    local drawings = ESP.Drawings[player]
    if drawings then
        for _, d in pairs(drawings) do
            if typeof(d) == "table" then
                for _, subD in ipairs(d) do subD:Remove() end
            elseif typeof(d) ~= "nil" then
                d:Remove()
            end
        end
        ESP.Drawings[player] = nil
    end
end)

return ESP
