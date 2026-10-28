local integration = require("Provisions.Auctionator")
local test = require("Tests.lib.runner")

local function fakeAuctionator(overrides)
    local value = {
        converted = {},
        creations = {},
    }
    value.API = { v1 = {} }
    value.API.v1.ConvertToSearchString = function(callerID, term)
        value.converted[#value.converted + 1] = {
            callerID = callerID,
            term = term,
        }
        return term.searchString .. ":" .. tostring(term.quantity)
    end
    value.API.v1.CreateShoppingList = function(callerID, name, searchStrings)
        value.creations[#value.creations + 1] = {
            callerID = callerID,
            name = name,
            searchStrings = searchStrings,
        }
    end
    for key, item in pairs(overrides or {}) do
        value.API.v1[key] = item
    end
    return value
end

return {
    test.case("availability requires both supported Auctionator v1 list APIs", function()
        test.assert_false(integration.IsAvailable({}))
        test.assert_false(integration.IsAvailable({ API = { v1 = {
            ConvertToSearchString = function() end,
        } } }))
        test.assert_true(integration.IsAvailable(fakeAuctionator()))
    end),

    test.case("shopping-list creation converts ordered duplicate terms and replaces the RGMS list", function()
        local auctionator = fakeAuctionator()
        local terms = {
            { searchString = "Argentleaf", isExact = true, tier = 1, quantity = 40 },
            { searchString = "Argentleaf", isExact = true, tier = 1, quantity = 20 },
            { searchString = "Peacebloom", isExact = true, quantity = 5 },
        }

        test.assert_true(integration.CreateShoppingList(terms, auctionator))

        test.assert_equal(auctionator.converted[1].callerID, "RGMS")
        test.assert_true(auctionator.converted[1].term == terms[1])
        test.assert_true(auctionator.converted[2].term == terms[2])
        test.assert_equal(auctionator.creations, {
            {
                callerID = "RGMS",
                name = "RGMS Provisions",
                searchStrings = {
                    "Argentleaf:40",
                    "Argentleaf:20",
                    "Peacebloom:5",
                },
            },
        })
    end),

    test.case("conversion and creation failures are returned without false success", function()
        local createCalls = 0
        local conversionFailure = fakeAuctionator({
            ConvertToSearchString = function()
                error("conversion rejected")
            end,
            CreateShoppingList = function()
                createCalls = createCalls + 1
            end,
        })
        local result, message = integration.CreateShoppingList({
            { searchString = "Herb", isExact = true, quantity = 1 },
        }, conversionFailure)
        test.assert_nil(result)
        test.assert_matches(message, "conversion rejected")
        test.assert_equal(createCalls, 0)

        local creationFailure = fakeAuctionator({
            CreateShoppingList = function()
                error("creation rejected")
            end,
        })
        result, message = integration.CreateShoppingList({
            { searchString = "Herb", isExact = true, quantity = 1 },
        }, creationFailure)
        test.assert_nil(result)
        test.assert_matches(message, "creation rejected")
    end),
}
