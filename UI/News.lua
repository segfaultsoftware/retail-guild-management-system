local _, RGMS = ...

local Runtime = assert(RGMS.UIRuntime, "UI/Widgets.lua must load first")

Runtime.Register("News", function()
function newsSetText(set)
    local lines = {}
    local function addMembers(members, formatter)
        for _, member in ipairs(members) do
            lines[#lines + 1] = formatter(member)
        end
    end
    addMembers(set.joiningMembers, function(member)
        return member .. " joined the guild."
    end)
    addMembers(set.leavingMembers, function(member)
        return member .. " left the guild."
    end)
    addMembers(set.rankChanges, function(change)
        return change.name .. "'s rank changed to " .. change.rankName .. "."
    end)
    return table.concat(lines, "\n"), #lines
end

function acquireNewsBlock(newsWindow, index)
    local block = newsWindow.blocks[index]
    if block then
        return block
    end
    block = CreateFrame("Frame", nil, newsWindow.content)
    block.panel = CreateFrame("Frame", nil, block, "BackdropTemplate")
    block.panel:SetPoint("TOPLEFT", block, "TOPLEFT", 0, 0)
    block.panel:SetPoint("TOPRIGHT", block, "TOPRIGHT", 0, 0)
    flatBackdrop(block.panel, PALETTE.control, PALETTE.border)
    block.check = CreateFrame("Button", nil, block.panel, "BackdropTemplate")
    block.check:SetSize(24, 24)
    block.check:SetPoint("TOPRIGHT", block.panel, "TOPRIGHT", -10, -10)
    block.check:SetBackdrop(nil)
    block.check.circleFill = block.check:CreateTexture(
        nil,
        "BACKGROUND",
        nil,
        -1
    )
    block.check.circleFill:SetAllPoints(block.check)
    block.check.circleFill:SetTexture(CIRCLE_TEXTURE)
    setTextureColor(block.check.circleFill, PALETTE.control)
    block.check.icon = block.check:CreateTexture(nil, "ARTWORK")
    block.check.icon:SetSize(16, 16)
    block.check.icon:SetPoint("CENTER", block.check, "CENTER", 0, 0)
    block.check.icon:SetTexture(CHECK_TEXTURE)
    if type(block.check.icon.SetDesaturated) == "function" then
        block.check.icon:SetDesaturated(true)
    end
    block.check.icon:SetVertexColor(1, 0.82, 0.2, 1)
    block.check:SetScript("OnEnter", function(button)
        showOwnedTooltip(button, "Dismiss", nil, {
            compact = true,
            anchorAtCursor = true,
        })
    end)
    block.check:SetScript("OnLeave", function(button)
        hideOwnedTooltip(button)
    end)

    block.text = block.panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    block.text:SetPoint("TOPLEFT", block.panel, "TOPLEFT", 12, -10)
    block.text:SetPoint("TOPRIGHT", block.panel, "TOPRIGHT", -48, -10)
    block.text:SetJustifyH("LEFT")
    block.text:SetJustifyV("TOP")
    setFont(block.text, FONT_REGULAR, 12)
    setTextColor(block.text, PALETTE.text)
    newsWindow.blocks[index] = block
    return block
end

function renderNewsSets(newsWindow, newsSets)
    newsSets = type(newsSets) == "table" and newsSets or {}
    newsWindow.newsSets = newsSets
    local y = 0
    for index, set in ipairs(newsSets) do
        local block = acquireNewsBlock(newsWindow, index)
        local text, lineCount = newsSetText(set)
        local height = math.max(44, lineCount * 15 + 20)
        block:ClearAllPoints()
        block:SetPoint("TOPLEFT", newsWindow.content, "TOPLEFT", 0, -y)
        block:SetPoint("TOPRIGHT", newsWindow.content, "TOPRIGHT", 0, -y)
        block:SetHeight(height)
        block.panel:SetHeight(height)
        block.text:SetText(text)
        block.setId = set.id
        block.check:SetScript("OnClick", function()
            if UI.globalScanLocked then
                return
            end
            local acknowledged, acknowledgeError = RGMS.Roster.AcknowledgeNewsSet(
                block.setId
            )
            if not acknowledged and type(RGMS.Print) == "function" then
                RGMS.Print("Could not acknowledge roster news: "
                    .. tostring(acknowledgeError) .. ".")
            end
        end)
        block:Show()
        y = y + height + 10
    end
    for index = #newsSets + 1, #newsWindow.blocks do
        newsWindow.blocks[index]:Hide()
    end
    local contentHeight = math.max(1, y > 0 and y - 10 or 1)
    newsWindow.content:SetHeight(contentHeight)
    setScrollBarShown(newsWindow.scrollFrame, contentHeight > 332)
    if contentHeight <= 332 then
        newsWindow.scrollFrame:SetVerticalScroll(0)
    end
end

function createNewsWindow(owner)
    local newsWindow = CreateFrame(
        "Frame",
        "RGMSNewsWindow",
        UIParent,
        "BackdropTemplate"
    )
    newsWindow:SetSize(400, 400)
    newsWindow:SetPoint("TOPLEFT", owner, "TOPRIGHT", 20, 0)
    newsWindow:SetFrameStrata("DIALOG")
    newsWindow:SetToplevel(true)
    newsWindow:EnableMouse(true)
    flatBackdrop(newsWindow, PALETTE.surface, PALETTE.border)
    local shadow = newsWindow:CreateTexture(nil, "BACKGROUND", nil, -8)
    shadow:SetTexture(WHITE_TEXTURE)
    shadow:SetPoint("TOPLEFT", newsWindow, "TOPLEFT", -6, 6)
    shadow:SetPoint("BOTTOMRIGHT", newsWindow, "BOTTOMRIGHT", 6, -6)
    shadow:SetVertexColor(0, 0, 0, 0.45)
    newsWindow.shadow = shadow

    newsWindow.title = newsWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    newsWindow.title:SetPoint("TOPLEFT", newsWindow, "TOPLEFT", 18, -17)
    newsWindow.title:SetText("News")
    setFont(newsWindow.title, FONT_SEMIBOLD, 13)
    setTextColor(newsWindow.title, PALETTE.text)

    newsWindow.closeButton = CreateFrame("Button", nil, newsWindow)
    newsWindow.closeButton:SetSize(32, 32)
    newsWindow.closeButton:SetPoint("TOPRIGHT", newsWindow, "TOPRIGHT", -8, -8)
    newsWindow.closeButton.icon = newsWindow.closeButton:CreateTexture(nil, "ARTWORK")
    newsWindow.closeButton.icon:SetAllPoints(newsWindow.closeButton)
    newsWindow.closeButton.icon:SetTexture(CLOSE_TEXTURE)
    newsWindow.closeButton:SetScript("OnClick", function()
        UI.CloseNews()
    end)

    newsWindow.scrollFrame = CreateFrame(
        "ScrollFrame",
        nil,
        newsWindow,
        "UIPanelScrollFrameTemplate"
    )
    newsWindow.scrollFrame:SetSize(394, 332)
    newsWindow.scrollFrame:SetPoint("TOPLEFT", newsWindow, "TOPLEFT", 3, -52)
    styleScrollFrame(newsWindow.scrollFrame)
    newsWindow.content = CreateFrame("Frame", nil, newsWindow.scrollFrame)
    newsWindow.content:SetSize(394, 1)
    newsWindow.scrollFrame:SetScrollChild(newsWindow.content)
    newsWindow.blocks = {}

    newsWindow.dimmer = CreateFrame("Frame", nil, newsWindow, "BackdropTemplate")
    newsWindow.dimmer:SetAllPoints(newsWindow)
    newsWindow.dimmer:SetFrameLevel(newsWindow:GetFrameLevel() + 100)
    newsWindow.dimmer:SetBackdrop({ bgFile = WHITE_TEXTURE })
    newsWindow.dimmer:SetBackdropColor(0, 0, 0, GLOBAL_DIMMER_ALPHA)
    newsWindow.dimmer:EnableMouse(true)
    newsWindow.dimmer.label = newsWindow.dimmer:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlight"
    )
    newsWindow.dimmer.label:SetPoint("CENTER", newsWindow.dimmer, "CENTER", 0, 0)
    newsWindow.dimmer.label:SetText("Scanning...")
    setFont(newsWindow.dimmer.label, FONT_SEMIBOLD, 16)
    setTextColor(newsWindow.dimmer.label, PALETTE.text)
    newsWindow.dimmer:Hide()
    newsWindow:Hide()
    return newsWindow
end


function UI.SetNewsSets(newsSets)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    renderNewsSets(UI.frame.newsWindow, newsSets)
    return true
end

function UI.OpenNews()
    if not UI.frame then
        local initialized, initializeError = UI.Initialize()
        if not initialized then
            return nil, initializeError
        end
    end
    if UI.frame.notesEditor:IsShown() then
        UI.CloseCharacterNoteEditor()
    end
    UI.SetNewsSets(type(RGMS.DB) == "table" and RGMS.DB.newsSets or {})
    UI.frame.newsWindow:ClearAllPoints()
    UI.frame.newsWindow:SetPoint("TOPLEFT", UI.frame, "TOPRIGHT", 20, 0)
    UI.frame.newsWindow:Show()
    return true
end

function UI.CloseNews()
    if not UI.frame then
        return true
    end
    UI.frame.newsWindow:Hide()
    return true
end


end, {
    "SetNewsSets",
    "OpenNews",
    "CloseNews",
})

