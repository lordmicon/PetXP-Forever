-- =========================
-- PetXP - WoW Forever (interface 16001)
-- Hunter pet XP bar with a settings window.
-- Ported from the Turtle WoW / 1.12 version.
-- =========================

-- Size settings
local barWidth  = 18
local barHeight = 300
local horWidth  = 300
local horHeight = 18

-- Default positions (point, relativePoint, x, y), used until the player drags the bar.
local DEFAULT_POS = {
    horizontal = { "CENTER", "CENTER", 0, -200 },
    vertical   = { "CENTER", "CENTER", 0, 0 },
}

local verticalMode = false
local isHunter = false
local elapsedTime = 0
local lastXP = -1
local previewMode = false -- set by the settings window's Preview button

local function Msg(s)
    print("|cff00ff00PetXP:|r " .. s)
end

-- =========================
-- Main Frame
-- =========================
local PetXP = CreateFrame("Frame", "PetXP", UIParent)
PetXP:Hide() -- stays hidden until we know the player is a Hunter with a pet

local function SavePosition()
    local point, _, relPoint, x, y = PetXP:GetPoint(1)
    if not point then return end
    if type(PetXP_Position) ~= "table" then PetXP_Position = {} end
    PetXP_Position[verticalMode and "vertical" or "horizontal"] = { point, relPoint, x, y }
end

PetXP:SetMovable(true)
PetXP:EnableMouse(true)
PetXP:RegisterForDrag("LeftButton")
PetXP:SetScript("OnDragStart", function(self) self:StartMoving() end)
PetXP:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SavePosition()
end)

-- Background
local bg = PetXP:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(PetXP)
bg:SetColorTexture(0, 0, 0, 0.6)

-- Status Bar
local bar = CreateFrame("StatusBar", nil, PetXP)
bar:SetAllPoints(PetXP)
bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
bar:SetMinMaxValues(0, 1)
bar:SetValue(0)

-- Border (SetBackdrop needs BackdropTemplate in the modern client)
local border = CreateFrame("Frame", nil, PetXP, "BackdropTemplate")
border:SetPoint("TOPLEFT", -1, 1)
border:SetPoint("BOTTOMRIGHT", 1, -1)
border:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12
})

-- Text
local text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
text:SetTextColor(1, 1, 1)

-- =========================
-- Layout Function
-- =========================
local function ApplyLayout()
    local key = verticalMode and "vertical" or "horizontal"
    local pos = (type(PetXP_Position) == "table" and PetXP_Position[key]) or DEFAULT_POS[key]

    PetXP:ClearAllPoints()
    PetXP:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])

    if verticalMode then
        PetXP:SetWidth(barWidth)
        PetXP:SetHeight(barHeight)
        bar:SetOrientation("VERTICAL")
        text:ClearAllPoints()
        text:SetPoint("BOTTOM", PetXP, "TOP", 0, 4)
        text:SetJustifyH("CENTER")
    else
        PetXP:SetWidth(horWidth)
        PetXP:SetHeight(horHeight)
        bar:SetOrientation("HORIZONTAL")
        text:ClearAllPoints()
        text:SetPoint("CENTER", bar, "CENTER", 0, 0)
    end
end

ApplyLayout()

-- =========================
-- Bar Color Logic
-- =========================
local function SetBarColorByPercent(pct)
    if pct < 0.33 then
        bar:SetStatusBarColor(1, 0, 0)
    elseif pct < 0.66 then
        bar:SetStatusBarColor(1, 0.5, 0)
    elseif pct < 1 then
        bar:SetStatusBarColor(1, 1, 0)
    else
        bar:SetStatusBarColor(0, 1, 0)
    end
end

local function DesaturateBar()
    bar:SetStatusBarColor(0.5, 0.5, 0.5)
end

-- =========================
-- Update Function
-- =========================
local function SetXPText(pct, petLevel, playerLevel, currXP, maxXP)
    if not PetXP_ShowText then
        text:Hide()
        return
    end
    if verticalMode then
        text:SetText(math.floor(pct * 100) .. "%\n(" .. petLevel .. "/" .. playerLevel .. ")")
    else
        text:SetText(
            "Level: " .. petLevel .. " of " .. playerLevel ..
            " | " .. currXP .. " / " .. maxXP ..
            " XP (" .. math.floor(pct * 100) .. "%)"
        )
    end
    text:Show()
end

