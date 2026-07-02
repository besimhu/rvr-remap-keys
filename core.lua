local NUM_ACTION_BUTTONS = NUM_ACTIONBAR_BUTTONS or 12

local exactMap = {
    ["CTRL-NUM PAD 8"] = "G8",
    ["CTRL-NUM PAD 7"] = "G7",
    ["C-NUM PAD 8"] = "G8",
    ["C-NUM PAD 7"] = "G7",
    ["MIDDLE MOUSE"] = "M3",
    ["NUM PAD +"] = "N+",
    ["NUMPAD +"] = "N+",
    ["NUMPADPLUS"] = "N+",
    ["NUM PAD PLUS"] = "N+",
    ["NUM PAD -"] = "N-",
    ["NUMPAD -"] = "N-",
    ["NUMPADMINUS"] = "N-",
    ["NUM PAD MINUS"] = "N-",
    ["NUM PAD ."] = "N.",
    ["NUMPAD ."] = "N.",
    ["NUMPADDECIMAL"] = "N.",
    ["NUM PAD DECIMAL"] = "N.",
    ["NUM PAD /"] = "N/",
    ["NUMPAD /"] = "N/",
    ["NUMPADDIVIDE"] = "N/",
    ["NUM PAD DIVIDE"] = "N/",
    ["NUM PAD *"] = "N*",
    ["NUMPAD *"] = "N*",
    ["NUMPADMULTIPLY"] = "N*",
    ["NUM PAD MULTIPLY"] = "N*",
}

local staticReplacements = {
    { "MOUSE WHEEL DOWN", "MWD" },
    { "MOUSE WHEEL UP", "MWU" },
    { "MOUSE WHEEL", "MW" },
    { "MOUSE BUTTON", "M" },
    { "MOUSEBUTTON", "M" },
    { "MOUSE", "M" },
    { "BUTTON", "M" },
    { "NUM PAD ", "N" },
    { "NUMPAD", "N" },
    { "PAGEUP", "PU" },
    { "PAGE DOWN", "PD" },
    { "PAGEDOWN", "PD" },
    { "PAGE UP", "PU" },
    { "SPACEBAR", "SP" },
    { "BACKSPACE", "BS" },
    { "DELETE", "DEL" },
    { "INSERT", "INS" },
    { "HOME", "HM" },
    { "ARROW", "" },
    { "CAPSLOCK", "CAPS" },
}

local function EscapePattern(text)
    if type(text) ~= "string" or text == "" then return "" end
    return text:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
end

local function GetGlobalUpper(globalName, fallback)
    local value = _G[globalName]
    if type(value) ~= "string" or value == "" then value = fallback end
    if type(value) ~= "string" or value == "" then return nil end
    return value:upper()
end

local mouseButtonPatterns
local function GetMouseButtonPatterns()
    if mouseButtonPatterns then return mouseButtonPatterns end

    mouseButtonPatterns = {}
    for i = 1, 31 do
        local label = GetGlobalUpper("KEY_BUTTON" .. i)
        if label then
            table.insert(mouseButtonPatterns, { EscapePattern(label), "M" .. i })
        end
    end

    local wheelDown = GetGlobalUpper("KEY_MOUSEWHEELDOWN")
    if wheelDown then table.insert(mouseButtonPatterns, { EscapePattern(wheelDown), "MWD" }) end

    local wheelUp = GetGlobalUpper("KEY_MOUSEWHEELUP")
    if wheelUp then table.insert(mouseButtonPatterns, { EscapePattern(wheelUp), "MWU" }) end

    return mouseButtonPatterns
end

local modifierPatterns
local function GetModifierPatterns()
    if modifierPatterns then return modifierPatterns end

    modifierPatterns = {}

    local function add(globalName, short, fallback)
        local label = GetGlobalUpper(globalName, fallback)
        if label then table.insert(modifierPatterns, { EscapePattern(label) .. "%-", short }) end
    end

    add("SHIFT_KEY_TEXT", "S", "SHIFT")
    add("CTRL_KEY_TEXT", "C", "CTRL")
    add("ALT_KEY_TEXT", "A", "ALT")

    return modifierPatterns
end

local keyPatterns
local function GetKeyPatterns()
    if keyPatterns then return keyPatterns end

    keyPatterns = {}

    local function add(globalName, short, fallback)
        local label = GetGlobalUpper(globalName, fallback)
        if label then table.insert(keyPatterns, { EscapePattern(label), short }) end
    end

    add("KEY_SPACE", "SP", "SPACEBAR")
    add("KEY_BACKSPACE", "BS", "BACKSPACE")

    return keyPatterns
end

local function ShortenHotkeyText(text)
    if type(text) ~= "string" or text == "" then return text end
    if RANGE_INDICATOR and text == RANGE_INDICATOR then return text end

    local short = text:upper()
    if exactMap[short] then return exactMap[short] end

    local isMinusKeybind = short:sub(-1) == "-" or short:match("MINUS$") ~= nil

    for _, replacement in ipairs(GetMouseButtonPatterns()) do
        short = short:gsub(replacement[1], replacement[2])
    end

    for _, replacement in ipairs(GetModifierPatterns()) do
        short = short:gsub(replacement[1], replacement[2])
    end

    for _, replacement in ipairs(GetKeyPatterns()) do
        short = short:gsub(replacement[1], replacement[2])
    end

    for _, replacement in ipairs(staticReplacements) do
        short = short:gsub(replacement[1], replacement[2])
    end

    short = short:gsub("CTRL%-", "C")
    short = short:gsub("CONTROL%-", "C")
    short = short:gsub("ALT%-", "A")
    short = short:gsub("SHIFT%-", "S")
    short = short:gsub("OPTION%-", "O")
    short = short:gsub("COMMAND%-", "CM")
    short = short:gsub("PLUS", "+")
    short = short:gsub("MINUS", "-")
    short = short:gsub("DECIMAL", ".")
    short = short:gsub("MULTIPLY", "*")
    short = short:gsub("DIVIDE", "/")
    short = short:gsub("[%s%-]", "")

    if isMinusKeybind then short = short .. "-" end

    return short
