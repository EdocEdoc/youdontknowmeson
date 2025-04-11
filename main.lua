--// Cache
local getgenv, getnamecallmethod, hookmetamethod, hookfunction, newcclosure, checkcaller, lower, gsub, match = getgenv, getnamecallmethod, hookmetamethod, hookfunction, newcclosure, checkcaller, string.lower, string.gsub, string.match

--// Loaded check
if getgenv().ED_AntiKick then
    return
end

--// Variables
local cloneref = cloneref or function(...) 
    return ...
end

local clonefunction = clonefunction or function(...)
    return ...
end

local Players, LocalPlayer, StarterGui = cloneref(game:GetService("Players")), cloneref(game:GetService("Players").LocalPlayer), cloneref(game:GetService("StarterGui"))

local SetCore = clonefunction(StarterGui.SetCore)
local FindFirstChild = clonefunction(game.FindFirstChild)

local CompareInstances = (CompareInstances and function(Instance1, Instance2)
    if typeof(Instance1) == "Instance" and typeof(Instance2) == "Instance" then
        return CompareInstances(Instance1, Instance2)
    end
end) or function(Instance1, Instance2)
    return (typeof(Instance1) == "Instance" and typeof(Instance2) == "Instance")
end

local CanCastToSTDString = function(...)
    return pcall(FindFirstChild, game, ...)
end

--// Global Variables
getgenv().ED_AntiKick = {
    Enabled = true,             -- ✅ Master switch for protection
    SendNotifications = true,   -- 🔔 Send notifications when actions are blocked
    CheckCaller = true,         -- 🕵️‍♂️ Blocks external scripts from kicking
    AntiTeleport = true,        -- 🚫 Anti-Teleport enabled
    AntiDetection = true,       -- 🛡️ Basic anti-detection enabled
}

--// Anti-Kick Protection
local OldNamecall
OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
    local self, message = ...
    local method = getnamecallmethod()
    
    if ((getgenv().ED_AntiKick.CheckCaller and not checkcaller()) or true) and CompareInstances(self, LocalPlayer) and gsub(method, "^%l", string.upper) == "Kick" and ED_AntiKick.Enabled then
        if CanCastToSTDString(message) then
            if getgenv().ED_AntiKick.SendNotifications then
                SetCore(StarterGui, "SendNotification", {
                    Title = "Exunys Developer - Anti-Kick",
                    Text = "Successfully intercepted an attempted kick.",
                    Icon = "rbxassetid://6238540373",
                    Duration = 2
                })
            end
            return
        end
    end

    return OldNamecall(...)
end))

local OldFunction
OldFunction = hookfunction(LocalPlayer.Kick, function(...)
    local self, Message = ...

    if ((ED_AntiKick.CheckCaller and not checkcaller()) or true) and CompareInstances(self, LocalPlayer) and ED_AntiKick.Enabled then
        if CanCastToSTDString(Message) then
            if ED_AntiKick.SendNotifications then
                SetCore(StarterGui, "SendNotification", {
                    Title = "Exunys Developer - Anti-Kick",
                    Text = "Successfully intercepted an attempted kick.",
                    Icon = "rbxassetid://6238540373",
                    Duration = 2
                })
            end
            return
        end
    end
end)

if getgenv().ED_AntiKick.SendNotifications then
    StarterGui:SetCore("SendNotification", {
        Title = "Exunys Developer - Anti-Kick",
        Text = "Anti-Kick script loaded!",
        Icon = "rbxassetid://6238537240",
        Duration = 3
    })
end

--// Anti-Teleport Protection
local lastPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position
game:GetService("RunService").Stepped:Connect(function()
    if ED_AntiKick.Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local currentPos = LocalPlayer.Character.HumanoidRootPart.Position
        if (lastPos - currentPos).Magnitude > 50 then -- If teleport exceeds 50 studs
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(lastPos)
            if ED_AntiKick.SendNotifications then
                SetCore(StarterGui, "SendNotification", {
                    Title = "Anti-Teleport",
                    Text = "Teleport blocked!",
                    Duration = 2
                })
            end
        else
            lastPos = currentPos
        end
    end
end)

--// Anti-Detection (Basic Script Scanner)
local suspiciousServices = {"ScriptContext", "LogService"}
for _, serviceName in ipairs(suspiciousServices) do
    local service = cloneref(game:GetService(serviceName))
    for _, method in ipairs({"Error", "MessageOut"}) do
        if service[method] then
            hookfunction(service[method], function(...)
                -- Prevent error messages or logs from being caught
                return
            end)
        end
    end
end