local function UpdatePetXP()
    -- Preview: show sample data so the settings can be tried without a pet out.
    if previewMode then
        bar:SetMinMaxValues(0, 2500)
        bar:SetValue(1250)
        SetBarColorByPercent(0.5)
        SetXPText(0.5, 30, 40, 1250, 2500)
        PetXP:Show()
        return
    end

    if not UnitExists("pet") then
        PetXP:Hide()
        return
    end

    local petLevel = UnitLevel("pet") or 0
    local playerLevel = UnitLevel("player") or 0
    local petIsDead = UnitIsDead("pet") or UnitIsGhost("pet")

    if petIsDead then
        DesaturateBar()
        if PetXP_ShowText then
            text:SetText(verticalMode and "Dead" or "Pet Dead")
            text:Show()
        else
            text:Hide()
        end
        PetXP:Show()
        return
    end

    if petLevel >= playerLevel then
        if PetXP_HideAtMax then
            PetXP:Hide()
            return
        end

        bar:SetMinMaxValues(0, 1)
        bar:SetValue(1)
        SetBarColorByPercent(1)

        if PetXP_ShowText then
            text:SetText(verticalMode and "Max" or ("Max Pet Level (" .. petLevel .. ")"))
            text:Show()
        else
            text:Hide()
        end

        PetXP:Show()
        return
    end

    if not GetPetExperience then
        PetXP:Hide()
        return
    end

    local currXP, maxXP = GetPetExperience()
    if not currXP or not maxXP or maxXP == 0 then
        PetXP:Hide()
        return
    end

    local pct = currXP / maxXP
    lastXP = currXP

    bar:SetMinMaxValues(0, maxXP)
    bar:SetValue(currXP)
    SetBarColorByPercent(pct)
    SetXPText(pct, petLevel, playerLevel, currXP, maxXP)

    PetXP:Show()
end

-- =========================
-- Settings actions (shared by the window and the slash commands)
-- =========================
local optionsFrame      -- the pop-up settings window
local RefreshOptions    -- defined below; syncs checkboxes with saved settings

local function SetVertical(value)
    verticalMode = value and true or false
    PetXP_VerticalMode = verticalMode
    ApplyLayout()
    UpdatePetXP()
    if RefreshOptions then RefreshOptions() end
end

local function SetShowText(value)
    PetXP_ShowText = value and true or false
    UpdatePetXP()
    if RefreshOptions then RefreshOptions() end
end

local function SetHideAtMax(value)
    PetXP_HideAtMax = value and true or false
    UpdatePetXP()
    if RefreshOptions then RefreshOptions() end
end

local function ResetPosition()
    if type(PetXP_Position) == "table" then
        PetXP_Position[verticalMode and "vertical" or "horizontal"] = nil
    end
    ApplyLayout()
end

-- =========================
-- Settings window
-- Built on the game's own frame template (marble background, gold border,
-- title bar and bottom button bar) so it matches the game's Options window.
-- =========================
local refreshers = {}
local BuildSettings

local function ToggleOptions()
    if not optionsFrame then
        BuildSettings()
    end
    if optionsFrame:IsShown() then
        optionsFrame:Hide()
    else
        optionsFrame:Show()
    end
end

function RefreshOptions()
    if not optionsFrame or not optionsFrame:IsShown() then return end
    for _, fn in ipairs(refreshers) do fn() end
end

-- Try several templates; use the first one this client knows about.
local function TryCreate(frameType, name, parent, templates)
    for _, tpl in ipairs(templates) do
        local ok, obj = pcall(CreateFrame, frameType, name, parent, tpl)
        if ok and obj then return obj, tpl end
    end
    return CreateFrame(frameType, name, parent)
end

-- Text label. y is negative (distance down from the top of the parent).
local function WLabel(parent, fontObject, str, x, y, width)
    local fs = parent:CreateFontString(nil, "OVERLAY", fontObject)
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetJustifyH("LEFT")
    if width then fs:SetWidth(width) end
    fs:SetText(str)
    return fs
end

local function WHeader(parent, str, x, y)
    return WLabel(parent, "GameFontHighlightLarge", str, x, y)
end

local function TextHeight(fs)
    local h = fs.GetStringHeight and fs:GetStringHeight()
    if type(h) ~= "number" or h <= 0 then h = 12 end
    return h
end

local DESC_WIDTH = 270

