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

    function region:GetRect()
        return self.left, self.bottom, self.width, self.height
    end

    function region:GetEffectiveScale()
        return self.effectiveScale or 1
    end

    function region:SetScript(scriptName, callback)
        self.scripts[scriptName] = callback
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

    function region:SetShown(shown)
        self.shown = shown
    end

    function region:SetText(value)
        value = tostring(value or "")
        if self.maxLetters and #value > self.maxLetters then
            value = string.sub(value, 1, self.maxLetters)
        end
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

    function region:SetTexture(value)
        self.texture = value
    end

    function region:SetFont(path, size, flags)
        self.font = { path, size, flags }
        self.setFontCalls = (self.setFontCalls or 0) + 1
    end

    function region:SetFontObject(fontObject)
        self.fontObject = fontObject
    end

    function region:SetVertexColor(red, green, blue, alpha)
        self.vertexColor = { red, green, blue, alpha }
    end

    function region:SetEnabled(enabled)
        self.enabled = enabled
    end

    function region:SetChecked(checked)
        self.checked = checked == true
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
        return countLines(self.text) * 14
    end

    function region:SetJustifyH(justification)
        self.justifyH = justification
    end

    function region:CreateFontString()
        return newRegion(self)
    end

    function region:CreateTexture()
        return newRegion(self)
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
        "SetFrameStrata",
        "SetToplevel",
        "SetMovable",
        "EnableMouse",
        "EnableMouseWheel",
        "SetClampedToScreen",
        "SetClampRectInsets",
        "SetBackdrop",
        "SetBackdropColor",
        "SetJustifyV",
        "SetAllPoints",
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
    local noteDeletes = {}
    local tagAssignments = {}
    local tagToggles = {}
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
    GameTooltip = tooltip
    UISpecialFrames = {}
    MenuUtil = {}
    CreateFont = function(name)
        local font = newRegion()
        font.name = name
        fonts[name] = font
        return font
    end
    CreateFrame = function(frameType, name, parent)
        local frame = newRegion(parent)
        frame.name = name
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
    PanelTemplates_SetNumTabs = function(frame, numberOfTabs)
        frame.numTabs = numberOfTabs
    end
    PanelTemplates_SetTab = function(frame, selectedTab)
        frame.selectedTab = selectedTab
    end

    local database = {
        ui = {},
    }
    local modifiedItemClicks = {}
    HandleModifiedItemClick = function(itemLink)
        modifiedItemClicks[#modifiedItemClicks + 1] = itemLink
        return true
    end
    if savedPosition then
        database.ui.windowPosition = savedPosition
    end

    local rgms = {
        DB = database,
        UILayout = layout,
        MainsAltsSearch = mainsAltsSearch,
        Roster = {
            RequestManualScan = function()
                refreshRequests = refreshRequests + 1
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
            SaveCharacterNote = function(identity, value)
                noteSaves[#noteSaves + 1] = { identity = identity, value = value }
                return true
            end,
            DeleteCharacterNote = function(identity)
                noteDeletes[#noteDeletes + 1] = identity
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
        },
    }
    local chunk = assert(loadfile("UI/UI.lua"))
    local ui = chunk("RGMS", rgms)

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
        noteDeletes = noteDeletes,
        tagAssignments = tagAssignments,
        tagToggles = tagToggles,
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
        test.assert_equal(frame.numTabs, 3)
        test.assert_equal(frame.tabs[2].label.text, "Mains/Alts")
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
        test.assert_equal(searchBox.relativeTo, frame.views.mainsalts.groupButton)
        test.assert_equal(searchBox.x, 8)
        test.assert_false(searchBox.autoFocus)
        test.assert_nil(searchBox.maxLetters)
        test.assert_equal(
            frame.views.mainsalts.mainsAltsSearchPlaceholder.text,
            "Search characters…"
        )
        test.assert_equal(
            frame.views.mainsalts.mainsAltsTagFilterButton.label.text,
            "Filter tags..."
        )
        test.assert_equal(frame.views.bank.text.text, "No bank scan yet")
        test.assert_equal(frame.views.bank.status.text, "No bank scan yet")
    end),

    test.case("primary tabs content status and close behavior use the public API", function()
        local harness = newHarness()
        harness.ui.Initialize()

        test.assert_true(harness.ui.Show("roster"))
        test.assert_true(harness.ui.IsShown())
        test.assert_equal(harness.ui.selectedTab, "roster")
        test.assert_true(harness.frame().views.roster:IsShown())
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

    test.case("Mains/Alts rows expand transiently and disable during roster scans", function()
        local harness = newHarness()
        harness.ui.Initialize()
        local report = {
            rows = {
                {
                    identity = "main-area52",
                    displayName = "Main-Area52",
                    note = "Main note",
                    hasNote = true,
                    altCount = 2,
                    alts = {
                        {
                            identity = "alta-area52",
                            displayName = "AltA-Area52",
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
        test.assert_nil(view.refreshButton)
        test.assert_equal(view.groupButton.text, "Group Toons")
        test.assert_false(view.groupButton:IsEnabled())
        test.assert_equal(view.mainsAltsLines[1].name.text, "Main-Area52 (+2)")
        test.assert_equal(view.mainsAltsHeader.character.points[1].x, 28)
        test.assert_equal(view.mainsAltsLines[1].checkbox.x, 8)
        test.assert_equal(#view.mainsAltsLines[1].checkbox.points, 1)
        test.assert_equal(view.mainsAltsLines[1].expandButton.x, 28)
        test.assert_equal(view.mainsAltsLines[1].name.x, 48)
        test.assert_true(view.mainsAltsLines[1].noteButton:IsShown())
        test.assert_equal(view.mainsAltsHeader.note.justifyH, "CENTER")
        test.assert_equal(view.mainsAltsLines[1].noteButton.relativePoint, "RIGHT")
        test.assert_equal(view.mainsAltsLines[1].noteButton.x, -196)
        test.assert_true(view.mainsAltsLines[1].hasNote)
        test.assert_true(view.mainsAltsLines[1].checkbox:IsShown())
        test.assert_true(view.mainsAltsLines[2].checkbox:IsShown())

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
        test.assert_false(harness.frame().notesEditor.deleteButton:IsEnabled())
        test.assert_false(harness.frame().notesEditor.cancelButton:IsEnabled())
        test.assert_false(harness.frame().notesEditor.closeButton:IsEnabled())
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
        test.assert_equal(view.mainsAltsLines[3].name.text, "Other-Area52 (+1)")
        test.assert_false(view.mainsAltsLinePool[4].frame:IsShown())
    end),

    test.case("Mains/Alts recycles a bounded row pool for very large guilds", function()
        local harness = newHarness()
        harness.ui.Initialize()
        local view = harness.frame().views.mainsalts
        view.scrollFrame:SetHeight(72)
        harness.ui.SetMainsAltsReport(mainsAltsReport(300))

        test.assert_equal(#view.mainsAltsRows, 300)
        test.assert_equal(view.mainsAltsTableHeight, 7208)
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

    test.case("Mains/Alts search filters full groups and preserves hidden selections", function()
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
        test.assert_true(view.expandedMainsAlts["main-area52"])
        test.assert_equal(view.scrollFrame:GetVerticalScroll(), 0)

        view.mainsAltsLines[1].expandButton.scripts.OnClick()
        test.assert_false(view.expandedMainsAlts["main-area52"] == true)
        view.mainsAltsSearchBox:SetText("MTVS")
        test.assert_true(view.expandedMainsAlts["main-area52"])

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
        test.assert_true(view.mainsAltsLines[1].checkbox:GetChecked())
        test.assert_true(view.mainsAltsLines[2].checkbox:GetChecked())
    end),

    test.case("Mains/Alts search follows keyboard lifecycle report and lock rules", function()
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
        harness.ui.SelectPrimaryTab("roster")
        test.assert_equal(view.mainsAltsSearchBox:GetText(), "")
        test.assert_nil(next(view.expandedMainsAlts))

        harness.ui.SelectPrimaryTab("mainsalts")
        view.mainsAltsSearchBox:SetText("solo")
        test.assert_nil(harness.database.ui.mainsAltsSearchQuery)
        harness.ui.Hide()
        test.assert_equal(view.mainsAltsSearchBox:GetText(), "")
    end),

    test.case("Mains/Alts tag pills edit filter intersect and follow transient lifecycle", function()
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

        test.assert_equal(view.mainsAltsHeader.tags.text, "Tags")
        test.assert_equal(view.mainsAltsLines[1].tagButton.label.text, "Tags")
        test.assert_equal(view.mainsAltsLines[2].tagButton.label.text, "Tags (1)")
        test.assert_true(view.mainsAltsLines[1].tagButton.tagCapsule ~= nil)
        test.assert_true(view.mainsAltsTagFilterButton.tagCapsule ~= nil)
        view.mainsAltsLines[1].tagButton.scripts.OnEnter()
        test.assert_false(view.mainsAltsTagPreview:IsShown())
        view.mainsAltsLines[2].tagButton.scripts.OnEnter()
        test.assert_true(view.mainsAltsTagPreview:IsShown())
        test.assert_equal(view.mainsAltsTagPreview.pills[1].label.text, "me")
        test.assert_true(
            view.mainsAltsTagPreview.pills[1].tagCapsule ~= nil
        )
        test.assert_equal(
            view.mainsAltsTagPreview.pills[1].tagCapsule.border.left.texture,
            "Interface\\CharacterFrame\\TempPortraitAlphaMask"
        )
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
        test.assert_equal(view.mainsAltsTagFilterButton.label.text, "Filter tags... (1)")
        test.assert_equal(view.mainsAltsLines[1].identity, "main-area52")
        test.assert_equal(view.mainsAltsLines[2].identity, "raidalt-area52")
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
        test.assert_true(view.mainsAltsTagEditor.input:HasFocus())
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
        harness.ui.SelectPrimaryTab("roster")
        test.assert_nil(next(view.mainsAltsTagFilters))
        test.assert_equal(view.mainsAltsTagFilterButton.label.text, "Filter tags...")
    end),

    test.case("Mains/Alts mutation scrolling waits for the final report and jumps to a clamped row", function()
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

    test.case("Mains/Alts ordinary renders preserve main ungrouped and expanded-alt anchors", function()
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

    test.case("Mains/Alts toggles keep the clicked main at the same visible row", function()
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

    test.case("Mains/Alts target scrolling is immediate and lifecycle input remains stable", function()
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
        harness.ui.SelectPrimaryTab("roster")
        test.assert_nil(view.mainsAltsScrollAnimation)
        test.assert_nil(view.pendingMainsAltsScrollTarget)
        harness.ui.SelectPrimaryTab("mainsalts")

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

    test.case("Mains/Alts missing mutation targets are cleared silently", function()
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

    test.case("one character-note editor switches discards limits saves and deletes", function()
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

        view.mainsAltsLines[1].noteButton.scripts.OnClick()
        test.assert_true(editor:IsShown())
        test.assert_equal(editor.character.text, "Editing note for Main-Area52")
        test.assert_equal(editor.editBox:GetText(), "Saved main note")
        test.assert_true(editor.deleteButton:IsEnabled())

        editor.editBox:SetText("unsaved change")
        view.mainsAltsLines[2].noteButton.scripts.OnClick()
        test.assert_true(editor:IsShown())
        test.assert_equal(editor.characterIdentity, "solo-area52")
        test.assert_equal(editor.editBox:GetText(), "")
        test.assert_false(editor.deleteButton:IsEnabled())
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
        test.assert_equal(#harness.noteSaves[1].value, 5500)

        view.mainsAltsLines[1].noteButton.scripts.OnClick()
        editor.deleteButton.scripts.OnClick()
        test.assert_false(editor:IsShown())
        test.assert_equal(harness.noteDeletes, { "main-area52" })

        view.mainsAltsLines[1].noteButton.scripts.OnClick()
        editor.editBox:SetText("discard me")
        editor.closeButton.scripts.OnClick()
        test.assert_false(editor:IsShown())
        test.assert_equal(#harness.noteSaves, 1)

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
        test.assert_equal(#harness.noteSaves, 1)
    end),

    test.case("roster refresh button starts manual scans and disables while scanning", function()
        local harness = newHarness()
        harness.ui.Initialize()
        local refreshButton = harness.frame().views.roster.refreshButton

        test.assert_true(refreshButton:IsEnabled())
        refreshButton.scripts.OnClick()
        test.assert_equal(harness.refreshRequests(), 1)

        test.assert_true(harness.ui.SetRosterScanInProgress(true))
        test.assert_false(refreshButton:IsEnabled())
        test.assert_true(harness.ui.SetRosterScanInProgress(false))
        test.assert_true(refreshButton:IsEnabled())

        test.assert_true(harness.ui.SetRosterAvailable(false))
        test.assert_false(refreshButton:IsEnabled())
        test.assert_true(harness.ui.SetRosterAvailable(true))
        test.assert_true(refreshButton:IsEnabled())
    end),

    test.case("bank refresh follows bank-open and scan lifecycle restrictions", function()
        local harness = newHarness()
        harness.ui.Initialize()
        local refreshButton = harness.frame().views.bank.refreshButton

        test.assert_false(refreshButton:IsEnabled())
        test.assert_true(harness.ui.SetGuildBankOpen(true))
        test.assert_true(refreshButton:IsEnabled())
        refreshButton.scripts.OnClick()
        test.assert_equal(harness.bankRefreshRequests(), 1)

        test.assert_true(harness.ui.SetBankScanInProgress(true))
        test.assert_false(refreshButton:IsEnabled())
        test.assert_true(harness.ui.SetBankScanInProgress(false))
        test.assert_true(refreshButton:IsEnabled())
        test.assert_true(harness.ui.SetGuildBankOpen(false))
        test.assert_false(refreshButton:IsEnabled())
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
        test.assert_equal(memberLine.primary.text, "Current-Example Realm")
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
    end),

    test.case("dragging saves a canonical per-character position", function()
        local harness = newHarness()
        harness.ui.Initialize()
        local frame = harness.frame()

        frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 125, 90)
        frame.dragHandle.scripts.OnDragStart()
        test.assert_true(frame.moving)
        frame.dragHandle.scripts.OnDragStop()

        test.assert_false(frame.moving)
        test.assert_equal(harness.database.ui.windowPosition, {
            point = "BOTTOMLEFT",
            relativePoint = "BOTTOMLEFT",
            x = 125,
            y = 90,
        })
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
        test.assert_matches(message, "mainsalts")
        test.assert_equal(harness.ui.selectedTab, "roster")
    end),

    test.case("numeric dropdown selections persist rename fallback and empty states", function()
        local harness = newHarness()
        harness.ui.Initialize()
        local ranks = {
            rosterRank(3, "Officer"),
            rosterRank(7, "Officer"),
        }
        test.assert_true(harness.ui.SetRosterReport({ ranks = ranks }))
        test.assert_true(harness.ui.SelectRosterRank(7))
        test.assert_equal(harness.database.ui.selectedRosterRankIndex, 7)
        ranks[2].name = "Renamed"
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

    test.case("dropdown menu initializers use a compositor-safe font object", function()
        local harness = newHarness()
        harness.ui.Initialize()
        test.assert_true(harness.ui.SetRosterReport({ ranks = {
            rosterRank(3, "Officer"),
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
        function rootDescription:CreateRadio()
            local description = {}
            function description:AddInitializer(initializer)
                self.initializer = initializer
            end
            descriptions[#descriptions + 1] = description
            return description
        end

        dropdown.menuGenerator(dropdown, rootDescription)
        local menuButton = newRegion()
        menuButton.fontString = newRegion(menuButton)
        function menuButton.fontString:SetFont()
            error("SetFont is disallowed by the Blizzard menu compositor")
        end
        descriptions[1].initializer(menuButton)

        test.assert_equal(menuButton:GetHeight(), 32)
        test.assert_equal(menuButton.fontString.fontObject, harness.fonts.RGMSMenuFont)
        test.assert_equal(harness.fonts.RGMSMenuFont.font, {
            "Interface\\AddOns\\RGMS\\assets\\fonts\\Inter-SemiBold.ttf",
            12,
            "",
        })
    end),

    test.case("global scan lock blocks the portal discards note drafts and leaves close available", function()
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
        test.assert_false(harness.frame().notesEditor:IsShown())
        for _, tabId in ipairs({ "roster", "mainsalts", "bank" }) do
            local spinner = harness.frame().views[tabId].spinner
            test.assert_true(spinner:IsShown())
            test.assert_equal(spinner.label.text, "Scanning...")
        end
        local selected, reason = harness.ui.SelectPrimaryTab("bank")
        test.assert_nil(selected)
        test.assert_equal(reason, "scan-locked")
        harness.frame().dragHandle.scripts.OnDragStart()
        test.assert_false(harness.frame().moving == true)
        harness.frame().closeButton.scripts.OnClick()
        test.assert_false(harness.ui.IsShown())

        test.assert_true(harness.ui.SetGlobalScanLock(false))
        for _, tabId in ipairs({ "roster", "mainsalts", "bank" }) do
            test.assert_false(harness.frame().views[tabId].spinner:IsShown())
        end
        harness.ui.Show("bank")
        test.assert_equal(harness.ui.selectedTab, "roster")
    end),
}
