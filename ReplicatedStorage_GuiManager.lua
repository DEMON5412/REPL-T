local GuiManager = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local function isMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local Templates = {}

Templates.Notification = function(text, modifier)
    local gui = Instance.new("ScreenGui")
    gui.Name = "Notification"
    gui.ResetOnSpawn = false

    local frame = Instance.new("Frame")
    frame.Name = "Notification__Frame"
    frame.Size = isMobile() and UDim2.new(0.85, 0, 0, 70) or UDim2.new(0, 360, 0, 80)
    frame.Position = isMobile() and UDim2.new(0.5, 0, 0.12, 0) or UDim2.new(0.5, -180, 0.12, -20)
    frame.AnchorPoint = Vector2.new(0.5, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local colorMap = {
        ["Success"] = Color3.fromRGB(56, 179, 93),
        ["Error"] = Color3.fromRGB(209, 72, 65),
        ["Info"] = Color3.fromRGB(40, 80, 160),
        ["Warning"] = Color3.fromRGB(255, 185, 0),
    }
    local bgColor = colorMap[modifier or "Info"] or colorMap["Info"]

    local bg = Instance.new("Frame")
    bg.Name = "Notification__Frame--Background"
    bg.BackgroundColor3 = bgColor
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.Position = UDim2.new(0, 0, 0, 0)
    bg.BackgroundTransparency = 0.1
    bg.BorderSizePixel = 0
    bg.Parent = frame

    local label = Instance.new("TextLabel")
    label.Name = "Notification__Text"
    label.Size = UDim2.new(1, -40, 1, -20)
    label.Position = UDim2.new(0, 20, 0, 10)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = isMobile() and 15 or 19
    label.TextWrapped = true
    label.Text = text or "Bir bildirim!"
    label.Parent = frame

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Notification__Close"
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -35, 0, 6)
    closeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 60)
    closeBtn.BackgroundTransparency = 0.30
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextSize = 21
    closeBtn.BorderSizePixel = 0
    closeBtn.ZIndex = 3
    closeBtn.Parent = frame

    return gui, frame, closeBtn
end

Templates.Announcement = function(trainingType, hostName, minRank, maxRank, participants, capacity, queue)
    local gui = Instance.new("ScreenGui")
    gui.Name = "TrainingAnnouncement_" .. trainingType
    gui.ResetOnSpawn = false

    local frame = Instance.new("Frame")
    frame.Name = "AnnouncementFrame"
    frame.Size = isMobile() and UDim2.new(0.95, 0, 0, 190) or UDim2.new(0, 400, 0, 150)
    frame.Position = isMobile() and UDim2.new(0.5, 0, 0.18, 0) or UDim2.new(0.5, -200, 0, 20)
    frame.AnchorPoint = isMobile() and Vector2.new(0.5,0) or Vector2.new(0,0)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 100)
    frame.BorderSizePixel = 2
    frame.Parent = gui

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Text = "EĞİTİM DUYURUSU"
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 80)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 20
    title.Parent = frame

    local hostLabel = Instance.new("TextLabel")
    hostLabel.Name = "HostLabel"
    hostLabel.Size = UDim2.new(0.5, 0, 0, 25)
    hostLabel.Position = UDim2.new(0, 10, 0, 35)
    hostLabel.Text = "Host: " .. hostName
    hostLabel.BackgroundTransparency = 1
    hostLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    hostLabel.Font = Enum.Font.SourceSans
    hostLabel.TextSize = 16
    hostLabel.TextXAlignment = Enum.TextXAlignment.Left
    hostLabel.Parent = frame

    local typeLabel = Instance.new("TextLabel")
    typeLabel.Name = "TypeLabel"
    typeLabel.Size = UDim2.new(0.5, 0, 0, 25)
    typeLabel.Position = UDim2.new(0.5, 0, 0, 35)
    typeLabel.Text = "Tür: " .. trainingType
    typeLabel.BackgroundTransparency = 1
    typeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    typeLabel.Font = Enum.Font.SourceSans
    typeLabel.TextSize = 16
    typeLabel.TextXAlignment = Enum.TextXAlignment.Left
    typeLabel.Parent = frame

    local joinButton = Instance.new("TextButton")
    joinButton.Name = "JoinButton"
    joinButton.Size = UDim2.new(0, 120, 0, 30)
    joinButton.Position = isMobile() and UDim2.new(0.05, 0, 0, 110) or UDim2.new(0.05, 0, 0, 70)
    joinButton.Text = "Katıl"
    joinButton.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
    joinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    joinButton.Font = Enum.Font.SourceSansBold
    joinButton.TextSize = 18
    joinButton.Parent = frame

    local participantsLabel = Instance.new("TextLabel")
    participantsLabel.Name = "ParticipantsLabel"
    participantsLabel.Size = UDim2.new(0, 180, 0, 30)
    participantsLabel.Position = isMobile() and UDim2.new(0.65, 0, 0, 110) or UDim2.new(0.65, 0, 0, 70)
    participantsLabel.Text = "Katılımcı: " .. tostring(participants or 0) .. "/" .. tostring(capacity or "-")
    participantsLabel.BackgroundTransparency = 1
    participantsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    participantsLabel.Font = Enum.Font.SourceSans
    participantsLabel.TextSize = 16
    participantsLabel.TextXAlignment = Enum.TextXAlignment.Left
    participantsLabel.Parent = frame

    local targetRankLabel = Instance.new("TextLabel")
    targetRankLabel.Name = "TargetRankLabel"
    targetRankLabel.Size = UDim2.new(0, 180, 0, 20)
    targetRankLabel.Position = isMobile() and UDim2.new(0.65, 0, 0, 95) or UDim2.new(0.65, 0, 0, 55)
    targetRankLabel.Text = "Hedef Rütbe: " .. minRank .. "-" .. maxRank
    targetRankLabel.BackgroundTransparency = 1
    targetRankLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    targetRankLabel.Font = Enum.Font.SourceSans
    targetRankLabel.TextSize = 14
    targetRankLabel.TextXAlignment = Enum.TextXAlignment.Left
    targetRankLabel.Parent = frame

    local queueLabel = Instance.new("TextLabel")
    queueLabel.Name = "QueueLabel"
    queueLabel.Size = UDim2.new(1, -20, 0, 25)
    queueLabel.Position = isMobile() and UDim2.new(0, 10, 0, 150) or UDim2.new(0, 10, 0, 120)
    queueLabel.BackgroundTransparency = 1
    queueLabel.Font = Enum.Font.SourceSans
    queueLabel.TextColor3 = Color3.fromRGB(240, 230, 130)
    queueLabel.TextSize = 15
    queueLabel.Text = queue and queue > 0 and ("Sıradasınız: " .. tostring(queue)) or ""
    queueLabel.Parent = frame

    return gui, joinButton, participantsLabel, queueLabel
