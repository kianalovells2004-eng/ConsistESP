-- loader.lua
-- Pepsi UI + ESP Loader

-- 1. Load Pepsi UI
local library = loadstring(game:GetObjects("rbxassetid://7657867786")[1].Source)("Pepsi's UI Library")

-- 2. Load ESP Module
local espUrl = "https://raw.githubusercontent.com/kianalovells2004-eng/ConsistESP/refs/heads/main/esp.lua"
local ESP = loadstring(game:HttpGet(espUrl))()

-- 3. Create Window
local window = library:CreateWindow({
    Name = "Consist ESP"
})

-- 4. Main Tab
local mainTab = window:CreateTab({
    Name = "Main"
})

-- 5. Left Section (ESP)
local leftSection = mainTab:CreateSection({
    Name = "ESP Settings",
    Side = "Left"
})

leftSection:AddToggle({
    Name = "ESP Enabled",
    Flag = "ESPEnabled",
    Value = false,
    Callback = function(value)
        ESP:Toggle(value)
    end
})

leftSection:AddToggle({
    Name = "Team Check",
    Flag = "TeamCheck",
    Value = false,
    Callback = function(value)
        ESP:ToggleTeamCheck(value)
    end
})

leftSection:AddToggle({
    Name = "Box ESP",
    Flag = "BoxESP",
    Value = false,
    Callback = function(value)
        ESP:ToggleBox(value)
        if not value then
            pcall(function()
                if library.Flags.BoxFill then
                    library.Flags.BoxFill:SetValue(false)
                end
                if library.Flags.BoxStreak then
                    library.Flags.BoxStreak:SetValue(false)
                end
            end)
        end
    end
})

leftSection:AddToggle({
    Name = "Corner Box",
    Flag = "CornerBox",
    Value = false,
    Callback = function(value)
        ESP:ToggleCornerBox(value)
    end
})

leftSection:AddToggle({
    Name = "Box Fill",
    Flag = "BoxFill",
    Value = false,
    Callback = function(value)
        if value and not ESP.BoxEnabled then
            pcall(function()
                if library.Flags.BoxFill then
                    library.Flags.BoxFill:SetValue(false)
                end
            end)
            return
        end
        ESP:ToggleBoxFill(value)
    end
})

leftSection:AddToggle({
    Name = "Box Streak",
    Flag = "BoxStreak",
    Value = false,
    Callback = function(value)
        if value and not ESP.BoxEnabled then
            pcall(function()
                if library.Flags.BoxStreak then
                    library.Flags.BoxStreak:SetValue(false)
                end
            end)
            return
        end
        ESP:ToggleBoxStreak(value)
    end
})

leftSection:AddSlider({
    Name = "Streak Speed",
    Flag = "StreakSpeed",
    Min = 1,
    Max = 10,
    Value = 1,
    Callback = function(value)
        ESP:SetStreakSpeed(value)
    end
})

leftSection:AddToggle({
    Name = "Name ESP",
    Flag = "NameESP",
    Value = false,
    Callback = function(value)
        ESP:ToggleName(value)
    end
})

leftSection:AddToggle({
    Name = "Display Name",
    Flag = "DisplayName",
    Value = false,
    Callback = function(value)
        ESP:ToggleDisplayName(value)
    end
})

leftSection:AddToggle({
    Name = "Item ESP (Tool)",
    Flag = "ItemESP",
    Value = false,
    Callback = function(value)
        ESP:ToggleItem(value)
    end
})

leftSection:AddToggle({
    Name = "Team Indicator",
    Flag = "TeamIndicator",
    Value = false,
    Callback = function(value)
        ESP:ToggleTeamIndicator(value)
    end
})

leftSection:AddToggle({
    Name = "Distance",
    Flag = "DistanceESP",
    Value = false,
    Callback = function(value)
        ESP:ToggleDistance(value)
    end
})

leftSection:AddToggle({
    Name = "Health Bar",
    Flag = "HealthBar",
    Value = false,
    Callback = function(value)
        ESP:ToggleHealthBar(value)
    end
})

leftSection:AddToggle({
    Name = "Health Text",
    Flag = "HealthText",
    Value = false,
    Callback = function(value)
        ESP:ToggleHealthText(value)
    end
})

leftSection:AddToggle({
    Name = "3D Box",
    Flag = "ThreeDBox",
    Value = false,
    Callback = function(value)
        ESP:Toggle3DBox(value)
    end
})


leftSection:AddToggle({
    Name = "Forcefield Indicator",
    Flag = "ForcefieldIndicator",
    Value = false,
    Callback = function(value)
        ESP:ToggleForcefield(value)
    end
})

-- 6. Right Section (Tracers)
local rightSection = mainTab:CreateSection({
    Name = "Tracers",
    Side = "Right"
})

rightSection:AddToggle({
    Name = "Body Tracer",
    Flag = "BodyTracer",
    Value = false,
    Callback = function(value)
        ESP:ToggleBodyTracer(value)
    end
})

rightSection:AddToggle({
    Name = "Tracer (Mouse)",
    Flag = "TracerMouse",
    Value = false,
    Callback = function(value)
        ESP:ToggleTracerMouse(value)
    end
})

rightSection:AddToggle({
    Name = "Tracer (Top)",
    Flag = "TracerTop",
    Value = false,
    Callback = function(value)
        ESP:ToggleTracerTop(value)
    end
})

rightSection:AddToggle({
    Name = "Tracer (Bottom)",
    Flag = "TracerBottom",
    Value = false,
    Callback = function(value)
        ESP:ToggleTracerBottom(value)
    end
})

-- 7. Colors Section
local colorSection = mainTab:CreateSection({
    Name = "Colors",
    Side = "Left"
})

colorSection:AddToggle({
    Name = "Team Color ESP",
    Flag = "TeamColorESP",
    Value = false,
    Callback = function(value)
        ESP:ToggleTeamColor(value)
    end
})

colorSection:AddColorpicker({
    Name = "Box Color",
    Flag = "BoxColor",
    Value = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        ESP:SetBoxColor(color)
    end
})

colorSection:AddColorpicker({
    Name = "Box Fill Color",
    Flag = "BoxFillColor",
    Value = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        ESP:SetBoxFillColor(color)
    end
})

colorSection:AddColorpicker({
    Name = "Streak Color",
    Flag = "StreakColor",
    Value = Color3.fromRGB(0, 255, 255),
    Callback = function(color)
        ESP:SetStreakColor(color)
    end
})

colorSection:AddColorpicker({
    Name = "Text Color",
    Flag = "TextColor",
    Value = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        ESP:SetTextColor(color)
    end
})

colorSection:AddColorpicker({
    Name = "Tracer Color",
    Flag = "TracerColor",
    Value = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        ESP:SetTracerColor(color)
    end
})

-- 8. Team Filter Section
local teamFilterSection = mainTab:CreateSection({
    Name = "Team Filter",
    Side = "Right"
})

local Teams = game:GetService("Teams")
for _, team in ipairs(Teams:GetTeams()) do
    local teamName = team.Name
    -- Default to true so all teams show initially
    ESP.WhitelistedTeams[teamName] = true 
    
    teamFilterSection:AddToggle({
        Name = "Show " .. teamName,
        Flag = "TeamFilter_" .. teamName,
        Value = true,
        Callback = function(value)
            ESP:ToggleWhitelistedTeam(teamName, value)
        end
    })
end

-- 9. Theme Designer
window:CreateDesigner({
    Credit = true,
    Info = "Consist ESP v2.3"
})

-- 10. Unload
window.Hide = function()
    ESP:Unload()
end

print("Consist ESP Loaded Successfully (v2.3)!")
