local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local GuiManager = require(ReplicatedStorage:WaitForChild("GuiManager"))

local GROUP_ID = 1234567

local TRAININGS = {
    {
        Type = "OR/1A",
        Name = "Temel Eğitim",
        PlaceId = 111111111,
        MinRank = 9,
        MaxRank = 9,
        MaxBatchSize = 8
    },
    {
        Type = "OR/1B",
        Name = "Taktiksel Eğitim",
        PlaceId = 222222222,
        MinRank = 8,
        MaxRank = 8,
        MaxBatchSize = 8
    },
    {
        Type = "OR/1C",
        Name = "Silah Eğitimi",
        PlaceId = 333333333,
        MinRank = 5,
        MaxRank = 5,
        MaxBatchSize = 8
    },
    {
        Type = "OR/1D",
        Name = "3. Seviye Eğitim",
        PlaceId = 444444444,
        MinRank = 3,
        MaxRank = 3,
        MaxBatchSize = 8
    },
    {
        Type = "OR/1E",
        Name = "2. Seviye Eğitim",
        PlaceId = 555555555,
        MinRank = 2,
        MaxRank = 2,
        MaxBatchSize = 8
    }
}
local trainingTypeMap = {}
for _, t in pairs(TRAININGS) do trainingTypeMap[t.Type] = t end

local OpenCommandMenu = Instance.new("RemoteEvent")
OpenCommandMenu.Name = "OpenCommandMenu"
OpenCommandMenu.Parent = ReplicatedStorage

local StartTraining = Instance.new("RemoteEvent")
StartTraining.Name = "StartTraining"
StartTraining.Parent = ReplicatedStorage

local JoinTraining = Instance.new("RemoteEvent")
JoinTraining.Name = "JoinTraining"
JoinTraining.Parent = ReplicatedStorage

local HostKick = Instance.new("RemoteEvent")
HostKick.Name = "HostKick"
HostKick.Parent = ReplicatedStorage

local HostStartNow = Instance.new("RemoteEvent")
HostStartNow.Name = "HostStartNow"
HostStartNow.Parent = ReplicatedStorage

local HostCancel = Instance.new("RemoteEvent")
HostCancel.Name = "HostCancel"
HostCancel.Parent = ReplicatedStorage

local activeTrainings = {}
local cooldowns = {}

local function getRankInGroup(player)
    return player:GetRankInGroup(GROUP_ID)
end

local function now()
    return os.clock()
end

local function canStart(player, trainingType)
    cooldowns[player.UserId] = cooldowns[player.UserId] or {}
    if cooldowns[player.UserId][trainingType] and now() - cooldowns[player.UserId][trainingType] < 20 then
        return false
    end
    return true
end

local function setStartCooldown(player, trainingType)
    cooldowns[player.UserId] = cooldowns[player.UserId] or {}
    cooldowns[player.UserId][trainingType] = now()
end

local function isInQueue(session, player)
    for i, v in ipairs(session.Queue) do
        if v == player then return i end
    end
    return false
end

local function updateAllAnnouncements(trainingType, hostName, minRank, maxRank, participants, capacity, session)
    for _, p in ipairs(Players:GetPlayers()) do
        local queue = isInQueue(session, p)
        GuiManager:ShowAnnouncement(
            p,
            trainingType,
            hostName,
            minRank,
            maxRank,
            participants,
            capacity,
            queue and queue > session.MaxBatchSize and (queue - session.MaxBatchSize) or 0,
            function()
                JoinTraining:FireServer(trainingType)
            end
        )
    end
end

