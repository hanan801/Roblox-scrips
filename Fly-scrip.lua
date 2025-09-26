-- Lunar Script by Developer
-- GUI dengan fitur speed boost, jump boost, infinity jump, anti slow, teleport, dan sistem login

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- DataStore untuk menyimpan konfigurasi
local DataStoreService = game:GetService("DataStoreService")
local configDataStore = DataStoreService:GetDataStore("LunarScriptConfig")

-- Variabel global
local speedBoostEnabled = false
local jumpBoostEnabled = false
local infinityJumpEnabled = false
local antiSlowEnabled = false
local antiLowJumpEnabled = false
local notificationsEnabled = true
local currentSpeed = 16
local currentJump = 50
local selectedPlayer = nil
local mainGui
local notificationFrame
local loginFrame
local mainFrame
local isGuiVisible = false

-- Fungsi untuk menampilkan notifikasi (jika diaktifkan)
local function showNotification(message, duration)
    if not notificationsEnabled then return end
    
    duration = duration or 3
    
    if notificationFrame then
        notificationFrame:Destroy()
    end
    
    notificationFrame = Instance.new("Frame")
    notificationFrame.Size = UDim2.new(0, 300, 0, 60)
    notificationFrame.Position = UDim2.new(1, 10, 0, 10)
    notificationFrame.AnchorPoint = Vector2.new(1, 0)
    notificationFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    notificationFrame.BorderSizePixel = 0
    notificationFrame.ZIndex = 100
    notificationFrame.Parent = mainGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notificationFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(100, 100, 100)
    stroke.Thickness = 2
    stroke.Parent = notificationFrame
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -20, 1, -30)
    messageLabel.Position = UDim2.new(0, 10, 0, 5)
    messageLabel.Text = message
    messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    messageLabel.BackgroundTransparency = 1
    messageLabel.TextSize = 14
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.ZIndex = 101
    messageLabel.Parent = notificationFrame
    
    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(0, 0, 0, 3)
    progressBar.Position = UDim2.new(0, 0, 1, -3)
    progressBar.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    progressBar.BorderSizePixel = 0
    progressBar.ZIndex = 101
    progressBar.Parent = notificationFrame
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 2)
    progressCorner.Parent = progressBar
    
    -- Animasi notifikasi masuk
    local entranceTween = TweenService:Create(notificationFrame, TweenInfo.new(0.3), {Position = UDim2.new(1, -10, 0, 10)})
    entranceTween:Play()
    
    -- Animasi progress bar
    local progressTween = TweenService:Create(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 0, 3)})
    progressTween:Play()
    
    -- Hapus notifikasi setelah durasi
    delay(duration, function()
        local exitTween = TweenService:Create(notificationFrame, TweenInfo.new(0.3), {Position = UDim2.new(1, 10, 0, 10)})
        exitTween:Play()
        wait(0.3)
        if notificationFrame then
            notificationFrame:Destroy()
        end
    end)
end

-- Fungsi untuk memperbarui kecepatan karakter
local function updateSpeed()
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        if speedBoostEnabled then
            player.Character.Humanoid.WalkSpeed = currentSpeed
        else
            player.Character.Humanoid.WalkSpeed = 16
        end
    end
end

-- Fungsi untuk memperbarui lompatan karakter
local function updateJump()
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        if jumpBoostEnabled and not infinityJumpEnabled then
            player.Character.Humanoid.JumpPower = currentJump
        else
            player.Character.Humanoid.JumpPower = 50
        end
    end
end

-- Fungsi Infinity Jump (Fly Mode)
local infinityJumpConnection
local function toggleInfinityJump()
    if infinityJumpEnabled then
        infinityJumpConnection = RunService.Heartbeat:Connect(function()
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                local humanoid = player.Character.Humanoid
                
                -- Cek jika pemain menekan tombol lompat
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    -- Terbang ke atas
                    humanoid.JumpPower = 0
                    if player.Character:FindFirstChild("HumanoidRootPart") then
                        player.Character.HumanoidRootPart.Velocity = Vector3.new(
                            player.Character.HumanoidRootPart.Velocity.X,
                            50,  -- Kecepatan terbang ke atas
                            player.Character.HumanoidRootPart.Velocity.Z
                        )
                    end
                else
                    -- Kembali ke lompatan normal jika tidak menekan space
                    humanoid.JumpPower = jumpBoostEnabled and currentJump or 50
                end
            end
        end)
    else
        if infinityJumpConnection then
            infinityJumpConnection:Disconnect()
            infinityJumpConnection = nil
        end
        -- Kembalikan ke lompatan normal
        updateJump()
    end
end

-- Fungsi anti slow (melawan efek slow)
local antiSlowConnection
local function toggleAntiSlow()
    if antiSlowEnabled then
        antiSlowConnection = RunService.Heartbeat:Connect(function()
            if speedBoostEnabled and player.Character and player.Character:FindFirstChild("Humanoid") then
                -- Tambahkan dan kurangi kecepatan secara cepat untuk melawan slow
                player.Character.Humanoid.WalkSpeed = currentSpeed + 1
                wait(0.05)
                if player.Character and player.Character:FindFirstChild("Humanoid") then
                    player.Character.Humanoid.WalkSpeed = currentSpeed
                end
            end
        end)
    else
        if antiSlowConnection then
            antiSlowConnection:Disconnect()
            antiSlowConnection = nil
        end
    end
end

-- Fungsi anti low jump (melawan efek rendahnya lompatan)
local antiLowJumpConnection
local function toggleAntiLowJump()
    if antiLowJumpEnabled then
        antiLowJumpConnection = RunService.Heartbeat:Connect(function()
            if jumpBoostEnabled and player.Character and player.Character:FindFirstChild("Humanoid") then
                -- Tambahkan dan kurangi kekuatan lompat secara cepat
                player.Character.Humanoid.JumpPower = currentJump + 5
                wait(0.05)
                if player.Character and player.Character:FindFirstChild("Humanoid") then
                    player.Character.Humanoid.JumpPower = currentJump
                end
            end
        end)
    else
        if antiLowJumpConnection then
            antiLowJumpConnection:Disconnect()
            antiLowJumpConnection = nil
        end
    end
end

