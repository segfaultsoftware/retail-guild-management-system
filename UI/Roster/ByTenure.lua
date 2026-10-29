local _, RGMS = ...

local Runtime = assert(RGMS.UIRuntime, "UI/Widgets.lua must load first")

Runtime.Register("RosterByTenure", function()
RANK_TAB_WIDTH = 0
RANK_TAB_HEIGHT = 24
RANK_TAB_GAP = 3
ROSTER_CONTENT_GAP = 24

ROSTER_TITLE_HEIGHT = 0

ROSTER_GROUP_HEIGHT = 24
ROSTER_ROW_HEIGHT = 24
ROSTER_GROUP_GAP = 0

function layoutRosterLines(view, availableWidth)
    if type(view.rosterLines) ~= "table" then
        return
    end

    local nameWidth = math.floor(availableWidth * 0.5)
    local lastOnlineWidth = math.floor(availableWidth * 0.3)
    local tenureWidth = availableWidth - nameWidth - lastOnlineWidth

    local lines = {}
    if view.rosterHeader then
        lines[#lines + 1] = view.rosterHeader
    end
    for _, line in ipairs(view.rosterLines) do
        lines[#lines + 1] = line
    end
    for _, line in ipairs(lines) do
        line.frame:SetWidth(availableWidth)
        line.primary:ClearAllPoints()
        line.secondary:ClearAllPoints()
        line.tertiary:ClearAllPoints()
        line.warningIndicator:ClearAllPoints()
        if line.memberRow then
            line.warningIndicator:SetPoint("LEFT", line.frame, "LEFT", 0, 0)
            line.primary:SetPoint(
                "LEFT",
                line.frame,
                "LEFT",
                MISSING_WARNING_SIZE + MISSING_WARNING_GAP,
                0
            )
        else
            line.primary:SetPoint("LEFT", line.frame, "LEFT", 0, 0)
        end
        if line.columns then
            local warningSpace = line.memberRow
                and (MISSING_WARNING_SIZE + MISSING_WARNING_GAP)
                or 0
            line.primary:SetWidth(math.max(1, nameWidth - warningSpace))
            line.secondary:SetPoint(
                "LEFT",
                line.frame,
                "LEFT",
                nameWidth,
                0
            )
            line.secondary:SetWidth(lastOnlineWidth)
            line.tertiary:SetPoint(
                "LEFT",
                line.frame,
                "LEFT",
                nameWidth + lastOnlineWidth,
                0
            )
            line.tertiary:SetWidth(tenureWidth)
        else
            line.primary:SetWidth(availableWidth)
        end
    end
end


function refreshRankScrollChild(view)
    if not view.rankScrollFrame then
        return
    end

    local viewportHeight = math.max(1, view.rankScrollFrame:GetHeight())
    local rankCount = type(view.rosterReport) == "table"
        and type(view.rosterReport.ranks) == "table"
        and #view.rosterReport.ranks
        or 0
    local contentHeight = rankCount * (RANK_TAB_HEIGHT + RANK_TAB_GAP) + 4
    view.rankScrollChild:SetHeight(math.max(viewportHeight, contentHeight))
end


function hideRosterLines(view)
    for _, line in ipairs(view.rosterLines or {}) do
        hideOwnedTooltip(line.warningIndicator)
        line.frame:Hide()
    end
    if view.rosterHeader then
        view.rosterHeader.frame:Hide()
    end
    view.rosterTableHeight = nil
end

function acquireRosterLine(view, index)
    local line = view.rosterLines[index]
    if line then
        return line
    end

    local frame = CreateFrame("Frame", nil, view.scrollChild)
    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(frame)
    background:SetTexture(WHITE_TEXTURE)
    local divider = frame:CreateTexture(nil, "BORDER")
    divider:SetTexture(WHITE_TEXTURE)
    divider:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    divider:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    divider:SetHeight(1)
    divider:SetVertexColor(unpackColor(PALETTE.border))
    local primary = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    local secondary = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    local tertiary = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    local warningIndicator = CreateFrame("Button", nil, frame)
    warningIndicator:SetSize(MISSING_WARNING_SIZE, MISSING_WARNING_SIZE)
    local warningTexture = warningIndicator:CreateTexture(nil, "ARTWORK")
    warningTexture:SetAllPoints()
    warningTexture:SetTexture(MISSING_WARNING_TEXTURE)
    warningIndicator:Hide()
    primary:SetJustifyH("LEFT")
    secondary:SetJustifyH("LEFT")
    tertiary:SetJustifyH("RIGHT")
    primary:SetJustifyV("MIDDLE")
    secondary:SetJustifyV("MIDDLE")
    tertiary:SetJustifyV("MIDDLE")
    if type(primary.SetWordWrap) == "function" then
        primary:SetWordWrap(false)
        secondary:SetWordWrap(false)
        tertiary:SetWordWrap(false)
    end
    line = {
        frame = frame,
        background = background,
        primary = primary,
        secondary = secondary,
        tertiary = tertiary,
        warningIndicator = warningIndicator,
    }
    line.primaryHitbox = attachTruncationTooltip(frame, primary)
    line.secondaryHitbox = attachTruncationTooltip(frame, secondary)
    line.tertiaryHitbox = attachTruncationTooltip(frame, tertiary)
    enableRowHover(line)
    warningIndicator:SetScript("OnEnter", function()
        if line.missingLastSeenDate == nil then
            return
        end
        showOwnedTooltip(
            warningIndicator,
            "Missing roster member",
            "Not found in the current successful roster snapshot.\nLast appeared (Pacific): "
                .. line.missingLastSeenDate
        )
    end)
    warningIndicator:SetScript("OnLeave", function()
        hideOwnedTooltip(warningIndicator)
    end)
    view.rosterLines[index] = line
    return line
end

function createRosterHeader(view)
    if view.rosterHeader then
        return view.rosterHeader
    end
    local frame = CreateFrame("Frame", nil, view, "BackdropTemplate")
    local header = {
        frame = frame,
        primary = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall"),
        secondary = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall"),
        tertiary = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall"),
        warningIndicator = CreateFrame("Frame", nil, frame),
        columns = true,
        memberRow = false,
    }
    header.warningIndicator:Hide()
    header.primary:SetText("Name-Realm")
    header.secondary:SetText("Last online")
    header.tertiary:SetText("Rank tenure")
    for _, field in ipairs({ "primary", "secondary", "tertiary" }) do
        header[field]:SetJustifyH(field == "tertiary" and "RIGHT" or "LEFT")
        header[field]:SetJustifyV("MIDDLE")
        setFont(header[field], FONT_SEMIBOLD, 12)
        setTextColor(header[field], PALETTE.text)
    end
    flatBackdrop(frame, PALETTE.control, PALETTE.border)
    frame:SetPoint("TOPLEFT", view, "TOPLEFT", 0, 0)
    frame:SetPoint("TOPRIGHT", view, "TOPRIGHT", -8, 0)
    frame:SetHeight(28)
    view.rosterHeader = header
    return header
end

function renderRosterRank(view, rank, forceTextRefresh)
    view.text:Hide()
    createRosterHeader(view).frame:Show()
    local lineIndex = 0
    local offset = 0

    local function addLine(
        height,
        primary,
        secondary,
        tertiary,
        columns,
        member
    )
        lineIndex = lineIndex + 1
        local line = acquireRosterLine(view, lineIndex)
        line.columns = columns == true
        line.memberRow = member ~= nil
        line.missingLastSeenDate = member
            and member.isMissing
            and member.missingLastSeenDate
            or nil
        if line.missingLastSeenDate == nil then
            hideOwnedTooltip(line.warningIndicator)
        end
        line.warningIndicator:SetShown(line.missingLastSeenDate ~= nil)
        line.frame:ClearAllPoints()
        line.frame:SetPoint("TOPLEFT", view.scrollChild, "TOPLEFT", 4, -offset)
        line.frame:SetHeight(height)
        local rowColor = member and ((lineIndex % 2 == 0) and PALETTE.zebra or PALETTE.surface)
            or PALETTE.control
        line.baseColor = rowColor
        line.background:SetVertexColor(unpackColor(rowColor))
        if forceTextRefresh then
            line.primary:SetText("")
            line.secondary:SetText("")
            line.tertiary:SetText("")
        end
        line.primary:SetText(primary or "")
        line.secondary:SetText(secondary or "")
        line.tertiary:SetText(tertiary or "")
        setCharacterNameColor(
            line.primary,
            member and member.classFileName or nil
        )
        if member then
            if type(line.primary.SetFontObject) == "function" then
                line.primary:SetFontObject("GameFontHighlight")
            end
            setFont(line.secondary, FONT_REGULAR, 12)
            setFont(line.tertiary, FONT_REGULAR, 12)
        else
            setFont(line.primary, FONT_SEMIBOLD, 12)
        end
        line.frame:Show()
        offset = offset + height
    end

    for groupIndex, group in ipairs(rank.groups) do
        addLine(ROSTER_GROUP_HEIGHT, group.title)
        if #group.members == 0 then
            addLine(
                ROSTER_ROW_HEIGHT,
                "|cff888888" .. group.emptyText .. "|r"
            )
        else
            for _, member in ipairs(group.members) do
                local dayLabel = member.tenureDays == 1 and "day" or "days"
                addLine(
                    ROSTER_ROW_HEIGHT,
                    member.displayName,
                    member.lastOnlineText,
                    string.format("%d %s", member.tenureDays, dayLabel),
                    true,
                    member
                )
            end
        end
        if groupIndex < #rank.groups then
            offset = offset + ROSTER_GROUP_GAP
        end
    end

    for index = lineIndex + 1, #view.rosterLines do
        hideOwnedTooltip(view.rosterLines[index].warningIndicator)
        view.rosterLines[index].frame:Hide()
    end
    view.rosterTableHeight = offset + 4
    view.scrollFrame:SetVerticalScroll(0)
    refreshScrollChild(view)
end

function findRosterRank(view, rankIndex)
    if type(view.rosterReport) ~= "table" then
        return nil
    end
    for _, rank in ipairs(view.rosterReport.ranks or {}) do
        if rank.index == rankIndex then
            return rank
        end
    end
    return nil
end


function UI.SelectRosterRank(rankIndex)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end

    local view = UI.frame.views.roster
    local rank = findRosterRank(view, rankIndex)
    if not rank then
        return nil, "roster rank is unavailable"
    end

    for buttonIndex, buttonRank in ipairs(view.rosterReport.ranks) do
        local button = view.rankButtons[buttonIndex]
        button:SetEnabled(buttonRank.index ~= rankIndex)
    end
    view.selectedRankIndex = rankIndex
    if type(RGMS.DB) == "table" and type(RGMS.DB.ui) == "table" then
        RGMS.DB.ui.selectedRosterRankIndex = rankIndex
    end
    updateDropdownLabel(view.rankDropdown, rank, "No ranks")
    if type(RGMS.PortalState) == "table" then
        RGMS.PortalState:selectionChanged("roster")
    end
    renderRosterRank(view, rank)
    return true
end

function UI.SetRosterReport(report)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    if type(report) ~= "table" or type(report.ranks) ~= "table" then
        return nil, "roster report must contain ranks"
    end

    local view = UI.frame.views.roster
    local previousRankIndex = type(RGMS.DB) == "table"
        and type(RGMS.DB.ui) == "table"
        and RGMS.DB.ui.selectedRosterRankIndex
        or view.selectedRankIndex
    view.rosterReport = report

    for index, rank in ipairs(report.ranks) do
        local button = view.rankButtons[index]
        if not button then
            button = CreateFrame(
                "Button",
                nil,
                view.rankScrollChild,
                "UIPanelButtonTemplate"
            )
            button:SetHeight(RANK_TAB_HEIGHT)
            view.rankButtons[index] = button
        end

        button:ClearAllPoints()
        button:SetWidth(RANK_TAB_WIDTH - 22)
        if index == 1 then
            button:SetPoint("TOPLEFT", view.rankScrollChild, "TOPLEFT", 0, -2)
        else
            button:SetPoint(
                "TOPLEFT",
                view.rankButtons[index - 1],
                "BOTTOMLEFT",
                0,
                -RANK_TAB_GAP
            )
        end
        button:SetText(rank.name)
        local rankIndex = rank.index
        button:SetScript("OnClick", function()
            UI.SelectRosterRank(rankIndex)
        end)
        button:Show()
    end
    for index = #report.ranks + 1, #view.rankButtons do
        view.rankButtons[index]:Hide()
    end

    view.rankScrollFrame:SetVerticalScroll(0)
    refreshRankScrollChild(view)

    local selectedRank = type(RGMS.Portal) == "table"
        and RGMS.Portal.resolveSelection(report.ranks, previousRankIndex, false)
        or findRosterRank(view, previousRankIndex)
        or report.ranks[1]
    if selectedRank then
        return UI.SelectRosterRank(selectedRank.index)
    end

    view.selectedRankIndex = nil
    if type(RGMS.DB) == "table" and type(RGMS.DB.ui) == "table" then
        RGMS.DB.ui.selectedRosterRankIndex = nil
    end
    updateDropdownLabel(view.rankDropdown, nil, "No ranks")
    hideRosterLines(view)
    view.text:Show()
    view.text:SetText("No roster data yet")
    view.scrollFrame:SetVerticalScroll(0)
    refreshScrollChild(view)
    return true
end


function createRosterByTenureView(view, parent)
    createRefreshButton(view, parent, true, "Refresh the guild roster.", function()
        RGMS.Roster.RequestManualScan()
    end)
    view.rosterAvailable = true
    view.rosterScanInProgress = false

    view.rankScrollFrame = CreateFrame(
        "ScrollFrame", nil, view, "UIPanelScrollFrameTemplate"
    )
    view.rankScrollFrame:SetPoint("TOPLEFT", view, "TOPLEFT", 0, 0)
    view.rankScrollFrame:SetPoint("BOTTOMLEFT", view, "BOTTOMLEFT", 0, 0)
    view.rankScrollFrame:SetWidth(1)
    view.rankScrollFrame:Hide()
    view.rankScrollChild = CreateFrame("Frame", nil, view.rankScrollFrame)
    view.rankScrollChild:SetSize(RANK_TAB_WIDTH - 22, 1)
    view.rankScrollFrame:SetScrollChild(view.rankScrollChild)
    view.rankButtons = {}
    view.rosterLines = {}
    view.rankDropdown = createDropdown(view, 200, "No ranks", function(index)
        UI.SelectRosterRank(index)
    end, function()
        return view.rosterReport and view.rosterReport.ranks or {}
    end)
    view.rankDropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", 64, -12)
    createByRankControl(view, true, view.status, "RIGHT", "LEFT", -CONTROL_GAP, 0)
    view.rankScrollFrame:SetScript("OnSizeChanged", function()
        refreshRankScrollChild(view)
    end)
    view.refreshVisible = function()
        local rank = findRosterRank(view, view.selectedRankIndex)
        if rank then
            updateDropdownLabel(view.rankDropdown, rank, "No ranks", true)
            renderRosterRank(view, rank, true)
        end
    end
end

end, {
    "SelectRosterRank",
    "SetRosterReport",
})


