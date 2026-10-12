local layout = require("UI.Layout")
local test = require("Tests.lib.runner")

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
        if point == "BOTTOMLEFT" and relativePoint == "BOTTOMLEFT" then
            self.left = self.x
            self.bottom = self.y
        end
    end

    function region:ClearAllPoints()
        self.point = nil
    end

    function region:GetLeft()
        return self.left
    end

    function region:GetBottom()
        return self.bottom
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
        self.shown = false
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
    local uiParent = newRegion()
    uiParent.width = screenWidth or 1920
    uiParent.height = screenHeight or 1080

    UIParent = uiParent
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
        ui = ui,
    }
end

return {
    test.case("window initializes hidden at a fixed size with scrollable placeholders", function()
        local harness = newHarness()
        test.assert_true(harness.ui.Initialize())

        local frame = harness.frame()
        test.assert_false(frame:IsShown())
        test.assert_equal(frame:GetWidth(), layout.WINDOW_WIDTH)
        test.assert_equal(frame:GetHeight(), layout.WINDOW_HEIGHT)
        test.assert_false(frame.resizable)
        test.assert_nil(harness.database.ui.windowPosition)
        test.assert_true(
            frame.views.roster.scrollChild:GetHeight()
                > frame.views.roster.scrollFrame:GetHeight()
        )
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
            x = 848,
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