end

Templates.CommandButton = function()
    local gui = Instance.new("ScreenGui")
    gui.Name = "CommandButton"
    gui.ResetOnSpawn = false
    local btn = Instance.new("TextButton")
    btn.Name = "CommandButton__Button"
    btn.Size = isMobile() and UDim2.new(0, 140, 0, 50) or UDim2.new(0, 100, 0, 38)
    btn.Position = isMobile() and UDim2.new(0, 8, 0.93, -19) or UDim2.new(0, 8, 0.5, -19)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 120)
    btn.Text = "Komut Menüsü"
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = isMobile() and 20 or 18
    btn.Parent = gui
    return gui, btn
end

Templates.HostPanel = function(trainingType, participantNames, onKick, onStartNow, onCancel)
    local gui = Instance.new("ScreenGui")
    gui.Name = "HostPanel_"..trainingType
    gui.ResetOnSpawn = false

    local frame = Instance.new("Frame")
    frame.Name = "HostPanelFrame"
    frame.Size = UDim2.new(0, 350, 0, 220)
    frame.Position = UDim2.new(0.5, -175, 0.1, 20)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 100)
    frame.BorderSizePixel = 2
    frame.Parent = gui

    local title = Instance.new("TextLabel")
    title.Name = "PanelTitle"
    title.Size = UDim2.new(1, 0, 0, 32)
    title.Text = trainingType.." - Host Panel"
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 80)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 19
    title.Parent = frame

    local y = 40
    for i, name in ipairs(participantNames) do
        local plabel = Instance.new("TextLabel")
        plabel.Name = "Participant_"..i
        plabel.Text = name
        plabel.Size = UDim2.new(0.7, 0, 0, 22)
        plabel.Position = UDim2.new(0, 14, 0, y)
        plabel.BackgroundTransparency = 1
        plabel.TextColor3 = Color3.fromRGB(220,220,220)
        plabel.Font = Enum.Font.SourceSans
        plabel.TextSize = 16
        plabel.TextXAlignment = Enum.TextXAlignment.Left
        plabel.Parent = frame

        local kick = Instance.new("TextButton")
        kick.Name = "KickBtn_"..name
        kick.Text = "Çıkar"
        kick.Size = UDim2.new(0, 48, 0, 22)
        kick.Position = UDim2.new(0.77, 0, 0, y)
        kick.BackgroundColor3 = Color3.fromRGB(180,40,40)
        kick.TextColor3 = Color3.new(1,1,1)
        kick.Font = Enum.Font.SourceSansBold
        kick.TextSize = 15
        kick.Parent = frame
        if typeof(onKick) == "function" then
            kick.MouseButton1Click:Connect(function()
                onKick(name)
            end)
        end
        y = y + 25
    end

    local startNow = Instance.new("TextButton")
    startNow.Name = "StartNow"
    startNow.Text = "Erken Başlat"
    startNow.Size = UDim2.new(0, 110, 0, 32)
    startNow.Position = UDim2.new(0, 15, 0, y+8)
    startNow.BackgroundColor3 = Color3.fromRGB(50,180,50)
    startNow.TextColor3 = Color3.new(1,1,1)
    startNow.Font = Enum.Font.SourceSansBold
    startNow.TextSize = 16
    startNow.Parent = frame
    if typeof(onStartNow) == "function" then
        startNow.MouseButton1Click:Connect(onStartNow)
    end

    local cancel = Instance.new("TextButton")
    cancel.Name = "Cancel"
    cancel.Text = "Eğitimi İptal Et"
    cancel.Size = UDim2.new(0, 110, 0, 32)
    cancel.Position = UDim2.new(0, 135, 0, y+8)
    cancel.BackgroundColor3 = Color3.fromRGB(180,50,50)
    cancel.TextColor3 = Color3.new(1,1,1)
    cancel.Font = Enum.Font.SourceSansBold
    cancel.TextSize = 16
    cancel.Parent = frame
    if typeof(onCancel) == "function" then
        cancel.MouseButton1Click:Connect(onCancel)
    end

    return gui