-- Fungsi untuk membuat GUI login
local function createLoginGUI()
    loginFrame = Instance.new("Frame")
    loginFrame.Size = UDim2.new(0, 350, 0, 250)
    loginFrame.Position = UDim2.new(0.5, -175, 0.5, -125)
    loginFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    loginFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    loginFrame.BorderSizePixel = 0
    loginFrame.ZIndex = 10
    loginFrame.Parent = mainGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = loginFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 80, 120)
    stroke.Thickness = 2
    stroke.Parent = loginFrame
    
    -- Background gradient
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(10, 10, 25)
    background.ZIndex = 0
    background.Parent = loginFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 50)
    titleLabel.Position = UDim2.new(0, 0, 0, 10)
    titleLabel.Text = "LUNAR SCRIPT"
    titleLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextSize = 24
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.ZIndex = 11
    titleLabel.Parent = loginFrame
    
    local keyLabel = Instance.new("TextLabel")
    keyLabel.Size = UDim2.new(1, -40, 0, 30)
    keyLabel.Position = UDim2.new(0, 20, 0, 80)
    keyLabel.Text = "Enter Key:"
    keyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    keyLabel.BackgroundTransparency = 1
    keyLabel.TextSize = 16
    keyLabel.Font = Enum.Font.Gotham
    keyLabel.TextXAlignment = Enum.TextXAlignment.Left
    keyLabel.ZIndex = 11
    keyLabel.Parent = loginFrame
    
    local keyBox = Instance.new("TextBox")
    keyBox.Size = UDim2.new(1, -40, 0, 35)
    keyBox.Position = UDim2.new(0, 20, 0, 110)
    keyBox.PlaceholderText = "Paste your key here"
    keyBox.Text = ""
    keyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyBox.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    keyBox.BorderSizePixel = 0
    keyBox.TextSize = 16
    keyBox.Font = Enum.Font.Gotham
    keyBox.ZIndex = 11
    keyBox.Parent = loginFrame
    
    local keyBoxCorner = Instance.new("UICorner")
    keyBoxCorner.CornerRadius = UDim.new(0, 5)
    keyBoxCorner.Parent = keyBox
    
    local loginButton = Instance.new("TextButton")
    loginButton.Size = UDim2.new(1, -40, 0, 40)
    loginButton.Position = UDim2.new(0, 20, 0, 160)
    loginButton.Text = "LOGIN"
    loginButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    loginButton.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
    loginButton.BorderSizePixel = 0
    loginButton.TextSize = 18
    loginButton.Font = Enum.Font.GothamBold
    loginButton.ZIndex = 11
    loginButton.Parent = loginFrame
    
    local loginButtonCorner = Instance.new("UICorner")
    loginButtonCorner.CornerRadius = UDim.new(0, 5)
    loginButtonCorner.Parent = loginButton
    
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, -40, 0, 40)
    infoLabel.Position = UDim2.new(0, 20, 0, 210)
    infoLabel.Text = "Get your key from our website"
    infoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    infoLabel.BackgroundTransparency = 1
    infoLabel.TextSize = 14
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.ZIndex = 11
    infoLabel.Parent = loginFrame
    
    -- Fungsi login
    loginButton.MouseButton1Click:Connect(function()
        local key = keyBox.Text
        
        -- Verifikasi kunci (contoh sederhana)
        if key ~= "" and string.len(key) >= 10 then
            -- Simpan kunci dan waktu login
            local loginData = {
                key = key,
                loginTime = os.time()
            }
            
            local success, error = pcall(function()
                configDataStore:SetAsync(player.UserId .. "_LoginData", loginData)
            end)
            
            if success then
                showNotification("Login successful!", 2)
                wait(1)
                loginFrame.Visible = false
                createMainGUI()
            else
                showNotification("Login failed: " .. error, 3)
            end
        else
            showNotification("Invalid key format", 2)
        end
    end)
end

