-- Pure provision validation, mutation, ordering, and guild-bank aggregation.

local _, RGMS = ...

local Model = {}

Model.MIN_NAME_LENGTH = 3
Model.MAX_NAME_LENGTH = 100
Model.MIN_TARGET = 1
Model.MAX_TARGET = 99999
Model.SILVER_QUALITY = 1
Model.GOLD_QUALITY = 2
Model.FALLBACK_ITEM_ICON = 134400

local function characterCount(value)
    local withoutContinuationBytes = string.gsub(value, "[\128-\191]", "")
    return #withoutContinuationBytes
end

local function trim(value)
    value = type(value) == "string" and value or ""
    return (string.gsub(string.gsub(value, "^%s+", ""), "%s+$", ""))
end

local function qualityFromDraft(draft)
    local silver = type(draft) == "table" and draft.silver == true
    local gold = type(draft) == "table" and draft.gold == true
    if silver and gold then
        return "either"
    elseif silver then
        return "silver"
    elseif gold then
        return "gold"
    end
    return nil
end

function Model.normalizeDraft(draft)
    draft = type(draft) == "table" and draft or {}
    local name = trim(draft.name)
    local targetText = type(draft.targetText) == "string"
        and trim(draft.targetText)
        or tostring(draft.target or "")
    local target = string.match(targetText, "^%d+$") and tonumber(targetText) or nil
    local quality = qualityFromDraft(draft)
    local length = characterCount(name)

    if length < Model.MIN_NAME_LENGTH or length > Model.MAX_NAME_LENGTH then
        return nil, "item name must contain 3 through 100 characters"
    end
    if quality == nil then
        return nil, "at least one crafting quality must be selected"
    end
    if target == nil or target < Model.MIN_TARGET or target > Model.MAX_TARGET then
        return nil, "target inventory count must be a whole number from 1 through 99,999"
    end

    return {
        name = name,
        quality = quality,
        target = target,
    }
end

function Model.toDraft(provision)
    if type(provision) ~= "table" then
        return { name = "", silver = false, gold = false, targetText = "" }
    end
    return {
        name = provision.name,
        silver = provision.quality == "silver" or provision.quality == "either",
        gold = provision.quality == "gold" or provision.quality == "either",
        targetText = tostring(provision.target),
    }
end

function Model.same(normalized, provision)
    return type(normalized) == "table"
        and type(provision) == "table"
        and normalized.name == provision.name
        and normalized.quality == provision.quality
        and normalized.target == provision.target
end

local function copyProvision(provision)
    return {
        id = provision.id,
        name = provision.name,
        quality = provision.quality,
        target = provision.target,
    }
end

local function copyList(provisions)
    local result = {}
    for index, provision in ipairs(provisions or {}) do
        result[index] = copyProvision(provision)
    end
    return result
end

function Model.add(provisions, nextId, normalized)
    if type(normalized) ~= "table" then
        return nil, "normalized provision is required"
    end
    local result = copyList(provisions)
    result[#result + 1] = {
        id = nextId,
        name = normalized.name,
        quality = normalized.quality,
        target = normalized.target,
    }
    return result, nextId + 1, nextId
end

function Model.update(provisions, id, normalized)
    local result = copyList(provisions)
    for _, provision in ipairs(result) do
        if provision.id == id then
            provision.name = normalized.name
            provision.quality = normalized.quality
            provision.target = normalized.target
            return result, id
        end
    end
    return nil, "selected provision was not found"
end

