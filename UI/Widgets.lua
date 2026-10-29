local _, RGMS = ...

local Runtime = {
    Registrations = {},
}
RGMS.UIRuntime = Runtime

function Runtime.Register(name, installer, exports)
    assert(type(name) == "string" and name ~= "", "UI module name is required")
    assert(type(installer) == "function", "UI module installer is required")
    assert(Runtime.RegistrationNames == nil or Runtime.RegistrationNames[name] == nil,
        "duplicate UI module registration: " .. name)
    Runtime.RegistrationNames = Runtime.RegistrationNames or {}
    Runtime.RegistrationNames[name] = true
    Runtime.Registrations[#Runtime.Registrations + 1] = {
        name = name,
        installer = installer,
        exports = exports or {},
    }
end

local function delegate(implementation)
    return function(...)
        return implementation(...)
    end
end

function Runtime.Build()
    local scope = setmetatable({ RGMS = RGMS }, { __index = _G })
    local components = {}
    local facadeExports = {}

    for _, registration in ipairs(Runtime.Registrations) do
        setfenv(registration.installer, scope)
        registration.installer()
        local module = {}
        for _, name in ipairs(registration.exports) do
            local implementation = scope.UI and scope.UI[name]
            assert(type(implementation) == "function",
                registration.name .. " did not define UI." .. name)
            module[name] = implementation
            facadeExports[name] = implementation
        end
        components[registration.name] = module
    end

    local facade = assert(scope.UI, "UI facade was not initialized")
    local delegates = {}
    for name, implementation in pairs(facadeExports) do
        if delegates[implementation] == nil then
            delegates[implementation] = delegate(implementation)
        end
        facade[name] = delegates[implementation]
    end
    RGMS.UIComponents = components
    RGMS.UI = facade
    Runtime.Scope = scope
    return facade
end

