local layout = require("UI.Layout")
local mainsAltsSearch = require("MainsAlts.Search")
local test = require("Tests.lib.runner")

local EMPTY_TEXT = "<no members in this bracket>"

local function emptyGroups()
    return {
        { title = "This Week", emptyText = EMPTY_TEXT, members = {} },
        { title = "Last Week", emptyText = EMPTY_TEXT, members = {} },
        { title = "Two Weeks Ago", emptyText = EMPTY_TEXT, members = {} },
        { title = "It's Been a While", emptyText = EMPTY_TEXT, members = {} },
    }
end

local function rosterRank(index, name, label)
    return {
        index = index,
        name = name,
        label = label or name,
        groups = emptyGroups(),
    }
end

local function rosterTableText(view)
    local parts = {}
    for _, line in ipairs(view.rosterLines or {}) do
        if line.frame:IsShown() then
            parts[#parts + 1] = line.primary.text or ""
            parts[#parts + 1] = line.secondary.text or ""
            parts[#parts + 1] = line.tertiary.text or ""
        end
    end
    return table.concat(parts, "\n")
end

local function mainsAltsReport(count, prefix)
    local rows = {}
    prefix = prefix or "char"
    for index = 1, count do
        local identity = string.format("%s%02d-area52", prefix, index)
        rows[index] = {
            identity = identity,
            displayName = string.format("%s%02d-Area52", prefix, index),
            altCount = 0,
            alts = {},
        }
    end
    return { rows = rows }
end

local function newsSet(id, overrides)
    local value = {
        id = id,
        createdDate = "2024-06-01",
        joiningMembers = { "Alpha-Area52" },
        leavingMembers = {},
        rankChanges = {},
    }
    for key, item in pairs(overrides or {}) do
        value[key] = item
    end
    return value
end

local function countLines(value)
    local count = 1
    for _ in string.gmatch(value or "", "\n") do
        count = count + 1
    end
    return count
end

local function newRegion(parent)
    local region = {
        parent = parent,
        shown = true,
        width = 340,
        height = 420,
        scripts = {},
        points = {},
    }

    function region:SetSize(width, height)
        self.width = width
        self.height = height
    end

    function region:SetWidth(width)
        self.width = width
    end

    function region:SetHeight(height)
        self.height = height
    end

    function region:SetJustifyV(justifyV)
        self.justifyV = justifyV
    end

    function region:GetWidth()
        return self.width
    end

    function region:GetHeight()
        return self.height
    end

    function region:SetPoint(point, relativeTo, relativePoint, x, y)
        self.point = point
        self.relativeTo = relativeTo
        self.relativePoint = relativePoint
        self.x = x or 0
        self.y = y or 0
        self.points[#self.points + 1] = {
            point = point,
            relativeTo = relativeTo,
            relativePoint = relativePoint,
            x = x or 0,
            y = y or 0,
        }
        if point == "BOTTOMLEFT" and relativePoint == "BOTTOMLEFT" then
            self.left = self.x
            self.bottom = self.y
        end
    end

    function region:SetAllPoints(relativeTo)
        self.allPoints = relativeTo or true
    end

    function region:ClearAllPoints()
        self.point = nil
        self.points = {}
    end

    function region:GetLeft()
        return self.left
    end

    function region:GetBottom()
        return self.bottom
    end

    function region:GetTop()
        return self.top or (self.bottom and self.bottom + self.height or nil)
    end

    function region:GetRect()
        return self.left, self.bottom, self.width, self.height
    end

    function region:GetEffectiveScale()
        return self.effectiveScale or 1
    end

    function region:SetScript(scriptName, callback)
        self.scripts[scriptName] = callback
    end

    function region:HookScript(scriptName, callback)
        local previous = self.scripts[scriptName]
        if previous then
            self.scripts[scriptName] = function(...)
                previous(...)
                callback(...)
            end
        else
            self.scripts[scriptName] = callback
        end
    end

    function region:GetParent()
        return self.parent
    end

    function region:Show()
        self.shown = true
        if self.scripts.OnShow then
            self.scripts.OnShow(self)
        end
    end

    function region:Hide()
        local wasShown = self.shown
        self.shown = false
        if wasShown and self.scripts.OnHide then
            self.scripts.OnHide(self)
        end
    end

    function region:IsShown()
        return self.shown
    end

    function region:IsMouseOver()
        return self.mouseOver == true
    end

    function region:SetShown(shown)
        self.shown = shown
    end

    function region:SetText(value)
        value = tostring(value or "")
        if self.maxLetters and #value > self.maxLetters then
            value = string.sub(value, 1, self.maxLetters)
        end
        self.setTextCalls = (self.setTextCalls or 0) + 1
        self.textHistory = self.textHistory or {}
        self.textHistory[#self.textHistory + 1] = value
        self.text = value
        if self.scripts.OnTextChanged then
            self.scripts.OnTextChanged(self)
        end
    end

    function region:GetText()
        return self.text or ""
    end

    function region:GetStringWidth()
        return #(self.text or "") * 7
    end

    function region:SetTexture(value, wrapHorizontal, wrapVertical, filterMode)
        self.texture = value
        self.wrapHorizontal = wrapHorizontal
        self.wrapVertical = wrapVertical
        self.filterMode = filterMode
    end

    function region:SetTexCoord(left, right, top, bottom)
        self.texCoord = { left, right, top, bottom }
    end

    function region:SetFont(path, size, flags)
        self.font = { path, size, flags }
        self.setFontCalls = (self.setFontCalls or 0) + 1
    end

    function region:SetFontObject(fontObject)
        self.fontObject = fontObject
    end

    function region:SetTextColor(red, green, blue, alpha)
        self.textColor = { red, green, blue, alpha }
    end

    function region:SetVertexColor(red, green, blue, alpha)
        self.vertexColor = { red, green, blue, alpha }
    end

    function region:SetDesaturated(desaturated)
        self.desaturated = desaturated == true
    end

    function region:SetAlpha(alpha)
        self.alpha = alpha
    end

    function region:SetScale(scale)
        self.scale = scale
    end

    function region:GetScale()
        return self.scale or 1
    end

    function region:EnableMouse(enabled)
        self.mouseEnabled = enabled == true
    end

    function region:SetAtlas(atlas)
        self.atlas = atlas
    end

    function region:SetWordWrap(enabled)
        self.wordWrap = enabled == true
    end

    function region:SetNonSpaceWrap(enabled)
        self.nonSpaceWrap = enabled == true
    end

    function region:SetMaxLines(maximum)
        self.maxLines = maximum
    end

    function region:SetDrawLayer(drawLayer, sublevel)
        self.drawLayer = drawLayer
        self.sublevel = sublevel
    end

    function region:SetRotation(rotation)
        self.rotation = rotation
    end

    function region:SetClipsChildren(clipsChildren)
        self.clipsChildren = clipsChildren
    end

    function region:SetFrameLevel(frameLevel)
        self.frameLevel = frameLevel
    end

    function region:SetFrameStrata(frameStrata)
        self.frameStrata = frameStrata
    end

    function region:GetFrameLevel()
        return self.frameLevel or 0
    end

    function region:SetBackdropColor(red, green, blue, alpha)
        self.backdropColor = { red, green, blue, alpha }
    end

    function region:SetBackdropBorderColor(red, green, blue, alpha)
        self.backdropBorderColor = { red, green, blue, alpha }
    end

    function region:SetEnabled(enabled)
        self.enabled = enabled
    end

    function region:SetChecked(checked)
        self.checked = checked == true
    end

    function region:SetCheckedTexture(texture)
        self.checkedTexture = texture
    end

    function region:SetHighlightTexture(texture, blendMode)
        self.highlightTexture = texture
        self.highlightBlendMode = blendMode
    end

    function region:GetChecked()
        return self.checked == true
    end

    function region:IsEnabled()
        return self.enabled ~= false
    end

    function region:SetMaxLetters(maximum)
        self.maxLetters = maximum
    end

    function region:SetFocus()
        self.focused = true
        if self.scripts.OnEditFocusGained then
            self.scripts.OnEditFocusGained(self)
        end
    end

    function region:ClearFocus()
        self.focused = false
        if self.scripts.OnEditFocusLost then
            self.scripts.OnEditFocusLost(self)
        end
    end

    function region:HasFocus()
        return self.focused == true
    end

    function region:SetAutoFocus(autoFocus)
        self.autoFocus = autoFocus == true
    end

    function region:SetTextInsets(left, right, top, bottom)
        self.textInsets = { left, right, top, bottom }
    end

    function region:SetCursorPosition(position)
        self.cursorPosition = position
    end

    function region:GetStringHeight()
        if self.wordWrap and self.width and self.width > 0 then
            local lines = 0
            for line in string.gmatch((self.text or "") .. "\n", "([^\n]*)\n") do
                lines = lines + math.max(1, math.ceil(#line * 7 / self.width))
            end
            return lines * 14
        end
        return countLines(self.text) * 14
    end

    function region:SetJustifyH(justification)
        self.justifyH = justification
    end

    function region:CreateFontString(_, drawLayer, templateName, sublevel)
        local child = newRegion(self)
        child.drawLayer = drawLayer
        child.templateName = templateName
        child.sublevel = sublevel
        return child
    end

    function region:CreateTexture(_, drawLayer, templateName, sublevel)
        local child = newRegion(self)
        child.drawLayer = drawLayer
        child.templateName = templateName
        child.sublevel = sublevel
        return child
    end

    function region:SetScrollChild(child)
        self.scrollChild = child
    end

    function region:SetVerticalScroll(offset)
        self.verticalScroll = offset
    end

    function region:GetVerticalScroll()
        return self.verticalScroll or 0
    end

    function region:SetID(id)
        self.id = id
    end

    function region:RegisterEvent(event)
        self.registeredEvents = self.registeredEvents or {}
        self.registeredEvents[event] = true
    end

    function region:RegisterForDrag(button)
        self.dragButton = button
    end

    function region:StartMoving()
        self.moving = true
    end

    function region:StopMovingOrSizing()
        self.moving = false
    end

    local noOpMethods = {
        "SetToplevel",
        "SetMovable",
        "EnableMouseWheel",
        "SetClampedToScreen",
        "SetClampRectInsets",
        "SetBackdrop",
        "SetMultiLine",
    }
    for _, methodName in ipairs(noOpMethods) do
        region[methodName] = function() end
    end

    function region:SetResizable(resizable)
        self.resizable = resizable
    end

    return region
end

local function newHarness(savedPosition, screenWidth, screenHeight)
    local mainFrame
    local fonts = {}
    local refreshRequests = 0
    local bankRefreshRequests = 0
    local bankCancellations = 0
    local groupingRequests = {}
    local promotionRequests = {}
    local removalRequests = {}
    local noteSaves = {}
    local guildNoteRequests = 0
    local noteDrafts
    local noteIdentity
    local tagAssignments = {}
    local tagToggles = {}
    local tagDeleteRequests = {}
    local tagRefreshRequests = 0
    local provisionActions = {}
    local provisionReorderFailure
    local cursorX, cursorY = 0, 0
    local leftMouseDown = false
    local shownPopup
    local tooltip = {
        lines = {},
        shown = false,
    }
    function tooltip:SetOwner(owner, anchor)
        self.owner = owner
        self.anchor = anchor
    end
    function tooltip:SetText(value)
        self.lines = { value }
    end
    function tooltip:SetHyperlink(value)
        self.hyperlink = value
    end
    function tooltip:AddLine(value)
        self.lines[#self.lines + 1] = value
    end
    function tooltip:Show()
        self.shown = true
    end
    function tooltip:IsOwned(owner)
        return self.owner == owner
    end
    function tooltip:Hide()
        self.shown = false
        self.owner = nil
    end
    local uiParent = newRegion()
    uiParent.width = screenWidth or 1920
    uiParent.height = screenHeight or 1080

    UIParent = uiParent
    GetCursorPosition = function()
        return cursorX, cursorY
    end
    IsMouseButtonDown = function(button)
        return button == "LeftButton" and leftMouseDown
    end
    GameTooltip = tooltip
    RAID_CLASS_COLORS = {
        DRUID = { r = 1, g = 0.49, b = 0.04 },
        MAGE = { r = 0.25, g = 0.78, b = 0.92 },
        WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
    }
    UISpecialFrames = {}
    ACCEPT = "Accept"
    CANCEL = "Cancel"
    StaticPopupDialogs = {}
    StaticPopup_Show = function(key, text, _, data)
        shownPopup = {
            key = key,
            text = text,
            data = data,
        }
        return newRegion(UIParent)
    end
    MenuUtil = {}
    CreateFont = function(name)
        local font = newRegion()
        font.name = name
        fonts[name] = font
        return font
    end
    CreateFrame = function(frameType, name, parent, templateName)
        local frame = newRegion(parent)
        frame.name = name
        frame.templateName = templateName
        if frameType == "ScrollFrame" then
            frame.ScrollBar = newRegion(frame)
            frame.ScrollBar.ScrollUpButton = newRegion(frame.ScrollBar)
            frame.ScrollBar.ScrollDownButton = newRegion(frame.ScrollBar)
            frame.ScrollBar.ThumbTexture = newRegion(frame.ScrollBar)
        end
        if frameType == "DropdownButton" then
            function frame:SetupMenu(generator)
                self.menuGenerator = generator
            end
        end
        if name == "RGMSMainFrame" then
            mainFrame = frame
        end
        return frame
    end
    SmallMoneyFrame_OnLoad = function(frame)
        frame.moneyFrameLoaded = true
    end
    MoneyFrame_SetType = function(frame, moneyType)
        frame.moneyType = moneyType
    end
    MoneyFrame_Update = function(frame, money, forceShow)
        frame.money = money
        frame.moneyForceShow = forceShow
    end
    PanelTemplates_SetNumTabs = function(frame, numberOfTabs)
        frame.numTabs = numberOfTabs
    end
    PanelTemplates_SetTab = function(frame, selectedTab)
        frame.selectedTab = selectedTab
    end

    local database = {
        ui = {},
        newsSets = {},
    }
    local modifiedItemClicks = {}
    HandleModifiedItemClick = function(itemLink)
        modifiedItemClicks[#modifiedItemClicks + 1] = itemLink
        return true
    end
    if savedPosition then
        database.ui.windowPosition = savedPosition
    end

    local rgms
    rgms = {
        DB = database,
        UILayout = layout,
        MainsAltsSearch = mainsAltsSearch,
        Roster = {
            RequestManualScan = function()
                refreshRequests = refreshRequests + 1
            end,
            AcknowledgeNewsSet = function(setId)
                local retained = {}
                local removed = false
                for _, set in ipairs(database.newsSets) do
                    if set.id == setId then
                        removed = true
                    else
                        retained[#retained + 1] = set
                    end
                end
                if not removed then
                    return nil, "news set was not found"
                end
                database.newsSets = retained
                rgms.UI.SetNewsSets(retained)
                return true
            end,
        },
        Bank = {
            RequestManualScan = function()
                bankRefreshRequests = bankRefreshRequests + 1
            end,
            CancelScan = function()
                bankCancellations = bankCancellations + 1
            end,
        },
        Provisions = {
            OnTabSelected = function()
                provisionActions[#provisionActions + 1] = { action = "tab" }
                return true
            end,
            OnWindowClosed = function()
                provisionActions[#provisionActions + 1] = { action = "close" }
                return true
            end,
            New = function()
                provisionActions[#provisionActions + 1] = { action = "new" }
                return true
            end,
            Save = function()
                provisionActions[#provisionActions + 1] = { action = "save" }
                return true
            end,
            Delete = function(id)
                provisionActions[#provisionActions + 1] = {
                    action = "delete",
                    id = id,
                }
                return true
            end,
            Select = function(id)
                provisionActions[#provisionActions + 1] = {
                    action = "select",
                    id = id,
                }
                return true
            end,
            Reorder = function(ids)
                provisionActions[#provisionActions + 1] = {
                    action = "reorder",
                    ids = ids,
                }
                if provisionReorderFailure then
                    return nil, provisionReorderFailure
                end
                return true
            end,
            SetDraft = function(draft)
                provisionActions[#provisionActions + 1] = {
                    action = "draft",
                    draft = draft,
                }
                return true
            end,
        },
        MainsAlts = {
            GroupSelected = function(selectedIdentities)
                groupingRequests[#groupingRequests + 1] = selectedIdentities
                return true
            end,
            PromoteAlt = function(altIdentity)
                promotionRequests[#promotionRequests + 1] = altIdentity
                return true
            end,
            RemoveAlt = function(altIdentity)
                removalRequests[#removalRequests + 1] = altIdentity
                return true
            end,
            OpenCharacterNotes = function(identity, displayName, privateNote)
                noteIdentity = identity
                noteDrafts = {
                    privateNote = privateNote or "",
                    publicNote = identity == "main-area52" and "Live public" or "",
                    officerNote = identity == "main-area52" and "Live officer" or "",
                }
                return {
                    identity = identity,
                    displayName = displayName,
                    status = "ready",
                    drafts = noteDrafts,
                    publicVisible = true,
                    publicEditable = false,
                    officerVisible = true,
                    officerEditable = false,
                    saveEnabled = true,
                }
            end,
            SetCharacterNoteDraft = function(kind, value)
                noteDrafts[kind] = value
                return true
            end,
            SaveCharacterNotes = function()
                noteSaves[#noteSaves + 1] = {
                    identity = noteIdentity,
                    privateNote = noteDrafts.privateNote,
                    publicNote = noteDrafts.publicNote,
                    officerNote = noteDrafts.officerNote,
                }
                rgms.UI.CloseCharacterNoteEditor(true)
                return true
            end,
            CloseCharacterNotes = function()
                noteIdentity = nil
                noteDrafts = nil
                return true
            end,
            RequestGuildNotes = function()
                guildNoteRequests = guildNoteRequests + 1
                return true
            end,
            CreateOrAssignTag = function(identity, value)
                tagAssignments[#tagAssignments + 1] = {
                    identity = identity,
                    value = value,
                }
                return true, value
            end,
            ToggleCharacterTag = function(identity, name)
                tagToggles[#tagToggles + 1] = {
                    identity = identity,
                    name = name,
                }
                return true
            end,
            RefreshTags = function()
                tagRefreshRequests = tagRefreshRequests + 1
                return true
            end,
            DeleteTag = function(name)
                tagDeleteRequests[#tagDeleteRequests + 1] = name
                return true
            end,
        },
    }
    local chunk = assert(loadfile("UI/UI.lua"))
    local ui = chunk("RGMS", rgms)
    rgms.UI = ui

    return {
        database = database,
        fonts = fonts,
        frame = function()
            return mainFrame
        end,
        refreshRequests = function()
            return refreshRequests
        end,
        bankRefreshRequests = function()
            return bankRefreshRequests
        end,
        bankCancellations = function()
            return bankCancellations
        end,
        groupingRequests = groupingRequests,
        promotionRequests = promotionRequests,
        removalRequests = removalRequests,
        noteSaves = noteSaves,
        guildNoteRequests = function()
            return guildNoteRequests
        end,
        tagAssignments = tagAssignments,
        tagToggles = tagToggles,
        tagDeleteRequests = tagDeleteRequests,
        tagRefreshRequests = function()
            return tagRefreshRequests
        end,
        provisionActions = provisionActions,
        setCursor = function(x, y, down)
            cursorX = x
            cursorY = y
            leftMouseDown = down == true
        end,
        setProvisionReorderFailure = function(message)
            provisionReorderFailure = message
        end,
        shownPopup = function()
            return shownPopup
        end,
        tooltip = tooltip,
        modifiedItemClicks = modifiedItemClicks,
        ui = ui,
    }
end

return {
    test.case("window initializes hidden at a fixed size with explicit fresh states", function()
        local harness = newHarness()
        test.assert_true(harness.ui.Initialize())

        local frame = harness.frame()
        test.assert_false(frame:IsShown())
        test.assert_equal(frame:GetWidth(), layout.WINDOW_WIDTH)
        test.assert_equal(frame:GetHeight(), layout.WINDOW_HEIGHT)
        test.assert_equal(frame.views.roster.rankScrollFrame:GetWidth(), 1)
        test.assert_equal(frame.views.roster.scrollFrame.points[1].x, 0)
        test.assert_equal(frame.views.bank.bankTabScrollFrame:GetWidth(), 1)
        test.assert_equal(frame.views.bank.scrollFrame.points[1].x, 0)
        test.assert_equal(frame.numTabs, 4)
        test.assert_equal(frame.tabs[1].label.text, "Roster")
        test.assert_equal(frame.tabs[2].label.text, "Guild Bank")
        test.assert_equal(frame.tabs[3].label.text, "Provisions")
        test.assert_equal(frame.tabs[4].label.text, "Tags")
        test.assert_nil(frame.tabs[2].text)
        test.assert_equal(frame.views.roster.rankDropdown.parent, frame.views.roster)
        test.assert_equal(frame.views.bank.bankDropdown.parent, frame.views.bank)
        test.assert_equal(frame.logo.parent, frame.header)
        test.assert_equal(
            frame.logo.texture,
            "Interface\\AddOns\\RGMS\\assets\\rgms-logo.png"
        )
        test.assert_false(frame.resizable)
        test.assert_nil(harness.database.ui.windowPosition)
        test.assert_equal(frame.views.roster.text.text, "No roster data yet")
        test.assert_equal(frame.views.roster.status.text, "No roster data yet")
        test.assert_equal(frame.views.mainsalts.text.text, "No roster data yet")
        test.assert_equal(frame.views.mainsalts.status.text, "No roster data yet")
        local searchBox = frame.views.mainsalts.mainsAltsSearchBox
        test.assert_equal(searchBox:GetWidth(), 252)
        test.assert_equal(searchBox.relativeTo, frame)
        test.assert_equal(searchBox.x, 64)
        test.assert_false(searchBox.autoFocus)
        test.assert_nil(searchBox.maxLetters)
        test.assert_equal(
            frame.views.mainsalts.mainsAltsSearchPlaceholder.text,
            "Search..."
        )
        test.assert_equal(
            frame.views.mainsalts.mainsAltsTagFilterButton.label.text,
            "Tags..."
        )
        test.assert_equal(
            frame.views.mainsalts.mainsAltsTagFilterButton.relativeTo,
            searchBox
        )
        test.assert_equal(
            frame.views.mainsalts.groupButton.relativeTo,
            frame.views.mainsalts.mainsAltsTagFilterButton
        )
        test.assert_equal(frame.views.mainsalts.groupButton.x, 8)
        test.assert_equal(frame.views.mainsalts.byRankCheckbox.label.text, "By rank")
        test.assert_false(frame.views.mainsalts.byRankCheckbox:GetChecked())
        test.assert_true(frame.views.roster.byRankCheckbox:GetChecked())
        test.assert_equal(
            frame.views.mainsalts.byRankCheckbox.relativeTo,
            frame.views.mainsalts.status
        )
        test.assert_equal(frame.views.mainsalts.byRankCheckbox.point, "RIGHT")
        test.assert_equal(frame.views.mainsalts.byRankCheckbox.relativePoint, "LEFT")
        test.assert_equal(frame.views.mainsalts.byRankCheckbox.x, -8)
        test.assert_equal(
            frame.views.roster.byRankCheckbox.relativeTo,
            frame.views.roster.status
        )
        test.assert_equal(frame.views.bank.status.points[2].x, -96)
        test.assert_equal(
            frame.views.bank.status.points[2].x,
            frame.views.roster.status.points[2].x
        )
        test.assert_equal(frame.views.bank.status.height, 40)
        test.assert_equal(frame.views.bank.status.justifyV, "MIDDLE")
        test.assert_equal(frame.views.bank.text.text, "No bank scan yet")
        test.assert_equal(frame.views.bank.status.text, "No bank scan yet")
        test.assert_nil(frame.views.provisions.provisionStatusTitle)
        test.assert_nil(frame.views.provisions.provisionEditor.title)
        test.assert_equal(
            frame.views.provisions.provisionStatusPane.points[2].relativeTo,
            frame.views.provisions
        )
        test.assert_equal(
            frame.views.provisions.provisionStatusPane.points[2].relativePoint,
            "BOTTOM"
        )
        test.assert_equal(
            frame.views.provisions.provisionStatusPane.points[2].x,
            -8
        )
        test.assert_equal(
            frame.views.provisions.provisionEditor.points[1].relativeTo,
            frame.views.provisions
        )
        test.assert_equal(
            frame.views.provisions.provisionEditor.points[1].relativePoint,
            "TOP"
        )
        test.assert_equal(
            frame.views.provisions.provisionEditor.points[1].x,
            8
        )
        test.assert_equal(frame.views.provisions.status.text, "No provisions yet")
        test.assert_equal(
            frame.views.provisions.provisionR1.symbol.atlas,
            "Professions-Icon-Quality-12-Tier1"
        )
        test.assert_equal(
            frame.views.provisions.provisionR2.symbol.atlas,
            "Professions-Icon-Quality-12-Tier2"
        )
        test.assert_nil(frame.views.provisions.provisionR1.label)
        test.assert_nil(frame.views.provisions.provisionR2.label)
        test.assert_equal(frame.views.provisions.provisionEither.label.text, "Either")
        test.assert_false(frame.views.provisions.provisionR1:GetChecked())
        test.assert_false(frame.views.provisions.provisionR2:GetChecked())
        test.assert_false(frame.views.provisions.provisionEither:GetChecked())
        test.assert_equal(
            frame.views.provisions.newProvisionButton.text,
            "New Provision"
        )
        test.assert_equal(frame.views.provisions.saveProvisionButton.text, "Save")
        test.assert_nil(frame.views.provisions.deleteProvisionButton)
        test.assert_nil(frame.views.provisions.provisionAddRow)
        test.assert_nil(frame.views.provisions.addProvisionButton)
        test.assert_equal(frame.views.provisions.newProvisionButton:GetWidth(), 105)
        test.assert_equal(frame.views.provisions.saveProvisionButton:GetWidth(), 42)
        test.assert_equal(
            frame.views.provisions.newProvisionButton.point,
            "TOPLEFT"
        )
        test.assert_equal(
            frame.views.provisions.newProvisionButton.relativeTo,
            frame
        )
        test.assert_equal(frame.views.provisions.newProvisionButton.x, 64)
        test.assert_equal(frame.views.provisions.newProvisionButton.y, -12)
        for _, tabId in ipairs({ "bank", "provisions" }) do
            local moneyFrame = frame.views[tabId].guildBankBalanceFrame
            test.assert_equal(moneyFrame.templateName, "SmallMoneyFrameTemplate")
            test.assert_true(moneyFrame.moneyFrameLoaded)
            test.assert_equal(moneyFrame.moneyType, "GUILD_REPAIR")
            test.assert_equal(moneyFrame.point, "TOPRIGHT")
            test.assert_equal(moneyFrame.x, -84)
            test.assert_equal(moneyFrame.y, -29)
            test.assert_equal(moneyFrame:GetScale(), 1)
            test.assert_false(moneyFrame:IsShown())
            test.assert_equal(frame.views[tabId].status:GetHeight(), 40)
            test.assert_equal(frame.views[tabId].status.justifyV, "MIDDLE")
        end
        test.assert_equal(frame.views.provisions.saveProvisionButton.point, "BOTTOMRIGHT")
        test.assert_equal(frame.views.provisions.provisionNameLabel.y, -16)
        test.assert_equal(frame.views.provisions.provisionQualityLabel.y, -99)
        test.assert_equal(frame.views.provisions.provisionR1.y, -119)
        test.assert_equal(frame.views.provisions.provisionTargetLabel.y, -169)
        test.assert_equal(
            frame.views.provisions.provisionScrollFrame.points[1].relativeTo,
            frame.views.provisions.provisionStatusPane
        )
        test.assert_equal(
            frame.views.provisions.provisionScrollFrame.points[1].relativePoint,
            "TOPLEFT"
        )
        test.assert_equal(frame.views.provisions.provisionScrollFrame.points[1].x, 10)
        test.assert_equal(frame.views.provisions.provisionScrollFrame.points[1].y, -10)
        test.assert_equal(
            frame.views.provisions.provisionScrollFrame.points[2].relativeTo,
            frame.views.provisions.provisionStatusPane
        )
        test.assert_equal(
            frame.views.provisions.provisionScrollFrame.points[2].x,
            -10
        )
        test.assert_equal(frame.views.provisions.provisionScrollFrame.points[2].y, -10)
        test.assert_equal(frame.views.tags.text.text, "No tags yet")
        test.assert_equal(frame.views.tags.status.text, "No tags yet")
        test.assert_nil(frame.views.tags.refreshButton)
        test.assert_nil(frame.views.tags.groupButton)
        test.assert_nil(frame.views.tags.mainsAltsSearchBox)
    end),

    test.case("News is a fixed right drawer with explicit and automatic opening", function()
        local harness = newHarness()
        harness.database.newsSets = { newsSet("pending") }
        test.assert_true(harness.ui.Initialize())
        local frame = harness.frame()
        local drawer = frame.newsWindow

        test.assert_equal(drawer:GetWidth(), 400)
        test.assert_equal(drawer:GetHeight(), 400)
        test.assert_equal(drawer.shadow.texture, "Interface\\Buttons\\WHITE8X8")
        test.assert_equal(drawer.shadow.sublevel, -8)
        test.assert_equal(drawer.shadow.vertexColor, { 0, 0, 0, 0.45 })
        test.assert_equal(drawer.shadow.points[1].x, -6)
        test.assert_equal(drawer.shadow.points[1].y, 6)
        test.assert_equal(drawer.shadow.points[2].x, 6)
        test.assert_equal(drawer.shadow.points[2].y, -6)
        test.assert_false(drawer:IsShown())
        test.assert_true(harness.ui.Show())
        test.assert_true(drawer:IsShown())
        test.assert_equal(drawer.point, "TOPLEFT")
        test.assert_true(drawer.relativeTo == frame)
        test.assert_equal(drawer.relativePoint, "TOPRIGHT")
        test.assert_equal(drawer.x, 20)
        test.assert_equal(drawer.y, 0)

        drawer.closeButton.scripts.OnClick()
        test.assert_false(drawer:IsShown())
        test.assert_equal(#harness.database.newsSets, 1)
        frame.logoButton.scripts.OnClick()
        test.assert_true(drawer:IsShown())
        frame.logoButton.scripts.OnClick()
        test.assert_true(drawer:IsShown())
    end),

    test.case("News renders categories newest first and acknowledges sets independently", function()
        local harness = newHarness()
        harness.database.newsSets = {
            newsSet("newest", {
                joiningMembers = { "Alpha-Area52" },
                leavingMembers = { "Bravo-Area52" },
                rankChanges = {
                    { name = "Charlie-Area52", rankName = "Officer" },
                },
            }),
            newsSet("older", { joiningMembers = { "Delta-Area52" } }),
        }
        harness.ui.Initialize()
        harness.ui.OpenNews()
        local drawer = harness.frame().newsWindow

        test.assert_equal(drawer.blocks[1].setId, "newest")
        test.assert_equal(
            drawer.blocks[1].text.text,
            "Alpha-Area52 joined the guild.\n"
                .. "Bravo-Area52 left the guild.\n"
                .. "Charlie-Area52's rank changed to Officer."
        )
        test.assert_equal(drawer.scrollFrame:GetWidth(), 394)
        test.assert_equal(drawer.scrollFrame.x, 3)
        test.assert_equal(drawer.content:GetWidth(), 394)
        test.assert_equal(drawer.blocks[1].panel.points[1].x, 0)
        test.assert_equal(drawer.blocks[1].panel.points[2].x, 0)
        test.assert_equal(drawer.blocks[1].check.point, "TOPRIGHT")
        test.assert_true(drawer.blocks[1].check.relativeTo == drawer.blocks[1].panel)
        test.assert_equal(drawer.blocks[1].check.x, -10)
        test.assert_equal(drawer.blocks[1].text.font[2], 12)
        test.assert_nil(drawer.blocks[1].check.circleBorder)
        test.assert_true(drawer.blocks[1].check.circleFill.allPoints
            == drawer.blocks[1].check)
        test.assert_equal(
            drawer.blocks[1].check.icon.vertexColor,
            { 1, 0.82, 0.2, 1 }
        )
        test.assert_true(drawer.blocks[1].check.icon.desaturated)
        test.assert_equal(drawer.blocks[2].setId, "older")
        test.assert_equal(drawer.blocks[2].text.text, "Delta-Area52 joined the guild.")

        drawer.blocks[2].check.scripts.OnClick()
        test.assert_equal(#harness.database.newsSets, 1)
        test.assert_equal(harness.database.newsSets[1].id, "newest")
        test.assert_true(drawer:IsShown())
        drawer.blocks[1].check.scripts.OnClick()
        test.assert_equal(harness.database.newsSets, {})
        test.assert_true(drawer:IsShown())
    end),

    test.case("News and Notes are exclusive while the scan overlay locks both windows", function()
        local harness = newHarness()
        harness.database.newsSets = { newsSet("pending") }
        harness.ui.Initialize()
        harness.ui.Show()
        local frame = harness.frame()
        test.assert_true(frame.newsWindow:IsShown())

        test.assert_true(harness.ui.OpenCharacterNote(
            "main-area52",
            "Main-Area52",
            "Private",
            true
        ))
        test.assert_false(frame.newsWindow:IsShown())
        test.assert_true(frame.notesEditor:IsShown())
        harness.ui.OpenNews()
        test.assert_false(frame.notesEditor:IsShown())
        test.assert_true(frame.newsWindow:IsShown())
        test.assert_true(harness.ui.OpenCharacterNote(
            "main-area52",
            "Main-Area52",
            "Private",
            true
        ))
        test.assert_false(frame.newsWindow:IsShown())
        harness.ui.CloseCharacterNoteEditor()

        harness.ui.CompleteRosterScan(false)
        test.assert_false(frame.newsWindow:IsShown())
        harness.ui.CompleteRosterScan(true)
        test.assert_true(frame.newsWindow:IsShown())
        test.assert_true(harness.ui.SetGlobalScanLock(true))
        test.assert_true(frame.globalDimmer:IsShown())
        test.assert_true(frame.newsWindow.dimmer:IsShown())
        test.assert_true(harness.ui.SetGlobalScanLock(false))
        test.assert_false(frame.newsWindow.dimmer:IsShown())
    end),

    test.case("News shows its scrollbar only when blocks overflow", function()
        local harness = newHarness()
        harness.ui.Initialize()
        local sets = {}
        for index = 1, 8 do
            sets[index] = newsSet(tostring(index), {
                joiningMembers = { "Alpha" .. index, "Bravo" .. index },
            })
        end
        harness.ui.SetNewsSets(sets)
        local drawer = harness.frame().newsWindow
        test.assert_true(drawer.scrollFrame.ScrollBar:IsShown())

        harness.ui.SetNewsSets({ sets[1] })
        test.assert_false(drawer.scrollFrame.ScrollBar:IsShown())
    end),

    test.case("primary tabs content status and close behavior use the public API", function()
        local harness = newHarness()
        harness.ui.Initialize()

        test.assert_true(harness.ui.Show("roster"))
        test.assert_true(harness.ui.IsShown())
        test.assert_equal(harness.ui.selectedTab, "roster")
        test.assert_true(harness.frame().views.mainsalts:IsShown())
        test.assert_false(harness.frame().views.roster:IsShown())
        test.assert_false(harness.frame().views.bank:IsShown())

        test.assert_true(harness.ui.SetViewContent("bank", "Updated bank content"))
        test.assert_true(harness.ui.SetViewStatus("bank", "Scanning..."))
        test.assert_true(harness.ui.SelectPrimaryTab("bank"))
        test.assert_equal(harness.frame().views.bank.text.text, "Updated bank content")
        test.assert_equal(harness.frame().views.bank.status.text, "Scanning...")
        test.assert_equal(harness.ui.selectedTab, "bank")

        harness.frame().closeButton.scripts.OnClick()
        test.assert_false(harness.ui.IsShown())
    end),

    test.case("Roster switches ByName and ByTenure in place with session-only state", function()
        local harness = newHarness()
        harness.ui.Initialize()
        harness.ui.SetRosterReport({ ranks = { rosterRank(3, "Officer") } })
        local report = mainsAltsReport(20)
        report.tagCatalog = { "raid" }
        for _, row in ipairs(report.rows) do
            row.name = row.displayName
            row.tags = { "raid" }
        end
        harness.ui.SetMainsAltsReport(report)
        harness.ui.SetViewStatus("roster", "20 roster characters")
        harness.ui.Show()

        local frame = harness.frame()
        local byName = frame.views.mainsalts
        local byTenure = frame.views.roster
        byName.scrollFrame:SetHeight(72)
        test.assert_equal(harness.ui.selectedTab, "roster")
        test.assert_true(byName:IsShown())
        test.assert_false(byTenure:IsShown())
        test.assert_true(byName.groupButton:IsShown())
        test.assert_true(byName.mainsAltsSearchBox:IsShown())
        test.assert_true(byName.mainsAltsTagFilterButton:IsShown())
        test.assert_true(byName.refreshButton:IsShown())
        test.assert_equal(byName.status.text, "20 roster characters")
        test.assert_equal(byTenure.status.text, "20 roster characters")

        byName.mainsAltsSearchBox:SetText("char")
        byName.mainsAltsTagFilters.raid = true
        byName.expandedMainsAlts["char01-area52"] = true
        byName.mainsAltsSelections["char01-area52"] = true
        byName.scrollFrame:SetVerticalScroll(48)
        byName.mainsAltsTagFilterButton.scripts.OnClick()
        test.assert_true(byName.mainsAltsTagFilter:IsShown())

        test.assert_true(harness.ui.SelectRosterMode("ByTenure"))
        test.assert_equal(harness.ui.rosterScroll.ByName, 48)
        test.assert_false(byName:IsShown())
        test.assert_true(byTenure:IsShown())
        test.assert_false(byName.mainsAltsTagFilter:IsShown())
        test.assert_equal(byName.mainsAltsSearchBox:GetText(), "char")
        test.assert_true(byName.mainsAltsTagFilters.raid)
        test.assert_true(byName.expandedMainsAlts["char01-area52"])
        test.assert_true(byName.mainsAltsSelections["char01-area52"])
        test.assert_true(byTenure.rankDropdown:IsShown())
        test.assert_true(byTenure.byRankCheckbox:GetChecked())
        test.assert_true(byTenure.refreshButton:IsShown())
        byTenure.refreshButton.scripts.OnClick()
        test.assert_equal(harness.refreshRequests(), 1)
        test.assert_equal(harness.ui.rosterMode, "ByTenure")

        byTenure.scrollFrame:SetVerticalScroll(30)
        test.assert_true(harness.ui.SelectPrimaryTab("bank"))
        test.assert_true(harness.ui.SelectPrimaryTab("roster"))
        test.assert_true(byTenure:IsShown())
        test.assert_equal(byTenure.scrollFrame:GetVerticalScroll(), 30)
        test.assert_equal(harness.ui.rosterScroll.ByName, 48)
        test.assert_true(byName.mainsAltsTableHeight > byName.scrollFrame:GetHeight())

        test.assert_true(harness.ui.SelectRosterMode("ByName"))
        test.assert_equal(byName.scrollFrame:GetVerticalScroll(), 48)
        test.assert_true(byName.mainsAltsTagFilters.raid)
        test.assert_true(harness.ui.OpenCharacterNote(
            report.rows[1].identity,
            report.rows[1].displayName,
            ""
        ))
        local switched, reason = harness.ui.SelectRosterMode("ByTenure")
        test.assert_nil(switched)
        test.assert_equal(reason, "modal-open")
        harness.ui.CloseCharacterNoteEditor()

        harness.ui.SetMainsAltsAvailable(false)
        test.assert_false(byName.byRankCheckbox:IsEnabled())
        test.assert_false(byTenure.byRankCheckbox:IsEnabled())
        harness.ui.SetMainsAltsAvailable(true)
        harness.ui.SetRosterScanInProgress(true)
        test.assert_false(byName.byRankCheckbox:IsEnabled())
        test.assert_equal(harness.ui.rosterMode, "ByName")
        harness.ui.SetRosterScanInProgress(false)

        harness.ui.Hide()
        harness.ui.Show()
        test.assert_true(byName:IsShown())
        test.assert_false(byName.byRankCheckbox:GetChecked())
        test.assert_equal(byName.mainsAltsSearchBox:GetText(), "")
        test.assert_nil(next(byName.mainsAltsTagFilters))
        test.assert_equal(byName.scrollFrame:GetVerticalScroll(), 0)
    end),

    test.case("Tags renders a fixed-header catalog with previews and delete confirmation", function()
        local harness = newHarness()
        harness.ui.Initialize()
        harness.ui.Show()
        local rows = {
            {
                name = "me",
                characterPreview = "Main-Area52",
                characterCount = 1,
                immutable = true,
            },
            {
                name = "raid",
                characterPreview = "Alpha-Area52, Zeta-Area52",
                characterCount = 2,
                immutable = false,
            },
        }
        for index = 3, 24 do
            rows[index] = {
                name = string.format("tag%02d", index),
                characterPreview = string.rep("VeryLongCharacter-Area52, ", 10),
                characterCount = 10,
                immutable = false,
            }
        end

        test.assert_true(harness.ui.SetTagsReport({ rows = rows }))
        test.assert_true(harness.ui.SelectPrimaryTab("tags"))

        local view = harness.frame().views.tags
        test.assert_equal(harness.ui.selectedTab, "tags")
        test.assert_equal(harness.tagRefreshRequests(), 1)
        test.assert_true(view.tagHeader.frame:IsShown())
        test.assert_equal(view.tagHeader.frame.parent, view)
        test.assert_equal(view.tagHeader.name.text, "Tag")
        test.assert_equal(view.tagHeader.preview.text, "")
        test.assert_equal(view.tagHeader.delete.text, "")
        test.assert_equal(view.tagRows[1].frame.parent, view.scrollChild)
        test.assert_equal(view.tagRows[2].preview.text,
            "Alpha-Area52, Zeta-Area52")
        test.assert_false(view.tagRows[2].preview.wordWrap)
        test.assert_equal(view.tagRows[2].preview.maxLines, 1)
        test.assert_nil(view.tagRows[2].previewHitbox)
        test.assert_true(view.scrollFrame.ScrollBar:IsShown())
        test.assert_equal(view.tagRows[1].deleteIcon.atlas, "common-icon-delete")
        test.assert_false(view.tagRows[1].deleteButton:IsEnabled())
        test.assert_false(view.tagRows[1].deleteEnabled)
        test.assert_equal(view.tagRows[1].deleteButton.alpha, 0.45)

        test.assert_true(view.tagRows[2].deleteButton:IsEnabled())
        test.assert_true(view.tagRows[2].deleteEnabled)
        view.tagRows[2].deleteButton.scripts.OnClick()
        local popup = harness.shownPopup()
        test.assert_equal(popup.key, "RGMS_CONFIRM_TAG_DELETE")
        test.assert_equal(
            popup.text,
            "Delete tag 'raid'? This will remove it from 2 characters and cannot be undone."
        )
        test.assert_equal(#harness.tagDeleteRequests, 0)
        StaticPopupDialogs[popup.key].OnCancel(nil, popup.data)
        test.assert_equal(#harness.tagDeleteRequests, 0)
        StaticPopupDialogs[popup.key].OnAccept(nil, popup.data)
        test.assert_equal(harness.tagDeleteRequests, { "raid" })

        harness.ui.RequestTagDeletion({
            name = "solo",
            characterCount = 1,
            immutable = false,
        })
        test.assert_equal(
            harness.shownPopup().text,
            "Delete tag 'solo'? This will remove it from 1 character and cannot be undone."
        )

        harness.ui.SetGlobalScanLock(true)
        test.assert_false(view.tagRows[2].deleteButton:IsEnabled())
        test.assert_false(view.tagRows[2].deleteEnabled)
        local requested, reason = harness.ui.RequestTagDeletion(rows[2])
        test.assert_nil(requested)
        test.assert_equal(reason, "scan-locked")
    end),

    test.case("ByName rows expand transiently and disable during roster scans", function()
        local harness = newHarness()
        harness.ui.Initialize()
        local report = {
            rows = {
                {
                    identity = "main-area52",
                    displayName = "Main-Area52",
                    classFileName = "WARRIOR",
                    leadershipRole = "guild-master",
                    note = "Main note",
                    hasNote = true,
                    altCount = 2,
                    alts = {
                        {
                            identity = "alta-area52",
                            displayName = "AltA-Area52",
                            classFileName = "DRUID",
                            leadershipRole = "officer",
                            note = "",
                            hasNote = false,
                        },
                        {
                            identity = "altb-area52",
                            displayName = "AltB-Area52",
                            note = "Alt note",
                            hasNote = true,
                        },
                    },
                },
                {
                    identity = "solo-area52",
                    displayName = "Solo-Area52",
                    altCount = 0,
                    alts = {},
                },
                {
                    identity = "other-area52",
                    displayName = "Other-Area52",
                    altCount = 1,
                    alts = {
                        { identity = "otheralt-area52", displayName = "OtherAlt-Area52" },
                    },
                },
            },
        }

        test.assert_true(harness.ui.SetMainsAltsReport(report))
        test.assert_true(harness.ui.Show("mainsalts"))
        local view = harness.frame().views.mainsalts
        test.assert_true(view.refreshButton ~= nil)
        test.assert_equal(view.groupButton.text, "Group Toons")
        test.assert_false(view.groupButton:IsEnabled())
        test.assert_equal(view.mainsAltsLines[1].name.text, "Main-Area52 (+2)")
        test.assert_true(view.mainsAltsLines[1].rankIcon:IsShown())
        test.assert_equal(
            view.mainsAltsLines[1].rankIcon.texture,
            "Interface\\GroupFrame\\UI-Group-LeaderIcon"
        )
        test.assert_equal(view.mainsAltsLines[1].name.textColor, {
            0.78, 0.61, 0.43, 1,
        })
        test.assert_equal(view.mainsAltsHeader.character.points[1].x, 28)
        test.assert_equal(view.mainsAltsLines[1].checkbox.x, 8)
        test.assert_equal(#view.mainsAltsLines[1].checkbox.points, 1)
        test.assert_equal(view.mainsAltsLines[1].expandButton.x, 28)
        test.assert_equal(view.mainsAltsLines[1].name.x, 48)
        test.assert_true(view.mainsAltsLines[1].noteButton:IsShown())
        test.assert_equal(view.mainsAltsHeader.note.text, "")
        test.assert_equal(view.mainsAltsHeader.note.justifyH, "CENTER")
        test.assert_equal(view.mainsAltsLines[1].noteButton.relativePoint, "RIGHT")
        test.assert_equal(view.mainsAltsLines[1].noteButton.x, -196)
        test.assert_true(view.mainsAltsLines[1].hasNote)
        test.assert_true(view.mainsAltsLines[1].checkbox:IsShown())
        test.assert_true(view.mainsAltsLines[2].checkbox:IsShown())
        test.assert_nil(view.mainsAltsLines[1].checkbox.highlightTexture)

        view.mainsAltsLines[1].checkbox:SetChecked(true)
        view.mainsAltsLines[1].checkbox.scripts.OnClick(view.mainsAltsLines[1].checkbox)
        test.assert_false(view.groupButton:IsEnabled())
        view.mainsAltsLines[2].checkbox:SetChecked(true)
        view.mainsAltsLines[2].checkbox.scripts.OnClick(view.mainsAltsLines[2].checkbox)
        test.assert_true(view.groupButton:IsEnabled())
        harness.ui.SetRosterScanInProgress(true)
        view.mainsAltsLines[2].checkbox:SetChecked(false)
        view.mainsAltsLines[2].checkbox.scripts.OnClick(view.mainsAltsLines[2].checkbox)
        test.assert_true(view.mainsAltsLines[2].checkbox:GetChecked())
        view.groupButton.scripts.OnClick()
        test.assert_equal(harness.groupingRequests, {})
        harness.ui.SetRosterScanInProgress(false)
        view.groupButton.scripts.OnClick()
        test.assert_equal(harness.groupingRequests[1], {
            "main-area52",
            "solo-area52",
        })
        view.mainsAltsLines[3].checkbox:SetChecked(true)
        view.mainsAltsLines[3].checkbox.scripts.OnClick(view.mainsAltsLines[3].checkbox)
        test.assert_false(view.groupButton:IsEnabled())
        view.mainsAltsLines[3].checkbox:SetChecked(false)
        view.mainsAltsLines[3].checkbox.scripts.OnClick(view.mainsAltsLines[3].checkbox)
        test.assert_true(view.groupButton:IsEnabled())

        view.mainsAltsLines[1].expandButton.scripts.OnClick()
        test.assert_equal(view.mainsAltsLines[2].name.text, "AltA-Area52")
        test.assert_true(view.mainsAltsLines[2].rankIcon:IsShown())
        test.assert_equal(
            view.mainsAltsLines[2].rankIcon.texture,
            "Interface\\GroupFrame\\UI-Group-AssistantIcon"
        )
        test.assert_false(view.mainsAltsLines[3].rankIcon:IsShown())
        test.assert_equal(view.mainsAltsLines[2].name.textColor, {
            1, 0.49, 0.04, 1,
        })
        test.assert_equal(view.mainsAltsLines[2].name.x, 44)
        test.assert_false(view.mainsAltsLines[2].checkbox:IsShown())
        test.assert_true(view.mainsAltsLines[2].promoteButton:IsShown())
        test.assert_true(view.mainsAltsLines[2].removeButton:IsShown())
        test.assert_true(view.mainsAltsLines[2].noteButton:IsShown())
        test.assert_equal(view.mainsAltsLines[2].noteButton.relativePoint, "RIGHT")
        test.assert_equal(view.mainsAltsLines[2].noteButton.x, -196)
        test.assert_false(view.mainsAltsLines[2].hasNote)
        test.assert_equal(view.mainsAltsLines[3].name.text, "AltB-Area52")
        test.assert_equal(view.mainsAltsLines[4].name.text, "Solo-Area52")
        view.mainsAltsLines[2].promoteButton.scripts.OnClick()
        view.mainsAltsLines[3].removeButton.scripts.OnClick()
        test.assert_equal(harness.promotionRequests, { "alta-area52" })
        test.assert_equal(harness.removalRequests, { "altb-area52" })

        harness.ui.SetRosterScanInProgress(true)
        test.assert_false(view.groupButton:IsEnabled())
        test.assert_false(view.mainsAltsLines[1].checkbox:IsEnabled())
        test.assert_false(view.mainsAltsLines[1].expandButton:IsEnabled())
        test.assert_false(view.mainsAltsLines[2].promoteButton:IsEnabled())
        test.assert_false(view.mainsAltsLines[2].removeButton:IsEnabled())
        test.assert_false(view.mainsAltsLines[1].noteButton:IsEnabled())
        test.assert_false(view.mainsAltsLines[2].noteButton:IsEnabled())
        test.assert_false(harness.frame().notesEditor.saveButton:IsEnabled())
        test.assert_nil(harness.frame().notesEditor.deleteButton)
        test.assert_false(harness.frame().notesEditor.cancelButton:IsEnabled())
        test.assert_true(harness.frame().notesEditor.closeButton:IsEnabled())
        local toggled, message = harness.ui.ToggleMainsAltsGroup("main-area52")
        test.assert_nil(toggled)
        test.assert_matches(message, "disabled")

        harness.ui.SetRosterScanInProgress(false)
        test.assert_true(view.mainsAltsLines[1].checkbox:IsEnabled())
        test.assert_true(view.mainsAltsLines[2].promoteButton:IsEnabled())
        test.assert_true(view.mainsAltsLines[2].removeButton:IsEnabled())
        test.assert_true(view.mainsAltsLines[1].noteButton:IsEnabled())
        test.assert_true(view.groupButton:IsEnabled())
        harness.ui.CompleteRosterScan()
        test.assert_false(view.groupButton:IsEnabled())
        test.assert_false(view.mainsAltsLines[1].checkbox:GetChecked())
        test.assert_false(view.mainsAltsLines[4].checkbox:GetChecked())
        harness.ui.CompleteMainsAltsChange("main-area52")
        test.assert_false(view.groupButton:IsEnabled())
        test.assert_true(view.expandedMainsAlts["main-area52"])
        test.assert_false(view.mainsAltsLines[1].checkbox:GetChecked())
        test.assert_false(view.mainsAltsLines[4].checkbox:GetChecked())
        harness.ui.CompleteMainsAltsChange(nil)
        test.assert_nil(next(view.expandedMainsAlts))
        harness.ui.CompleteMainsAltsGrouping("main-area52")
        test.assert_false(view.groupButton:IsEnabled())
        test.assert_true(view.expandedMainsAlts["main-area52"])
        test.assert_false(view.mainsAltsLines[1].checkbox:GetChecked())
        harness.ui.Hide()
        test.assert_equal(view.mainsAltsLines[2].name.text, "Solo-Area52")
        test.assert_equal(view.mainsAltsLines[2].name.textColor, {
            0.957, 0.957, 0.961, 1,
        })
        test.assert_equal(view.mainsAltsLines[3].name.text, "Other-Area52 (+1)")
        test.assert_false(view.mainsAltsLinePool[4].frame:IsShown())
    end),

    test.case("ByName recycles a bounded row pool for very large guilds", function()
        local harness = newHarness()
        harness.ui.Initialize()
        local view = harness.frame().views.mainsalts
        view.scrollFrame:SetHeight(72)
        harness.ui.SetMainsAltsReport(mainsAltsReport(300))

        test.assert_equal(#view.mainsAltsRows, 300)
        test.assert_equal(view.mainsAltsTableHeight, 7208)
        test.assert_true(view.scrollFrame.ScrollBar:IsShown())
        test.assert_true(#view.mainsAltsLinePool <= 5)
        test.assert_equal(view.mainsAltsLines[1].identity, "char01-area52")

        local row150Offset = 4 + (149 * 24)
        view.scrollFrame.scripts.OnVerticalScroll(view.scrollFrame, row150Offset)

        test.assert_equal(view.scrollFrame:GetVerticalScroll(), row150Offset)
        test.assert_true(#view.mainsAltsLinePool <= 5)
        test.assert_nil(view.mainsAltsLines[1])
        test.assert_equal(view.mainsAltsLines[150].identity, "char150-area52")

        local poolSize = #view.mainsAltsLinePool
        view.mainsAltsLines[150].checkbox:SetChecked(true)
        view.mainsAltsLines[150].checkbox.scripts.OnClick(
            view.mainsAltsLines[150].checkbox
        )
        test.assert_true(view.mainsAltsSelections["char150-area52"])
        view.scrollFrame.scripts.OnVerticalScroll(view.scrollFrame, row150Offset + 24)
        test.assert_equal(view.mainsAltsLines[151].identity, "char151-area52")
        test.assert_equal(#view.mainsAltsLinePool, poolSize)
        view.mainsAltsLines[151].checkbox:SetChecked(true)
        view.mainsAltsLines[151].checkbox.scripts.OnClick(
            view.mainsAltsLines[151].checkbox
        )
        test.assert_true(view.mainsAltsSelections["char151-area52"])
    end),

    test.case("ByName search filters full groups and preserves hidden selections", function()
        local harness = newHarness()
        harness.ui.Initialize()
        harness.ui.Show()
        harness.ui.SelectPrimaryTab("mainsalts")
        local view = harness.frame().views.mainsalts
        local report = {
            rows = {
                {
                    name = "Main",
                    identity = "main-area52",
                    displayName = "Main-Area52",
                    altCount = 2,
                    alts = {
                        {
                            name = "OtherAlt",
                            identity = "otheralt-area52",
                            displayName = "OtherAlt-Area52",
                            searchableNotes = { "secret identity" },
                        },
                        {
                            name = "Mountvesuvius",
                            identity = "mountvesuvius-area52",
                            displayName = "Mountvesuvius-Area52",
                        },
                    },
                },
                {
                    name = "Solo",
                    identity = "solo-area52",
                    displayName = "Solo-Area52",
                    altCount = 0,
                    alts = {},
                },
            },
        }
        harness.ui.SetMainsAltsReport(report)

        view.mainsAltsLines[2].checkbox:SetChecked(true)
        view.mainsAltsLines[2].checkbox.scripts.OnClick(
            view.mainsAltsLines[2].checkbox
        )
        view.scrollFrame:SetVerticalScroll(25)
        view.mainsAltsSearchBox:SetText("m t v s")

        test.assert_equal(view.mainsAltsLines[1].name.text, "Main-Area52 (+2)")
        test.assert_equal(view.mainsAltsLines[2].name.text, "OtherAlt-Area52")
        test.assert_equal(view.mainsAltsLines[3].name.text, "Mountvesuvius-Area52")
        test.assert_false(view.mainsAltsLines[1].isFilterMatch)
        test.assert_false(view.mainsAltsLines[2].isFilterMatch)
        test.assert_true(view.mainsAltsLines[3].isFilterMatch)
        test.assert_equal(view.mainsAltsLines[3].background.vertexColor, {
            0.231,
            0.137,
            0.192,
            1,
        })
        view.mainsAltsLines[3].frame.scripts.OnEnter()
        test.assert_equal(
            view.mainsAltsLines[3].background.vertexColor,
            { 0.133, 0.149, 0.18, 1 }
        )
        view.mainsAltsLines[3].frame.scripts.OnLeave()
        test.assert_equal(view.mainsAltsLines[3].background.vertexColor, {
            0.231,
            0.137,
            0.192,
            1,
        })
        test.assert_true(view.expandedMainsAlts["main-area52"])
        test.assert_equal(view.scrollFrame:GetVerticalScroll(), 0)

        view.mainsAltsLines[1].expandButton.scripts.OnClick()
        test.assert_false(view.expandedMainsAlts["main-area52"] == true)
        view.mainsAltsSearchBox:SetText("MTVS")
        test.assert_true(view.expandedMainsAlts["main-area52"])

        view.mainsAltsSearchBox:SetText("scid")
        test.assert_false(view.mainsAltsLines[1].isFilterMatch)
        test.assert_true(view.mainsAltsLines[2].isFilterMatch)
        test.assert_false(view.mainsAltsLines[3].isFilterMatch)

        view.mainsAltsLines[1].checkbox:SetChecked(true)
        view.mainsAltsLines[1].checkbox.scripts.OnClick(
            view.mainsAltsLines[1].checkbox
        )
        test.assert_true(view.groupButton:IsEnabled())
        view.groupButton.scripts.OnClick()
        test.assert_equal(harness.groupingRequests[1], {
            "main-area52",
            "solo-area52",
        })

        view.mainsAltsSearchClear.scripts.OnClick()
        test.assert_equal(view.mainsAltsSearchBox:GetText(), "")
        test.assert_true(view.mainsAltsSearchBox:HasFocus())
        test.assert_nil(next(view.expandedMainsAlts))
        test.assert_equal(view.mainsAltsLines[2].name.text, "Solo-Area52")
        test.assert_false(view.mainsAltsLines[1].isFilterMatch)
        test.assert_false(view.mainsAltsLines[2].isFilterMatch)
        test.assert_true(view.mainsAltsLines[1].checkbox:GetChecked())
        test.assert_true(view.mainsAltsLines[2].checkbox:GetChecked())
    end),

    test.case("ByName search follows keyboard lifecycle report and lock rules", function()
        local harness = newHarness()
        harness.ui.Initialize()
        harness.ui.Show()
        harness.ui.SelectPrimaryTab("mainsalts")
        local view = harness.frame().views.mainsalts
        local report = {
            rows = {
                {
                    name = "Main",
                    identity = "main-area52",
                    displayName = "Main-Area52",
                    altCount = 1,
                    alts = {
                        {
                            name = "Mountvesuvius",
                            identity = "mountvesuvius-area52",
                            displayName = "Mountvesuvius-Area52",
                        },
                    },
                },
                {
                    name = "Solo",
                    identity = "solo-area52",
                    displayName = "Solo-Area52",
                    altCount = 0,
                    alts = {},
                },
            },
        }
        harness.ui.SetMainsAltsReport(report)

        view.mainsAltsSearchBox:SetText("mtvs")
        view.mainsAltsLines[1].expandButton.scripts.OnClick()
        test.assert_false(view.expandedMainsAlts["main-area52"] == true)
        harness.ui.SetMainsAltsReport(report)
        test.assert_true(view.expandedMainsAlts["main-area52"])

        test.assert_true(harness.ui.SetGlobalScanLock(true))
        test.assert_false(view.mainsAltsSearchBox:IsEnabled())
        test.assert_equal(view.mainsAltsSearchBox:GetText(), "mtvs")
        harness.ui.SetMainsAltsReport(report)
        test.assert_true(view.expandedMainsAlts["main-area52"])
        test.assert_true(harness.ui.SetGlobalScanLock(false))
        test.assert_true(view.mainsAltsSearchBox:IsEnabled())

        harness.ui.SetMainsAltsAvailable(false)
        test.assert_false(view.mainsAltsSearchBox:IsEnabled())
        test.assert_equal(view.mainsAltsSearchBox:GetText(), "mtvs")
        harness.ui.SetMainsAltsAvailable(true)

        view.mainsAltsSearchBox:SetText("solo")
        view.mainsAltsSearchBox:SetFocus()
        view.mainsAltsSearchBox.scripts.OnEnterPressed(view.mainsAltsSearchBox)
        test.assert_equal(view.mainsAltsSearchBox:GetText(), "solo")
        test.assert_false(view.mainsAltsSearchBox:HasFocus())

        view.mainsAltsSearchBox:SetText("zzz")
        test.assert_true(view.mainsAltsHeader:IsShown())
        test.assert_false(view.mainsAltsLinePool[1].frame:IsShown())
        test.assert_false(view.text:IsShown())

        view.mainsAltsSearchBox:SetFocus()
        view.mainsAltsSearchBox.scripts.OnEscapePressed()
        test.assert_equal(view.mainsAltsSearchBox:GetText(), "")
        test.assert_false(view.mainsAltsSearchBox:HasFocus())
        test.assert_nil(next(view.expandedMainsAlts))

        view.mainsAltsSearchBox:SetText("solo")
        harness.ui.SelectRosterMode("ByTenure")
        test.assert_equal(view.mainsAltsSearchBox:GetText(), "solo")
        harness.ui.SelectPrimaryTab("bank")
        harness.ui.SelectPrimaryTab("roster")
        test.assert_equal(view.mainsAltsSearchBox:GetText(), "solo")

        harness.ui.SelectRosterMode("ByName")
        test.assert_nil(harness.database.ui.mainsAltsSearchQuery)
        harness.ui.Hide()
        test.assert_equal(view.mainsAltsSearchBox:GetText(), "")
    end),

    test.case("ByName tag icons edit filter intersect and follow transient lifecycle", function()
        local harness = newHarness()
        harness.ui.Initialize()
        harness.ui.Show()
        harness.ui.SelectPrimaryTab("mainsalts")
        local view = harness.frame().views.mainsalts
        local report = {
            tagCatalog = { "me", "raid", "tank" },
            rows = {
                {
                    name = "Main",
                    identity = "main-area52",
                    displayName = "Main-Area52",
                    tags = {},
                    altCount = 1,
                    alts = {
                        {
                            name = "RaidAlt",
                            identity = "raidalt-area52",
                            displayName = "RaidAlt-Area52",
                            tags = { "raid" },
                        },
                    },
                },
                {
                    name = "Solo",
                    identity = "solo-area52",
                    displayName = "Solo-Area52",
                    tags = { "me" },
                    altCount = 0,
                    alts = {},
                },
            },
        }
        harness.ui.SetMainsAltsReport(report)

        test.assert_equal(view.mainsAltsHeader.tags.text, "")
        test.assert_equal(
            view.mainsAltsLines[1].tagButton.icon.texture,
            "Interface\\AddOns\\RGMS\\assets\\icons\\tag.png"
        )
        test.assert_equal(
            view.mainsAltsLines[1].tagButton.icon.vertexColor,
            { 0.55, 0.55, 0.55, 0.65 }
        )
        test.assert_equal(
            view.mainsAltsLines[2].tagButton.icon.vertexColor,
            { 1, 0.82, 0.2, 1 }
        )
        test.assert_equal(view.mainsAltsLines[1].tagButton.width, 16)
        test.assert_equal(view.mainsAltsLines[1].tagButton.x, -236)
        test.assert_true(view.mainsAltsTagFilterButton.tagCapsule ~= nil)
        test.assert_equal(view.mainsAltsTagFilterButton.width, 124)
        test.assert_equal(view.mainsAltsTagFilterButton.height, 28)
        test.assert_equal(view.mainsAltsTagFilterButton.y, 1)
        test.assert_equal(view.mainsAltsTagFilterButton.label.point, "CENTER")
        test.assert_equal(
            view.mainsAltsTagFilterButton.label.relativePoint,
            "CENTER"
        )
        test.assert_equal(view.mainsAltsTagFilterButton.label.y, -1)
        test.assert_equal(
            view.mainsAltsTagFilterButton.label.font,
            {
                "Interface\\AddOns\\RGMS\\assets\\fonts\\Inter-SemiBold.ttf",
                12,
                "",
            }
        )
        local filterCapsule = view.mainsAltsTagFilterButton.tagCapsule
        test.assert_equal(filterCapsule.border.left.width, 14)
        test.assert_equal(filterCapsule.border.left.height, 28)
        test.assert_equal(filterCapsule.border.left.texCoord, { 0, 0.5, 0, 1 })
        test.assert_equal(filterCapsule.border.right.texCoord, { 0.5, 1, 0, 1 })
        test.assert_equal(filterCapsule.border.left.wrapHorizontal, "CLAMP")
        test.assert_equal(filterCapsule.border.left.wrapVertical, "CLAMP")
        test.assert_equal(filterCapsule.border.left.drawLayer, "BACKGROUND")
        test.assert_equal(filterCapsule.border.left.sublevel, -2)
        test.assert_equal(filterCapsule.fill.left.width, 13)
        test.assert_equal(filterCapsule.fill.left.height, 26)
        test.assert_equal(filterCapsule.fill.left.sublevel, -1)
        test.assert_equal(
            view.mainsAltsTagFilterButton.label.drawLayer,
            "OVERLAY"
        )
        view.mainsAltsLines[1].tagButton.scripts.OnEnter()
        test.assert_false(view.mainsAltsTagPreview:IsShown())
        view.mainsAltsLines[2].tagButton.scripts.OnEnter()
        test.assert_true(view.mainsAltsTagPreview:IsShown())
        test.assert_equal(view.mainsAltsTagPreview.point, "TOPRIGHT")
        test.assert_equal(view.mainsAltsTagPreview.relativePoint, "BOTTOMRIGHT")
        test.assert_equal(view.mainsAltsTagPreview.pills[1].label.text, "me")
        test.assert_true(
            view.mainsAltsTagPreview.pills[1].tagCapsule ~= nil
        )
        test.assert_equal(
            view.mainsAltsTagPreview.pills[1].tagCapsule.border.left.texture,
            "Interface\\CharacterFrame\\TempPortraitAlphaMask"
        )
        test.assert_equal(
            view.mainsAltsTagPreview.pills[1].tagCapsule.border.left.width,
            10
        )
        test.assert_equal(
            view.mainsAltsTagPreview.pills[1].label.drawLayer,
            "OVERLAY"
        )
        test.assert_equal(view.mainsAltsTagPreview.pills[1].label.setTextCalls, 2)
        view.mainsAltsLines[2].tagButton.scripts.OnLeave()
        test.assert_false(view.mainsAltsTagPreview:IsShown())

        view.mainsAltsLines[2].checkbox:SetChecked(true)
        view.mainsAltsLines[2].checkbox.scripts.OnClick(view.mainsAltsLines[2].checkbox)
        view.mainsAltsTagFilterButton.scripts.OnClick()
        test.assert_true(view.mainsAltsTagFilter:IsShown())
        test.assert_equal(view.mainsAltsTagFilter.pills[2].label.text, "raid")
        test.assert_true(view.mainsAltsTagFilter.pills[2].tagCapsule ~= nil)
        view.mainsAltsTagFilter.pills[2].scripts.OnClick(
            view.mainsAltsTagFilter.pills[2]
        )
        test.assert_equal(
            view.mainsAltsTagFilterButton.label.text,
            "Tags... (1)"
        )
        local filterTextHistory = view.mainsAltsTagFilterButton.label.textHistory
        test.assert_equal(
            filterTextHistory[#filterTextHistory - 1],
            ""
        )
        test.assert_equal(
            filterTextHistory[#filterTextHistory],
            "Tags... (1)"
        )
        test.assert_equal(view.mainsAltsLines[1].identity, "main-area52")
        test.assert_equal(view.mainsAltsLines[2].identity, "raidalt-area52")
        test.assert_false(view.mainsAltsLines[1].isFilterMatch)
        test.assert_true(view.mainsAltsLines[2].isFilterMatch)
        test.assert_true(view.expandedMainsAlts["main-area52"])
        test.assert_true(view.mainsAltsSelections["solo-area52"])

        view.mainsAltsLines[1].checkbox:SetChecked(true)
        view.mainsAltsLines[1].checkbox.scripts.OnClick(view.mainsAltsLines[1].checkbox)
        test.assert_true(view.groupButton:IsEnabled())
        view.mainsAltsLines[1].expandButton.scripts.OnClick()
        test.assert_false(view.expandedMainsAlts["main-area52"] == true)
        view.mainsAltsSearchBox:SetText("")
        test.assert_true(view.expandedMainsAlts["main-area52"])

        view.mainsAltsSearchBox:SetText("main")
        test.assert_false(view.mainsAltsLinePool[1].frame:IsShown())
        view.mainsAltsSearchBox:SetText("")
        test.assert_equal(view.mainsAltsLines[2].identity, "raidalt-area52")

        view.mainsAltsLines[2].tagButton.scripts.OnClick()
        test.assert_true(view.mainsAltsTagEditor:IsShown())
        test.assert_equal(view.mainsAltsTagEditor.point, "TOPRIGHT")
        test.assert_equal(view.mainsAltsTagEditor.relativePoint, "BOTTOMRIGHT")
        test.assert_true(view.mainsAltsTagEditor.input:HasFocus())
        test.assert_false(view.mainsAltsTagDismissLayer:IsShown())
        report.rows[1].tags = { "me" }
        view.mainsAltsLines[1].tagButton.scripts.OnEnter()
        test.assert_false(view.mainsAltsTagPreview:IsShown())
        report.rows[1].tags = {}
        test.assert_equal(view.mainsAltsTagEditor.pills[1].label.text, "me")
        test.assert_false(view.mainsAltsTagEditor.pills[1].selected)
        test.assert_true(view.mainsAltsTagEditor.pills[2].selected)
        test.assert_true(view.mainsAltsTagEditor.pills[1].tagCapsule ~= nil)
        test.assert_true(view.mainsAltsTagEditor.input.tagCapsule ~= nil)
        view.mainsAltsTagEditor.pills[3].scripts.OnClick(
            view.mainsAltsTagEditor.pills[3]
        )
        test.assert_equal(harness.tagToggles[1], {
            identity = "raidalt-area52",
            name = "tank",
        })
        view.mainsAltsTagEditor.input:SetText(string.rep("x", 33))
        test.assert_equal(#view.mainsAltsTagEditor.input:GetText(), 32)
        view.mainsAltsTagEditor.input.scripts.OnEnterPressed(
            view.mainsAltsTagEditor.input
        )
        test.assert_equal(harness.tagAssignments[1], {
            identity = "raidalt-area52",
            value = string.rep("x", 32),
        })
        test.assert_equal(view.mainsAltsTagEditor.input:GetText(), "")
        test.assert_true(view.mainsAltsTagEditor.input:HasFocus())
        view.mainsAltsTagEditor.input.scripts.OnEscapePressed()
        test.assert_false(view.mainsAltsTagEditor:IsShown())
        view.mainsAltsLines[2].tagButton.scripts.OnClick()
        test.assert_true(view.mainsAltsTagEditor:IsShown())
        view.mainsAltsTagEditor.input:SetText("discard me")
        view.mainsAltsTagEditor.mouseOver = true
        view.mainsAltsTagMouseListener.scripts.OnEvent(
            view.mainsAltsTagMouseListener,
            "GLOBAL_MOUSE_DOWN",
            "LeftButton"
        )
        test.assert_true(view.mainsAltsTagEditor:IsShown())
        test.assert_equal(view.mainsAltsTagEditor.input:GetText(), "discard me")
        view.mainsAltsTagEditor.mouseOver = false
        view.mainsAltsTagMouseListener.scripts.OnEvent(
            view.mainsAltsTagMouseListener,
            "GLOBAL_MOUSE_DOWN",
            "LeftButton"
        )
        test.assert_false(view.mainsAltsTagEditor:IsShown())
        test.assert_equal(view.mainsAltsTagEditor.input:GetText(), "")
        test.assert_equal(#harness.tagAssignments, 1)
        view.mainsAltsLines[2].tagButton.scripts.OnClick()
        test.assert_true(view.mainsAltsTagEditor:IsShown())
        test.assert_equal(view.mainsAltsTagEditor.input:GetText(), "")
        test.assert_false(view.mainsAltsTagDismissLayer:IsShown())
        view.mainsAltsTagEditor.input:SetText("same character draft")
        view.mainsAltsLines[2].tagButton.mouseOver = true
        view.mainsAltsTagMouseListener.scripts.OnEvent(
            view.mainsAltsTagMouseListener,
            "GLOBAL_MOUSE_DOWN",
            "LeftButton"
        )
        test.assert_true(view.mainsAltsTagEditor:IsShown())
        view.mainsAltsLines[2].tagButton.scripts.OnClick()
        test.assert_false(view.mainsAltsTagEditor:IsShown())
        test.assert_equal(view.mainsAltsTagEditor.input:GetText(), "")
        view.mainsAltsLines[2].tagButton.mouseOver = false

        view.mainsAltsLines[2].tagButton.scripts.OnClick()
        view.mainsAltsTagEditor.input:SetText("different character draft")
        view.mainsAltsLines[1].tagButton.mouseOver = true
        view.mainsAltsTagMouseListener.scripts.OnEvent(
            view.mainsAltsTagMouseListener,
            "GLOBAL_MOUSE_DOWN",
            "LeftButton"
        )
        view.mainsAltsLines[1].tagButton.scripts.OnClick()
        test.assert_true(view.mainsAltsTagEditor:IsShown())
        test.assert_equal(
            view.mainsAltsTagEditor.characterIdentity,
            "main-area52"
        )
        test.assert_equal(view.mainsAltsTagEditor.input:GetText(), "")
        view.mainsAltsLines[1].tagButton.mouseOver = false

        view.mainsAltsLines[2].tagButton.mouseOver = true
        view.mainsAltsTagMouseListener.scripts.OnEvent(
            view.mainsAltsTagMouseListener,
            "GLOBAL_MOUSE_DOWN",
            "LeftButton"
        )
        view.mainsAltsLines[2].tagButton.scripts.OnClick()
        view.mainsAltsLines[2].tagButton.mouseOver = false
        test.assert_equal(
            view.mainsAltsTagEditor.characterIdentity,
            "raidalt-area52"
        )

        report.rows[1].alts[1].tags = {}
        harness.ui.SetMainsAltsReport(report)
        test.assert_false(view.mainsAltsTagEditor:IsShown())
        test.assert_false(view.mainsAltsLinePool[1].frame:IsShown())
        report.rows[1].alts[1].tags = { "raid" }
        harness.ui.SetMainsAltsReport(report)
        test.assert_true(view.expandedMainsAlts["main-area52"])

        view.mainsAltsTagFilterButton.scripts.OnClick()
        test.assert_true(view.mainsAltsTagFilter:IsShown())
        harness.ui.SetGlobalScanLock(true)
        test.assert_false(view.mainsAltsTagFilter:IsShown())
        test.assert_true(view.mainsAltsTagFilters.raid)
        test.assert_false(view.mainsAltsTagFilterButton:IsEnabled())
        harness.ui.SetGlobalScanLock(false)
        test.assert_true(view.mainsAltsTagFilterButton:IsEnabled())

        view.mainsAltsTagFilterButton.scripts.OnClick()
        test.assert_true(view.mainsAltsTagFilter:IsShown())
        view.mainsAltsTagDismissLayer.scripts.OnClick()
        test.assert_false(view.mainsAltsTagFilter:IsShown())
        harness.ui.SelectRosterMode("ByTenure")
        test.assert_true(view.mainsAltsTagFilters.raid)
        harness.ui.SelectRosterMode("ByName")
        test.assert_equal(view.mainsAltsTagFilterButton.label.text, "Tags... (1)")
    end),

    test.case("ByName mutation scrolling waits for the final report and jumps to a clamped row", function()
        local harness = newHarness()
        harness.ui.Initialize()
        harness.ui.Show("mainsalts")
        harness.ui.SelectPrimaryTab("mainsalts")
        local view = harness.frame().views.mainsalts
        view.scrollFrame:SetHeight(72)
        local report = mainsAltsReport(10)
        harness.ui.SetMainsAltsReport(report)

        harness.ui.CompleteMainsAltsChange("char08-area52")
        test.assert_equal(view.scrollFrame:GetVerticalScroll(), 0)
        test.assert_equal(view.pendingMainsAltsScrollTarget, "char08-area52")
        test.assert_nil(view.mainsAltsScrollAnimation)

        local reordered = mainsAltsReport(10)
        reordered.rows[5], reordered.rows[8] = reordered.rows[8], reordered.rows[5]
        harness.ui.SetMainsAltsReport(reordered)
        test.assert_nil(view.pendingMainsAltsScrollTarget)
        test.assert_nil(view.mainsAltsScrollAnimation)
        test.assert_equal(view.scrollFrame:GetVerticalScroll(), 100)
        test.assert_equal(view.scrollChild:GetHeight(), 248)

        harness.ui.CompleteMainsAltsChange("char10-area52")
        harness.ui.SetMainsAltsReport(report)
        test.assert_nil(view.mainsAltsScrollAnimation)
        test.assert_equal(view.scrollFrame:GetVerticalScroll(), 176)
        test.assert_equal(view.scrollChild:GetHeight(), 248)
    end),

    test.case("ByName ordinary renders preserve main ungrouped and expanded-alt anchors", function()
        local harness = newHarness()
        harness.ui.Initialize()
        local view = harness.frame().views.mainsalts
        view.scrollFrame:SetHeight(72)
        local report = mainsAltsReport(8)
        harness.ui.SetMainsAltsReport(report)

        view.scrollFrame:SetVerticalScroll(30)
        local moved = mainsAltsReport(8)
        table.insert(moved.rows, 1, {
            identity = "added-area52",
            displayName = "Added-Area52",
            altCount = 0,
            alts = {},
        })
        harness.ui.SetMainsAltsReport(moved)
        test.assert_equal(view.scrollFrame:GetVerticalScroll(), 54)

        view.scrollFrame:SetVerticalScroll(54)
        local removedAnchor = mainsAltsReport(8)
        table.remove(removedAnchor.rows, 2)
        harness.ui.SetMainsAltsReport(removedAnchor)
        test.assert_equal(view.scrollFrame:GetVerticalScroll(), 54)

        local grouped = {
            rows = {
                {
                    identity = "main-area52",
                    displayName = "Main-Area52",
                    altCount = 2,
                    alts = {
                        { identity = "alta-area52", displayName = "AltA-Area52" },
                        { identity = "altb-area52", displayName = "AltB-Area52" },
                    },
                },
                {
                    identity = "solo-area52",
                    displayName = "Solo-Area52",
                    altCount = 0,
                    alts = {},
                },
            },
        }
        harness.ui.SetMainsAltsReport(grouped)
        harness.ui.ToggleMainsAltsGroup("main-area52")
        view.scrollFrame:SetVerticalScroll(30)
        local withLeadingRow = {
            rows = {
                {
                    identity = "leading-area52",
                    displayName = "Leading-Area52",
                    altCount = 0,
                    alts = {},
                },
                grouped.rows[1],
                grouped.rows[2],
            },
        }
        harness.ui.SetMainsAltsReport(withLeadingRow)
        test.assert_equal(view.scrollFrame:GetVerticalScroll(), 54)
        test.assert_equal(view.mainsAltsLines[3].identity, "alta-area52")
    end),

    test.case("ByName toggles keep the clicked main at the same visible row", function()
        local harness = newHarness()
        harness.ui.Initialize()
        local view = harness.frame().views.mainsalts
        view.scrollFrame:SetHeight(72)
        harness.ui.SetMainsAltsReport({
            rows = {
                {
                    identity = "first-area52",
                    displayName = "First-Area52",
                    altCount = 0,
                    alts = {},
                },
                {
                    identity = "second-area52",
                    displayName = "Second-Area52",
                    altCount = 0,
                    alts = {},
                },
                {
                    identity = "main-area52",
                    displayName = "Main-Area52",
                    altCount = 2,
                    alts = {
                        { identity = "alta-area52", displayName = "AltA-Area52" },
                        { identity = "altb-area52", displayName = "AltB-Area52" },
                    },
                },
                {
                    identity = "last-area52",
                    displayName = "Last-Area52",
                    altCount = 0,
                    alts = {},
                },
            },
        })

        test.assert_true(harness.ui.ToggleMainsAltsGroup("main-area52"))
        view.scrollFrame:SetVerticalScroll(56)
        local expandedMain = view.mainsAltsLines[3]
        test.assert_equal(expandedMain.identity, "main-area52")
        local relativeOffset = expandedMain.offset - view.scrollFrame:GetVerticalScroll()

        test.assert_true(harness.ui.ToggleMainsAltsGroup("main-area52"))
        test.assert_equal(view.scrollFrame:GetVerticalScroll(), 56)
        test.assert_equal(view.mainsAltsLines[3].offset - 56, relativeOffset)

        test.assert_true(harness.ui.ToggleMainsAltsGroup("main-area52"))
        test.assert_equal(view.scrollFrame:GetVerticalScroll(), 56)
        test.assert_equal(view.mainsAltsLines[3].offset - 56, relativeOffset)
    end),

    test.case("ByName target scrolling is immediate and lifecycle input remains stable", function()
        local harness = newHarness()
        harness.ui.Initialize()
        harness.ui.Show("mainsalts")
        harness.ui.SelectPrimaryTab("mainsalts")
        local view = harness.frame().views.mainsalts
        view.scrollFrame:SetHeight(72)
        local report = mainsAltsReport(10)
        harness.ui.SetMainsAltsReport(report)

        local function start(identity)
            harness.ui.CompleteMainsAltsChange(identity)
            harness.ui.SetMainsAltsReport(report)
            test.assert_nil(view.mainsAltsScrollAnimation)
        end

        start("char08-area52")
        local retargetOffset = view.scrollFrame:GetVerticalScroll()
        harness.ui.CompleteMainsAltsChange("char04-area52")
        test.assert_nil(view.mainsAltsScrollAnimation)
        harness.ui.SetMainsAltsReport(report)
        test.assert_equal(view.scrollFrame:GetVerticalScroll(), 76)

        view.scrollFrame.scripts.OnMouseWheel(view.scrollFrame, -1)
        test.assert_nil(view.mainsAltsScrollAnimation)
        local wheelOffset = view.scrollFrame:GetVerticalScroll()
        test.assert_true(wheelOffset > 76)

        start("char08-area52")
        view.scrollFrame.scripts.OnVerticalScroll(view.scrollFrame, 25)
        test.assert_nil(view.mainsAltsScrollAnimation)
        test.assert_equal(view.scrollFrame:GetVerticalScroll(), 25)

        start("char08-area52")
        harness.ui.SelectRosterMode("ByTenure")
        test.assert_nil(view.mainsAltsScrollAnimation)
        test.assert_nil(view.pendingMainsAltsScrollTarget)
        harness.ui.SelectRosterMode("ByName")

        start("char08-area52")
        harness.ui.SetRosterScanInProgress(true)
        test.assert_nil(view.mainsAltsScrollAnimation)
        harness.ui.SetRosterScanInProgress(false)

        start("char08-area52")
        harness.ui.SetMainsAltsAvailable(false)
        test.assert_nil(view.mainsAltsScrollAnimation)
        harness.ui.SetMainsAltsAvailable(true)

        start("char08-area52")
        harness.ui.Hide()
        test.assert_nil(view.mainsAltsScrollAnimation)
        test.assert_equal(view.scrollFrame:GetVerticalScroll(), 0)
    end),

    test.case("ByName missing mutation targets are cleared silently", function()
        local harness = newHarness()
        harness.ui.Initialize()
        harness.ui.Show("mainsalts")
        local view = harness.frame().views.mainsalts
        view.scrollFrame:SetHeight(72)
        local report = mainsAltsReport(8)
        harness.ui.SetMainsAltsReport(report)
        view.scrollFrame:SetVerticalScroll(30)

        harness.ui.CompleteMainsAltsChange("missing-area52")
        harness.ui.SetMainsAltsReport(report)
        test.assert_nil(view.pendingMainsAltsScrollTarget)
        test.assert_nil(view.mainsAltsScrollAnimation)
        test.assert_equal(view.scrollFrame:GetVerticalScroll(), 30)

        harness.ui.SetMainsAltsReport(report)
        test.assert_nil(view.mainsAltsScrollAnimation)
        test.assert_equal(view.scrollFrame:GetVerticalScroll(), 30)
    end),

    test.case("combined character-note editor switches discards limits and saves", function()
        local harness = newHarness()
        harness.ui.Initialize()
        harness.ui.SetMainsAltsReport({
            rows = {
                {
                    identity = "main-area52",
                    displayName = "Main-Area52",
                    note = "Saved main note",
                    hasNote = true,
                    altCount = 0,
                    alts = {},
                },
                {
                    identity = "solo-area52",
                    displayName = "Solo-Area52",
                    note = "",
                    hasNote = false,
                    altCount = 0,
                    alts = {},
                },
            },
        })
        local view = harness.frame().views.mainsalts
        local editor = harness.frame().notesEditor

        test.assert_equal(editor.point, "TOPLEFT")
        test.assert_equal(editor.relativeTo, harness.frame())
        test.assert_equal(editor.relativePoint, "TOPRIGHT")
        test.assert_equal(editor.x, 20)
        test.assert_equal(editor.y, 0)
        test.assert_equal(
            editor.shadow.texture,
            "Interface\\Buttons\\WHITE8X8"
        )
        test.assert_equal(editor.shadow.drawLayer, "BACKGROUND")
        test.assert_equal(editor.shadow.sublevel, -8)
        test.assert_equal(editor.shadow.points[1].x, -6)
        test.assert_equal(editor.shadow.points[1].y, 6)
        test.assert_equal(editor.shadow.points[2].x, 6)
        test.assert_equal(editor.shadow.points[2].y, -6)
        test.assert_equal(editor.shadow.vertexColor, { 0, 0, 0, 0.45 })
        test.assert_equal(editor.textArea.templateName, "BackdropTemplate")
        test.assert_equal(
            editor.textArea.backdropColor,
            { 0.133, 0.149, 0.18, 1 }
        )
        test.assert_equal(editor.fields.privateNote.points[1].x, 20)
        test.assert_equal(editor.fields.privateNote.points[2].x, -20)
        test.assert_equal(editor.fields.officerNote.points[1].y, -78)
        test.assert_equal(editor.fields.publicNote.points[1].y, -198)
        test.assert_equal(editor.fields.privateNote.points[1].y, -318)
        test.assert_equal(editor.fields.privateNote.label.text, "Private Note")
        test.assert_equal(editor.fields.publicNote.label.text, "Public Note")
        test.assert_equal(editor.fields.officerNote.label.text, "Officer Note")
        test.assert_equal(editor.fields.publicNote.helpButton.background.text, "○")
        test.assert_equal(editor.fields.officerNote.helpButton.background.text, "○")
        test.assert_equal(editor.fields.publicNote.helpButton.glyph.text, "?")
        test.assert_equal(editor.fields.officerNote.helpButton.glyph.text, "?")
        test.assert_nil(editor.fields.privateNote.helpButton)
        test.assert_nil(editor.fields.publicNote.scrollFrame.templateName)
        test.assert_nil(editor.fields.officerNote.scrollFrame.templateName)
        test.assert_equal(editor.fields.publicNote.scrollFrame.points[2].x, 0)
        test.assert_equal(editor.fields.officerNote.scrollFrame.points[2].x, 0)
        test.assert_equal(
            editor.fields.privateNote.scrollFrame.templateName,
            "UIPanelScrollFrameTemplate"
        )
        test.assert_equal(editor.fields.privateNote.scrollFrame.points[2].x, -18)
        test.assert_not_nil(editor.fields.publicNote.readOnlyOverlay)
        test.assert_not_nil(editor.fields.officerNote.readOnlyOverlay)
        test.assert_equal(#editor.fields.publicNote.readOnlyOverlay.stripes, 24)
        test.assert_true(editor.fields.publicNote.readOnlyOverlay.clipsChildren)
        test.assert_equal(
            editor.fields.publicNote.readOnlyOverlay.stripes[1]:GetHeight(),
            5
        )
        test.assert_equal(
            editor.fields.publicNote.readOnlyOverlay.stripes[1].rotation,
            math.pi / 4
        )
        test.assert_equal(
            editor.fields.publicNote.readOnlyOverlay.stripes[1].vertexColor[4],
            0.1
        )
        test.assert_false(editor.fields.publicNote.characterCount:IsShown())
        test.assert_false(editor.fields.officerNote.characterCount:IsShown())
        test.assert_true(editor.fields.privateNote.characterCount:IsShown())
        editor.fields.publicNote.helpButton.scripts.OnEnter(
            editor.fields.publicNote.helpButton
        )
        local noteTooltip = harness.frame().ownedTooltip
        test.assert_equal(noteTooltip.title.text, "")
        test.assert_false(noteTooltip.title:IsShown())
        test.assert_equal(
            noteTooltip.body.text,
            "This note is read-only in RGMS. To change it, use the default Guild Roster interface."
        )
        test.assert_nil(noteTooltip.body.text:find("World of Warcraft", 1, true))
        editor.fields.publicNote.helpButton.scripts.OnLeave(
            editor.fields.publicNote.helpButton
        )
        test.assert_false(noteTooltip:IsShown())
        test.assert_nil(editor.editBox.templateName)
        test.assert_equal(editor.editBox:GetWidth(), 370)
        test.assert_equal(editor.editBox:GetHeight(), 116)
        test.assert_equal(editor.editBox.justifyH, "LEFT")
        test.assert_equal(editor.editBox.textInsets, { 8, 8, 8, 8 })

        for index, focusSurface in ipairs({
            editor.textArea,
            editor.scrollFrame,
            editor.editBox,
        }) do
            editor.editBox:ClearFocus()
            focusSurface.scripts.OnMouseDown(
                focusSurface,
                ({ "LeftButton", "RightButton", "MiddleButton" })[index]
            )
            test.assert_true(editor.editBox:HasFocus())
        end

        view.mainsAltsLines[1].noteButton.scripts.OnClick()
        test.assert_true(editor:IsShown())
        test.assert_equal(editor.character.text, "Editing notes for Main-Area52")
        test.assert_equal(editor.editBox:GetText(), "Saved main note")
        test.assert_equal(editor.fields.publicNote.editBox:GetText(), "Live public")
        test.assert_equal(editor.fields.officerNote.editBox:GetText(), "Live officer")
        test.assert_false(editor.fields.publicNote.editBox:IsEnabled())
        test.assert_false(editor.fields.officerNote.editBox:IsEnabled())
        test.assert_nil(editor.deleteButton)

        editor.editBox:SetText("unsaved change")
        view.mainsAltsLines[2].noteButton.scripts.OnClick()
        test.assert_true(editor:IsShown())
        test.assert_equal(editor.characterIdentity, "solo-area52")
        test.assert_equal(editor.editBox:GetText(), "")
        editor.cancelButton.scripts.OnClick()
        test.assert_false(editor:IsShown())
        test.assert_equal(harness.noteSaves, {})

        view.mainsAltsLines[1].noteButton.scripts.OnClick()
        editor.editBox:SetText(string.rep("x", 5501))
        test.assert_equal(#editor.editBox:GetText(), 5500)
        test.assert_true(editor.saveButton:IsEnabled())
        editor.saveButton.scripts.OnClick()
        test.assert_false(editor:IsShown())
        test.assert_equal(harness.noteSaves[1].identity, "main-area52")
        test.assert_equal(#harness.noteSaves[1].privateNote, 5500)
        test.assert_equal(harness.noteSaves[1].publicNote, "Live public")

        view.mainsAltsLines[1].noteButton.scripts.OnClick()
        editor.editBox:SetText("")
        editor.saveButton.scripts.OnClick()
        test.assert_false(editor:IsShown())
        test.assert_equal(harness.noteSaves[2].privateNote, "")

        view.mainsAltsLines[1].noteButton.scripts.OnClick()
        editor.editBox:SetText("discard me")
        editor.closeButton.scripts.OnClick()
        test.assert_false(editor:IsShown())
        test.assert_equal(#harness.noteSaves, 2)

        harness.ui.SetMainsAltsReport({
            rows = {
                {
                    identity = "main-area52",
                    displayName = "Main-Area52",
                    note = "",
                    hasNote = false,
                    altCount = 0,
                    alts = {},
                },
            },
        })
        test.assert_false(view.mainsAltsLines[1].hasNote)
        test.assert_equal(
            view.mainsAltsLines[1].noteButton.icon.vertexColor,
            { 0.55, 0.55, 0.55, 0.65 }
        )

        view.mainsAltsLines[1].noteButton.scripts.OnClick()
        editor.editBox:SetText("discard this removed character edit")
        harness.ui.SetMainsAltsReport({ rows = {} })
        test.assert_false(editor:IsShown())
        test.assert_equal(#harness.noteSaves, 2)
    end),

    test.case("combined note loading read-only and saving states preserve close access", function()
        local harness = newHarness()
        harness.ui.Initialize()
        test.assert_true(harness.ui.OpenCharacterNote(
            "main-area52",
            "Main-Area52",
            "private",
            true
        ))
        local editor = harness.frame().notesEditor
        editor.fields.publicNote.editBox:SetText(string.rep("p", 32))
        editor.fields.officerNote.editBox:SetText(string.rep("o", 32))
        test.assert_equal(#editor.fields.publicNote.editBox:GetText(), 31)
        test.assert_equal(#editor.fields.officerNote.editBox:GetText(), 31)

        harness.ui.SetCharacterNoteState({
            identity = "main-area52",
            displayName = "Main-Area52",
            status = "loading",
            drafts = {
                privateNote = "private draft",
                publicNote = "",
                officerNote = "",
            },
            publicVisible = true,
            publicEditable = false,
            officerVisible = false,
            officerEditable = false,
            loading = true,
            saveEnabled = false,
        })
        test.assert_true(editor.fields.privateNote.editBox:IsEnabled())
        test.assert_false(editor.fields.publicNote.editBox:IsEnabled())
        test.assert_false(editor.fields.officerNote:IsShown())
        test.assert_equal(editor.fields.publicNote.points[1].y, -78)
        test.assert_equal(editor.fields.privateNote.points[1].y, -198)
        test.assert_equal(editor:GetHeight(), 450)
        test.assert_true(editor.guildOverlay.points[1].relativeTo
            == editor.fields.publicNote)
        test.assert_true(editor.guildOverlay:IsShown())
        test.assert_true(editor.guildOverlay.spinning)
        test.assert_false(editor.saveButton:IsEnabled())

        harness.ui.SetCharacterNoteState({
            identity = "main-area52",
            displayName = "Main-Area52",
            status = "saving",
            drafts = {
                privateNote = "private draft",
                publicNote = "public draft",
                officerNote = "officer draft",
            },
            publicVisible = true,
            publicEditable = true,
            officerVisible = true,
            officerEditable = true,
            saving = true,
            saveEnabled = false,
        })
        test.assert_true(editor.operationOverlay:IsShown())
        test.assert_false(editor.fields.privateNote.editBox:IsEnabled())
        test.assert_false(editor.cancelButton:IsEnabled())
        test.assert_true(editor.closeButton:IsEnabled())
    end),

    test.case("roster refresh button starts manual scans and disables while scanning", function()
        local harness = newHarness()
        harness.ui.Initialize()
        local refreshButton = harness.frame().views.roster.refreshButton

        test.assert_equal(refreshButton:GetWidth(), 32)
        test.assert_equal(refreshButton:GetText(), "")
        test.assert_nil(refreshButton.templateName)
        test.assert_equal(refreshButton.icon.width, 18)
        test.assert_equal(
            refreshButton.icon.texture,
            "Interface\\AddOns\\RGMS\\assets\\icons\\refresh-cw.png"
        )
        test.assert_equal(
            refreshButton.icon.vertexColor,
            { 0.957, 0.957, 0.961, 1 }
        )
        refreshButton.scripts.OnEnter(refreshButton)
        test.assert_equal(
            refreshButton.icon.vertexColor,
            { 0.957, 0.447, 0.714, 1 }
        )
        local tooltip = harness.frame().ownedTooltip
        test.assert_true(tooltip:IsShown())
        test.assert_true(tooltip.owner == refreshButton)
        test.assert_equal(tooltip.title.text, "Refresh")
        test.assert_equal(tooltip.body.text, "Refresh the guild roster.")
        refreshButton.scripts.OnMouseDown(refreshButton)
        test.assert_equal(
            refreshButton.icon.vertexColor,
            { 0.925, 0.282, 0.6, 1 }
        )
        refreshButton.scripts.OnMouseUp(refreshButton)
        test.assert_equal(
            refreshButton.icon.vertexColor,
            { 0.957, 0.447, 0.714, 1 }
        )
        refreshButton.scripts.OnLeave(refreshButton)
        test.assert_false(tooltip:IsShown())
        test.assert_equal(
            refreshButton.icon.vertexColor,
            { 0.957, 0.957, 0.961, 1 }
        )

        test.assert_true(refreshButton:IsEnabled())
        refreshButton.scripts.OnClick()
        test.assert_equal(harness.refreshRequests(), 1)

        test.assert_true(harness.ui.SetRosterScanInProgress(true))
        test.assert_false(refreshButton:IsEnabled())
        test.assert_equal(
            refreshButton.icon.vertexColor,
            { 0.443, 0.443, 0.478, 1 }
        )
        test.assert_true(harness.ui.SetRosterScanInProgress(false))
        test.assert_true(refreshButton:IsEnabled())
        test.assert_equal(
            refreshButton.icon.vertexColor,
            { 0.957, 0.957, 0.961, 1 }
        )

        test.assert_true(harness.ui.SetRosterAvailable(false))
        test.assert_false(refreshButton:IsEnabled())
        test.assert_true(harness.ui.SetRosterAvailable(true))
        test.assert_true(refreshButton:IsEnabled())
    end),

    test.case("bank refresh follows bank-open and scan lifecycle restrictions", function()
        local harness = newHarness()
        harness.ui.Initialize()
        local refreshButton = harness.frame().views.bank.refreshButton

        test.assert_equal(refreshButton:GetWidth(), 32)
        test.assert_equal(refreshButton:GetText(), "")
        test.assert_nil(refreshButton.templateName)
        test.assert_equal(
            refreshButton.icon.texture,
            "Interface\\AddOns\\RGMS\\assets\\icons\\refresh-cw.png"
        )
        test.assert_equal(
            refreshButton.icon.vertexColor,
            { 0.443, 0.443, 0.478, 1 }
        )
        refreshButton.scripts.OnEnter(refreshButton)
        local tooltip = harness.frame().ownedTooltip
        test.assert_true(tooltip:IsShown())
        test.assert_true(tooltip.owner == refreshButton)
        test.assert_equal(tooltip.title.text, "Refresh")
        test.assert_equal(tooltip.body.text, "Refresh the guild bank.")
        refreshButton.scripts.OnLeave(refreshButton)
        test.assert_false(tooltip:IsShown())

        test.assert_false(refreshButton:IsEnabled())
        test.assert_true(harness.ui.SetGuildBankOpen(true))
        test.assert_true(refreshButton:IsEnabled())
        test.assert_equal(
            refreshButton.icon.vertexColor,
            { 0.957, 0.957, 0.961, 1 }
        )
        refreshButton.scripts.OnClick()
        test.assert_equal(harness.bankRefreshRequests(), 1)

        test.assert_true(harness.ui.SetBankScanInProgress(true))
        test.assert_false(refreshButton:IsEnabled())
        test.assert_true(harness.ui.SetBankScanInProgress(false))
        test.assert_true(refreshButton:IsEnabled())
        test.assert_true(harness.ui.SetGuildBankOpen(false))
        test.assert_false(refreshButton:IsEnabled())
    end),

    test.case("Provisions renders editor actions progress rows scrolling and scan locking", function()
        local harness = newHarness()
        harness.ui.Initialize()
        local view = harness.frame().views.provisions

        test.assert_true(view.newProvisionButton:IsEnabled())
        test.assert_false(view.saveProvisionButton:IsEnabled())
        test.assert_false(view.refreshButton:IsEnabled())
        harness.ui.SetGuildBankOpen(true)
        test.assert_true(view.refreshButton:IsEnabled())
        view.refreshButton.scripts.OnClick()
        test.assert_equal(harness.bankRefreshRequests(), 1)

        test.assert_true(harness.ui.SetGuildBankBalance(1233452412))
        for _, tabId in ipairs({ "bank", "provisions" }) do
            local balance = harness.frame().views[tabId].guildBankBalanceFrame
            test.assert_true(balance:IsShown())
            test.assert_equal(balance.money, 1233452412)
            test.assert_true(balance.moneyForceShow)
            test.assert_equal(harness.frame().views[tabId].status:GetHeight(), 18)
        end
        test.assert_true(harness.ui.SetGuildBankBalance(nil))
        for _, tabId in ipairs({ "bank", "provisions" }) do
            test.assert_false(
                harness.frame().views[tabId].guildBankBalanceFrame:IsShown()
            )
            test.assert_equal(harness.frame().views[tabId].status:GetHeight(), 40)
        end
        test.assert_true(harness.ui.SetGuildBankBalance(0))
        test.assert_true(view.guildBankBalanceFrame:IsShown())
        test.assert_equal(view.guildBankBalanceFrame.money, 0)

        harness.ui.SetProvisionsEditor({
            selectedId = 7,
            draft = {
                name = "Feast",
                silver = true,
                gold = false,
                targetText = "10",
            },
            valid = true,
            changed = false,
        })
        test.assert_false(view.saveProvisionButton:IsEnabled())
        test.assert_true(view.provisionR1:GetChecked())
        test.assert_false(view.provisionR2:GetChecked())
        test.assert_false(view.provisionEither:GetChecked())
        harness.ui.SetProvisionsEditor({
            selectedId = 7,
            draft = {
                name = "Feast",
                silver = true,
                gold = false,
                targetText = "11",
            },
            valid = true,
            changed = true,
        })
        test.assert_true(view.saveProvisionButton:IsEnabled())

        view.provisionR2.scripts.OnClick()
        local r2Draft = harness.provisionActions[#harness.provisionActions].draft
        test.assert_false(r2Draft.silver)
        test.assert_true(r2Draft.gold)
        test.assert_false(view.provisionR1:GetChecked())
        test.assert_true(view.provisionR2:GetChecked())
        test.assert_false(view.provisionEither:GetChecked())
        view.provisionEither.scripts.OnClick()
        local eitherDraft = harness.provisionActions[#harness.provisionActions].draft
        test.assert_true(eitherDraft.silver)
        test.assert_true(eitherDraft.gold)
        test.assert_false(view.provisionR1:GetChecked())
        test.assert_false(view.provisionR2:GetChecked())
        test.assert_true(view.provisionEither:GetChecked())

        local rows = {}
        for index = 1, 10 do
            rows[index] = {
                id = index == 1 and 7 or index + 10,
                name = "Provision " .. index,
                quality = index == 1 and "silver"
                    or (index == 2 and "gold" or "either"),
                target = 10,
                current = index == 1 and 123 or 0,
                progress = index == 1 and 1 or 0,
                progressText = index == 1 and "123 / 10" or "0 / 10",
                icon = index == 1 and 987654 or 134400,
            }
        end
        harness.ui.SetProvisionsReport({ rows = rows }, 7)
        local first = view.provisionRows[1]
        test.assert_equal(first.icon.texture, 987654)
        test.assert_equal(first.name.text, "Provision 1")
        test.assert_equal(first.name.points[2].point, "TOPRIGHT")
        test.assert_equal(first.name.points[2].relativeTo, first.frame)
        test.assert_equal(first.name.points[2].relativePoint, "TOPRIGHT")
        test.assert_equal(first.name.points[2].y, -11)
        test.assert_equal(first.badge.atlas, "Professions-Icon-Quality-12-Tier1")
        test.assert_true(first.badge:IsShown())
        test.assert_equal(first.progressText.text, "123 / 10")
        test.assert_equal(first.fill.width, 178)
        test.assert_equal(first.deleteIcon.atlas, "common-icon-delete")
        test.assert_equal(first.deleteButton.relativeTo, first.progress)
        test.assert_equal(first.deleteButton.relativePoint, "RIGHT")
        test.assert_equal(first.deleteButton.x, 6)
        test.assert_true(first.deleteButton:IsEnabled())
        test.assert_equal(first.frame.backdropBorderColor, { 0.204, 0.227, 0.275, 1 })
        test.assert_true(first.selectionBorder.top:IsShown())
        test.assert_true(first.selectionBorder.bottom:IsShown())
        test.assert_true(first.selectionBorder.left:IsShown())
        test.assert_true(first.selectionBorder.right:IsShown())
        test.assert_equal(first.selectionBorder.top:GetHeight(), 2)
        test.assert_equal(first.selectionBorder.left:GetWidth(), 2)
        test.assert_equal(view.provisionRows[2].icon.texture, 134400)
        test.assert_equal(
            view.provisionRows[2].badge.atlas,
            "Professions-Icon-Quality-12-Tier2"
        )
        test.assert_true(view.provisionRows[2].badge:IsShown())
        test.assert_false(view.provisionRows[3].badge:IsShown())
        test.assert_false(view.provisionRows[2].selectionBorder.top:IsShown())
        test.assert_false(view.provisionRows[2].fill:IsShown())
        test.assert_true(view.provisionScrollFrame.ScrollBar:IsShown())

        rows[1].name = "Updated Provision"
        harness.ui.SetProvisionsReport({ rows = rows }, 7)
        test.assert_equal(view.provisionRows[1].name.text, "Updated Provision")

        view.provisionRows[2].frame.scripts.OnClick()
        test.assert_equal(harness.provisionActions[#harness.provisionActions], {
            action = "select",
            id = 12,
        })
        view.newProvisionButton.scripts.OnClick()
        test.assert_equal(harness.provisionActions[#harness.provisionActions].action, "new")
        view.saveProvisionButton.scripts.OnClick()
        test.assert_equal(harness.provisionActions[#harness.provisionActions].action, "save")
        view.provisionRows[2].deleteButton.scripts.OnClick()
        test.assert_equal(harness.provisionActions[#harness.provisionActions], {
            action = "delete",
            id = 12,
        })

        harness.ui.Show()
        harness.ui.SelectPrimaryTab("provisions")
        local tabCalls = 0
        for _, action in ipairs(harness.provisionActions) do
            if action.action == "tab" then
                tabCalls = tabCalls + 1
            end
        end
        test.assert_equal(tabCalls, 1)
        harness.ui.SelectPrimaryTab("tags")
        harness.ui.SelectPrimaryTab("provisions")
        test.assert_equal(harness.provisionActions[#harness.provisionActions].action, "tab")

        local preservedName = view.provisionNameInput:GetText()
        harness.ui.SetGlobalScanLock(true)
        test.assert_false(view.newProvisionButton:IsEnabled())
        test.assert_false(view.saveProvisionButton:IsEnabled())
        test.assert_false(view.provisionRows[1].deleteButton:IsEnabled())
        test.assert_equal(view.provisionNameInput:GetText(), preservedName)
        harness.ui.SetGlobalScanLock(false)
        test.assert_true(view.newProvisionButton:IsEnabled())
        harness.ui.SetDataState(false, "corrupt")
        test.assert_false(view.newProvisionButton:IsEnabled())
        test.assert_false(view.guildBankBalanceFrame:IsShown())
        harness.ui.Hide()
        test.assert_equal(harness.provisionActions[#harness.provisionActions].action, "close")
    end),

    test.case("Provision row drag threshold preserves clicks and changed outside drops reorder once", function()
        local harness = newHarness()
        harness.ui.Initialize()
        local view = harness.frame().views.provisions
        view.provisionScrollFrame.left = 100
        view.provisionScrollFrame.bottom = 100
        view.provisionScrollFrame:SetSize(300, 150)
        local rows = {
            {
                id = 1,
                name = "Feast",
                quality = "either",
                progress = 0,
                progressText = "0 / 10",
                icon = 765432,
            },
            { id = 2, name = "Flask", quality = "gold", progress = 0.5, progressText = "5 / 10" },
            { id = 3, name = "Oil", quality = "silver", progress = 1, progressText = "10 / 10" },
        }
        harness.ui.SetProvisionsReport({ rows = rows }, 2)
        harness.ui.SetProvisionsEditor({
            selectedId = 2,
            draft = { name = "Unsaved Flask", gold = true, targetText = "11" },
            valid = true,
            changed = true,
        })

        local first = view.provisionRows[1]
        harness.setCursor(150, 216, true)
        first.frame.scripts.OnMouseDown(first.frame, "LeftButton")
        harness.setCursor(153, 216, true)
        view.provisionDragWatcher.scripts.OnUpdate(nil, 0.1)
        test.assert_false(view.provisionDrag.dragging)
        harness.setCursor(153, 216, false)
        first.frame.scripts.OnMouseUp(first.frame, "LeftButton")
        first.frame.scripts.OnClick(first.frame)
        test.assert_equal(harness.provisionActions[#harness.provisionActions], {
            action = "select",
            id = 1,
        })

        local actionCount = #harness.provisionActions
        harness.setCursor(150, 216, true)
        first.frame.scripts.OnMouseDown(first.frame, "LeftButton")
        harness.setCursor(150, 130, true)
        view.provisionDragWatcher.scripts.OnUpdate(nil, 0.1)
        test.assert_true(view.provisionDrag.dragging)
        test.assert_true(view.provisionDragPreview.frame:IsShown())
        test.assert_true(view.provisionDragPreview.frame.parent == UIParent)
        test.assert_equal(view.provisionDragPreview.frame.frameStrata, "TOOLTIP")
        test.assert_equal(view.provisionDragPreview.frame:GetFrameLevel(), 10000)
        test.assert_equal(view.provisionDragPreview.name.text, "Feast")
        test.assert_equal(view.provisionDragPreview.icon.texture, 765432)
        test.assert_equal(view.provisionDragPreview.frame.x, 100)
        test.assert_equal(view.provisionsReport.rows[1].id, 2)
        test.assert_equal(view.provisionsReport.rows[2].id, 1)
        test.assert_equal(view.provisionRows[2].frame.alpha, 0)
        test.assert_nil(first.frame.scripts.OnDragStart)
        test.assert_nil(first.deleteButton.scripts.OnMouseDown)
        test.assert_nil(first.deleteButton.scripts.OnDragStart)
        test.assert_false(harness.frame().moving == true)

        harness.setCursor(500, 80, false)
        view.provisionDragWatcher.scripts.OnUpdate(nil, 0.1)
        test.assert_nil(view.provisionDrag)
        test.assert_false(view.provisionDragPreview.frame:IsShown())
        test.assert_equal(harness.provisionActions[#harness.provisionActions], {
            action = "reorder",
            ids = { 2, 1, 3 },
        })
        test.assert_equal(view.provisionNameInput:GetText(), "Unsaved Flask")
        test.assert_equal(view.selectedProvisionId, 2)

        first.frame.scripts.OnClick(first.frame)
        test.assert_equal(#harness.provisionActions, actionCount + 1)

        local reorderCountBefore = 0
        for _, action in ipairs(harness.provisionActions) do
            if action.action == "reorder" then
                reorderCountBefore = reorderCountBefore + 1
            end
        end
        local currentFirst = view.provisionRows[1]
        harness.setCursor(150, 216, true)
        currentFirst.frame.scripts.OnMouseDown(currentFirst.frame, "LeftButton")
        harness.setCursor(160, 216, true)
        view.provisionDragWatcher.scripts.OnUpdate(nil, 0.1)
        harness.setCursor(160, 216, false)
        currentFirst.frame.scripts.OnMouseUp(currentFirst.frame, "LeftButton")
        local reorderCountAfter = 0
        for _, action in ipairs(harness.provisionActions) do
            if action.action == "reorder" then
                reorderCountAfter = reorderCountAfter + 1
            end
        end
        test.assert_equal(reorderCountAfter, reorderCountBefore)
    end),

    test.case("Provision drag auto-scrolls beyond both edges and keeps updating its drop", function()
        local harness = newHarness()
        harness.ui.Initialize()
        local view = harness.frame().views.provisions
        view.provisionScrollFrame.left = 100
        view.provisionScrollFrame.bottom = 100
        view.provisionScrollFrame:SetSize(300, 140)
        local rows = {}
        for index = 1, 10 do
            rows[index] = {
                id = index,
                name = "Provision " .. index,
                quality = "either",
                progress = 0,
                progressText = "0 / 10",
            }
        end
        harness.ui.SetProvisionsReport({ rows = rows })

        local first = view.provisionRows[1]
        harness.setCursor(150, 205, true)
        first.frame.scripts.OnMouseDown(first.frame, "LeftButton")
        harness.setCursor(150, 50, true)
        view.provisionDragWatcher.scripts.OnUpdate(nil, 0.5)
        test.assert_equal(view.provisionScrollFrame:GetVerticalScroll(), 60)
        test.assert_true(view.provisionsReport.rows[1].id ~= 1)
        local firstOutsideIndex
        for index, row in ipairs(view.provisionsReport.rows) do
            if row.id == 1 then
                firstOutsideIndex = index
            end
        end

        harness.setCursor(150, -500, true)
        view.provisionDragWatcher.scripts.OnUpdate(nil, 0.5)
        test.assert_equal(view.provisionScrollFrame:GetVerticalScroll(), 120)
        local secondOutsideIndex
        for index, row in ipairs(view.provisionsReport.rows) do
            if row.id == 1 then
                secondOutsideIndex = index
            end
        end
        test.assert_true(secondOutsideIndex > firstOutsideIndex)

        harness.setCursor(500, -500, true)
        view.provisionDragWatcher.scripts.OnUpdate(nil, 1)
        test.assert_equal(view.provisionScrollFrame:GetVerticalScroll(), 120)
        test.assert_equal(view.provisionsReport.rows[secondOutsideIndex].id, 1)

        harness.setCursor(150, 300, true)
        view.provisionDragWatcher.scripts.OnUpdate(nil, 1)
        test.assert_equal(view.provisionScrollFrame:GetVerticalScroll(), 0)
        test.assert_equal(view.provisionsReport.rows[1].id, 1)

        local maximum = view.provisionScrollChild:GetHeight()
            - view.provisionScrollFrame:GetHeight()
        view.provisionScrollFrame:SetVerticalScroll(maximum)
        harness.setCursor(150, 50, true)
        view.provisionDragWatcher.scripts.OnUpdate(nil, 1)
        test.assert_equal(view.provisionScrollFrame:GetVerticalScroll(), maximum)

        harness.setCursor(150, 280, true)
        view.provisionDragWatcher.scripts.OnUpdate(nil, 0.1)
        test.assert_true(view.provisionDragPreview.frame.y > 240)
        test.assert_true(view.provisionDragPreview.frame.parent == UIParent)
        harness.ui.CancelProvisionDrag()
        test.assert_false(view.provisionDragPreview.frame:IsShown())
    end),

    test.case("Provision drag interruptions and persistence failures restore visual state", function()
        local function preparedHarness()
            local harness = newHarness()
            harness.ui.Initialize()
            local view = harness.frame().views.provisions
            view.provisionScrollFrame.left = 100
            view.provisionScrollFrame.bottom = 100
            view.provisionScrollFrame:SetSize(300, 150)
            harness.ui.SetProvisionsReport({ rows = {
                { id = 1, name = "Feast", quality = "either", progress = 0, progressText = "0 / 10" },
                { id = 2, name = "Flask", quality = "gold", progress = 0, progressText = "0 / 10" },
                { id = 3, name = "Oil", quality = "silver", progress = 0, progressText = "0 / 10" },
            } }, 2)
            harness.ui.SetProvisionsEditor({
                selectedId = 2,
                draft = { name = "Unsaved Flask", gold = true, targetText = "11" },
                valid = true,
                changed = true,
            })
            return harness, view
        end
        local function startChangedDrag(harness, view)
            local first = view.provisionRows[1]
            harness.setCursor(150, 216, true)
            first.frame.scripts.OnMouseDown(first.frame, "LeftButton")
            harness.setCursor(150, 130, true)
            view.provisionDragWatcher.scripts.OnUpdate(nil, 0.1)
            test.assert_equal(view.provisionsReport.rows[1].id, 2)
        end
        local function assertRestored(harness, view)
            test.assert_nil(view.provisionDrag)
            test.assert_equal(view.provisionsReport.rows[1].id, 1)
            test.assert_equal(view.provisionsReport.rows[2].id, 2)
            test.assert_equal(view.provisionRows[1].frame.alpha, 1)
            test.assert_equal(view.provisionNameInput:GetText(), "Unsaved Flask")
            test.assert_equal(view.selectedProvisionId, 2)
            for _, action in ipairs(harness.provisionActions) do
                test.assert_false(action.action == "reorder")
            end
        end

        local harness, view = preparedHarness()
        startChangedDrag(harness, view)
        harness.ui.SetGlobalScanLock(true)
        assertRestored(harness, view)
        harness.ui.SetGlobalScanLock(false)

        harness.ui.Show()
        harness.ui.SelectPrimaryTab("provisions")
        startChangedDrag(harness, view)
        harness.ui.SelectPrimaryTab("tags")
        assertRestored(harness, view)

        harness.ui.SelectPrimaryTab("provisions")
        startChangedDrag(harness, view)
        harness.ui.Hide()
        assertRestored(harness, view)

        harness, view = preparedHarness()
        startChangedDrag(harness, view)
        harness.ui.SetDataState(false, "corrupt")
        test.assert_nil(view.provisionDrag)
        for _, action in ipairs(harness.provisionActions) do
            test.assert_false(action.action == "reorder")
        end

        harness, view = preparedHarness()
        harness.setProvisionReorderFailure("simulated storage failure")
        startChangedDrag(harness, view)
        harness.setCursor(500, 80, false)
        view.provisionDragWatcher.scripts.OnUpdate(nil, 0.1)
        test.assert_equal(view.provisionsReport.rows[1].id, 1)
        test.assert_equal(view.provisionsReport.rows[2].id, 2)
        test.assert_equal(view.provisionNameInput:GetText(), "Unsaved Flask")
        test.assert_equal(view.selectedProvisionId, 2)
        test.assert_equal(harness.provisionActions[#harness.provisionActions], {
            action = "reorder",
            ids = { 2, 1, 3 },
        })
    end),

    test.case("success toasts stack newest-first and independently fade reflow and clear", function()
        local harness = newHarness()
        harness.ui.Initialize()
        harness.ui.Show()
        local frame = harness.frame()

        local first = assert(harness.ui.ShowToast("Successfully added Feast"))
        local longest = "Removed " .. string.rep("W", 100) .. " from Provisions"
        local second = assert(harness.ui.ShowToast(longest))

        test.assert_equal(frame.toasts, { second, first })
        test.assert_equal(second.point, "TOP")
        test.assert_equal(second.relativeTo, frame.header)
        test.assert_equal(second.relativePoint, "TOP")
        test.assert_equal(second.y, 10)
        test.assert_equal(first.point, "TOP")
        test.assert_equal(first.relativeTo, second)
        test.assert_equal(first.relativePoint, "BOTTOM")
        test.assert_equal(first.y, -2)
        test.assert_equal(first:GetWidth(), second:GetWidth())
        test.assert_true(second:GetWidth() <= frame:GetWidth() - 2)
        test.assert_true(second:GetParent() == frame)
        test.assert_true(second.text.wordWrap)
        test.assert_true(second.text.nonSpaceWrap)
        test.assert_equal(second.text.maxLines, 0)
        test.assert_equal(second.text.text, longest)
        test.assert_true(second:GetHeight() > first:GetHeight())
        test.assert_equal(second.backdropColor, { 0.059, 0.067, 0.082, 1 })
        test.assert_equal(second.backdropBorderColor, { 0.204, 0.227, 0.275, 1 })
        test.assert_equal(second.accent.vertexColor, { 0.925, 0.282, 0.6, 1 })
        test.assert_equal(second.text.textColor, { 0.957, 0.957, 0.961, 1 })
        test.assert_false(second.mouseEnabled)
        test.assert_true(second:GetFrameLevel() > frame:GetFrameLevel())
        test.assert_true(second:GetFrameLevel() < frame.modalDimmer:GetFrameLevel())
        test.assert_true(second:GetFrameLevel() < frame.globalDimmer:GetFrameLevel())

        first.scripts.OnUpdate(first, 3)
        test.assert_equal(first.alpha, 1)
        second.scripts.OnUpdate(second, 2)
        test.assert_equal(second.alpha, 1)
        first.scripts.OnUpdate(first, 0.5)
        test.assert_equal(first.alpha, 0.5)
        test.assert_equal(second.alpha, 1)

        harness.ui.SelectPrimaryTab("provisions")
        harness.ui.SelectPrimaryTab("tags")
        test.assert_equal(frame.toasts, { second, first })
        test.assert_equal(first.elapsed, 3.5)
        test.assert_equal(second.elapsed, 2)

        first.scripts.OnUpdate(first, 0.5)
        test.assert_equal(frame.toasts, { second })
        test.assert_false(first:IsShown())
        test.assert_equal(second.relativeTo, frame.header)
        test.assert_equal(second.y, 10)

        second.scripts.OnUpdate(second, 2)
        test.assert_equal(#frame.toasts, 0)
        test.assert_false(second:IsShown())

        harness.ui.ShowToast("Successfully added Flask")
        harness.ui.Hide()
        test.assert_equal(#frame.toasts, 0)
    end),

    test.case("disabled saved data explains the recovery path and disables controls", function()
        local harness = newHarness()
        harness.ui.Initialize()
        harness.ui.SetGuildBankOpen(true)

        test.assert_true(harness.ui.SetDataState(false, "corrupt"))

        local frame = harness.frame()
        test.assert_false(frame.views.roster.refreshButton:IsEnabled())
        test.assert_false(frame.views.bank.refreshButton:IsEnabled())
        test.assert_equal(
            frame.views.roster.status.text,
            "Reports and scans unavailable"
        )
        test.assert_equal(
            frame.views.bank.status.text,
            "Reports and scans unavailable"
        )
        test.assert_matches(frame.views.roster.text.text, "Saved data is corrupt")
        test.assert_matches(frame.views.roster.text.text, "/rgms reset")
        test.assert_equal(frame.views.bank.text.text, frame.views.roster.text.text)

        test.assert_true(harness.ui.SetDataState(true))
        test.assert_true(frame.views.roster.refreshButton:IsEnabled())
        test.assert_true(frame.views.bank.refreshButton:IsEnabled())

        test.assert_true(harness.ui.SetDataState(false, "incompatible"))
        test.assert_matches(frame.views.bank.text.text, "Saved data is incompatible")
    end),

    test.case("activity and recovery status changes keep committed reports visible", function()
        local harness = newHarness()
        harness.ui.Initialize()
        local rosterReport = { ranks = { rosterRank(1, "Guild Master") } }
        local bankReport = {
            tabs = {
                {
                    index = 1,
                    name = "Materials",
                    icon = 9001,
                    isViewable = true,
                    lastAccessibleText = "2024-06-22 09:30 PT",
                    rows = {},
                },
            },
        }
        harness.ui.SetRosterReport(rosterReport)
        harness.ui.SetBankReport(bankReport)
        local frame = harness.frame()

        harness.ui.SetRosterScanInProgress(true)
        harness.ui.SetViewStatus("roster", "Updating...")
        harness.ui.SetBankScanInProgress(true)
        harness.ui.SetViewStatus("bank", "Scanning...")
        test.assert_true(frame.views.roster.rosterReport == rosterReport)
        test.assert_true(frame.views.roster.rosterLines[1].frame:IsShown())
        test.assert_true(frame.views.bank.bankReport == bankReport)
        test.assert_true(frame.views.bank.bankMessage:IsShown())

        harness.ui.SetRosterScanInProgress(false)
        harness.ui.SetViewStatus("roster", "Last successful update: prior")
        harness.ui.SetBankScanInProgress(false)
        harness.ui.SetViewStatus("bank", "Last successful scan: prior")
        test.assert_true(frame.views.roster.rosterReport == rosterReport)
        test.assert_true(frame.views.roster.rosterLines[1].frame:IsShown())
        test.assert_true(frame.views.bank.bankReport == bankReport)
        test.assert_true(frame.views.bank.bankMessage:IsShown())
    end),

    test.case("bank tabs render access state rows stale styling tooltips and links", function()
        local harness = newHarness()
        harness.ui.Initialize()
        local itemLink = "|Hitem:1001|h[Ancient Cloth]|h"
        local report = {
            tabs = {
                {
                    index = 1,
                    name = "Materials",
                    icon = 9001,
                    isViewable = true,
                    lastAccessibleText = "2024-06-22 09:30 PT",
                    rows = {
                        {
                            tabIndex = 1,
                            tabName = "Materials",
                            slotIndex = 4,
                            itemId = 1001,
                            itemLink = itemLink,
                            itemName = "Ancient Cloth",
                            icon = 8001,
                            quantity = 20,
                            stableSinceDate = "2024-06-01",
                            ageDays = 21,
                            isStale = true,
                        },
                    },
                },
                {
                    index = 2,
                    name = "Restricted",
                    icon = 9002,
                    isViewable = false,
                    lastAccessibleText = "2024-06-20 08:00 PT",
                    rows = {},
                },
                {
                    index = 3,
                    name = "Never Seen",
                    icon = 9003,
                    isViewable = false,
                    rows = {},
                },
                {
                    index = 4,
                    name = "Empty",
                    icon = 9004,
                    isViewable = true,
                    lastAccessibleText = "2024-06-22 09:35 PT",
                    rows = {},
                },
            },
        }

        test.assert_true(harness.ui.SetBankReport(report))
        local view = harness.frame().views.bank
        test.assert_equal(view.bankTabButtons[1].text, "   Materials")
        test.assert_equal(view.bankTabButtons[1].icon.texture, 9001)
        test.assert_equal(view.bankDropdown.label.text, "Materials")
        test.assert_equal(view.bankDropdown.icon.texture, 9001)
        test.assert_equal(view.bankRows[1].item.text, "Ancient Cloth")
        test.assert_nil(view.bankRows[1].tab)
        test.assert_equal(view.bankRows[1].slot.text, "4")
        test.assert_equal(view.bankRows[1].slot.parent, view.bankRows[1].slotCell)
        test.assert_equal(view.bankRows[1].slotCell:GetWidth(), 56)
        test.assert_equal(view.bankHeader.slot.justifyH, "CENTER")
        test.assert_equal(view.bankRows[1].slot.justifyH, "CENTER")
        test.assert_equal(view.bankRows[1].count.text, "20")
        test.assert_equal(view.bankHeader.count.justifyH, "CENTER")
        test.assert_equal(view.bankRows[1].count.justifyH, "CENTER")
        test.assert_equal(view.bankRows[1].count:GetWidth(), 64)
        test.assert_equal(view.bankRows[1].stable.text, "2024-06-01")
        test.assert_equal(view.bankRows[1].age.text, "|cffff555521 days|r")

        view.bankRows[1].itemButton.scripts.OnEnter()
        test.assert_true(harness.tooltip.shown)
        test.assert_equal(harness.tooltip.hyperlink, itemLink)
        view.bankRows[1].itemButton.scripts.OnClick()
        test.assert_equal(harness.modifiedItemClicks, { itemLink })
        view.bankRows[1].itemButton.scripts.OnLeave()
        test.assert_false(harness.tooltip.shown)

        view.bankTabButtons[2].scripts.OnClick()
        test.assert_equal(view.selectedBankTabIndex, 2)
        test.assert_equal(view.bankMessage.text, "|cffff5555No access|r")
        test.assert_equal(view.bankDropdown.label.text, "Restricted")
        test.assert_false(view.bankRows[1].frame:IsShown())

        view.bankTabButtons[3].scripts.OnClick()
        test.assert_equal(view.bankMessage.text, "|cffff5555No access|r")
        test.assert_equal(view.bankDropdown.label.text, "Never Seen")

        view.bankTabButtons[4].scripts.OnClick()
        test.assert_equal(view.bankMessage.text, "|cff888888No occupied slots|r")
        test.assert_equal(view.bankDropdown.label.text, "Empty")
    end),

    test.case("large bank tab and inventory lists scroll inside the fixed view", function()
        local harness = newHarness()
        harness.ui.Initialize()
        local report = { tabs = {} }
        for tabIndex = 1, 30 do
            local tab = {
                index = tabIndex,
                name = "Tab " .. tabIndex,
                icon = 9000 + tabIndex,
                isViewable = true,
                lastAccessibleText = "2024-06-22 09:30 PT",
                rows = {},
            }
            report.tabs[tabIndex] = tab
        end
        for slotIndex = 1, 98 do
            report.tabs[1].rows[slotIndex] = {
                tabIndex = 1,
                tabName = "Tab 1",
                slotIndex = slotIndex,
                itemId = 1000 + slotIndex,
                itemLink = "|Hitem:1|h[Test Item]|h",
                itemName = "Test Item " .. slotIndex,
                icon = 8000,
                quantity = 1,
                stableSinceDate = "2024-06-01",
                ageDays = 21,
                isStale = true,
            }
        end

        harness.ui.SetBankReport(report)
        local view = harness.frame().views.bank
        test.assert_true(
            view.bankTabScrollChild:GetHeight() > view.bankTabScrollFrame:GetHeight()
        )
        test.assert_true(view.scrollChild:GetHeight() > view.scrollFrame:GetHeight())
        test.assert_true(view.scrollFrame.ScrollBar:IsShown())
    end),

    test.case("bank item scrollbar appears only when the selected tab overflows", function()
        local harness = newHarness()
        harness.ui.Initialize()
        local view = harness.frame().views.bank
        view.scrollFrame:SetHeight(76)

        local report = { tabs = {} }
        for tabIndex = 1, 2 do
            local tab = {
                index = tabIndex,
                name = "Tab " .. tabIndex,
                icon = 9000 + tabIndex,
                isViewable = true,
                rows = {},
            }
            local rowCount = tabIndex == 1 and 3 or 4
            for slotIndex = 1, rowCount do
                tab.rows[slotIndex] = {
                    slotIndex = slotIndex,
                    itemLink = "|Hitem:1|h[Test Item]|h",
                    itemName = "Test Item " .. slotIndex,
                    icon = 8000,
                    quantity = 1,
                    stableSinceDate = "2024-06-01",
                    ageDays = 21,
                    isStale = true,
                }
            end
            report.tabs[tabIndex] = tab
        end

        test.assert_true(harness.ui.SetBankReport(report))
        test.assert_equal(view.scrollChild:GetHeight(), view.scrollFrame:GetHeight())
        test.assert_false(view.scrollFrame.ScrollBar:IsShown())

        test.assert_true(harness.ui.SelectBankTab(2))
        test.assert_true(view.scrollChild:GetHeight() > view.scrollFrame:GetHeight())
        test.assert_true(view.scrollFrame.ScrollBar:IsShown())

        test.assert_true(harness.ui.SelectBankTab(1))
        test.assert_false(view.scrollFrame.ScrollBar:IsShown())
    end),

    test.case("ByName scrollbar appears only when character rows overflow", function()
        local harness = newHarness()
        harness.ui.Initialize()
        local view = harness.frame().views.mainsalts
        view.scrollFrame:SetHeight(80)

        test.assert_true(harness.ui.SetMainsAltsReport(mainsAltsReport(3)))
        test.assert_equal(view.scrollChild:GetHeight(), view.scrollFrame:GetHeight())
        test.assert_false(view.scrollFrame.ScrollBar:IsShown())

        test.assert_true(harness.ui.SetMainsAltsReport(mainsAltsReport(4)))
        test.assert_true(view.scrollChild:GetHeight() > view.scrollFrame:GetHeight())
        test.assert_true(view.scrollFrame.ScrollBar:IsShown())

        test.assert_true(harness.ui.SetMainsAltsReport(mainsAltsReport(3)))
        test.assert_false(view.scrollFrame.ScrollBar:IsShown())
    end),

    test.case("closing RGMS preserves a bank scan and committed bank content", function()
        local harness = newHarness()
        harness.ui.Initialize()
        harness.ui.SetViewContent("bank", "Previously committed bank report")
        harness.ui.Show("bank")

        harness.frame().closeButton.scripts.OnClick()

        test.assert_equal(harness.bankCancellations(), 0)
        test.assert_equal(
            harness.frame().views.bank.text.text,
            "Previously committed bank report"
        )
    end),

    test.case("roster rank tabs render all brackets and selection is observation-safe", function()
        local harness = newHarness()
        harness.database.roster = {
            members = { { displayName = "Stored-Example Realm" } },
        }
        local expectedObservations = {
            members = { { displayName = "Stored-Example Realm" } },
        }
        harness.ui.Initialize()

        local first = rosterRank(1, "Guild Master")
        first.groups[1].members[1] = {
            displayName = "Current-Example Realm",
            classFileName = "MAGE",
            lastOnlineText = "5 hours ago",
            tenureDays = 12,
        }
        local second = rosterRank(7, "Trial", "Trial (Rank 7)")
        local report = { ranks = { first, second } }

        test.assert_true(harness.ui.SetRosterReport(report))
        local view = harness.frame().views.roster
        test.assert_equal(view.rankButtons[1].text, "Guild Master")
        test.assert_equal(view.rankButtons[2].text, "Trial")
        local tableText = rosterTableText(view)
        test.assert_matches(tableText, "Current%-Example Realm")
        test.assert_matches(tableText, "5 hours ago")
        test.assert_matches(tableText, "12 days")
        test.assert_false(string.find(tableText, " | ", 1, true) ~= nil)
        local memberLine = view.rosterLines[2]
        test.assert_equal(view.rosterLines[1].primary.textColor, {
            0.957, 0.957, 0.961, 1,
        })
        test.assert_equal(memberLine.primary.text, "Current-Example Realm")
        test.assert_equal(memberLine.primary.textColor, {
            0.25, 0.78, 0.92, 1,
        })
        test.assert_equal(memberLine.secondary.text, "5 hours ago")
        test.assert_equal(memberLine.tertiary.text, "12 days")

        view.rankButtons[2].scripts.OnClick()
        test.assert_equal(view.selectedRankIndex, 7)
        test.assert_equal(harness.database.roster, expectedObservations)
        tableText = rosterTableText(view)
        test.assert_equal(select(2, string.gsub(tableText, EMPTY_TEXT, "")), 4)
    end),

    test.case("missing roster rows show a warning with the RGMS hover tooltip", function()
        local harness = newHarness()
        harness.ui.Initialize()
        local first = rosterRank(1, "Guild Master")
        first.groups[1].members = {
            {
                displayName = "Current-Example Realm",
                lastOnlineText = "Online",
                tenureDays = 30,
                isMissing = false,
            },
            {
                displayName = "Missing-Example Realm",
                lastOnlineText = "10 days ago",
                tenureDays = 20,
                isMissing = true,
                missingLastSeenDate = "2024-05-22",
            },
        }

        test.assert_true(harness.ui.SetRosterReport({ ranks = { first } }))
        local view = harness.frame().views.roster
        local currentLine = view.rosterLines[2]
        local missingLine = view.rosterLines[3]

        test.assert_false(currentLine.warningIndicator:IsShown())
        test.assert_true(missingLine.warningIndicator:IsShown())
        test.assert_equal(
            missingLine.warningIndicator.points[1].x,
            0
        )

        missingLine.warningIndicator.scripts.OnEnter()
        local tooltip = harness.frame().ownedTooltip
        test.assert_true(tooltip:IsShown())
        test.assert_true(tooltip.owner == missingLine.warningIndicator)
        test.assert_equal(tooltip.title.text, "Missing roster member")
        test.assert_matches(tooltip.body.text, "Last appeared %(Pacific%): 2024%-05%-22")

        missingLine.warningIndicator.scripts.OnLeave()
        test.assert_false(tooltip:IsShown())

        local otherOwner = {}
        harness.tooltip.owner = otherOwner
        harness.tooltip.shown = true
        missingLine.warningIndicator.scripts.OnLeave()
        test.assert_true(harness.tooltip.shown)
        test.assert_equal(harness.tooltip.owner, otherOwner)

        missingLine.warningIndicator.scripts.OnEnter()
        local reappeared = rosterRank(1, "Guild Master")
        reappeared.groups[1].members[1] = {
            displayName = "Missing-Example Realm",
            lastOnlineText = "Online",
            tenureDays = 0,
            isMissing = false,
        }
        test.assert_true(harness.ui.SetRosterReport({ ranks = { reappeared } }))
        test.assert_false(view.rosterLines[2].warningIndicator:IsShown())
        test.assert_false(tooltip:IsShown())
        test.assert_true(harness.tooltip.shown)
    end),

    test.case("long rank and member lists scroll inside the fixed roster view", function()
        local harness = newHarness()
        harness.ui.Initialize()
        local report = { ranks = {} }
        for index = 1, 30 do
            report.ranks[index] = rosterRank(index, "Rank " .. index)
        end
        for index = 1, 100 do
            report.ranks[1].groups[1].members[index] = {
                displayName = string.format("Member%03d-Example Realm", index),
                lastOnlineText = "1 day ago",
                tenureDays = 10,
            }
        end

        harness.ui.SetRosterReport(report)
        local view = harness.frame().views.roster
        test.assert_true(
            view.rankScrollChild:GetHeight() > view.rankScrollFrame:GetHeight()
        )
        test.assert_true(view.scrollChild:GetHeight() > view.scrollFrame:GetHeight())
        test.assert_true(view.scrollFrame.ScrollBar:IsShown())
    end),

    test.case("roster scrollbar appears only when the selected rank overflows", function()
        local harness = newHarness()
        harness.ui.Initialize()
        local view = harness.frame().views.roster
        view.scrollFrame:SetHeight(196)

        local exactRank = rosterRank(1, "Exact")
        local overflowRank = rosterRank(2, "Overflow")
        overflowRank.groups[1].members = {
            {
                displayName = "First-Example Realm",
                lastOnlineText = "Online",
                tenureDays = 1,
            },
            {
                displayName = "Second-Example Realm",
                lastOnlineText = "Online",
                tenureDays = 1,
            },
        }

        test.assert_true(harness.ui.SetRosterReport({
            ranks = { exactRank, overflowRank },
        }))
        test.assert_equal(view.scrollChild:GetHeight(), view.scrollFrame:GetHeight())
        test.assert_false(view.scrollFrame.ScrollBar:IsShown())

        test.assert_true(harness.ui.SelectRosterRank(2))
        test.assert_true(view.scrollChild:GetHeight() > view.scrollFrame:GetHeight())
        test.assert_true(view.scrollFrame.ScrollBar:IsShown())

        test.assert_true(harness.ui.SelectRosterRank(1))
        test.assert_false(view.scrollFrame.ScrollBar:IsShown())
    end),

    test.case("dragging non-text controls saves a canonical position", function()
        local harness = newHarness()
        harness.ui.Initialize()
        local frame = harness.frame()
        test.assert_true(harness.ui.SetMainsAltsReport(mainsAltsReport(1)))
        local dynamicLine = frame.views.mainsalts.mainsAltsLinePool[1]

        local dragSurfaces = {
            frame,
            frame.header,
            frame.tabs[1],
            frame.views.roster.scrollFrame,
            frame.views.roster.refreshButton,
            dynamicLine.frame,
            dynamicLine.noteButton,
            frame.notesEditor,
        }

        for _, surface in ipairs(dragSurfaces) do
            test.assert_equal(surface.dragButton, "LeftButton")
            test.assert_not_nil(surface.scripts.OnDragStart)
            test.assert_not_nil(surface.scripts.OnDragStop)
        end

        frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 125, 90)
        frame.notesEditor.scripts.OnDragStart()
        test.assert_true(frame.moving)
        frame.notesEditor.scripts.OnDragStop()

        test.assert_false(frame.moving)
        test.assert_equal(harness.database.ui.windowPosition, {
            point = "BOTTOMLEFT",
            relativePoint = "BOTTOMLEFT",
            x = 125,
            y = 90,
        })
    end),

    test.case("editable text controls preserve native click-drag selection", function()
        local harness = newHarness()
        harness.ui.Initialize()

        local searchBox = harness.frame().views.mainsalts.mainsAltsSearchBox
        test.assert_nil(searchBox.dragButton)
        test.assert_nil(searchBox.scripts.OnDragStart)
        test.assert_nil(searchBox.scripts.OnDragStop)
    end),

    test.case("guild bank alignment uses scaled bounds without saving a position", function()
        local harness = newHarness(nil, 1920, 1080)
        harness.ui.Initialize()
        local guildBankFrame = newRegion(UIParent)
        guildBankFrame.left = 10
        guildBankFrame.bottom = 130
        guildBankFrame.width = 380
        guildBankFrame.height = 280
        guildBankFrame.effectiveScale = 2

        local aligned = harness.ui.AlignToRightOf(guildBankFrame)

        test.assert_not_nil(aligned)
        test.assert_equal(harness.database.ui.windowPosition, nil)
        test.assert_equal(harness.frame().left, 792)
        test.assert_equal(harness.frame().bottom, 260)
    end),

    test.case("guild bank alignment preserves a saved manual position", function()
        local savedPosition = {
            point = "BOTTOMLEFT",
            relativePoint = "BOTTOMLEFT",
            x = 125,
            y = 90,
        }
        local harness = newHarness(savedPosition)
        harness.ui.Initialize()
        local guildBankFrame = newRegion(UIParent)
        guildBankFrame.left = 20
        guildBankFrame.bottom = 260
        guildBankFrame.width = 760
        guildBankFrame.height = 560

        local aligned = harness.ui.AlignToRightOf(guildBankFrame)

        test.assert_false(aligned)
        test.assert_equal(harness.database.ui.windowPosition, savedPosition)
        test.assert_equal(harness.frame().left, 125)
        test.assert_equal(harness.frame().bottom, 90)
    end),

    test.case("saved off-screen positions are recovered and persisted", function()
        local harness = newHarness({
            point = "BOTTOMLEFT",
            relativePoint = "BOTTOMLEFT",
            x = 9000,
            y = -4000,
        }, 1280, 720)

        harness.ui.Initialize()
        test.assert_equal(harness.database.ui.windowPosition, {
            point = "BOTTOMLEFT",
            relativePoint = "BOTTOMLEFT",
            x = 428,
            y = 12,
        })
        test.assert_true(layout.isFullyVisible(
            harness.database.ui.windowPosition,
            layout.WINDOW_WIDTH,
            layout.WINDOW_HEIGHT,
            1280,
            720
        ))
    end),

    test.case("invalid primary tab requests fail without changing selection", function()
        local harness = newHarness()
        harness.ui.Initialize()

        local selected, message = harness.ui.SelectPrimaryTab("settings")
        test.assert_nil(selected)
        test.assert_equal(message, "primary tab must be roster, bank, provisions, or tags")
        test.assert_equal(harness.ui.selectedTab, "roster")
    end),

    test.case("numeric dropdown selections persist rename fallback and empty states", function()
        local harness = newHarness()
        harness.ui.Initialize()
        local ranks = {
            rosterRank(3, "Officer", "Officer (Rank 3)"),
            rosterRank(7, "Officer", "Officer (Rank 7)"),
        }
        test.assert_true(harness.ui.SetRosterReport({ ranks = ranks }))
        test.assert_equal(
            harness.frame().views.roster.rankDropdown.label.text,
            "Officer (Rank 3)"
        )
        test.assert_true(harness.ui.SelectRosterRank(7))
        test.assert_equal(harness.database.ui.selectedRosterRankIndex, 7)
        test.assert_equal(
            harness.frame().views.roster.rankDropdown.label.text,
            "Officer (Rank 7)"
        )
        ranks[2].name = "Renamed"
        ranks[2].label = "Renamed"
        test.assert_true(harness.ui.SetRosterReport({ ranks = ranks }))
        test.assert_equal(harness.frame().views.roster.selectedRankIndex, 7)
        test.assert_equal(harness.frame().views.roster.rankDropdown.label.text, "Renamed")

        harness.database.ui.selectedBankTabIndex = 99
        test.assert_true(harness.ui.SetBankReport({ tabs = {
            { index = 5, name = "Fifth", icon = 5, isViewable = false, rows = {} },
            { index = 2, name = "Second", icon = 2, isViewable = false, rows = {} },
        } }))
        test.assert_equal(harness.frame().views.bank.selectedBankTabIndex, 2)
        test.assert_equal(harness.database.ui.selectedBankTabIndex, 2)

        test.assert_true(harness.ui.SetRosterReport({ ranks = {} }))
        test.assert_equal(harness.frame().views.roster.rankDropdown.label.text, "No ranks")
        test.assert_false(harness.frame().views.roster.rankDropdown:IsEnabled())
        test.assert_true(harness.ui.SetBankReport({ tabs = {} }))
        test.assert_equal(harness.frame().views.bank.bankDropdown.label.text, "No bank tabs")
        test.assert_false(harness.frame().views.bank.bankDropdown:IsEnabled())
    end),

    test.case("prepared reports repaint their selections when views become visible", function()
        local harness = newHarness()
        harness.ui.Initialize()
        local rosterRankReport = rosterRank(3, "Officer")
        test.assert_true(harness.ui.SetRosterReport({ ranks = {
            rosterRankReport,
        } }))
        test.assert_true(harness.ui.SetBankReport({ tabs = {
            {
                index = 2,
                name = "Materials",
                icon = 9001,
                isViewable = true,
                rows = {},
            },
        } }))

        local frame = harness.frame()
        local rosterLabelCalls = frame.views.roster.rankDropdown.label.setTextCalls
        local rosterHeadingCalls = frame.views.roster.rosterLines[1].primary.setTextCalls
        local bankLabelCalls = frame.views.bank.bankDropdown.label.setTextCalls

        test.assert_true(harness.ui.Show())
        test.assert_true(harness.ui.SelectRosterMode("ByTenure"))
        test.assert_equal(frame.views.roster.rankDropdown.label.text, "Officer")
        test.assert_equal(frame.views.roster.rosterLines[1].primary.text, "This Week")
        test.assert_equal(
            frame.views.roster.rankDropdown.label.setTextCalls,
            rosterLabelCalls + 2
        )
        test.assert_equal(
            frame.views.roster.rosterLines[1].primary.setTextCalls,
            rosterHeadingCalls + 2
        )
        test.assert_equal(harness.database.ui.selectedRosterRankIndex, 3)

        test.assert_true(harness.ui.SelectPrimaryTab("bank"))
        test.assert_equal(frame.views.bank.bankDropdown.label.text, "Materials")
        test.assert_equal(
            frame.views.bank.bankDropdown.label.setTextCalls,
            bankLabelCalls + 2
        )
        test.assert_equal(harness.database.ui.selectedBankTabIndex, 2)
    end),

    test.case("dropdown menu initializers use a compositor-safe font object", function()
        local harness = newHarness()
        harness.ui.Initialize()
        test.assert_true(harness.ui.SetRosterReport({ ranks = {
            rosterRank(3, "Officer", "Officer (Rank 3)"),
            rosterRank(7, "Officer", "Officer (Rank 7)"),
        } }))
        local dropdown = harness.frame().views.roster.rankDropdown
        local descriptions = {}
        local rootDescription = {}
        function rootDescription:SetScrollMode(height)
            self.scrollMode = height
        end
        function rootDescription:SetMinimumWidth(width)
            self.minimumWidth = width
        end
        function rootDescription:CreateRadio(label)
            local description = { label = label }
            function description:AddInitializer(initializer)
                self.initializer = initializer
            end
            descriptions[#descriptions + 1] = description
            return description
        end

        dropdown.menuGenerator(dropdown, rootDescription)
        local menuButton = newRegion()
        menuButton.fontString = newRegion(menuButton)
        menuButton.leftTexture1 = newRegion(menuButton)
        menuButton.leftTexture2 = newRegion(menuButton)
        function menuButton:AttachTexture()
            local texture = newRegion(self)
            self.attachedTextures = self.attachedTextures or {}
            self.attachedTextures[#self.attachedTextures + 1] = texture
            return texture
        end
        function menuButton.fontString:SetFont()
            error("SetFont is disallowed by the Blizzard menu compositor")
        end
        descriptions[1].initializer(menuButton)

        test.assert_equal(descriptions[1].label, "Officer (Rank 3)")
        test.assert_equal(descriptions[2].label, "Officer (Rank 7)")
        test.assert_equal(menuButton:GetHeight(), 32)
        test.assert_equal(menuButton.fontString.fontObject, harness.fonts.RGMSMenuFont)
        test.assert_equal(
            menuButton.leftTexture1.vertexColor,
            { 0.204, 0.227, 0.275, 1 }
        )
        test.assert_equal(menuButton.leftTexture1.width, 16)
        test.assert_equal(menuButton.leftTexture1.height, 16)
        test.assert_equal(
            menuButton.leftTexture1.texture,
            "Interface\\CharacterFrame\\TempPortraitAlphaMask"
        )
        test.assert_equal(menuButton.leftTexture1.drawLayer, "ARTWORK")
        test.assert_equal(menuButton.leftTexture1.sublevel, 0)
        test.assert_equal(menuButton.leftTexture1.point, "LEFT")
        test.assert_equal(menuButton.leftTexture1.relativeTo, menuButton)
        test.assert_equal(menuButton.leftTexture1.relativePoint, "LEFT")
        test.assert_equal(menuButton.leftTexture1.x, 10)
        test.assert_equal(
            menuButton.leftTexture2.texture,
            "Interface\\CharacterFrame\\TempPortraitAlphaMask"
        )
        test.assert_equal(
            menuButton.leftTexture2.vertexColor,
            { 0.925, 0.282, 0.6, 1 }
        )
        test.assert_equal(menuButton.leftTexture2.width, 8)
        test.assert_equal(menuButton.leftTexture2.height, 8)
        test.assert_equal(menuButton.leftTexture2.sublevel, 2)
        test.assert_equal(menuButton.leftTexture2.relativeTo, menuButton.leftTexture1)
        test.assert_equal(menuButton.rgmsRadioInterior.width, 12)
        test.assert_equal(menuButton.rgmsRadioInterior.height, 12)
        test.assert_equal(
            menuButton.rgmsRadioInterior.vertexColor,
            { 0.059, 0.067, 0.082, 1 }
        )
        test.assert_equal(menuButton.rgmsRadioInterior.sublevel, 1)
        test.assert_equal(
            menuButton.rgmsRadioInterior.relativeTo,
            menuButton.leftTexture1
        )
        test.assert_equal(menuButton.fontString.relativeTo, menuButton.leftTexture1)
        test.assert_equal(menuButton.fontString.relativePoint, "RIGHT")
        test.assert_equal(menuButton.fontString.x, 8)
        test.assert_equal(harness.fonts.RGMSMenuFont.font, {
            "Interface\\AddOns\\RGMS\\assets\\fonts\\Inter-SemiBold.ttf",
            12,
            "",
        })
    end),

    test.case("global scan lock covers the full portal and leaves close available", function()
        local harness = newHarness()
        harness.ui.Initialize()
        harness.ui.Show()
        test.assert_true(harness.ui.OpenCharacterNote(
            "hero-area52",
            "Hero-Area52",
            "unsaved",
            false
        ))
        test.assert_true(harness.frame().notesEditor:IsShown())

        test.assert_true(harness.ui.SetGlobalScanLock(true))
        test.assert_true(harness.frame().globalDimmer:IsShown())
        test.assert_equal(
            harness.frame().globalDimmer.backdropColor,
            { 0, 0, 0, 0.8 }
        )
        local notice = harness.frame().globalDimmer.notice
        test.assert_equal(
            harness.frame().globalDimmer:GetFrameLevel(),
            harness.frame():GetFrameLevel() + 100
        )
        test.assert_equal(harness.frame().globalDimmer.allPoints, harness.frame())
        test.assert_equal(
            notice:GetFrameLevel(),
            harness.frame().globalDimmer:GetFrameLevel() + 1
        )
        test.assert_equal(
            harness.frame().closeButton:GetFrameLevel(),
            harness.frame().globalDimmer:GetFrameLevel() + 2
        )
        test.assert_equal(notice.label.text, "Scanning...")
        test.assert_equal(notice.label.font, {
            "Interface\\AddOns\\RGMS\\assets\\fonts\\Inter-SemiBold.ttf",
            16,
            "",
        })
        test.assert_equal(
            notice.icon.texture,
            "Interface\\AddOns\\RGMS\\assets\\icons\\loader-circle.png"
        )
        notice.scripts.OnUpdate(notice, 0.5)
        test.assert_equal(notice.rotation, 2.5)
        test.assert_equal(notice.icon.rotation, 2.5)
        test.assert_false(harness.frame().notesEditor:IsShown())
        for _, tabId in ipairs({ "roster", "mainsalts", "bank", "provisions", "tags" }) do
            test.assert_nil(harness.frame().views[tabId].spinner)
        end
        local selected, reason = harness.ui.SelectPrimaryTab("bank")
        test.assert_nil(selected)
        test.assert_equal(reason, "scan-locked")
        harness.frame().views.roster.scrollFrame.scripts.OnDragStart()
        test.assert_false(harness.frame().moving == true)
        harness.frame().closeButton.scripts.OnClick()
        test.assert_false(harness.ui.IsShown())

        test.assert_true(harness.ui.SetGlobalScanLock(false))
        test.assert_equal(
            harness.frame().closeButton:GetFrameLevel(),
            harness.frame().closeButtonBaseFrameLevel
        )
        harness.ui.Show("bank")
        test.assert_equal(harness.ui.selectedTab, "roster")
    end),
}