function Model.delete(provisions, id)
    local result = {}
    local removed = false
    for _, provision in ipairs(provisions or {}) do
        if provision.id == id then
            removed = true
        else
            result[#result + 1] = copyProvision(provision)
        end
    end
    if not removed then
        return nil, "selected provision was not found"
    end
    return result
end

function Model.reorder(provisions, orderedIds)
    if type(orderedIds) ~= "table" or #orderedIds ~= #(provisions or {}) then
        return nil, "provision order must contain every saved provision ID"
    end

    local byId = {}
    for _, provision in ipairs(provisions or {}) do
        byId[provision.id] = provision
    end

    local result = {}
    local seen = {}
    for index, id in ipairs(orderedIds) do
        if seen[id] or byId[id] == nil then
            return nil, "provision order must contain every saved provision ID once"
        end
        seen[id] = true
        result[index] = copyProvision(byId[id])
    end
    return result
end

function Model.find(provisions, id)
    for _, provision in ipairs(provisions or {}) do
        if provision.id == id then
            return provision
        end
    end
    return nil
end

local function itemNameFromLink(itemLink)
    local name = type(itemLink) == "string"
        and string.match(itemLink, "|h%[([^%]]+)%]|h")
        or nil
    if name == nil then
        return nil
    end

    -- Midnight appends the crafting-quality icon markup to the item name
    -- inside the hyperlink's display brackets. Provision names intentionally
    -- omit that presentation-only suffix, so remove only trailing WoW atlas
    -- or texture markup while preserving the actual localized item name.
    local previous
    repeat
        previous = name
        name = string.gsub(name, "%s*|A:[^|]-|a%s*$", "")
        name = string.gsub(name, "%s*|T[^|]-|t%s*$", "")
    until name == previous
    return trim(name)
end

local function qualityMatches(mode, craftingQuality)
    if mode == "either" then
        return true
    elseif mode == "silver" then
        return craftingQuality == Model.SILVER_QUALITY
    elseif mode == "gold" then
        return craftingQuality == Model.GOLD_QUALITY
    end
    return false
end

local function usableIcon(icon)
    return (type(icon) == "number" and icon > 0)
        or (type(icon) == "string" and icon ~= "")
end

local function slotPrecedesIcon(slot, item)
    return item.icon == nil
        or slot.tabIndex < item.iconTabIndex
        or (slot.tabIndex == item.iconTabIndex
            and slot.slotIndex < item.iconSlotIndex)
end

local function viewableTabs(bank)
    local result = {}
    for _, tab in ipairs(bank.tabs or {}) do
        if type(tab) == "table" and tab.isViewable == true then
            result[tab.index] = true
        end
    end
    return result
end

function Model.buildReport(provisions, bank, lower)
    lower = type(lower) == "function" and lower or string.lower
    bank = type(bank) == "table" and bank or {}
    local counts = {}
    local accessibleTabs = viewableTabs(bank)
    if type(bank.scannedAt) == "table" and type(bank.slots) == "table" then
        for _, slot in ipairs(bank.slots) do
            local name = itemNameFromLink(slot.itemLink)
            if name then
                local key = lower(name)
                local qualities = counts[key]
                if qualities == nil then
                    qualities = { all = 0, silver = 0, gold = 0 }
                    counts[key] = qualities
                end
                if usableIcon(slot.icon)
                    and slotPrecedesIcon(slot, qualities) then
                    qualities.icon = slot.icon
                    qualities.iconTabIndex = slot.tabIndex
                    qualities.iconSlotIndex = slot.slotIndex
                end
                if accessibleTabs[slot.tabIndex] then
                    local quantity = tonumber(slot.quantity) or 0
                    qualities.all = qualities.all + quantity
                    if slot.craftingQuality == Model.SILVER_QUALITY then
                        qualities.silver = qualities.silver + quantity
                    elseif slot.craftingQuality == Model.GOLD_QUALITY then
                        qualities.gold = qualities.gold + quantity
                    end
                end
            end
        end
    end

    local rows = {}
    for _, provision in ipairs(provisions or {}) do
        local totals = counts[lower(provision.name)]
        local current = 0
        if totals then
            if provision.quality == "either" then
                current = totals.all
            elseif provision.quality == "silver" then
                current = totals.silver
            elseif provision.quality == "gold" then
                current = totals.gold
            end
        end
        rows[#rows + 1] = {
            id = provision.id,
            name = provision.name,
            quality = provision.quality,
            target = provision.target,
            current = current,
            progress = math.min(1, current / provision.target),
            progressText = tostring(current) .. " / " .. tostring(provision.target),
            icon = totals and totals.icon or Model.FALLBACK_ITEM_ICON,
        }
    end

    local hasShortage = false
    for _, row in ipairs(rows) do
        if row.current < row.target then
            hasShortage = true
            break
        end
    end

    return {
        rows = rows,
        canCreateShoppingList = type(bank.scannedAt) == "table"
            and #rows > 0
            and hasShortage,
    }
end

function Model.buildAuctionatorTerms(provisions, bank, lower)
    local report = Model.buildReport(provisions, bank, lower)
    local terms = {}
    for _, row in ipairs(report.rows) do
        if row.current < row.target then
            local tier
            if row.quality == "silver" then
                tier = 1
            elseif row.quality == "gold" then
                tier = 2
            end
            terms[#terms + 1] = {
                searchString = row.name,
                isExact = true,
                tier = tier,
                quantity = row.target - row.current,
            }
        end
    end
    return terms
end

function Model.qualityMatches(mode, craftingQuality)
    return qualityMatches(mode, craftingQuality)
end

function Model.itemNameFromLink(itemLink)
    return itemNameFromLink(itemLink)
end

if type(RGMS) == "table" then
    RGMS.ProvisionModel = Model
end

return Model