Runtime.Register("Widgets", function()
UI = RGMS.UI or {}
createFrame = CreateFrame
windowDragRoot = nil
startWindowDrag = nil
stopWindowDrag = nil
setEditBoxEnabled = nil


TAB_ORDER = { "roster", "bank", "provisions", "tags" }
ALL_VIEW_IDS = { "roster", "mainsalts", "bank", "provisions", "tags" }
TAB_TITLES = {
    roster = "Roster",
    bank = "Guild Bank",
    provisions = "Provisions",
    tags = "Tags",
}

INITIAL_COPY = {
    roster = "No roster data yet",
    mainsalts = "No roster data yet",
    bank = "No bank scan yet",
    provisions = "No provisions yet",
    tags = "No tags yet",
}


CONTROL_GAP = 8

DROPDOWN_RADIO_SIZE = 16
DROPDOWN_RADIO_INNER_SIZE = 12
DROPDOWN_RADIO_DOT_SIZE = 8
DROPDOWN_RADIO_LEFT = 10
DROPDOWN_RADIO_LABEL_GAP = 8

MISSING_WARNING_GAP = 4
MISSING_WARNING_TEXTURE = "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew"
WHITE_TEXTURE = "Interface\\Buttons\\WHITE8X8"
CIRCLE_TEXTURE = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
BORDER_TEXTURE = "Interface\\Tooltips\\UI-Tooltip-Border"
LOGO_TEXTURE = "Interface\\AddOns\\RGMS\\assets\\rgms-logo.png"
CLOSE_TEXTURE = "Interface\\AddOns\\RGMS\\assets\\icons\\x.png"
CHEVRON_TEXTURE = "Interface\\AddOns\\RGMS\\assets\\icons\\chevron-right.png"
REFRESH_TEXTURE = "Interface\\AddOns\\RGMS\\assets\\icons\\refresh-cw.png"
LOADER_TEXTURE = "Interface\\AddOns\\RGMS\\assets\\icons\\loader-circle.png"
CHECK_TEXTURE = "Interface\\AddOns\\RGMS\\assets\\icons\\check.png"
TAG_DELETE_ATLAS = "common-icon-delete"
TAG_DELETE_DIALOG_KEY = "RGMS_CONFIRM_TAG_DELETE"
FONT_REGULAR = "Interface\\AddOns\\RGMS\\assets\\fonts\\Inter-Regular.ttf"
FONT_SEMIBOLD = "Interface\\AddOns\\RGMS\\assets\\fonts\\Inter-SemiBold.ttf"
PALETTE = type(RGMS.Portal) == "table" and RGMS.Portal.PALETTE or {
    shell = { 0.059, 0.067, 0.082, 1 }, surface = { 0.094, 0.106, 0.129, 1 },
    control = { 0.133, 0.149, 0.18, 1 }, border = { 0.204, 0.227, 0.275, 1 },
    zebra = { 0.114, 0.125, 0.153, 1 }, filterMatch = { 0.231, 0.137, 0.192, 1 },
    pink = { 0.925, 0.282, 0.6, 1 }, pinkHover = { 0.957, 0.447, 0.714, 1 }, text = { 0.957, 0.957, 0.961, 1 },
    secondary = { 0.631, 0.631, 0.667, 1 }, disabled = { 0.443, 0.443, 0.478, 1 },
    error = { 0.973, 0.443, 0.443, 1 },
}

function unpackColor(color)
    return color[1], color[2], color[3], color[4]
end

function setFont(region, path, size)
    if region and type(region.SetFont) == "function" then
        region:SetFont(path, size, "")
    end
end

MENU_FONT = nil
if type(CreateFont) == "function" then
    MENU_FONT = CreateFont("RGMSMenuFont")
    setFont(MENU_FONT, FONT_SEMIBOLD, 12)
end

function setTextColor(region, color)
    if region and type(region.SetTextColor) == "function" then
        region:SetTextColor(unpackColor(color))
    end
end

function setCharacterNameColor(region, classFileName)
    local color = type(RAID_CLASS_COLORS) == "table"
        and RAID_CLASS_COLORS[classFileName]
        or nil
    if type(color) == "table"
        and type(color.r) == "number"
        and type(color.g) == "number"
        and type(color.b) == "number" then
        region:SetTextColor(color.r, color.g, color.b, 1)
        return
    end
    setTextColor(region, PALETTE.text)
end

function flatBackdrop(frame, color, borderColor)
    if type(frame.SetBackdrop) ~= "function" then
        return
    end
    frame:SetBackdrop({
        bgFile = WHITE_TEXTURE,
        edgeFile = BORDER_TEXTURE,
        tile = false,
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    frame:SetBackdropColor(unpackColor(color))
    if type(frame.SetBackdropBorderColor) == "function" then
        frame:SetBackdropBorderColor(unpackColor(borderColor or PALETTE.border))
    end
end


function setTextureColor(texture, color)
    if texture and type(texture.SetVertexColor) == "function" then
        texture:SetVertexColor(unpackColor(color))
    end
end

function styleTagCapsule(control, background, borderColor)
    if not control then
        return
    end
    if type(control.SetBackdrop) == "function" then
        control:SetBackdrop(nil)
    end
    if not control.tagCapsule then
        local capsule = {}
        for _, layer in ipairs({ "border", "fill" }) do
            local sublevel = layer == "border" and -2 or -1
            capsule[layer] = {
                left = control:CreateTexture(nil, "BACKGROUND", nil, sublevel),
                center = control:CreateTexture(nil, "BACKGROUND", nil, sublevel),
                right = control:CreateTexture(nil, "BACKGROUND", nil, sublevel),
            }
            capsule[layer].left:SetTexture(
                CIRCLE_TEXTURE,
                "CLAMP",
                "CLAMP"
            )
            capsule[layer].left:SetTexCoord(0, 0.5, 0, 1)
            capsule[layer].center:SetTexture(WHITE_TEXTURE)
            capsule[layer].right:SetTexture(
                CIRCLE_TEXTURE,
                "CLAMP",
                "CLAMP"
            )
            capsule[layer].right:SetTexCoord(0.5, 1, 0, 1)
        end
        control.tagCapsule = capsule
    end

    local capsule = control.tagCapsule
    local height = math.max(2, control:GetHeight() or TAG_PILL_HEIGHT)
    local radius = height / 2
    local inset = 1
    local innerHeight = math.max(1, height - inset * 2)
    local innerRadius = innerHeight / 2

    capsule.border.left:ClearAllPoints()
    capsule.border.left:SetSize(radius, height)
    capsule.border.left:SetPoint("LEFT", control, "LEFT", 0, 0)
    capsule.border.center:ClearAllPoints()
    capsule.border.center:SetPoint("TOPLEFT", control, "TOPLEFT", radius, 0)
    capsule.border.center:SetPoint("BOTTOMRIGHT", control, "BOTTOMRIGHT", -radius, 0)
    capsule.border.right:ClearAllPoints()
    capsule.border.right:SetSize(radius, height)
    capsule.border.right:SetPoint("RIGHT", control, "RIGHT", 0, 0)

    capsule.fill.left:ClearAllPoints()
    capsule.fill.left:SetSize(innerRadius, innerHeight)
    capsule.fill.left:SetPoint("LEFT", control, "LEFT", inset, 0)
    capsule.fill.center:ClearAllPoints()
    capsule.fill.center:SetPoint("TOPLEFT", control, "TOPLEFT", radius, -inset)
    capsule.fill.center:SetPoint(
        "BOTTOMRIGHT",
        control,
        "BOTTOMRIGHT",
        -radius,
        inset
    )
    capsule.fill.right:ClearAllPoints()
    capsule.fill.right:SetSize(innerRadius, innerHeight)
    capsule.fill.right:SetPoint("RIGHT", control, "RIGHT", -inset, 0)

    for _, texture in pairs(capsule.border) do
        setTextureColor(texture, borderColor or PALETTE.border)
    end
    for _, texture in pairs(capsule.fill) do
        setTextureColor(texture, background or PALETTE.control)
    end
end

function styleButton(button, kind, height)
    if not button then
        return
    end
    button:SetHeight(height or 32)
    local background = kind == "primary" and PALETTE.pink or PALETTE.control
    flatBackdrop(button, background, kind == "danger" and PALETTE.error or PALETTE.border)
    if type(button.GetFontString) == "function" then
        local label = button:GetFontString()
        setFont(label, FONT_SEMIBOLD, 12)
        setTextColor(label, kind == "danger" and PALETTE.error or PALETTE.text)
    end
    button:SetScript("OnEnter", function(self)
        if self:IsEnabled() and type(self.SetBackdropColor) == "function" then
            self:SetBackdropColor(unpackColor(kind == "primary" and PALETTE.pinkHover or PALETTE.border))
        end
    end)
    button:SetScript("OnLeave", function(self)
        if type(self.SetBackdropColor) == "function" then
            self:SetBackdropColor(unpackColor(background))
        end
    end)
    button:SetScript("OnMouseDown", function(self)
        if self:IsEnabled() and type(self.SetBackdropColor) == "function" then
            local pressed = kind == "primary" and PALETTE.pinkHover or PALETTE.shell
            self:SetBackdropColor(unpackColor(pressed))
        end
    end)
    button:SetScript("OnMouseUp", function(self)
        if type(self.SetBackdropColor) == "function" then
            self:SetBackdropColor(unpackColor(background))
        end
    end)
end

function setRefreshButtonEnabled(button, enabled)
    enabled = enabled == true
    button:SetEnabled(enabled)
    setTextureColor(button.icon, enabled and PALETTE.text or PALETTE.disabled)
end

function styleScrollFrame(scrollFrame)
    local scrollBar = scrollFrame and (scrollFrame.ScrollBar or scrollFrame.scrollBar)
    if not scrollBar then
        return
    end
    if type(scrollBar.SetWidth) == "function" then
        scrollBar:SetWidth(8)
    end
    for _, button in ipairs({
        scrollBar.ScrollUpButton,
        scrollBar.ScrollDownButton,
        scrollBar.Back,
        scrollBar.Forward,
    }) do
        if button and type(button.Hide) == "function" then
            button:Hide()
        end
    end
    local thumb = scrollBar.ThumbTexture
        or (type(scrollBar.GetThumbTexture) == "function" and scrollBar:GetThumbTexture())
    if thumb then
        thumb:SetTexture(WHITE_TEXTURE)
        thumb:SetVertexColor(unpackColor(PALETTE.border))
    end
end

function setScrollBarShown(scrollFrame, shown)
    local scrollBar = scrollFrame and (scrollFrame.ScrollBar or scrollFrame.scrollBar)
    if scrollBar and type(scrollBar.SetShown) == "function" then
        scrollBar:SetShown(shown == true)
    end
end

showOwnedTooltip = nil
hideOwnedTooltip = nil
closeMainsAltsTagEditor = nil
closeMainsAltsTagFilter = nil
refreshMainsAltsTagEditor = nil
refreshMainsAltsTagFilter = nil
updateMainsAltsTagFilterAppearance = nil
updateRosterModeControls = nil

function attachTruncationTooltip(parent, textRegion)
    local hitbox = CreateFrame("Button", nil, parent)
    hitbox:SetAllPoints(textRegion)
    hitbox:SetScript("OnEnter", function(button)
        if type(textRegion.IsTruncated) == "function" and textRegion:IsTruncated() then
            showOwnedTooltip(button, "Full value", textRegion:GetText())
        end
    end)
    hitbox:SetScript("OnLeave", function(button)
        hideOwnedTooltip(button)
    end)
    return hitbox
end

function enableRowHover(line)
    line.frame:EnableMouse(true)
    line.frame:SetScript("OnEnter", function()
        line.background:SetVertexColor(unpackColor(PALETTE.control))
    end)
    line.frame:SetScript("OnLeave", function()
        line.background:SetVertexColor(unpackColor(line.baseColor or PALETTE.surface))
    end)
end


function refreshScrollChild(view)
    local availableWidth = math.max(1, view.scrollFrame:GetWidth() - 8)
    view.scrollChild:SetWidth(availableWidth)
    view.text:SetWidth(availableWidth)
    layoutRosterLines(view, availableWidth)
    layoutBankLines(view, availableWidth)
    layoutMainsAltsLines(view, availableWidth)
    layoutTagManagementLines(view, availableWidth)

    local viewportHeight = math.max(1, view.scrollFrame:GetHeight())
    local contentHeight = view.rosterTableHeight
        or view.bankTableHeight
        or view.mainsAltsTableHeight
        or view.tagTableHeight
        or (view.text:GetStringHeight() + 16)
    setScrollBarShown(view.scrollFrame, contentHeight > viewportHeight)
    view.scrollChild:SetHeight(math.max(viewportHeight, contentHeight))
end


function updateDropdownLabel(dropdown, option, emptyLabel, forceTextRefresh)
    if not dropdown then
        return
    end
    dropdown.selectedOption = option
    dropdown.label:ClearAllPoints()
    dropdown.label:SetPoint("LEFT", dropdown, "LEFT", option and option.icon and 34 or 12, 0)
    dropdown.label:SetPoint("RIGHT", dropdown, "RIGHT", -28, 0)
    local label = option and (option.label or option.name) or emptyLabel
    if forceTextRefresh then
        dropdown.label:SetText("")
    end
    dropdown.label:SetText(label)
    dropdown:SetEnabled(option ~= nil and UI.globalScanLocked ~= true)
    if dropdown.icon then
        dropdown.icon:SetShown(option ~= nil and option.icon ~= nil)
        if option and option.icon then
            dropdown.icon:SetTexture(option.icon)
        end
    end
end

function styleDropdownRadio(button)
    local ring = button.leftTexture1
    if ring then
        ring:ClearAllPoints()
        ring:SetPoint("LEFT", button, "LEFT", DROPDOWN_RADIO_LEFT, 0)
        ring:SetSize(DROPDOWN_RADIO_SIZE, DROPDOWN_RADIO_SIZE)
        ring:SetTexture(CIRCLE_TEXTURE)
        ring:SetDrawLayer("ARTWORK", 0)
        ring:SetVertexColor(unpackColor(PALETTE.border))

        local interior = button:AttachTexture()
        interior:SetPoint("CENTER", ring, "CENTER", 0, 0)
        interior:SetSize(DROPDOWN_RADIO_INNER_SIZE, DROPDOWN_RADIO_INNER_SIZE)
        interior:SetTexture(CIRCLE_TEXTURE)
        interior:SetDrawLayer("ARTWORK", 1)
        interior:SetVertexColor(unpackColor(PALETTE.shell))
        button.rgmsRadioInterior = interior
    end

    local dot = button.leftTexture2
    if dot and ring then
        dot:ClearAllPoints()
        dot:SetPoint("CENTER", ring, "CENTER", 0, 0)
        dot:SetSize(DROPDOWN_RADIO_DOT_SIZE, DROPDOWN_RADIO_DOT_SIZE)
        dot:SetTexture(CIRCLE_TEXTURE)
        dot:SetDrawLayer("ARTWORK", 2)
        dot:SetVertexColor(unpackColor(PALETTE.pink))
    end

    if button.fontString and ring then
        button.fontString:ClearAllPoints()
        button.fontString:SetPoint(
            "LEFT",
            ring,
            "RIGHT",
            DROPDOWN_RADIO_LABEL_GAP,
            0
        )
    end
end

function createDropdown(parent, width, emptyLabel, selected, options)
    local frameType = type(MenuUtil) == "table" and "DropdownButton" or "Button"
    local dropdown = CreateFrame(frameType, nil, parent, "BackdropTemplate")
    dropdown:SetSize(width, 32)
    flatBackdrop(dropdown, PALETTE.control, PALETTE.border)
    dropdown.label = dropdown:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    dropdown.label:SetPoint("LEFT", dropdown, "LEFT", 12, 0)
    dropdown.label:SetPoint("RIGHT", dropdown, "RIGHT", -28, 0)
    dropdown.label:SetJustifyH("LEFT")
    setFont(dropdown.label, FONT_SEMIBOLD, 12)
    setTextColor(dropdown.label, PALETTE.text)
    dropdown.icon = dropdown:CreateTexture(nil, "ARTWORK")
    dropdown.icon:SetSize(18, 18)
    dropdown.icon:SetPoint("LEFT", dropdown, "LEFT", 8, 0)
    dropdown.arrow = dropdown:CreateTexture(nil, "ARTWORK")
    dropdown.arrow:SetSize(16, 16)
    dropdown.arrow:SetPoint("RIGHT", dropdown, "RIGHT", -8, 0)
    dropdown.arrow:SetTexture("Interface\\AddOns\\RGMS\\assets\\icons\\chevron-down.png")
    dropdown.emptyLabel = emptyLabel
    dropdown.options = options
    dropdown.selectOption = selected
    dropdown:SetScript("OnClick", function()
        if type(dropdown.OpenMenu) == "function" then
            dropdown:OpenMenu()
        end
    end)
    if type(dropdown.SetupMenu) == "function" then
        dropdown:SetupMenu(function(_, rootDescription)
            rootDescription:SetScrollMode(240)
            rootDescription:SetMinimumWidth(200)
            for _, option in ipairs(dropdown.options() or {}) do
                local menuOption = option
                local description = rootDescription:CreateRadio(
                    menuOption.label or menuOption.name,
                    function(value)
                        return dropdown.selectedOption
                            and dropdown.selectedOption.index == value
                    end,
                    function(value)
                        dropdown.selectOption(value)
                    end,
                    menuOption.index
                )
                description:AddInitializer(function(button)
                    button:SetHeight(32)
                    styleDropdownRadio(button)
                    if button.fontString and MENU_FONT
                        and type(button.fontString.SetFontObject) == "function" then
                        button.fontString:SetFontObject(MENU_FONT)
                    end
                    if menuOption.icon and type(button.AttachTexture) == "function" then
                        local icon = button:AttachTexture()
                        icon:SetSize(18, 18)
                        icon:SetPoint("RIGHT", button, "RIGHT", -8, 0)
                        icon:SetTexture(menuOption.icon)
                    end
                end)
            end
        end)
    end
    updateDropdownLabel(dropdown, nil, emptyLabel)
    return dropdown
end


function createByRankControl(view, checked, relativeTo, point, relativePoint, x, y)
    local control = CreateFrame("CheckButton", nil, view, "BackdropTemplate")
    control:SetSize(BY_RANK_CONTROL_WIDTH, 32)
    control:SetPoint(point, relativeTo, relativePoint, x, y)

    control.box = CreateFrame("Frame", nil, control, "BackdropTemplate")
    control.box:SetSize(BY_RANK_CHECKBOX_SIZE, BY_RANK_CHECKBOX_SIZE)
    control.box:SetPoint("LEFT", control, "LEFT", 0, 0)
    flatBackdrop(control.box, PALETTE.control, PALETTE.border)
    control.check = control.box:CreateTexture(nil, "ARTWORK")
    control.check:SetAllPoints(control.box)
    control.check:SetTexture(CHECK_TEXTURE)
    control.check:SetShown(checked == true)

    control.label = control:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    control.label:SetPoint("LEFT", control.box, "RIGHT", 6, 0)
    control.label:SetJustifyH("LEFT")
    control.label:SetText("By rank")
    setFont(control.label, FONT_SEMIBOLD, 12)
    setTextColor(control.label, PALETTE.text)
    control:SetChecked(checked == true)
    control:SetScript("OnClick", function(button)
        local selected, reason = UI.SelectRosterMode(
            button:GetChecked() and "ByTenure" or "ByName"
        )
        if not selected then
            button:SetChecked(activeRosterMode() == "ByTenure")
            button.check:SetShown(button:GetChecked())
            if reason and reason ~= "modal-open" and type(RGMS.Print) == "function" then
                RGMS.Print("Could not change the Roster presentation: " .. tostring(reason) .. ".")
            end
        end
    end)
    view.byRankCheckbox = control
    return control
end


setEditBoxEnabled = function(editBox, enabled)
    if type(editBox.SetEnabled) == "function" then
        editBox:SetEnabled(enabled)
    elseif enabled and type(editBox.Enable) == "function" then
        editBox:Enable()
    elseif not enabled and type(editBox.Disable) == "function" then
        editBox:Disable()
    end
end


function createRefreshButton(view, parent, enabled, body, onClick)
    local button = CreateFrame("Button", nil, view)
    button:SetSize(32, 32)
    button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -56, -12)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(18, 18)
    button.icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.icon:SetTexture(REFRESH_TEXTURE)
    setRefreshButtonEnabled(button, enabled)
    button:SetScript("OnEnter", function(control)
        if control:IsEnabled() then
            setTextureColor(control.icon, PALETTE.pinkHover)
        end
        showOwnedTooltip(control, "Refresh", body)
    end)
    button:SetScript("OnLeave", function(control)
        setTextureColor(
            control.icon,
            control:IsEnabled() and PALETTE.text or PALETTE.disabled
        )
        hideOwnedTooltip(control)
    end)
    button:SetScript("OnMouseDown", function(control)
        if control:IsEnabled() then
            setTextureColor(control.icon, PALETTE.pink)
        end
    end)
    button:SetScript("OnMouseUp", function(control)
        if control:IsEnabled() then
            setTextureColor(control.icon, PALETTE.pinkHover)
        end
    end)
    button:SetScript("OnClick", onClick)
    view.refreshButton = button
    return button
end

end, {})


