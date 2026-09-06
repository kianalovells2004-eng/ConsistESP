-- tracers.lua
-- Bullet Tracers Logic Module (Replicated Vape Logic)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local BulletTracers = {
    Enabled = false,
    Material = "SmoothPlastic",
    Color = Color3.fromRGB(255, 255, 255),
    Opacity = 0.5,
    Lifetime = 0.2,
    Fade = true,
    DrawingToggle = false,
    drawingobjs = {}
}

local toolConns = {}

local function clearToolConns()
    for _, conn in pairs(toolConns) do
        conn:Disconnect()
    end
    toolConns = {}
end

local function setupTools()
    clearToolConns()
    local char = LocalPlayer.Character
    if char then
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Tool") then
                toolConns[child] = child.Activated:Connect(function()
                    if not BulletTracers.Enabled then return end
                    
                    local origin = child.Handle and child.Handle.Position or Camera.CFrame.Position
                    if child:FindFirstChild("Muzzle") then
                        origin = child.Muzzle.Position
                    end

                    local dir = Mouse.Hit.Position
                    local velocity = CFrame.lookAt(origin, dir).LookVector * 1000
                    
                    if BulletTracers.DrawingToggle then
                        local obj = Drawing.new('Line')
                        obj.Thickness = 2
                        obj.Color = BulletTracers.Color
                        BulletTracers.drawingobjs[obj] = {origin, origin + velocity, os.clock()}
                        task.delay(BulletTracers.Lifetime, function()
                            BulletTracers.drawingobjs[obj] = nil
                            obj.Visible = false
                            obj:Remove()
                        end)
                    else
                        local obj = Instance.new('Part')
                        obj.Size = Vector3.new(0.1, 0.1, velocity.Magnitude)
                        obj.CFrame = CFrame.lookAt(origin + (velocity / 2), origin + velocity)
                        obj.CanCollide = false
                        obj.CanQuery = false
                        obj.Anchored = true
                        obj.Material = Enum.Material[BulletTracers.Material] or Enum.Material.SmoothPlastic
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
                end)
            end
        end
        
        toolConns["ChildAdded"] = char.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                toolConns[child] = child.Activated:Connect(function()
                    if not BulletTracers.Enabled then return end
                    
                    local origin = child.Handle and child.Handle.Position or Camera.CFrame.Position
                    if child:FindFirstChild("Muzzle") then
                        origin = child.Muzzle.Position
                    end

                    local dir = Mouse.Hit.Position
                    local velocity = CFrame.lookAt(origin, dir).LookVector * 1000
                    
                    if BulletTracers.DrawingToggle then
                        local obj = Drawing.new('Line')
                        obj.Thickness = 2
                        obj.Color = BulletTracers.Color
                        BulletTracers.drawingobjs[obj] = {origin, origin + velocity, os.clock()}
                        task.delay(BulletTracers.Lifetime, function()
                            BulletTracers.drawingobjs[obj] = nil
                            obj.Visible = false
                            obj:Remove()
                        end)
                    else
                        local obj = Instance.new('Part')
                        obj.Size = Vector3.new(0.1, 0.1, velocity.Magnitude)
                        obj.CFrame = CFrame.lookAt(origin + (velocity / 2), origin + velocity)
                        obj.CanCollide = false
                        obj.CanQuery = false
                        obj.Anchored = true
                        obj.Material = Enum.Material[BulletTracers.Material] or Enum.Material.SmoothPlastic
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
    if BulletTracers.Enabled and BulletTracers.DrawingToggle then
        for obj, data in pairs(BulletTracers.drawingobjs) do
            local from, vis = Camera:WorldToViewportPoint(data[1])
            local to, vis2 = Camera:WorldToViewportPoint(data[2])
            if vis and vis2 then
                obj.Visible = true
                obj.From = Vector2.new(from.X, from.Y)
                obj.To = Vector2.new(to.X, to.Y)
                if BulletTracers.Fade then
                    obj.Transparency = BulletTracers.Opacity * (1 - math.clamp((os.clock() - data[3]) / BulletTracers.Lifetime, 0, 1))
                else
                    obj.Transparency = BulletTracers.Opacity
                end
            else
                obj.Visible = false
            end
        end
    end
end)

-- API Functions for UI
function BulletTracers:Toggle(state)
    self.Enabled = state
    if not state then
        for obj, _ in pairs(self.drawingobjs) do
            if obj then
                obj.Visible = false
                obj:Remove()
            end
        end
        self.drawingobjs = {}
    end
end

function BulletTracers:SetMaterial(val) self.Material = val end
function BulletTracers:SetColor(val) self.Color = val end
function BulletTracers:SetOpacity(val) self.Opacity = val end
function BulletTracers:SetLifetime(val) self.Lifetime = val end
function BulletTracers:SetFade(state) self.Fade = state end
function BulletTracers:SetDrawing(state) self.DrawingToggle = state end

function BulletTracers:Unload()
    self:Toggle(false)
    clearToolConns()
end

return BulletTracers
