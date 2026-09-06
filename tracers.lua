-- tracers.lua
-- Bullet Tracers Logic Module

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local BulletTracers = {
    Enabled = false,
    Material = "Neon",
    Color = Color3.fromRGB(255, 0, 0),
    Opacity = 1,
    Lifetime = 0.2,
    Fade = true,
    UseDrawing = false,
    DrawingObjs = {}
}

local toolConns = {}

local function clearToolConns()
    for _, conn in pairs(toolConns) do
        conn:Disconnect()
    end
    toolConns = {}
end

local function onToolActivated(tool)
    if not BulletTracers.Enabled then return end
    
    local char = LocalPlayer.Character
    if not char then return end

    local muzzle = tool:FindFirstChild("Muzzle") or tool:FindFirstChild("Handle")
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    local origin = muzzle and muzzle.Position or (rootPart and rootPart.Position)
    if not origin then return end
    
    local targetPos = Mouse.Hit.Position
    local velocity = CFrame.lookAt(origin, targetPos).LookVector * 1000
    
    if BulletTracers.UseDrawing then
        local obj = Drawing.new('Line')
        obj.Thickness = 2
        obj.Color = BulletTracers.Color
        BulletTracers.DrawingObjs[obj] = {origin, origin + velocity, os.clock()}
        
        task.delay(BulletTracers.Lifetime, function()
            BulletTracers.DrawingObjs[obj] = nil
            if obj then
                obj.Visible = false
                obj:Remove()
            end
        end)
    else
        local obj = Instance.new('Part')
        obj.Size = Vector3.new(0.1, 0.1, velocity.Magnitude)
        obj.CFrame = CFrame.lookAt(origin + (velocity / 2), origin + velocity)
        obj.CanCollide = false
        obj.CanQuery = false
        obj.Anchored = true
        obj.Material = Enum.Material[BulletTracers.Material] or Enum.Material.Neon
        obj.Color = BulletTracers.Color
        obj.Transparency = 1 - BulletTracers.Opacity
        obj.Parent = workspace
        
        if BulletTracers.Fade then
            local tween = TweenService:Create(obj, TweenInfo.new(BulletTracers.Lifetime), { Transparency = 1 })
            tween.Completed:Connect(function() tween:Destroy() end)
            tween:Play()
        end
        
        task.delay(BulletTracers.Lifetime, obj.Destroy, obj)
    end
end

local function setupTools()
    clearToolConns()
    local char = LocalPlayer.Character
    if char then
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Tool") then
                toolConns[child] = child.Activated:Connect(function()
                    onToolActivated(child)
                end)
            end
        end
        
        toolConns["ChildAdded"] = char.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                toolConns[child] = child.Activated:Connect(function()
                    onToolActivated(child)
                end)
            end
        end)
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    setupTools()
end)
setupTools()

RunService.RenderStepped:Connect(function()
    if BulletTracers.Enabled and BulletTracers.UseDrawing then
        for obj, data in pairs(BulletTracers.DrawingObjs) do
            if obj and obj.Remove then
                local from, vis = Camera:WorldToViewportPoint(data[1])
                local to, vis2 = Camera:WorldToViewportPoint(data[2])
                if vis and vis2 then
                    obj.Visible = true
                    obj.From = Vector2.new(from.X, from.Y)
                    obj.To = Vector2.new(to.X, to.Y)
                    if BulletTracers.Fade then
                        obj.Transparency = BulletTracers.Opacity * (1 - math.clamp((os.clock() - data[3]) / BulletTracers.Lifetime, 0, 1))
                    else
                        obj.Transparency = 1 - BulletTracers.Opacity
                    end
                else
                    obj.Visible = false
                end
            end
        end
    end
end)

-- API Functions for UI
function BulletTracers:Toggle(state)
    self.Enabled = state
    if not state then
        for obj, _ in pairs(self.DrawingObjs) do
            if obj then
                obj.Visible = false
                obj:Remove()
            end
        end
        self.DrawingObjs = {}
    end
end

function BulletTracers:SetMaterial(mat) self.Material = mat end
function BulletTracers:SetColor(color) self.Color = color end
function BulletTracers:SetOpacity(val) self.Opacity = val end
function BulletTracers:SetLifetime(val) self.Lifetime = val end
function BulletTracers:SetFade(state) self.Fade = state end
function BulletTracers:SetUseDrawing(state) self.UseDrawing = state end

function BulletTracers:Unload()
    self:Toggle(false)
    clearToolConns()
end

return BulletTracers