end

local function GetHotkeyRegion(button)
    if not button then return nil end
    return button.HotKey or button.hotkey
end

local function InstallHotkeyTextHook(hotkey)
    if not hotkey or hotkey.BRK_SetTextHooked then return end
    if not hotkey.SetText then return end

    hotkey.BRK_SetTextHooked = true
    hooksecurefunc(hotkey, "SetText", function(self, text)
        if self.BRK_SettingText then return end
        if type(text) ~= "string" or text == "" then return end
        if RANGE_INDICATOR and text == RANGE_INDICATOR then return end

        local shortText = ShortenHotkeyText(text)
        if shortText and shortText ~= text and shortText ~= self:GetText() then
            self.BRK_SettingText = true
            self:SetText(shortText)
            self.BRK_SettingText = nil
            self.BRK_ShortApplied = true
            self.BRK_OriginalText = text
            self.BRK_ShortValue = shortText
        end
    end)
end

local function UpdateHotkey(button)
    local hotkey = GetHotkeyRegion(button)
    if not hotkey or not hotkey.GetText or not hotkey.SetText then return end

    InstallHotkeyTextHook(hotkey)

    local currentText = hotkey:GetText()
    if type(currentText) ~= "string" or currentText == "" then return end

    if hotkey.BRK_ShortApplied and currentText ~= hotkey.BRK_ShortValue then
        hotkey.BRK_ShortApplied = nil
        hotkey.BRK_OriginalText = nil
        hotkey.BRK_ShortValue = nil
    end

    if not hotkey.BRK_ShortApplied then
        hotkey.BRK_OriginalText = currentText
    end

    local shortText = ShortenHotkeyText(hotkey.BRK_OriginalText or currentText)
    if shortText and shortText ~= currentText then
        hotkey.BRK_SettingText = true
        hotkey:SetText(shortText)
        hotkey.BRK_SettingText = nil
        hotkey.BRK_ShortApplied = true
        hotkey.BRK_ShortValue = shortText
    end
end

local buttonGroups = {
    { "ActionButton", NUM_ACTION_BUTTONS },
    { "MultiBarBottomLeftButton", NUM_ACTION_BUTTONS },
    { "MultiBarBottomRightButton", NUM_ACTION_BUTTONS },
    { "MultiBarLeftButton", NUM_ACTION_BUTTONS },
    { "MultiBarRightButton", NUM_ACTION_BUTTONS },
    { "MultiBar5Button", NUM_ACTION_BUTTONS },
    { "MultiBar6Button", NUM_ACTION_BUTTONS },
    { "MultiBar7Button", NUM_ACTION_BUTTONS },
    { "PetActionButton", NUM_PET_ACTION_SLOTS or 10 },
    { "StanceButton", NUM_STANCE_SLOTS or NUM_SHAPESHIFT_SLOTS or 10 },
    { "PossessButton", NUM_POSSESS_SLOTS or 2 },
    { "OverrideActionBarButton", NUM_ACTION_BUTTONS },
    { "EABButton", 180 },
}

local function ForEachKnownButton(callback)
    local seen = {}

    for _, group in ipairs(buttonGroups) do
        local prefix, count = group[1], group[2]
        for i = 1, count do
            local button = _G[prefix .. i]
            if button and not seen[button] then
                seen[button] = true
                callback(button)
            end
        end
    end

    if ExtraActionButton1 and not seen[ExtraActionButton1] then
        callback(ExtraActionButton1)
    end
end

local function RefreshAllHotkeys()
    ForEachKnownButton(UpdateHotkey)
end

local refreshPending
local function RequestHotkeyRefresh()
    if refreshPending then return end
    refreshPending = true

    local function refresh()
        refreshPending = nil
        RefreshAllHotkeys()
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(0, refresh)
        C_Timer.After(0.05, RefreshAllHotkeys)
        C_Timer.After(0.25, RefreshAllHotkeys)
    else
        refresh()
    end
end

local eabUpdateKeybindsHooked
local function InstallEllesmereHook()
    if eabUpdateKeybindsHooked then return end
    if type(_G._EAB_UpdateKeybinds) ~= "function" then return end

    hooksecurefunc("_EAB_UpdateKeybinds", RequestHotkeyRefresh)
    eabUpdateKeybindsHooked = true
end

local function InstallHotkeyHook()
    local hooked = false

    if ActionBarActionButtonMixin and type(ActionBarActionButtonMixin.UpdateHotkeys) == "function" then
        hooksecurefunc(ActionBarActionButtonMixin, "UpdateHotkeys", UpdateHotkey)
        hooked = true
    end

    if PetActionButtonMixin and type(PetActionButtonMixin.UpdateHotkeys) == "function" then
        hooksecurefunc(PetActionButtonMixin, "UpdateHotkeys", UpdateHotkey)
        hooked = true
    end

    if not hooked then
        ForEachKnownButton(function(button)
            if button.UpdateHotkeys then hooksecurefunc(button, "UpdateHotkeys", UpdateHotkey) end
        end)
    end

    InstallEllesmereHook()
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
frame:RegisterEvent("UPDATE_BINDINGS")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        InstallHotkeyHook()
    elseif event == "ADDON_LOADED" then
        InstallEllesmereHook()
    end

    RequestHotkeyRefresh()
end)