-- Fungsi untuk membuat GUI utama
local function createMainGUI()
    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 400, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.ZIndex = 5
    mainFrame.Visible = true
    mainFrame.Parent = mainGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 80, 120)
    stroke.Thickness = 2
    stroke.Parent = mainFrame
    
    -- Background gradient
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(10, 10, 25)
    background.ZIndex = 0
    background.Parent = mainFrame
    
    -- Header dengan tombol close
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 40)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    header.BorderSizePixel = 0
    header.ZIndex = 6
    header.Parent = mainFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 10)
    headerCorner.Parent = header
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -50, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.Text = "LUNAR SCRIPT"
    titleLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 7
    titleLabel.Parent = header
    
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 100, 100)
    closeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    closeButton.BorderSizePixel = 0
    closeButton.TextSize = 16
    closeButton.Font = Enum.Font.GothamBold
    closeButton.ZIndex = 7
    closeButton.Parent = header
    
    local closeButtonCorner = Instance.new("UICorner")
    closeButtonCorner.CornerRadius = UDim.new(0, 5)
    closeButtonCorner.Parent = closeButton
    
    -- Tab container
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, -20, 0, 30)
    tabContainer.Position = UDim2.new(0, 10, 0, 50)
    tabContainer.BackgroundTransparency = 1
    tabContainer.ZIndex = 6
    tabContainer.Parent = mainFrame
    
    -- Tabs
    local tabs = {"Main", "Information", "Settings"}
    local tabButtons = {}
    local tabFrames = {}
    
    for i, tabName in ipairs(tabs) do
        local tabButton = Instance.new("TextButton")
        tabButton.Size = UDim2.new(0.33, -5, 1, 0)
        tabButton.Position = UDim2.new((i-1) * 0.33, 0, 0, 0)
        tabButton.Text = tabName
        tabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
        tabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        tabButton.BorderSizePixel = 0
        tabButton.TextSize = 14
        tabButton.Font = Enum.Font.Gotham
        tabButton.ZIndex = 7
        tabButton.Parent = tabContainer
        
        local tabButtonCorner = Instance.new("UICorner")
        tabButtonCorner.CornerRadius = UDim.new(0, 5)
        tabButtonCorner.Parent = tabButton
        
        local tabFrame = Instance.new("ScrollingFrame")
        tabFrame.Size = UDim2.new(1, -20, 1, -100)
        tabFrame.Position = UDim2.new(0, 10, 0, 90)
        tabFrame.BackgroundTransparency = 1
        tabFrame.BorderSizePixel = 0
        tabFrame.ScrollBarThickness = 5
        tabFrame.Visible = (i == 1)
        tabFrame.ZIndex = 6
        tabFrame.Parent = mainFrame
        
        tabButtons[tabName] = tabButton
        tabFrames[tabName] = tabFrame
        
        tabButton.MouseButton1Click:Connect(function()
            for _, frame in pairs(tabFrames) do
                frame.Visible = false
            end
            tabFrame.Visible = true
            
            for _, button in pairs(tabButtons) do
                button.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            end
            tabButton.BackgroundColor3 = Color3.fromRGB(70, 100, 150)
        end)
    end
    
    -- Konten tab Main
    local mainTab = tabFrames["Main"]
    
    -- Speed Boost Section
    local speedSection = Instance.new("Frame")
    speedSection.Size = UDim2.new(1, 0, 0, 80)
    speedSection.Position = UDim2.new(0, 0, 0, 10)
    speedSection.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    speedSection.BorderSizePixel = 0
    speedSection.ZIndex = 7
    speedSection.Parent = mainTab
    
    local speedSectionCorner = Instance.new("UICorner")
    speedSectionCorner.CornerRadius = UDim.new(0, 5)
    speedSectionCorner.Parent = speedSection
    
    local speedLabel = Instance.new("TextLabel")
    speedLabel.Size = UDim2.new(1, -20, 0, 25)
    speedLabel.Position = UDim2.new(0, 10, 0, 5)
    speedLabel.Text = "Speed Boost"
    speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    speedLabel.BackgroundTransparency = 1
    speedLabel.TextSize = 16
    speedLabel.Font = Enum.Font.Gotham
    speedLabel.TextXAlignment = Enum.TextXAlignment.Left
    speedLabel.ZIndex = 8
    speedLabel.Parent = speedSection
    
    local speedToggle = Instance.new("TextButton")
    speedToggle.Size = UDim2.new(0, 50, 0, 25)
    speedToggle.Position = UDim2.new(1, -60, 0, 5)
    speedToggle.Text = "OFF"
    speedToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedToggle.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    speedToggle.BorderSizePixel = 0
    speedToggle.TextSize = 12
    speedToggle.Font = Enum.Font.GothamBold
    speedToggle.ZIndex = 8
    speedToggle.Parent = speedSection
    
    local speedToggleCorner = Instance.new("UICorner")
    speedToggleCorner.CornerRadius = UDim.new(0, 5)
    speedToggleCorner.Parent = speedToggle
    
    local speedValueLabel = Instance.new("TextLabel")
    speedValueLabel.Size = UDim2.new(0, 40, 0, 25)
    speedValueLabel.Position = UDim2.new(0.5, -20, 0, 45)
    speedValueLabel.Text = tostring(currentSpeed)
    speedValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedValueLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    speedValueLabel.BorderSizePixel = 0
    speedValueLabel.TextSize = 14
    speedValueLabel.Font = Enum.Font.GothamBold
    speedValueLabel.ZIndex = 8
    speedValueLabel.Parent = speedSection
    
    local speedValueCorner = Instance.new("UICorner")
    speedValueCorner.CornerRadius = UDim.new(0, 5)
    speedValueCorner.Parent = speedValueLabel
    
    local speedDecreaseButton = Instance.new("TextButton")
    speedDecreaseButton.Size = UDim2.new(0, 30, 0, 25)
    speedDecreaseButton.Position = UDim2.new(0.5, -60, 0, 45)
    speedDecreaseButton.Text = "<"
    speedDecreaseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedDecreaseButton.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
    speedDecreaseButton.BorderSizePixel = 0
    speedDecreaseButton.TextSize = 14
    speedDecreaseButton.Font = Enum.Font.GothamBold
    speedDecreaseButton.ZIndex = 8
    speedDecreaseButton.Parent = speedSection
    
    local speedDecreaseCorner = Instance.new("UICorner")
    speedDecreaseCorner.CornerRadius = UDim.new(0, 5)
    speedDecreaseCorner.Parent = speedDecreaseButton
    
    local speedIncreaseButton = Instance.new("TextButton")
    speedIncreaseButton.Size = UDim2.new(0, 30, 0, 25)
    speedIncreaseButton.Position = UDim2.new(0.5, 30, 0, 45)
    speedIncreaseButton.Text = ">"
    speedIncreaseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedIncreaseButton.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
    speedIncreaseButton.BorderSizePixel = 0
    speedIncreaseButton.TextSize = 14
    speedIncreaseButton.Font = Enum.Font.GothamBold
    speedIncreaseButton.ZIndex = 8
    speedIncreaseButton.Parent = speedSection
    
    local speedIncreaseCorner = Instance.new("UICorner")
    speedIncreaseCorner.CornerRadius = UDim.new(0, 5)
    speedIncreaseCorner.Parent = speedIncreaseButton
    
    -- Jump Boost Section
    local jumpSection = Instance.new("Frame")
    jumpSection.Size = UDim2.new(1, 0, 0, 80)
    jumpSection.Position = UDim2.new(0, 0, 0, 100)
    jumpSection.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    jumpSection.BorderSizePixel = 0
    jumpSection.ZIndex = 7
    jumpSection.Parent = mainTab
    
    local jumpSectionCorner = Instance.new("UICorner")
    jumpSectionCorner.CornerRadius = UDim.new(0, 5)
    jumpSectionCorner.Parent = jumpSection
    
    local jumpLabel = Instance.new("TextLabel")
    jumpLabel.Size = UDim2.new(1, -20, 0, 25)
    jumpLabel.Position = UDim2.new(0, 10, 0, 5)
    jumpLabel.Text = "Jump Boost"
    jumpLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    jumpLabel.BackgroundTransparency = 1
    jumpLabel.TextSize = 16
    jumpLabel.Font = Enum.Font.Gotham
    jumpLabel.TextXAlignment = Enum.TextXAlignment.Left
    jumpLabel.ZIndex = 8
    jumpLabel.Parent = jumpSection
    
    local jumpToggle = Instance.new("TextButton")
    jumpToggle.Size = UDim2.new(0, 50, 0, 25)
    jumpToggle.Position = UDim2.new(1, -60, 0, 5)
    jumpToggle.Text = "OFF"
    jumpToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    jumpToggle.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    jumpToggle.BorderSizePixel = 0
    jumpToggle.TextSize = 12
    jumpToggle.Font = Enum.Font.GothamBold
    jumpToggle.ZIndex = 8
    jumpToggle.Parent = jumpSection
    
    local jumpToggleCorner = Instance.new("UICorner")
    jumpToggleCorner.CornerRadius = UDim.new(0, 5)
    jumpToggleCorner.Parent = jumpToggle
    
    local jumpValueLabel = Instance.new("TextLabel")
    jumpValueLabel.Size = UDim2.new(0, 40, 0, 25)
    jumpValueLabel.Position = UDim2.new(0.5, -20, 0, 45)
    jumpValueLabel.Text = tostring(currentJump)
    jumpValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    jumpValueLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    jumpValueLabel.BorderSizePixel = 0
    jumpValueLabel.TextSize = 14
    jumpValueLabel.Font = Enum.Font.GothamBold
    jumpValueLabel.ZIndex = 8
    jumpValueLabel.Parent = jumpSection
    
    local jumpValueCorner = Instance.new("UICorner")
    jumpValueCorner.CornerRadius = UDim.new(0, 5)
    jumpValueCorner.Parent = jumpValueLabel
    
    local jumpDecreaseButton = Instance.new("TextButton")
    jumpDecreaseButton.Size = UDim2.new(0, 30, 0, 25)
    jumpDecreaseButton.Position = UDim2.new(0.5, -60, 0, 45)
    jumpDecreaseButton.Text = "<"
    jumpDecreaseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    jumpDecreaseButton.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
    jumpDecreaseButton.BorderSizePixel = 0
    jumpDecreaseButton.TextSize = 14
    jumpDecreaseButton.Font = Enum.Font.GothamBold
    jumpDecreaseButton.ZIndex = 8
    jumpDecreaseButton.Parent = jumpSection
    
    local jumpDecreaseCorner = Instance.new("UICorner")
    jumpDecreaseCorner.CornerRadius = UDim.new(0, 5)
    jumpDecreaseCorner.Parent = jumpDecreaseButton
    
    local jumpIncreaseButton = Instance.new("TextButton")
    jumpIncreaseButton.Size = UDim2.new(0, 30, 0, 25)
    jumpIncreaseButton.Position = UDim2.new(0.5, 30, 0, 45)
    jumpIncreaseButton.Text = ">"
    jumpIncreaseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    jumpIncreaseButton.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
    jumpIncreaseButton.BorderSizePixel = 0
    jumpIncreaseButton.TextSize = 14
    jumpIncreaseButton.Font = Enum.Font.GothamBold
    jumpIncreaseButton.ZIndex = 8
    jumpIncreaseButton.Parent = jumpSection
    
    local jumpIncreaseCorner = Instance.new("UICorner")
    jumpIncreaseCorner.CornerRadius = UDim.new(0, 5)
    jumpIncreaseCorner.Parent = jumpIncreaseButton
    
    -- Infinity Jump Section
    local infinityJumpSection = Instance.new("Frame")
    infinityJumpSection.Size = UDim2.new(1, 0, 0, 40)
    infinityJumpSection.Position = UDim2.new(0, 0, 0, 190)
    infinityJumpSection.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    infinityJumpSection.BorderSizePixel = 0
    infinityJumpSection.ZIndex = 7
    infinityJumpSection.Parent = mainTab
    
    local infinityJumpSectionCorner = Instance.new("UICorner")
    infinityJumpSectionCorner.CornerRadius = UDim.new(0, 5)
    infinityJumpSectionCorner.Parent = infinityJumpSection
    
    local infinityJumpLabel = Instance.new("TextLabel")
    infinityJumpLabel.Size = UDim2.new(1, -70, 1, 0)
    infinityJumpLabel.Position = UDim2.new(0, 10, 0, 0)
    infinityJumpLabel.Text = "Infinity Jump (Fly Mode)"
    infinityJumpLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    infinityJumpLabel.BackgroundTransparency = 1
    infinityJumpLabel.TextSize = 16
    infinityJumpLabel.Font = Enum.Font.Gotham
    infinityJumpLabel.TextXAlignment = Enum.TextXAlignment.Left
    infinityJumpLabel.ZIndex = 8
    infinityJumpLabel.Parent = infinityJumpSection
    
    local infinityJumpToggle = Instance.new("TextButton")
    infinityJumpToggle.Size = UDim2.new(0, 50, 0, 25)
    infinityJumpToggle.Position = UDim2.new(1, -60, 0, 7)
    infinityJumpToggle.Text = "OFF"
    infinityJumpToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    infinityJumpToggle.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    infinityJumpToggle.BorderSizePixel = 0
    infinityJumpToggle.TextSize = 12
    infinityJumpToggle.Font = Enum.Font.GothamBold
    infinityJumpToggle.ZIndex = 8
    infinityJumpToggle.Parent = infinityJumpSection
    
    local infinityJumpToggleCorner = Instance.new("UICorner")
    infinityJumpToggleCorner.CornerRadius = UDim.new(0, 5)
    infinityJumpToggleCorner.Parent = infinityJumpToggle
    
    -- Anti Slow Section
    local antiSlowSection = Instance.new("Frame")
    antiSlowSection.Size = UDim2.new(1, 0, 0, 40)
    antiSlowSection.Position = UDim2.new(0, 0, 0, 240)
    antiSlowSection.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    antiSlowSection.BorderSizePixel = 0
    antiSlowSection.ZIndex = 7
    antiSlowSection.Parent = mainTab
    
    local antiSlowSectionCorner = Instance.new("UICorner")
    antiSlowSectionCorner.CornerRadius = UDim.new(0, 5)
    antiSlowSectionCorner.Parent = antiSlowSection
    
    local antiSlowLabel = Instance.new("TextLabel")
    antiSlowLabel.Size = UDim2.new(1, -70, 1, 0)
    antiSlowLabel.Position = UDim2.new(0, 10, 0, 0)
    antiSlowLabel.Text = "Anti Slow"
    antiSlowLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    antiSlowLabel.BackgroundTransparency = 1
    antiSlowLabel.TextSize = 16
    antiSlowLabel.Font = Enum.Font.Gotham
    antiSlowLabel.TextXAlignment = Enum.TextXAlignment.Left
    antiSlowLabel.ZIndex = 8
    antiSlowLabel.Parent = antiSlowSection
    
    local antiSlowToggle = Instance.new("TextButton")
    antiSlowToggle.Size = UDim2.new(0, 50, 0, 25)
    antiSlowToggle.Position = UDim2.new(1, -60, 0, 7)
    antiSlowToggle.Text = "OFF"
    antiSlowToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    antiSlowToggle.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    antiSlowToggle.BorderSizePixel = 0
    antiSlowToggle.TextSize = 12
    antiSlowToggle.Font = Enum.Font.GothamBold
    antiSlowToggle.ZIndex = 8
    antiSlowToggle.Parent = antiSlowSection
    
    local antiSlowToggleCorner = Instance.new("UICorner")
    antiSlowToggleCorner.CornerRadius = UDim.new(0, 5)
    antiSlowToggleCorner.Parent = antiSlowToggle
    
    -- Anti Low Jump Section
    local antiLowJumpSection = Instance.new("Frame")
    antiLowJumpSection.Size = UDim2.new(1, 0, 0, 40)
    antiLowJumpSection.Position = UDim2.new(0, 0, 0, 290)
    antiLowJumpSection.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    antiLowJumpSection.BorderSizePixel = 0
    antiLowJumpSection.ZIndex = 7
    antiLowJumpSection.Parent = mainTab
    
    local antiLowJumpSectionCorner = Instance.new("UICorner")
    antiLowJumpSectionCorner.CornerRadius = UDim.new(0, 5)
    antiLowJumpSectionCorner.Parent = antiLowJumpSection
    
    local antiLowJumpLabel = Instance.new("TextLabel")
    antiLowJumpLabel.Size = UDim2.new(1, -70, 1, 0)
    antiLowJumpLabel.Position = UDim2.new(0, 10, 0, 0)
    antiLowJumpLabel.Text = "Anti Low Jump"
    antiLowJumpLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    antiLowJumpLabel.BackgroundTransparency = 1
    antiLowJumpLabel.TextSize = 16
    antiLowJumpLabel.Font = Enum.Font.Gotham
    antiLowJumpLabel.TextXAlignment = Enum.TextXAlignment.Left
    antiLowJumpLabel.ZIndex = 8
    antiLowJumpLabel.Parent = antiLowJumpSection
    
    local antiLowJumpToggle = Instance.new("TextButton")
    antiLowJumpToggle.Size = UDim2.new(0, 50, 0, 25)
    antiLowJumpToggle.Position = UDim2.new(1, -60, 0, 7)
    antiLowJumpToggle.Text = "OFF"
    antiLowJumpToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    antiLowJumpToggle.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    antiLowJumpToggle.BorderSizePixel = 0
    antiLowJumpToggle.TextSize = 12
    antiLowJumpToggle.Font = Enum.Font.GothamBold
    antiLowJumpToggle.ZIndex = 8
    antiLowJumpToggle.Parent = antiLowJumpSection
    
    local antiLowJumpToggleCorner = Instance.new("UICorner")
    antiLowJumpToggleCorner.CornerRadius = UDim.new(0, 5)
    antiLowJumpToggleCorner.Parent = antiLowJumpToggle
    
    -- Teleport Section
    local teleportSection = Instance.new("Frame")
    teleportSection.Size = UDim2.new(1, 0, 0, 120)
    teleportSection.Position = UDim2.new(0, 0, 0, 340)
    teleportSection.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    teleportSection.BorderSizePixel = 0
    teleportSection.ZIndex = 7
    teleportSection.Parent = mainTab
    
    local teleportSectionCorner = Instance.new("UICorner")
    teleportSectionCorner.CornerRadius = UDim.new(0, 5)
    teleportSectionCorner.Parent = teleportSection
    
    local teleportLabel = Instance.new("TextLabel")
    teleportLabel.Size = UDim2.new(1, -20, 0, 25)
    teleportLabel.Position = UDim2.new(0, 10, 0, 5)
    teleportLabel.Text = "Teleport to Player"
    teleportLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    teleportLabel.BackgroundTransparency = 1
    teleportLabel.TextSize = 16
    teleportLabel.Font = Enum.Font.Gotham
    teleportLabel.TextXAlignment = Enum.TextXAlignment.Left
    teleportLabel.ZIndex = 8
    teleportLabel.Parent = teleportSection
    
    local playerDropdown = Instance.new("ScrollingFrame")
    playerDropdown.Size = UDim2.new(1, -20, 0, 60)
    playerDropdown.Position = UDim2.new(0, 10, 0, 35)
    playerDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    playerDropdown.BorderSizePixel = 0
    playerDropdown.ScrollBarThickness = 5
    playerDropdown.ZIndex = 8
    playerDropdown.Parent = teleportSection
    
    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = UDim.new(0, 5)
    dropdownCorner.Parent = playerDropdown
    
    local refreshButton = Instance.new("TextButton")
    refreshButton.Size = UDim2.new(0.45, 0, 0, 25)
    refreshButton.Position = UDim2.new(0, 10, 0, 100)
    refreshButton.Text = "Refresh"
    refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    refreshButton.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
    refreshButton.BorderSizePixel = 0
    refreshButton.TextSize = 14
    refreshButton.Font = Enum.Font.Gotham
    refreshButton.ZIndex = 8
    refreshButton.Parent = teleportSection
    
    local refreshButtonCorner = Instance.new("UICorner")
    refreshButtonCorner.CornerRadius = UDim.new(0, 5)
    refreshButtonCorner.Parent = refreshButton
    
    local teleportButton = Instance.new("TextButton")
    teleportButton.Size = UDim2.new(0.45, 0, 0, 25)
    teleportButton.Position = UDim2.new(0.55, 0, 0, 100)
    teleportButton.Text = "Teleport"
    teleportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    teleportButton.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
    teleportButton.BorderSizePixel = 0
    teleportButton.TextSize = 14
    teleportButton.Font = Enum.Font.Gotham
    teleportButton.ZIndex = 8
    teleportButton.Parent = teleportSection
    
    local teleportButtonCorner = Instance.new("UICorner")
    teleportButtonCorner.CornerRadius = UDim.new(0, 5)
    teleportButtonCorner.Parent = teleportButton
    
    -- Konten tab Information
    local infoTab = tabFrames["Information"]
    
    local discordButton = Instance.new("TextButton")
    discordButton.Size = UDim2.new(1, -20, 0, 40)
    discordButton.Position = UDim2.new(0, 10, 0, 20)
    discordButton.Text = "Join Discord"
    discordButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    discordButton.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    discordButton.BorderSizePixel = 0
    discordButton.TextSize = 16
    discordButton.Font = Enum.Font.GothamBold
    discordButton.ZIndex = 7
    discordButton.Parent = infoTab
    
    local discordButtonCorner = Instance.new("UICorner")
    discordButtonCorner.CornerRadius = UDim.new(0, 5)
    discordButtonCorner.Parent = discordButton
    
    local infoText = Instance.new("TextLabel")
    infoText.Size = UDim2.new(1, -20, 0, 200)
    infoText.Position = UDim2.new(0, 10, 0, 70)
    infoText.Text = "Lunar Script v1.0\n\nFeatures:\n- Speed Boost\n- Jump Boost\n- Infinity Jump (Fly Mode)\n- Anti Slow\n- Anti Low Jump\n- Player Teleport\n\nCreated with ❤️ for Roblox"
    infoText.TextColor3 = Color3.fromRGB(200, 200, 200)
    infoText.BackgroundTransparency = 1
    infoText.TextSize = 14
    infoText.Font = Enum.Font.Gotham
    infoText.TextXAlignment = Enum.TextXAlignment.Left
    infoText.ZIndex = 7
    infoText.Parent = infoTab
    
    -- Konten tab Settings
    local settingsTab = tabFrames["Settings"]
    
    local themeLabel = Instance.new("TextLabel")
    themeLabel.Size = UDim2.new(1, -20, 0, 25)
    themeLabel.Position = UDim2.new(0, 10, 0, 20)
    themeLabel.Text = "Background Theme"
    themeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    themeLabel.BackgroundTransparency = 1
    themeLabel.TextSize = 16
    themeLabel.Font = Enum.Font.Gotham
    themeLabel.TextXAlignment = Enum.TextXAlignment.Left
    themeLabel.ZIndex = 7
    themeLabel.Parent = settingsTab
    
    local themes = {"Space", "Ocean", "Dark"}
    local themeButtons = {}
    
    for i, theme in ipairs(themes) do
        local themeButton = Instance.new("TextButton")
        themeButton.Size = UDim2.new(1, -20, 0, 30)
        themeButton.Position = UDim2.new(0, 10, 0, 50 + (i-1)*40)
        themeButton.Text = theme
        themeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        themeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        themeButton.BorderSizePixel = 0
        themeButton.TextSize = 14
        themeButton.Font = Enum.Font.Gotham
        themeButton.ZIndex = 7
        themeButton.Parent = settingsTab
        
        local themeButtonCorner = Instance.new("UICorner")
        themeButtonCorner.CornerRadius = UDim.new(0, 5)
        themeButtonCorner.Parent = themeButton
        
        themeButtons[theme] = themeButton
        
        themeButton.MouseButton1Click:Connect(function()
            -- Ubah tema background
            if theme == "Space" then
                background.BackgroundColor3 = Color3.fromRGB(10, 10, 25)
            elseif theme == "Ocean" then
                background.BackgroundColor3 = Color3.fromRGB(10, 25, 40)
            elseif theme == "Dark" then
                background.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            end
            
            showNotification("Theme changed to " .. theme, 2)
        end)
    end
    
    local notificationLabel = Instance.new("TextLabel")
    notificationLabel.Size = UDim2.new(1, -20, 0, 25)
    notificationLabel.Position = UDim2.new(0, 10, 0, 180)
    notificationLabel.Text = "Notifications"
    notificationLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    notificationLabel.BackgroundTransparency = 1
    notificationLabel.TextSize = 16
    notificationLabel.Font = Enum.Font.Gotham
    notificationLabel.TextXAlignment = Enum.TextXAlignment.Left
    notificationLabel.ZIndex = 7
    notificationLabel.Parent = settingsTab
    
    local notificationToggle = Instance.new("TextButton")
    notificationToggle.Size = UDim2.new(0, 50, 0, 25)
    notificationToggle.Position = UDim2.new(1, -70, 0, 180)
    notificationToggle.Text = "ON"
    notificationToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    notificationToggle.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    notificationToggle.BorderSizePixel = 0
    notificationToggle.TextSize = 12
    notificationToggle.Font = Enum.Font.GothamBold
    notificationToggle.ZIndex = 7
    notificationToggle.Parent = settingsTab
    
    local notificationToggleCorner = Instance.new("UICorner")
    notificationToggleCorner.CornerRadius = UDim.new(0, 5)
    notificationToggleCorner.Parent = notificationToggle
    
    local saveButton = Instance.new("TextButton")
    saveButton.Size = UDim2.new(1, -20, 0, 35)
    saveButton.Position = UDim2.new(0, 10, 0, 220)
    saveButton.Text = "Save Configuration"
    saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    saveButton.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
    saveButton.BorderSizePixel = 0
    saveButton.TextSize = 16
    saveButton.Font = Enum.Font.GothamBold
    saveButton.ZIndex = 7
    saveButton.Parent = settingsTab
    
    local saveButtonCorner = Instance.new("UICorner")
    saveButtonCorner.CornerRadius = UDim.new(0, 5)
    saveButtonCorner.Parent = saveButton
    
    -- Fungsi untuk refresh daftar player
    local function refreshPlayerList()
        for _, child in ipairs(playerDropdown:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        local players = Players:GetPlayers()
        for i, plr in ipairs(players) do
            if plr ~= player then
                local playerButton = Instance.new("TextButton")
                playerButton.Size = UDim2.new(1, -10, 0, 20)
                playerButton.Position = UDim2.new(0, 5, 0, (i-1)*25)
                playerButton.Text = plr.Name
                playerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                playerButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
                playerButton.BorderSizePixel = 0
                playerButton.TextSize = 12
                playerButton.Font = Enum.Font.Gotham
                playerButton.ZIndex = 9
                playerButton.Parent = playerDropdown
                
                local playerButtonCorner = Instance.new("UICorner")
                playerButtonCorner.CornerRadius = UDim.new(0, 3)
                playerButtonCorner.Parent = playerButton
                
                playerButton.MouseButton1Click:Connect(function()
                    selectedPlayer = plr
                    showNotification("Selected: " .. plr.Name, 2)
                end)
            end
        end
    end
    
    -- Event handlers untuk tombol
    speedToggle.MouseButton1Click:Connect(function()
        speedBoostEnabled = not speedBoostEnabled
        if speedBoostEnabled then
            speedToggle.Text = "ON"
            speedToggle.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
            showNotification("Speed Boost enabled", 2)
        else
            speedToggle.Text = "OFF"
            speedToggle.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
            showNotification("Speed Boost disabled", 2)
        end
        updateSpeed()
    end)
    
    speedIncreaseButton.MouseButton1Click:Connect(function()
        currentSpeed = currentSpeed + 1
        speedValueLabel.Text = tostring(currentSpeed)
        updateSpeed()
        showNotification("Speed: " .. currentSpeed, 1)
    end)
    
    speedDecreaseButton.MouseButton1Click:Connect(function()
        if currentSpeed > 1 then
            currentSpeed = currentSpeed - 1
            speedValueLabel.Text = tostring(currentSpeed)
            updateSpeed()
            showNotification("Speed: " .. currentSpeed, 1)
        end
    end)
    
    jumpToggle.MouseButton1Click:Connect(function()
        jumpBoostEnabled = not jumpBoostEnabled
        if jumpBoostEnabled then
            jumpToggle.Text = "ON"
            jumpToggle.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
            showNotification("Jump Boost enabled", 2)
        else
            jumpToggle.Text = "OFF"
            jumpToggle.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
            showNotification("Jump Boost disabled", 2)
        end
        updateJump()
    end)
    
    jumpIncreaseButton.MouseButton1Click:Connect(function()
        currentJump = currentJump + 1
        jumpValueLabel.Text = tostring(currentJump)
        updateJump()
        showNotification("Jump: " .. currentJump, 1)
    end)
    
    jumpDecreaseButton.MouseButton1Click:Connect(function()
        if currentJump > 1 then
            currentJump = currentJump - 1
            jumpValueLabel.Text = tostring(currentJump)
            updateJump()
            showNotification("Jump: " .. currentJump, 1)
        end
    end)
    
    infinityJumpToggle.MouseButton1Click:Connect(function()
        infinityJumpEnabled = not infinityJumpEnabled
        if infinityJumpEnabled then
            infinityJumpToggle.Text = "ON"
            infinityJumpToggle.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
            showNotification("Infinity Jump enabled. Press SPACE to fly!", 3)
        else
            infinityJumpToggle.Text = "OFF"
            infinityJumpToggle.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
            showNotification("Infinity Jump disabled", 2)
        end
        toggleInfinityJump()
    end)
    
    antiSlowToggle.MouseButton1Click:Connect(function()
        antiSlowEnabled = not antiSlowEnabled
        if antiSlowEnabled then
            antiSlowToggle.Text = "ON"
            antiSlowToggle.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
            showNotification("Anti Slow enabled", 2)
        else
            antiSlowToggle.Text = "OFF"
            antiSlowToggle.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
            showNotification("Anti Slow disabled", 2)
        end
        toggleAntiSlow()
    end)
    
    antiLowJumpToggle.MouseButton1Click:Connect(function()
        antiLowJumpEnabled = not antiLowJumpEnabled
        if antiLowJumpEnabled then
            antiLowJumpToggle.Text = "ON"
            antiLowJumpToggle.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
            showNotification("Anti Low Jump enabled", 2)
        else
            antiLowJumpToggle.Text = "OFF"
            antiLowJumpToggle.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
            showNotification("Anti Low Jump disabled", 2)
        end
        toggleAntiLowJump()
    end)
    
    notificationToggle.MouseButton1Click:Connect(function()
        notificationsEnabled = not notificationsEnabled
        if notificationsEnabled then
            notificationToggle.Text = "ON"
            notificationToggle.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
            showNotification("Notifications enabled", 2)
        else
            notificationToggle.Text = "OFF"
            notificationToggle.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
            -- Tidak bisa menampilkan notifikasi karena dinonaktifkan
        end
    end)
    
    refreshButton.MouseButton1Click:Connect(function()
        refreshPlayerList()
        showNotification("Player list refreshed", 2)
    end)
    
    teleportButton.MouseButton1Click:Connect(function()
        if selectedPlayer then
            if selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    player.Character.HumanoidRootPart.CFrame = selectedPlayer.Character.HumanoidRootPart.CFrame
                    showNotification("Teleported to " .. selectedPlayer.Name, 2)
                else
                    showNotification("Your character not found", 2)
                end
            else
                showNotification("Player character not found", 2)
            end
        else
            showNotification("No player selected", 2)
        end
    end)
    
    discordButton.MouseButton1Click:Connect(function()
        showNotification("Discord link copied to clipboard", 2)
        -- Simulasi copy ke clipboard (tidak bisa di Roblox)
        setclipboard("https://discord.gg/wHxFkYnf")
    end)
    
    saveButton.MouseButton1Click:Connect(function()
        local config = {
            theme = background.BackgroundColor3,
            speed = currentSpeed,
            jump = currentJump,
            speedEnabled = speedBoostEnabled,
            jumpEnabled = jumpBoostEnabled,
            infinityJumpEnabled = infinityJumpEnabled,
            antiSlow = antiSlowEnabled,
            antiLowJump = antiLowJumpEnabled,
            notifications = notificationsEnabled
        }
        
        local success, error = pcall(function()
            configDataStore:SetAsync(player.UserId .. "_Config", config)
        end)
        
        if success then
            showNotification("Configuration saved", 2)
        else
            showNotification("Error saving config: " .. error, 3)
        end
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        -- Tampilkan konfirmasi close
        local confirmFrame = Instance.new("Frame")
        confirmFrame.Size = UDim2.new(0, 250, 0, 120)
        confirmFrame.Position = UDim2.new(0.5, -125, 0.5, -60)
        confirmFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        confirmFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        confirmFrame.BorderSizePixel = 0
        confirmFrame.ZIndex = 20
        confirmFrame.Parent = mainGui
        
        local confirmCorner = Instance.new("UICorner")
        confirmCorner.CornerRadius = UDim.new(0, 10)
        confirmCorner.Parent = confirmFrame
        
        local confirmStroke = Instance.new("UIStroke")
        confirmStroke.Color = Color3.fromRGB(100, 100, 100)
        confirmStroke.Thickness = 2
        confirmStroke.Parent = confirmFrame
        
        local confirmLabel = Instance.new("TextLabel")
        confirmLabel.Size = UDim2.new(1, 0, 0, 40)
        confirmLabel.Position = UDim2.new(0, 0, 0, 10)
        confirmLabel.Text = "Close Lunar Script?"
        confirmLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        confirmLabel.BackgroundTransparency = 1
        confirmLabel.TextSize = 18
        confirmLabel.Font = Enum.Font.GothamBold
        confirmLabel.ZIndex = 21
        confirmLabel.Parent = confirmFrame
        
        local yesButton = Instance.new("TextButton")
        yesButton.Size = UDim2.new(0, 80, 0, 30)
        yesButton.Position = UDim2.new(0, 30, 0, 70)
        yesButton.Text = "YES"
        yesButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        yesButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        yesButton.BorderSizePixel = 0
        yesButton.TextSize = 14
        yesButton.Font = Enum.Font.GothamBold
        yesButton.ZIndex = 21
        yesButton.Parent = confirmFrame
        
        local yesCorner = Instance.new("UICorner")
        yesCorner.CornerRadius = UDim.new(0, 5)
        yesCorner.Parent = yesButton
        
        local noButton = Instance.new("TextButton")
        noButton.Size = UDim2.new(0, 80, 0, 30)
        noButton.Position = UDim2.new(1, -110, 0, 70)
        noButton.Text = "NO"
        noButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        noButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        noButton.BorderSizePixel = 0
        noButton.TextSize = 14
        noButton.Font = Enum.Font.GothamBold
        noButton.ZIndex = 21
        noButton.Parent = confirmFrame
        
        local noCorner = Instance.new("UICorner")
        noCorner.CornerRadius = UDim.new(0, 5)
        noCorner.Parent = noButton
        
        yesButton.MouseButton1Click:Connect(function()
            -- Tutup semua GUI
            mainGui:Destroy()
            -- Hentikan semua koneksi
            if antiSlowConnection then
                antiSlowConnection:Disconnect()
            end
            if antiLowJumpConnection then
                antiLowJumpConnection:Disconnect()
            end
            if infinityJumpConnection then
                infinityJumpConnection:Disconnect()
            end
        end)
        
        noButton.MouseButton1Click:Connect(function()
            confirmFrame:Destroy()
        end)
    end)
    
    -- Load konfigurasi yang disimpan
    local success, savedConfig = pcall(function()
        return configDataStore:GetAsync(player.UserId .. "_Config")
    end)
    
    if success and savedConfig then
        background.BackgroundColor3 = savedConfig.theme or Color3.fromRGB(10, 10, 25)
        currentSpeed = savedConfig.speed or 16
        currentJump = savedConfig.jump or 50
        speedBoostEnabled = savedConfig.speedEnabled or false
        jumpBoostEnabled = savedConfig.jumpEnabled or false
        infinityJumpEnabled = savedConfig.infinityJumpEnabled or false
        antiSlowEnabled = savedConfig.antiSlow or false
        antiLowJumpEnabled = savedConfig.antiLowJump or false
        notificationsEnabled = savedConfig.notifications or true
        
        speedValueLabel.Text = tostring(currentSpeed)
        jumpValueLabel.Text = tostring(currentJump)
        
        if speedBoostEnabled then
            speedToggle.Text = "ON"
            speedToggle.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        end
        
        if jumpBoostEnabled then
            jumpToggle.Text = "ON"
            jumpToggle.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        end
        
        if infinityJumpEnabled then
            infinityJumpToggle.Text = "ON"
            infinityJumpToggle.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
            toggleInfinityJump()
        end
        
        if antiSlowEnabled then
            antiSlowToggle.Text = "ON"
            antiSlowToggle.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
            toggleAntiSlow()
        end
        
        if antiLowJumpEnabled then
            antiLowJumpToggle.Text = "ON"
            antiLowJumpToggle.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
            toggleAntiLowJump()
        end
        
        if not notificationsEnabled then
            notificationToggle.Text = "OFF"
            notificationToggle.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        end
    end
    
    -- Refresh daftar player pertama kali
    refreshPlayerList()
end

-- Fungsi untuk membuat toggle button di layar
local function createToggleButton()
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 100, 0, 30)
    toggleButton.Position = UDim2.new(0, 10, 0, 10)
    toggleButton.Text = "Lunar Script"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
    toggleButton.BorderSizePixel = 0
    toggleButton.TextSize = 14
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.ZIndex = 2
    toggleButton.Parent = mainGui
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 5)
    toggleCorner.Parent = toggleButton
    
    toggleButton.MouseButton1Click:Connect(function()
        isGuiVisible = not isGuiVisible
        if mainFrame then
            mainFrame.Visible = isGuiVisible
        end
        if loginFrame then
            loginFrame.Visible = isGuiVisible
        end
    end)
    
    -- Buat GUI dapat digeser
    local dragging = false
    local dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        if mainFrame then
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end

    toggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            if mainFrame then
                startPos = mainFrame.Position
            end
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    toggleButton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging and mainFrame then
            update(input)
        end
    end)
end

-- Fungsi utama untuk inisialisasi script
local function init()
    -- Buat main GUI container
    mainGui = Instance.new("ScreenGui")
    mainGui.Name = "LunarScript"
    mainGui.ResetOnSpawn = false
    mainGui.Parent = playerGui
    
    -- Cek apakah user sudah login
    local success, loginData = pcall(function()
        return configDataStore:GetAsync(player.UserId .. "_LoginData")
    end)
    
    if success and loginData then
        -- Cek apakah kunci masih valid (24 jam)
        local currentTime = os.time()
        local loginTime = loginData.loginTime
        local expirationTime = loginTime + (24 * 60 * 60) -- 24 jam
        
        if currentTime < expirationTime then
            -- Kunci masih valid, buat GUI utama
            createMainGUI()
        else
            -- Kunci kadaluarsa, tampilkan login
            createLoginGUI()
            showNotification("Login expired. Please login again.", 3)
        end
    else
        -- Belum login, tampilkan login GUI
        createLoginGUI()
    end
    
    -- Buat toggle button
    createToggleButton()
end

-- Jalankan inisialisasi
init()