-- Radio buttons that all edit one setting. Row height follows the real height
-- of the description text, so wrapped descriptions never collide with the
-- next row. items = { { value, label, description }, ... }; returns next y.
local function WRadioGroup(parent, x, y, items, getFn, setFn)
    local entries = {}
    for _, item in ipairs(items) do
        local value, label, desc = item[1], item[2], item[3]
        local b = TryCreate("CheckButton", nil, parent, { "UIRadioButtonTemplate", "UICheckButtonTemplate" })
        b:SetSize(22, 22)
        b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
        b:SetHitRectInsets(0, -230, 0, 0) -- clicking the label works too
        WLabel(parent, "GameFontNormal", label, x + 26, y - 4)
        local rowH = 26
        if desc then
            local d = WLabel(parent, "GameFontDisableSmall", desc, x + 26, y - 20, DESC_WIDTH)
            rowH = math.max(30, 20 + TextHeight(d) + 8)
        end
        b:SetScript("OnClick", function()
            setFn(value)
            RefreshOptions()
        end)
        entries[#entries + 1] = { button = b, value = value }
        y = y - rowH
    end
    refreshers[#refreshers + 1] = function()
        local cur = getFn()
        for _, e in ipairs(entries) do e.button:SetChecked(cur == e.value) end
    end
    return y
end

-- A checkbox with a label and an explanation underneath; returns next y.
local function WCheck(parent, x, y, label, desc, getFn, setFn)
    local c = TryCreate("CheckButton", nil, parent, { "UICheckButtonTemplate" })
    c:SetSize(26, 26)
    c:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    c:SetHitRectInsets(0, -230, 0, 0)
    WLabel(parent, "GameFontNormal", label, x + 30, y - 6)
    local rowH = 32
    if desc then
        local d = WLabel(parent, "GameFontDisableSmall", desc, x + 30, y - 24, DESC_WIDTH - 4)
        rowH = math.max(34, 24 + TextHeight(d) + 10)
    end
    c:SetScript("OnClick", function(self)
        setFn(self:GetChecked() and true or false)
        RefreshOptions()
    end)
    refreshers[#refreshers + 1] = function() c:SetChecked(getFn() and true or false) end
    return y - rowH
end

local function WButton(parent, label, width, point, x, y, onClick)
    local b = TryCreate("Button", nil, parent, { "UIPanelButtonTemplate" })
    b:SetSize(width, 22)
    b:SetText(label)
    b:SetPoint(point, parent, point, x, y)
    b:SetScript("OnClick", onClick)
    return b
end

-- A small colored square followed by a line of text.
local function WSwatch(parent, x, y, r, g, b, str)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetSize(14, 14)
    t:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    t:SetColorTexture(r, g, b, 1)
    WLabel(parent, "GameFontHighlight", str, x + 22, y - 1)
end

function BuildSettings()
    -- Same frame the game's own Options window uses, with fallbacks for older clients.
    local win, tpl = TryCreate("Frame", "PetXPOptionsFrame", UIParent,
        { "ButtonFrameTemplateNoPortrait", "ButtonFrameTemplate", "BasicFrameTemplateWithInset", "BackdropTemplate" })
    optionsFrame = win
    win:SetSize(680, 420)
    win:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    win:SetFrameStrata("DIALOG")
    win:SetMovable(true)
    win:SetClampedToScreen(true)
    win:EnableMouse(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", function(self) self:StartMoving() end)
    win:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    local isButtonFrame = (tpl == "ButtonFrameTemplateNoPortrait" or tpl == "ButtonFrameTemplate")
    if tpl == "ButtonFrameTemplate" then
        pcall(function()
            if ButtonFrameTemplate_HidePortrait then ButtonFrameTemplate_HidePortrait(win) end
        end)
    end
    if isButtonFrame and win.Inset then
        win.Inset:ClearAllPoints()
        win.Inset:SetPoint("TOPLEFT", win, "TOPLEFT", 4, -26)
        win.Inset:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -6, 28)
    end
    if not isButtonFrame and tpl ~= "BasicFrameTemplateWithInset" then
        -- plain fallback look
        if win.SetBackdrop then
            win:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = true, tileSize = 32, edgeSize = 32,
                insets = { left = 8, right = 8, top = 8, bottom = 8 },
            })
        end
        local closeBtn = TryCreate("Button", nil, win, { "UIPanelCloseButton" })
        closeBtn:SetPoint("TOPRIGHT", win, "TOPRIGHT", -4, -4)
    end

    if isButtonFrame and win.SetTitle then
        win:SetTitle("PetXP Settings")
    else
        local title = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", win, "TOP", 0, -6)
        title:SetText("PetXP Settings")
    end

    table.insert(UISpecialFrames, "PetXPOptionsFrame") -- Escape closes it

    -- ===== LEFT COLUMN: layout =====
    local lx, y = 20, -38
    WHeader(win, "Bar layout", lx, y); y = y - 28
    y = WRadioGroup(win, lx, y, {
        { false, "Horizontal bar", "A wide bar with full details: pet level, XP numbers and percentage." },
        { true,  "Vertical bar",   "A tall, narrow bar with short text (percentage and levels). Good beside a frame or screen edge." },
    }, function() return verticalMode end, SetVertical)

    y = y - 10
    WHeader(win, "Moving the bar", lx, y); y = y - 28
    WLabel(win, "GameFontHighlightSmall",
        "Drag the bar itself with the left mouse button. Its position is saved separately for each layout. "
        .. "Use Reset position (below) to put it back in the default spot.",
        lx + 4, y, 300)

    -- ===== RIGHT COLUMN: options + colors =====
    local rx, ry = 350, -38
    WHeader(win, "Display options", rx, ry); ry = ry - 28
    ry = WCheck(win, rx - 2, ry, "Show text on the bar",
        "Turn this off if you only want the colored bar with no writing on it.",
        function() return PetXP_ShowText end, SetShowText)
    ry = WCheck(win, rx - 2, ry, "Hide bar at max pet level",
        "A pet cannot level past you. When your pet reaches your level there is no more XP to track, so this hides the bar until you level up or summon a lower-level pet.",
        function() return PetXP_HideAtMax end, SetHideAtMax)

    ry = ry - 8
    WHeader(win, "Bar colors", rx, ry); ry = ry - 28
    WSwatch(win, rx + 4, ry,       1, 0,   0,   "Under 33% to the next level"); ry = ry - 22
    WSwatch(win, rx + 4, ry,       1, 0.5, 0,   "33% to 66%");                  ry = ry - 22
    WSwatch(win, rx + 4, ry,       1, 1,   0,   "66% to 99%");                  ry = ry - 22
    WSwatch(win, rx + 4, ry,       0, 1,   0,   "Pet is at max level");         ry = ry - 22
    WSwatch(win, rx + 4, ry,       0.5, 0.5, 0.5, "Pet is dead")

    -- ===== BOTTOM =====
    WLabel(win, "GameFontDisableSmall",
        "Tip: the bar only shows while your pet is out. Use Preview bar to see your changes without one. "
        .. "Type /petxp in chat any time to open this window.",
        20, -362, 640)

    -- these sit in the frame's bottom bar, like the Close button in the game's Options window
    local previewBtn
    previewBtn = WButton(win, "Preview bar", 110, "BOTTOMLEFT", 12, 4, function()
        previewMode = not previewMode
        previewBtn:SetText(previewMode and "Stop preview" or "Preview bar")
        UpdatePetXP()
    end)
    WButton(win, "Reset position", 120, "BOTTOMLEFT", 128, 4, function()
        ResetPosition()
        Msg("Bar position reset for the current layout.")
    end)
    WButton(win, "Close", 90, "BOTTOMRIGHT", -10, 4, function() win:Hide() end)

    win:SetScript("OnShow", function() RefreshOptions() end)
    win:SetScript("OnHide", function()
        if previewMode then
            previewMode = false
            previewBtn:SetText("Preview bar")
            UpdatePetXP()
        end
    end)
    win:Hide()
end

-- =========================
-- Options > AddOns page
-- =========================
local function RegisterOptionsPanel()
    local panel = CreateFrame("Frame")
    panel.name = "PetXP"

    local version = ""
    pcall(function()
        local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
        version = getMeta and getMeta("PetXP", "Version") or ""
    end)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
    title:SetText("PetXP " .. version)

    local function paragraph(str, y)
        local fs = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        fs:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)
        fs:SetWidth(560)
        fs:SetJustifyH("LEFT")
        fs:SetText(str)
        return fs
    end

    paragraph("Shows your Hunter pet's experience as a movable bar on your screen. "
        .. "The bar appears while you have a pet out and shows how close it is to its next level.", -52)

    local open = TryCreate("Button", nil, panel, { "UIPanelButtonTemplate" })
    open:SetSize(160, 26)
    open:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -110)
    open:SetText("Open settings")
    open:SetScript("OnClick", function()
        -- Close the game's options window first so ours isn't hidden behind it
        pcall(function()
            if SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
        end)
        if not optionsFrame or not optionsFrame:IsShown() then
            ToggleOptions()
        end
    end)

    local good = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    good:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -156)
    good:SetText("How to use")
    paragraph("Drag the bar with the left mouse button to move it. In the settings window you can "
        .. "choose a horizontal or vertical bar, show or hide the text, and hide the bar once your "
        .. "pet reaches your level.", -180)
    paragraph("Type /petxp to open the settings window at any time, or /petxp help for the "
        .. "list of commands.", -250)

    pcall(function()
        if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
            local category = Settings.RegisterCanvasLayoutCategory(panel, "PetXP")
            Settings.RegisterAddOnCategory(category)
        elseif InterfaceOptions_AddCategory then
            InterfaceOptions_AddCategory(panel)
        end
    end)