local function updateAllParticipants(trainingType, session)
    for _, p in ipairs(Players:GetPlayers()) do
        local queue = isInQueue(session, p)
        GuiManager:UpdateParticipantsLabel(p, trainingType, #session.Participants, session.MaxBatchSize, queue and queue > session.MaxBatchSize and (queue - session.MaxBatchSize) or 0)
    end
end

OpenCommandMenu.OnServerEvent:Connect(function(player)
    GuiManager:ShowCommandButton(player, function()
        local menu = Instance.new("ScreenGui")
        menu.Name = "CommandMenu"
        menu.Parent = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")
        for i, t in ipairs(TRAININGS) do
            local btn = Instance.new("TextButton")
            btn.Name = "TrainingBtn_"..t.Type
            btn.Position = UDim2.new(0, 20, 0, 30 + (i-1)*50)
            btn.Size = UDim2.new(0, 250, 0, 40)
            btn.Text = t.Name .. " (Rütbe: "..t.MinRank.."-"..t.MaxRank..")"
            btn.BackgroundColor3 = Color3.fromRGB(40,40,120)
            btn.TextColor3 = Color3.new(1,1,1)
            btn.Parent = menu
            btn.MouseButton1Click:Connect(function()
                StartTraining:FireServer(t.Type)
                menu:Destroy()
            end)
        end
    end)
end)

StartTraining.OnServerEvent:Connect(function(player, trainingType)
    local t = trainingTypeMap[trainingType]
    if not t then return end
    if not canStart(player, trainingType) then
        GuiManager:ShowNotification(player, "Kısa sürede tekrar eğitim başlatamazsın.", "Warning")
        return
    end
    local rank = getRankInGroup(player)
    if rank < t.MinRank or rank > t.MaxRank then
        GuiManager:ShowNotification(player, "Rütbeniz uygun değil!", "Error")
        return
    end
    for _, session in pairs(activeTrainings) do
        if session.Host == player then
            GuiManager:ShowNotification(player, "Zaten aktif bir eğitim başlattın.", "Warning")
            return
        end
    end
    if activeTrainings[trainingType] then
        local session = activeTrainings[trainingType]
        table.insert(session.Queue, player)
        updateAllAnnouncements(trainingType, session.Host.Name, t.MinRank, t.MaxRank, #session.Participants, t.MaxBatchSize, session)
        GuiManager:ShowNotification(player, "Bu eğitim zaten başlatıldı, sıraya eklendin.", "Info")
        return
    end
    local code = TeleportService:ReserveServer(t.PlaceId)
    local session = {
        Host = player,
        Participants = {},
        Queue = {},
        ServerCode = code,
        PlaceId = t.PlaceId,
        StartTime = os.time(),
        MaxBatchSize = t.MaxBatchSize
    }
    activeTrainings[trainingType] = session
    setStartCooldown(player, trainingType)
    updateAllAnnouncements(trainingType, player.Name, t.MinRank, t.MaxRank, 0, t.MaxBatchSize, session)
    task.spawn(function()
        task.wait(30)
        for _, p in ipairs(Players:GetPlayers()) do
            GuiManager:Hide(p, "TrainingAnnouncement_" .. trainingType)
        end
        activeTrainings[trainingType] = nil
    end)
    GuiManager:ShowHostPanel(player, trainingType, {}, function(name)
        HostKick:FireServer(trainingType, name)
    end, function()
        HostStartNow:FireServer(trainingType)
    end, function()
        HostCancel:FireServer(trainingType)
    end)
end)

JoinTraining.OnServerEvent:Connect(function(player, trainingType)
    local t = trainingTypeMap[trainingType]
    local session = activeTrainings[trainingType]
    if not t or not session then return end
    local rank = getRankInGroup(player)
    if rank < t.MinRank or rank > t.MaxRank then
        GuiManager:ShowNotification(player, "Rütbeniz uygun değil!", "Error")
        return
    end
    for _, v in ipairs(session.Participants) do
        if v == player then
            GuiManager:ShowNotification(player, "Zaten katılımcısınız!", "Warning")
            return
        end
    end
    for _, q in ipairs(session.Queue) do
        if q == player then
            GuiManager:ShowNotification(player, "Zaten sıradasınız!", "Warning")
            return
        end
    end
    table.insert(session.Queue, player)
    updateAllParticipants(trainingType, session)
    GuiManager:ShowNotification(player, "Katılım talebin sıraya eklendi.", "Info")
    if session.Host then
        local names = {}
        for _, p in ipairs(session.Participants) do table.insert(names, p.Name) end
        GuiManager:ShowHostPanel(session.Host, trainingType, names, function(name)
            HostKick:FireServer(trainingType, name)
        end, function()
            HostStartNow:FireServer(trainingType)
        end, function()
            HostCancel:FireServer(trainingType)
        end)
    end
end)

HostKick.OnServerEvent:Connect(function(player, trainingType, kickName)
    local session = activeTrainings[trainingType]
    if session and session.Host == player then
        for i, p in ipairs(session.Participants) do
            if p.Name == kickName then
                table.remove(session.Participants, i)
                if p then
                    GuiManager:ShowNotification(p, "Host tarafından çıkarıldınız.", "Warning")
                end
                break
            end
        end
        updateAllParticipants(trainingType, session)
        local names = {}
        for _, p in ipairs(session.Participants) do table.insert(names, p.Name) end
        GuiManager:ShowHostPanel(player, trainingType, names, function(name)
            HostKick:FireServer(trainingType, name)
        end, function()
            HostStartNow:FireServer(trainingType)
        end, function()
            HostCancel:FireServer(trainingType)
        end)
    end
end)

HostStartNow.OnServerEvent:Connect(function(player, trainingType)
    local t = trainingTypeMap[trainingType]
    local session = activeTrainings[trainingType]
    if session and session.Host == player then
        local toTeleport = {}
        for i = 1, math.min(t.MaxBatchSize, #session.Queue) do
            local pl = session.Queue[1]
            table.remove(session.Queue, 1)
            if pl then
                table.insert(session.Participants, pl)
                table.insert(toTeleport, pl)
            end
        end
        if #toTeleport > 0 then
            local teleportOptions = Instance.new("TeleportOptions")
            teleportOptions.ServerInstanceId = session.ServerCode
            TeleportService:TeleportAsync(t.PlaceId, toTeleport, teleportOptions)
        end
        updateAllParticipants(trainingType, session)
        local names = {}
        for _, p in ipairs(session.Participants) do table.insert(names, p.Name) end
        GuiManager:ShowHostPanel(player, trainingType, names, function(name)
            HostKick:FireServer(trainingType, name)
        end, function()
            HostStartNow:FireServer(trainingType)
        end, function()
            HostCancel:FireServer(trainingType)
        end)
    end
end)

HostCancel.OnServerEvent:Connect(function(player, trainingType)
    local session = activeTrainings[trainingType]
    if session and session.Host == player then
        for _, p in ipairs(Players:GetPlayers()) do
            GuiManager:Hide(p, "TrainingAnnouncement_" .. trainingType)
        end
        activeTrainings[trainingType] = nil
    end
end)

Players.PlayerAdded:Connect(function(player)
    while not player:FindFirstChild("PlayerGui") do task.wait() end
    GuiManager:ShowCommandButton(player, function()
        OpenCommandMenu:FireServer(player)
    end)
end)