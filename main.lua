-- loader.lua
-- Pepsi UI + ESP Loader
-- Fetches ESP module from GitHub and integrates with Pepsi UI

-- 1. 加载 Pepsi UI 库（从 Roblox 资产加载，推荐方式）[reference:0]
local library = loadstring(game:GetObjects("rbxassetid://7657867786")[1].Source)("Pepsi's UI Library")

-- 2. 从 GitHub 加载 ESP 模块[reference:1]
local espUrl = "https://raw.githubusercontent.com/kianalovells2004-eng/ConsistESP/refs/heads/main/esp.lua"
local ESP = loadstring(game:HttpGet(espUrl))()

-- 3. 创建窗口[reference:2]
local window = library:CreateWindow({
    Name = "Consist ESP"
})

-- 4. 创建主标签页[reference:3]
local mainTab = window:CreateTab({
    Name = "Main"
})

-- 5. 创建左侧分区[reference:4]
local leftSection = mainTab:CreateSection({
    Name = "ESP Settings",
    Side = "Left"
})

-- 6. 添加组件

-- 主开关（Toggle）
leftSection:AddToggle({
    Name = "ESP Enabled",
    Flag = "ESPEnabled",
    Value = false,
    Callback = function(value)
        ESP:Toggle(value)
    end
})

-- Box ESP
leftSection:AddToggle({
    Name = "Box ESP",
    Flag = "BoxESP",
    Value = false,
    Callback = function(value)
        ESP:ToggleBox(value)
    end
})

-- Box Fill
leftSection:AddToggle({
    Name = "Box Fill",
    Flag = "BoxFill",
    Value = false,
    Callback = function(value)
        ESP:ToggleBoxFill(value)
    end
})

-- Name ESP
leftSection:AddToggle({
    Name = "Name ESP",
    Flag = "NameESP",
    Value = false,
    Callback = function(value)
        ESP:ToggleName(value)
    end
})

-- Distance
leftSection:AddToggle({
    Name = "Distance",
    Flag = "DistanceESP",
    Value = false,
    Callback = function(value)
        ESP:ToggleDistance(value)
    end
})

-- Health Bar
leftSection:AddToggle({
    Name = "Health Bar",
    Flag = "HealthBar",
    Value = false,
    Callback = function(value)
        ESP:ToggleHealthBar(value)
    end
})

-- Health Text
leftSection:AddToggle({
    Name = "Health Text",
    Flag = "HealthText",
    Value = false,
    Callback = function(value)
        ESP:ToggleHealthText(value)
    end
})

-- 3D Box
leftSection:AddToggle({
    Name = "3D Box",
    Flag = "ThreeDBox",
    Value = false,
    Callback = function(value)
        ESP:Toggle3DBox(value)
    end
})

-- 7. 创建右侧分区（Tracers）
local rightSection = mainTab:CreateSection({
    Name = "Tracers",
    Side = "Right"
})

-- Tracer: Local Player
rightSection:AddToggle({
    Name = "Tracer (Local)",
    Flag = "TracerLocal",
    Value = false,
    Callback = function(value)
        ESP:ToggleTracerLocal(value)
    end
})

-- Tracer: Mouse
rightSection:AddToggle({
    Name = "Tracer (Mouse)",
    Flag = "TracerMouse",
    Value = false,
    Callback = function(value)
        ESP:ToggleTracerMouse(value)
    end
})

-- Tracer: Top
rightSection:AddToggle({
    Name = "Tracer (Top)",
    Flag = "TracerTop",
    Value = false,
    Callback = function(value)
        ESP:ToggleTracerTop(value)
    end
})

-- Tracer: Bottom
rightSection:AddToggle({
    Name = "Tracer (Bottom)",
    Flag = "TracerBottom",
    Value = false,
    Callback = function(value)
        ESP:ToggleTracerBottom(value)
    end
})

-- 8. 颜色设置分区
local colorSection = mainTab:CreateSection({
    Name = "Colors",
    Side = "Left"
})

-- Box Color[reference:5]
colorSection:AddColorpicker({
    Name = "Box Color",
    Flag = "BoxColor",
    Value = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        ESP:SetBoxColor(color)
    end
})

-- Box Fill Color
colorSection:AddColorpicker({
    Name = "Box Fill Color",
    Flag = "BoxFillColor",
    Value = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        ESP:SetBoxFillColor(color)
    end
})

-- Text Color
colorSection:AddColorpicker({
    Name = "Text Color",
    Flag = "TextColor",
    Value = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        ESP:SetTextColor(color)
    end
})

-- Tracer Color
colorSection:AddColorpicker({
    Name = "Tracer Color",
    Flag = "TracerColor",
    Value = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        ESP:SetTracerColor(color)
    end
})

-- 9. 创建主题设计器[reference:6]
window:CreateDesigner({
    Credit = true,
    Info = "Consist ESP v1.0"
})

-- 10. 窗口关闭时清理
window.Hide = function()
    ESP:Unload()
end

print("ESP Loaded successfully!")