end

-- =========================
-- Events
-- =========================
PetXP:RegisterEvent("ADDON_LOADED")

PetXP:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= "PetXP" then return end
        self:UnregisterEvent("ADDON_LOADED")

        -- SavedVariables are only available now, not when the file first runs.
        if PetXP_HideAtMax == nil then PetXP_HideAtMax = false end
        if PetXP_VerticalMode == nil then PetXP_VerticalMode = false end -- default horizontal
        if PetXP_ShowText == nil then PetXP_ShowText = true end
        if type(PetXP_Position) ~= "table" then PetXP_Position = {} end
        verticalMode = PetXP_VerticalMode

        local _, playerClass = UnitClass("player")
        isHunter = (playerClass == "HUNTER")
        if not isHunter then return end

        ApplyLayout()

        -- A broken options page must never stop the bar itself from working.
        pcall(RegisterOptionsPanel)

        -- RegisterEvent errors on unknown names in the modern client, so guard each one.
        for _, e in ipairs({
            "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "UNIT_PET", "UNIT_PET_EXPERIENCE",
            "PET_UI_UPDATE", "UNIT_LEVEL", "PLAYER_LEVEL_UP",
            "UNIT_HEALTH", "PLAYER_ALIVE", "PLAYER_UNGHOST",
        }) do
            pcall(self.RegisterEvent, self, e)
        end

        UpdatePetXP()
        return
    end

    if not isHunter then return end

    if event == "PLAYER_LOGIN" then
        Msg("loaded. Type |cffffff00/petxp|r to open the settings window, "
            .. "or find PetXP under Options > AddOns.")
        self:UnregisterEvent("PLAYER_LOGIN")
        return
    end

    -- Only react to the player's pet / the player for unit events.
    if (event == "UNIT_PET" or event == "UNIT_LEVEL" or event == "UNIT_HEALTH"
        or event == "UNIT_PET_EXPERIENCE") and arg1 and arg1 ~= "player" and arg1 ~= "pet" then
        return
    end

    UpdatePetXP()
