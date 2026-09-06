-- bullettracersmenu.lua
-- Pepsi UI + Bullet Tracers Loader

-- 1. Load Pepsi UI
local library = loadstring(game:GetObjects("rbxassetid://7657867786")[1].Source)("Pepsi's UI Library")

-- 2. Load Bullet Tracers Module (Added ?v=2 to prevent caching issues)
local tracerUrl = "https://raw.githubusercontent.com/kianalovells2004-eng/ConsistESP/refs/heads/main/tracers.lua?v=2"
local BulletTracers = loadstring(game:HttpGet(tracerUrl))()

-- 3. Create Window
local window = library:CreateWindow({
    Name = "Consist Bullet Tracers"
})

-- 4. Main Tab
local mainTab = window:CreateTab({
    Name = "Main"
})

-- 5. Left Section (Settings)
local leftSection = mainTab:CreateSection({
    Name = "Tracer Settings",
    Side = "Left"
})

leftSection:AddToggle({
    Name = "Enable Tracers",
    Flag = "TracerEnabled",
    Value = false,
    Callback = function(value)
        BulletTracers:Toggle(value)
    end
})

leftSection:AddToggle({
    Name = "Fade",
    Flag = "TracerFade",
    Value = true,
    Callback = function(value)
        BulletTracers:SetFade(value)
    end
})

leftSection:AddToggle({
    Name = "Drawing",
    Flag = "TracerDrawing",
    Value = false,
    Callback = function(value)
        BulletTracers:SetDrawing(value)
    end
})

-- 6. Right Section (Customization)
local rightSection = mainTab:CreateSection({
    Name = "Customization",
    Side = "Right"
})

local materials = {'SmoothPlastic'}
for _, v in ipairs(Enum.Material:GetEnumItems()) do
    if v.Name ~= 'SmoothPlastic' then
        table.insert(materials, v.Name)
    end
end

rightSection:AddDropdown({
    Name = "Material",
    Flag = "TracerMaterial",
    Value = "SmoothPlastic",
    List = materials,
    Callback = function(value)
        BulletTracers:SetMaterial(value)
    end
})

rightSection:AddColorpicker({
    Name = "Tracer Color",
    Flag = "TracerColor",
    Value = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        BulletTracers:SetColor(color)
    end
})

rightSection:AddSlider({
    Name = "Opacity",
    Flag = "TracerOpacity",
    Min = 0,
    Max = 1,
    Value = 0.5,
    Decimal = 10,
    Callback = function(value)
        BulletTracers:SetOpacity(value)
    end
})

rightSection:AddSlider({
    Name = "Lifetime",
    Flag = "TracerLifetime",
    Min = 0,
    Max = 0.5,
    Value = 0.2,
    Decimal = 10,
    Callback = function(value)
        BulletTracers:SetLifetime(value)
    end
})

-- 7. Theme Designer
window:CreateDesigner({
    Credit = true,
    Info = "Consist Bullet Tracers v1.0"
})

-- 8. Unload
window.Hide = function()
    BulletTracers:Unload()
end

print("Consist Bullet Tracers Loaded Successfully!")
