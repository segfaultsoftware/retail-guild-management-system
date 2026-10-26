-- Pure presentation and interaction state for the fixed RGMS portal. WoW
-- frames consume this module, while tests can exercise behavior without the
-- Retail client.

local _, RGMS = ...

local Portal = {}

Portal.VIEWS = { "roster", "bank", "provisions", "tags" }
Portal.NAVIGATION = {
    { id = "roster", label = "Roster" },
    { id = "bank", label = "Guild Bank" },
    { id = "provisions", label = "Provisions" },
    { id = "tags", label = "Tags" },
}

Portal.PALETTE = {
    shell = { 0x0F / 255, 0x11 / 255, 0x15 / 255, 1 },
    surface = { 0x18 / 255, 0x1B / 255, 0x21 / 255, 1 },
    control = { 0x22 / 255, 0x26 / 255, 0x2E / 255, 1 },
    border = { 0x34 / 255, 0x3A / 255, 0x46 / 255, 1 },
    zebra = { 0x1D / 255, 0x20 / 255, 0x27 / 255, 1 },
    filterMatch = { 0x3B / 255, 0x23 / 255, 0x31 / 255, 1 },
    pink = { 0xEC / 255, 0x48 / 255, 0x99 / 255, 1 },
    pinkHover = { 0xF4 / 255, 0x72 / 255, 0xB6 / 255, 1 },
    text = { 0xF4 / 255, 0xF4 / 255, 0xF5 / 255, 1 },
    secondary = { 0xA1 / 255, 0xA1 / 255, 0xAA / 255, 1 },
    disabled = { 0x71 / 255, 0x71 / 255, 0x7A / 255, 1 },
    success = { 0x4A / 255, 0xDE / 255, 0x80 / 255, 1 },
    warning = { 0xFB / 255, 0xBF / 255, 0x24 / 255, 1 },
    error = { 0xF8 / 255, 0x71 / 255, 0x71 / 255, 1 },
}

local VALID_VIEW = {
    roster = true,
    bank = true,
    provisions = true,
    tags = true,
}

local function copyScrollPositions()
    return {
        roster = { ByName = 0, ByTenure = 0 },
        bank = 0,
        provisions = 0,
        tags = 0,
    }
end

local function numericIndex(option)
    return type(option) == "table" and option.index or nil
end

function Portal.resolveSelection(options, savedIndex, lowestNumeric)
    options = type(options) == "table" and options or {}
    for _, option in ipairs(options) do
        if numericIndex(option) == savedIndex then
            return option
        end
    end
    if not lowestNumeric then
        return options[1]
    end
    local selected
    for _, option in ipairs(options) do
        if type(numericIndex(option)) == "number"
            and (selected == nil or option.index < selected.index) then
            selected = option
        end
    end
    return selected
end

function Portal.dropdown(options, savedIndex, emptyLabel, lowestNumeric)
    local selected = Portal.resolveSelection(options, savedIndex, lowestNumeric)
    return {
        options = type(options) == "table" and options or {},
        selected = selected,
        selectedIndex = selected and selected.index or nil,
        label = selected and selected.name or emptyLabel,
        disabled = selected == nil,
    }
end

function Portal.contextControls(view, rosterMode)
    if view == "roster" then
        if rosterMode == "ByTenure" then
            return {
                dropdown = "rank",
                byRank = true,
                primary = "Refresh",
                close = true,
            }
        end
        return {
            primary = "Group Toons",
            search = "character",
            tags = "Tags...",
            byRank = false,
            close = true,
        }
    elseif view == "bank" then
        return { dropdown = "bankTab", primary = "Refresh", close = true }
    elseif view == "provisions" then
        return { primary = "Refresh", close = true }
    elseif view == "tags" then
        return { close = true }
    end
    return nil
end

function Portal.bankTimestamp(lastScan)
    if lastScan then
        return "Last scan: " .. lastScan
    end
    return nil
end

function Portal.status(operational, timestamp, emptyStatus)
    if type(operational) == "string" and operational ~= "" then
        return operational
    end
    if type(timestamp) == "string" and timestamp ~= "" then
        return timestamp
    end
    return emptyStatus or ""
end

function Portal.create()
    local controller = {
        selectedView = "roster",
        rosterMode = "ByName",
        scroll = copyScrollPositions(),
        open = false,
        scanOwner = nil,
        modalOpen = false,
        noteDraft = nil,
    }

    function controller:openWindow()
        if not self.open then
            self.scroll = copyScrollPositions()
        end
        self.open = true
        self.selectedView = "roster"
        self.rosterMode = "ByName"
        return self.selectedView
    end

    function controller:closeWindow()
        self.open = false
        self.selectedView = "roster"
        self.rosterMode = "ByName"
        self.scroll = copyScrollPositions()
        self.modalOpen = false
        self.noteDraft = nil
    end

    function controller:selectView(view)
        if self.scanOwner ~= nil then
            return nil, "scan-locked"
        end
        if not VALID_VIEW[view] then
            return nil, "invalid-view"
        end
        self.selectedView = view
        return true
    end

    function controller:selectRosterMode(mode)
        if self.scanOwner ~= nil then
            return nil, "scan-locked"
        end
        if self.modalOpen then
            return nil, "modal-open"
        end
        if mode ~= "ByName" and mode ~= "ByTenure" then
            return nil, "invalid-roster-mode"
        end
        self.rosterMode = mode
        return true
    end

    function controller:setScroll(view, offset, rosterMode)
        if not VALID_VIEW[view] then
            return nil, "invalid-view"
        end
        if self.scanOwner ~= nil then
            return nil, "scan-locked"
        end
        local normalized = math.max(0, tonumber(offset) or 0)
        if view == "roster" then
            rosterMode = rosterMode or self.rosterMode
            if rosterMode ~= "ByName" and rosterMode ~= "ByTenure" then
                return nil, "invalid-roster-mode"
            end
            self.scroll.roster[rosterMode] = normalized
            return normalized
        end
        self.scroll[view] = normalized
        return normalized
    end

    function controller:selectionChanged(view)
        if not VALID_VIEW[view] then
            return nil, "invalid-view"
        end
        if view == "roster" then
            self.scroll.roster.ByTenure = 0
        else
            self.scroll[view] = 0
        end
        return true
    end

    function controller:openNote(draft)
        if self.scanOwner ~= nil then
            return nil, "scan-locked"
        end
        self.modalOpen = true
        self.noteDraft = draft
        return true
    end

    function controller:closeNote()
        self.modalOpen = false
        self.noteDraft = nil
        return true
    end

    function controller:beginScan(owner)
        if self.scanOwner ~= nil then
            return nil, "scan-in-progress"
        end
        if owner ~= "roster" and owner ~= "bank" then
            return nil, "invalid-scan-owner"
        end
        self.scanOwner = owner
        self.modalOpen = false
        self.noteDraft = nil
        return true
    end

    function controller:finishScan(owner)
        if self.scanOwner ~= owner then
            return false
        end
        self.scanOwner = nil
        return true
    end

    function controller:isLocked()
        return self.scanOwner ~= nil
    end

    function controller:commandAllowed(command)
        command = tostring(command or ""):lower()
        if self.scanOwner == nil then
            return true
        end
        return command == "" or command == "open" or command == "help" or command == "debug"
    end

    function controller:canDrag()
        return self.scanOwner == nil
    end

    return controller
end

if type(RGMS) == "table" then
    RGMS.Portal = Portal
end

return Portal
