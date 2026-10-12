-- Pure guild-bank report projection. It derives ordered nested tabs and
-- display rows without retaining references to, or mutating, saved state.

local _, RGMS = ...

local Report = {}
local State = type(RGMS) == "table"
    and RGMS.BankState
    or require("Bank.State")

Report.STALE_DAYS = 21
Report.FALLBACK_ITEM_ICON = 134400

local function itemNameFromLink(itemLink, itemId)
    local name = type(itemLink) == "string"
        and string.match(itemLink, "|h%[([^%]]+)%]|h")
    if name and name ~= "" then
        return name
    end
    return "Item " .. tostring(itemId)
end

local function rowComesBefore(left, right)
    if left.stableSinceDate ~= right.stableSinceDate then
        return left.stableSinceDate < right.stableSinceDate
    end
    if left.tabIndex ~= right.tabIndex then
        return left.tabIndex < right.tabIndex
    end
    if left.slotIndex ~= right.slotIndex then
        return left.slotIndex < right.slotIndex
    end
    local leftName = string.lower(left.itemName)
    local rightName = string.lower(right.itemName)
    if leftName ~= rightName then
        return leftName < rightName
    end
    return left.itemName < right.itemName
end

function Report.build(dataset, currentDate, dateTime)
    if type(dataset) ~= "table"
        or type(dataset.tabs) ~= "table"
        or type(dataset.slots) ~= "table" then
        return nil, "bank report dataset is invalid"
    end
    if type(dateTime) ~= "table"
        or type(dateTime.currentPacificDate) ~= "function"
        or type(dateTime.calendarDayDifference) ~= "function"
        or type(dateTime.formatPacificTimestamp) ~= "function" then
        return nil, "Pacific date utilities are unavailable"
    end

    if currentDate == nil then
        local dateError
        currentDate, dateError = dateTime.currentPacificDate()
        if not currentDate then
            return nil, dateError
        end
    end

    local orderedTabs = {}
    local duplicateIndexes = {}
    for _, tab in ipairs(dataset.tabs) do
        if type(tab) ~= "table"
            or type(tab.index) ~= "number"
            or type(tab.name) ~= "string"
            or type(tab.isViewable) ~= "boolean" then
            return nil, "bank report tab is invalid"
        end
        if duplicateIndexes[tab.index] then
            return nil, "bank report contains duplicate tab index " .. tab.index
        end
        duplicateIndexes[tab.index] = true
        orderedTabs[#orderedTabs + 1] = tab
    end
    table.sort(orderedTabs, function(left, right)
        return left.index < right.index
    end)

    local result = { tabs = {} }
    local projectedTabsByIndex = {}
    for _, tab in ipairs(orderedTabs) do
        local projected = {
            index = tab.index,
            name = tab.name,
            icon = tab.icon,
            isViewable = tab.isViewable,
            rows = {},
        }
        if tab.lastAccessibleAt ~= nil then
            local formatted, formatError = dateTime.formatPacificTimestamp(
                tab.lastAccessibleAt.unixSeconds
            )
            if not formatted then
                return nil, formatError
            end
            projected.lastAccessibleAt = {
                unixSeconds = tab.lastAccessibleAt.unixSeconds,
                iso8601 = tab.lastAccessibleAt.iso8601,
            }
            projected.lastAccessibleText = formatted
        end
        result.tabs[#result.tabs + 1] = projected
        projectedTabsByIndex[tab.index] = projected
    end

    local rows = {}
    for _, slot in ipairs(dataset.slots) do
        local tab = projectedTabsByIndex[slot.tabIndex]
        if tab == nil then
            return nil, "bank slot refers to an unavailable tab"
        end
        if tab.isViewable then
            local ageDays, ageError = State.daysSince(
                slot.stableSinceDate,
                currentDate,
                dateTime
            )
            if ageDays == nil then
                return nil, ageError
            end
            rows[#rows + 1] = {
                tabIndex = tab.index,
                tabName = tab.name,
                slotIndex = slot.slotIndex,
                itemId = slot.itemId,
                itemLink = slot.itemLink,
                itemName = itemNameFromLink(slot.itemLink, slot.itemId),
                icon = slot.icon or Report.FALLBACK_ITEM_ICON,
                quantity = slot.quantity,
                stableSinceDate = slot.stableSinceDate,
                ageDays = ageDays,
                isStale = ageDays >= Report.STALE_DAYS,
            }
        end
    end

    table.sort(rows, rowComesBefore)
    for _, row in ipairs(rows) do
        local tab = projectedTabsByIndex[row.tabIndex]
        tab.rows[#tab.rows + 1] = row
    end

    return result
end

if type(RGMS) == "table" then
    RGMS.BankReport = Report
end

return Report
