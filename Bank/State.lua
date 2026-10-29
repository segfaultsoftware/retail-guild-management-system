-- Pure guild-bank slot transitions. This module receives complete successful
-- observations and date helpers explicitly, so it never depends on WoW APIs or
-- the current machine clock.

local _, RGMS = ...

local State = {}

local function deepCopy(value, active)
    if type(value) ~= "table" then
        return value
    end

    active = active or {}
    if active[value] then
        return nil, "bank snapshot contains a recursive table"
    end

    active[value] = true
    local result = {}
    for key, item in pairs(value) do
        local copiedKey, keyError = deepCopy(key, active)
        if keyError then
            active[value] = nil
            return nil, keyError
        end

        local copiedItem, itemError = deepCopy(item, active)
        if itemError then
            active[value] = nil
            return nil, itemError
        end
        result[copiedKey] = copiedItem
    end
    active[value] = nil
    return result
end

local function requireDateTime(dateTime)
    if type(dateTime) ~= "table"
        or type(dateTime.currentPacificDate) ~= "function"
        or type(dateTime.calendarDayDifference) ~= "function" then
        return nil, "Pacific date utilities are unavailable"
    end
    return true
end

local function isPositiveInteger(value)
    return type(value) == "number"
        and value >= 1
        and value == math.floor(value)
end

local function slotKey(tabIndex, slotIndex)
    return tostring(tabIndex) .. ":" .. tostring(slotIndex)
end

local function indexTabs(tabs)
    if type(tabs) ~= "table" then
        return nil, "completed bank tabs must be a table"
    end

    local indexed = {}
    for _, tab in ipairs(tabs) do
        if type(tab) ~= "table"
            or not isPositiveInteger(tab.index)
            or type(tab.isViewable) ~= "boolean" then
            return nil, "completed bank tab identity or access state is invalid"
        end
        if indexed[tab.index] ~= nil then
            return nil, "completed bank contains duplicate tab index " .. tab.index
        end
        indexed[tab.index] = tab
    end
    return indexed
end

local function indexSlots(slots, source)
    if type(slots) ~= "table" then
        return nil, source .. " slots must be a table"
    end

    local indexed = {}
    for _, slot in ipairs(slots) do
        if type(slot) ~= "table"
            or not isPositiveInteger(slot.tabIndex)
            or not isPositiveInteger(slot.slotIndex)
            or not isPositiveInteger(slot.itemId)
            or not isPositiveInteger(slot.quantity) then
            return nil, source .. " slot identity or contents are invalid"
        end

        local key = slotKey(slot.tabIndex, slot.slotIndex)
        if indexed[key] ~= nil then
            return nil, source .. " contains duplicate slot " .. key
        end
        indexed[key] = slot
    end
    return indexed
end

local function pacificDateForSnapshot(snapshot, dateTime)
    if type(snapshot) ~= "table"
        or type(snapshot.scannedAt) ~= "table"
        or type(snapshot.scannedAt.unixSeconds) ~= "number" then
        return nil, "completed bank snapshot timestamp is invalid"
    end

    return dateTime.currentPacificDate(snapshot.scannedAt.unixSeconds)
end

function State.reduce(previousDataset, snapshot, dateTime)
    local dateTimeAvailable, dateTimeError = requireDateTime(dateTime)
    if not dateTimeAvailable then
        return nil, dateTimeError
    end
    if type(previousDataset) ~= "table" then
        return nil, "previous bank dataset must be a table"
    end

    local observedDate, dateError = pacificDateForSnapshot(snapshot, dateTime)
    if not observedDate then
        return nil, dateError
    end
    if type(snapshot.money) ~= "number"
        or snapshot.money < 0
        or snapshot.money ~= math.floor(snapshot.money) then
        return nil, "completed bank snapshot money must be a non-negative integer"
    end

    local tabs, tabError = indexTabs(snapshot.tabs)
    if not tabs then
        return nil, tabError
    end
    local previousTabs, previousTabError = indexTabs(previousDataset.tabs)
    if not previousTabs then
        return nil, previousTabError
    end
    local previousSlots, previousError = indexSlots(
        previousDataset.slots,
        "previous bank dataset"
    )
    if not previousSlots then
        return nil, previousError
    end
    local observedSlots, observedError = indexSlots(
        snapshot.slots,
        "completed bank snapshot"
    )
    if not observedSlots then
        return nil, observedError
    end

    local nextDataset, copyError = deepCopy({
        guild = snapshot.guild,
        scannedAt = snapshot.scannedAt,
        money = snapshot.money,
        tabs = snapshot.tabs,
        slots = snapshot.slots,
    })
    if not nextDataset then
        return nil, copyError
    end

    for _, tab in ipairs(nextDataset.tabs) do
        if tab.isViewable then
            tab.lastAccessibleAt = {
                unixSeconds = snapshot.scannedAt.unixSeconds,
                iso8601 = snapshot.scannedAt.iso8601,
            }
        else
            tab.lastAccessibleAt = nil
            local previousTab = previousTabs[tab.index]
            if previousTab ~= nil and previousTab.lastAccessibleAt ~= nil then
                tab.lastAccessibleAt = {
                    unixSeconds = previousTab.lastAccessibleAt.unixSeconds,
                    iso8601 = previousTab.lastAccessibleAt.iso8601,
                }
            end
        end
    end

    for _, slot in ipairs(nextDataset.slots) do
        local tab = tabs[slot.tabIndex]
        if tab == nil then
            return nil, "completed bank slot refers to an unavailable tab"
        end
        if not tab.isViewable then
            return nil, "completed bank snapshot contains a slot from an inaccessible tab"
        end

        local previous = previousSlots[slotKey(slot.tabIndex, slot.slotIndex)]
        if previous ~= nil
            and previous.itemId == slot.itemId
            and previous.quantity <= slot.quantity then
            slot.stableSinceDate = previous.stableSinceDate
        else
            slot.stableSinceDate = observedDate
        end
    end

    for _, previous in ipairs(previousDataset.slots) do
        local tab = tabs[previous.tabIndex]
        if tab ~= nil and not tab.isViewable then
            local retained, retainedError = deepCopy(previous)
            if not retained then
                return nil, retainedError
            end
            nextDataset.slots[#nextDataset.slots + 1] = retained
        end
    end

    table.sort(nextDataset.slots, function(left, right)
        if left.tabIndex == right.tabIndex then
            return left.slotIndex < right.slotIndex
        end
        return left.tabIndex < right.tabIndex
    end)

    return nextDataset
end

function State.daysSince(stableSinceDate, currentDate, dateTime)
    local dateTimeAvailable, dateTimeError = requireDateTime(dateTime)
    if not dateTimeAvailable then
        return nil, dateTimeError
    end

    local days, differenceError = dateTime.calendarDayDifference(
        stableSinceDate,
        currentDate
    )
    if days ~= nil then
        return days
    end
    if type(differenceError) == "string"
        and string.find(
            differenceError,
            "later date precedes earlier date",
            1,
            true
        ) then
        return 0
    end
    return nil, differenceError
end

if type(RGMS) == "table" then
    RGMS.BankState = State
end

return State
