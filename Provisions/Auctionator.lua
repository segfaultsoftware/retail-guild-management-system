-- Thin adapter around Auctionator's supported v1 shopping-list API.

local _, RGMS = ...

local Integration = {}

Integration.CALLER_ID = "RGMS"
Integration.LIST_NAME = "RGMS Provisions"

local function resolveAPI(auctionator)
    auctionator = auctionator or rawget(_G, "Auctionator")
    local api = type(auctionator) == "table"
        and type(auctionator.API) == "table"
        and type(auctionator.API.v1) == "table"
        and auctionator.API.v1
        or nil
    if type(api) ~= "table"
        or type(api.ConvertToSearchString) ~= "function"
        or type(api.CreateShoppingList) ~= "function" then
        return nil
    end
    return api
end

function Integration.IsAvailable(auctionator)
    return resolveAPI(auctionator) ~= nil
end

function Integration.CreateShoppingList(terms, auctionator)
    local api = resolveAPI(auctionator)
    if not api then
        return nil, "Auctionator v1 shopping-list API is unavailable"
    end
    if type(terms) ~= "table" then
        return nil, "shopping-list terms must be a table"
    end

    local searchStrings = {}
    for index, term in ipairs(terms) do
        local converted, searchString = pcall(
            api.ConvertToSearchString,
            Integration.CALLER_ID,
            term
        )
        if not converted then
            return nil, searchString
        end
        if type(searchString) ~= "string" then
            return nil, "Auctionator returned an invalid search string"
        end
        searchStrings[index] = searchString
    end

    local created, creationError = pcall(
        api.CreateShoppingList,
        Integration.CALLER_ID,
        Integration.LIST_NAME,
        searchStrings
    )
    if not created then
        return nil, creationError
    end
    return true
end

if type(RGMS) == "table" then
    RGMS.AuctionatorIntegration = Integration
end

return Integration