end)

-- =========================
-- Polling Fallback
-- =========================
PetXP:SetScript("OnUpdate", function(self, elapsed)
    if not isHunter or not GetPetExperience then return end
    if not UnitExists("pet") then return end

    elapsedTime = elapsedTime + elapsed
    if elapsedTime < 0.5 then return end
    elapsedTime = 0

    local currXP = GetPetExperience()
    if currXP and currXP ~= lastXP then
        UpdatePetXP()
    end
end)

-- =========================
-- Help
-- =========================
local function PetXP_ShowHelp()
    print("|cff00ff00PetXP Commands:|r")
    print("/petxp  - Open the settings window")
    print("/petxp toggle  - Switch between vertical and horizontal layout")
    print("/petxp hideatmax on|off  - Hide the bar when your pet is at max level")
    print("/petxp showtext on|off  - Show or hide the text on the bar")
    print("/petxp reset  - Reset the bar position for the current layout")
    print("/petxp help  - Show this help")
end

-- =========================
-- Slash Commands
-- =========================
SLASH_PETXP1 = "/petxp"
SlashCmdList["PETXP"] = function(msg)
    if type(msg) ~= "string" then msg = "" end
    msg = string.lower(msg)
    msg = msg:gsub("^%s+", ""):gsub("%s+$", "")

    if not isHunter then
        Msg("PetXP only works for Hunters.")
        return
    end

    if msg == "" or msg == "options" or msg == "config" or msg == "settings" then
        ToggleOptions()

    elseif msg == "toggle" then
        SetVertical(not verticalMode)
        Msg("Layout toggled")

    elseif msg == "hideatmax on" then
        SetHideAtMax(true)
        Msg("Hide at max ENABLED")

    elseif msg == "hideatmax off" then
        SetHideAtMax(false)
        Msg("Hide at max DISABLED")

    elseif msg == "showtext on" then
        SetShowText(true)
        Msg("Text ENABLED")

    elseif msg == "showtext off" then
        SetShowText(false)
        Msg("Text DISABLED")

    elseif msg == "reset" then
        ResetPosition()
        Msg("Bar position reset for the current layout.")

    else
        PetXP_ShowHelp()
    end
end