end

function GuiManager:ShowNotification(player, text, modifier, duration)
    duration = duration or 2.5
    self:Hide(player, "Notification")
    local gui, frame, closeBtn = Templates.Notification(text, modifier)
    local playerGui = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")
    gui.Parent = playerGui
    TweenService:Create(frame, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = isMobile() and UDim2.new(0.5, 0, 0.17, 0) or UDim2.new(0.5, -180, 0.18, 0),
        BackgroundTransparency = 0
    }):Play()
    local closed = false
    local function close()
        if closed then return end
        closed = true
        if gui.Parent then
            TweenService:Create(frame, TweenInfo.new(0.28, Enum.EasingStyle.Quad), {
                Position = isMobile() and UDim2.new(0.5, 0, 0.10, -30) or UDim2.new(0.5, -180, 0.10, -30),
                BackgroundTransparency = 1
            }):Play()
            task.wait(0.29)
            gui:Destroy()
        end
    end
    closeBtn.MouseButton1Click:Connect(close)
    task.spawn(function() task.wait(duration) close() end)
end

function GuiManager:ShowCommandButton(player, onClick)
    self:Hide(player, "CommandButton")
    local gui, btn = Templates.CommandButton()
    local playerGui = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")
    gui.Parent = playerGui
    if typeof(onClick) == "function" then
        btn.MouseButton1Click:Connect(onClick)
    end
end

function GuiManager:ShowAnnouncement(player, trainingType, hostName, minRank, maxRank, participants, capacity, queue, onJoin)
    self:Hide(player, "TrainingAnnouncement_" .. trainingType)
    local gui, joinButton, participantsLabel, queueLabel = Templates.Announcement(trainingType, hostName, minRank, maxRank, participants, capacity, queue)
    local playerGui = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")
    gui.Parent = playerGui
    if typeof(onJoin) == "function" then
        joinButton.MouseButton1Click:Connect(onJoin)
    end
    return participantsLabel, queueLabel
end

function GuiManager:ShowHostPanel(player, trainingType, participantNames, onKick, onStartNow, onCancel)
    self:Hide(player, "HostPanel_"..trainingType)
    local gui = Templates.HostPanel(trainingType, participantNames, onKick, onStartNow, onCancel)
    local playerGui = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")
    gui.Parent = playerGui
end

function GuiManager:UpdateParticipantsLabel(player, trainingType, participants, capacity, queue)
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    local gui = playerGui:FindFirstChild("TrainingAnnouncement_" .. trainingType)
    if gui and gui:FindFirstChild("AnnouncementFrame") then
        if gui.AnnouncementFrame:FindFirstChild("ParticipantsLabel") then
            gui.AnnouncementFrame.ParticipantsLabel.Text = "Katılımcı: " .. tostring(participants) .. "/" .. tostring(capacity or "-")
        end
        if gui.AnnouncementFrame:FindFirstChild("QueueLabel") then
            gui.AnnouncementFrame.QueueLabel.Text = queue and queue > 0 and ("Sıradasınız: " .. tostring(queue)) or ""
        end
    end
end

function GuiManager:Hide(player, guiName)
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    local gui = playerGui:FindFirstChild(guiName)
    if gui then
        gui:Destroy()
    end
end

return GuiManager