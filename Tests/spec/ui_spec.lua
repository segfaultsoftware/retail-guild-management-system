local layout = require("UI.Layout")
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
        self.text = value
    end

    function region:SetTexture(value)
        self.texture = value
    end

    function region:SetEnabled(enabled)
        self.enabled = enabled
    end

    function region:IsEnabled()
        return self.enabled ~= false
    end

    function region:GetStringHeight()
        return countLines(self.text) * 14
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
        "SetClampedToScreen",
        "SetClampRectInsets",
        "SetBackdrop",
        "SetBackdropColor",
        "SetJustifyH",
        "SetJustifyV",
        "SetAllPoints",
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
    local refreshRequests = 0
    local bankRefreshRequests = 0
    local bankCancellations = 0
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
    CreateFrame = function(_, name, parent)
        local frame = newRegion(parent)
        frame.name = name
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
    }
    local chunk = assert(loadfile("UI/UI.lua"))
    local ui = chunk("RGMS", rgms)

    return {
        database = database,
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
        test.assert_equal(frame.views.roster.rankScrollFrame:GetWidth(), 242)
        test.assert_equal(frame.views.roster.scrollFrame.points[1].x, 266)
        test.assert_equal(frame.views.bank.bankTabScrollFrame:GetWidth(), 200)
        test.assert_equal(frame.views.bank.scrollFrame.points[1].x, 218)
        test.assert_false(frame.resizable)
        test.assert_nil(harness.database.ui.windowPosition)
        test.assert_equal(frame.views.roster.text.text, "No roster data yet")
        test.assert_equal(frame.views.roster.status.text, "No roster data yet")
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
        test.assert_true(frame.views.bank.bankTitle:IsShown())

        harness.ui.SetRosterScanInProgress(false)
        harness.ui.SetViewStatus("roster", "Last successful update: prior")
        harness.ui.SetBankScanInProgress(false)
        harness.ui.SetViewStatus("bank", "Last successful scan: prior")
        test.assert_true(frame.views.roster.rosterReport == rosterReport)
        test.assert_true(frame.views.roster.rosterLines[1].frame:IsShown())
        test.assert_true(frame.views.bank.bankReport == bankReport)
        test.assert_true(frame.views.bank.bankTitle:IsShown())
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
        test.assert_equal(view.bankTitle.text, "Last accessible: 2024-06-22 09:30 PT")
        test.assert_equal(view.bankRows[1].item.text, "Ancient Cloth")
        test.assert_equal(view.bankRows[1].tab.text, "Materials")
        test.assert_equal(view.bankRows[1].slot.text, "4")
        test.assert_equal(view.bankRows[1].count.text, "20")
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
        test.assert_equal(view.bankTitle.text, "Last accessible: 2024-06-20 08:00 PT")
        test.assert_false(view.bankRows[1].frame:IsShown())

        view.bankTabButtons[3].scripts.OnClick()
        test.assert_equal(view.bankMessage.text, "|cffff5555No access|r")
        test.assert_equal(view.bankTitle.text, "No successful access yet")

        view.bankTabButtons[4].scripts.OnClick()
        test.assert_equal(view.bankMessage.text, "|cff888888No occupied slots|r")
        test.assert_equal(view.bankTitle.text, "Last accessible: 2024-06-22 09:35 PT")
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

    test.case("closing RGMS cancels a bank scan without clearing bank content", function()
        local harness = newHarness()
        harness.ui.Initialize()
        harness.ui.SetViewContent("bank", "Previously committed bank report")
        harness.ui.Show("bank")

        harness.frame().closeButton.scripts.OnClick()

        test.assert_equal(harness.bankCancellations(), 1)
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
        test.assert_equal(view.rankButtons[2].text, "Trial (Rank 7)")
        local tableText = rosterTableText(view)
        test.assert_matches(tableText, "Current%-Example Realm")
        test.assert_matches(tableText, "5 hours ago")
        test.assert_matches(tableText, "12 days")
        test.assert_false(string.find(tableText, " | ", 1, true) ~= nil)
        local memberLine = view.rosterLines[4]
        test.assert_equal(memberLine.primary.text, "Current-Example Realm")
        test.assert_equal(memberLine.secondary.text, "5 hours ago")
        test.assert_equal(memberLine.tertiary.text, "12 days")

        view.rankButtons[2].scripts.OnClick()
        test.assert_equal(view.selectedRankIndex, 7)
        test.assert_equal(harness.database.roster, expectedObservations)
        tableText = rosterTableText(view)
        test.assert_equal(select(2, string.gsub(tableText, EMPTY_TEXT, "")), 4)
    end),

    test.case("missing roster rows show a warning with the standard hover tooltip", function()
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
        local currentLine = view.rosterLines[4]
        local missingLine = view.rosterLines[5]

        test.assert_false(currentLine.warningIndicator:IsShown())
        test.assert_true(missingLine.warningIndicator:IsShown())
        test.assert_equal(
            missingLine.warningIndicator.points[1].x,
            0
        )

        missingLine.warningIndicator.scripts.OnEnter()
        test.assert_true(harness.tooltip.shown)
        test.assert_equal(harness.tooltip.owner, missingLine.warningIndicator)
        test.assert_equal(harness.tooltip.anchor, "ANCHOR_RIGHT")
        test.assert_equal(harness.tooltip.lines, {
            "Missing roster member",
            "Not found in the current successful roster snapshot.",
            "Last appeared (Pacific): 2024-05-22",
        })

        missingLine.warningIndicator.scripts.OnLeave()
        test.assert_false(harness.tooltip.shown)

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
        test.assert_false(view.rosterLines[4].warningIndicator:IsShown())
        test.assert_false(harness.tooltip.shown)
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
        test.assert_matches(message, "roster or bank")
        test.assert_equal(harness.ui.selectedTab, "roster")
    end),
}
