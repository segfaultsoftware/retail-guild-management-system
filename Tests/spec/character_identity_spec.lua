local characterIdentity = require("Core.CharacterIdentity")
local clientFlavor = require("Core.ClientFlavor")
local names = require("Roster.Names")
local test = require("Tests.lib.runner")

local function create(input)
    local result, createError = characterIdentity.create(input)
    if not result then
        error(createError)
    end
    return result
end

local function assertCreateError(input, expected)
    local result, createError = characterIdentity.create(input)
    test.assert_nil(result)
    test.assert_equal(createError, expected)
end

local function readAll(path)
    local file = assert(io.open(path, "rb"))
    local contents = file:read("*a")
    file:close()
    return contents
end

return {
    test.case("Retail construction preserves established keys and labels", function()
        local realm = "Ner'Zhul-Ner'zhul-Ne"
        local identity = create({
            flavor = clientFlavor.RETAIL,
            region = "us",
            name = "Nalla",
            realm = realm,
            guid = "Player-1-00000001",
        })

        test.assert_equal(identity.key, names.identity("Nalla", realm))
        test.assert_equal(identity.displayName, names.displayName("Nalla", realm))
        test.assert_equal(identity.sortName, "nalla-ner'zhul")
        test.assert_equal(identity.region, "US")
        test.assert_equal(identity.realm, "Ner'Zhul")
        test.assert_equal(identity.guid, "Player-1-00000001")

        local caseVariant = create({
            flavor = clientFlavor.RETAIL,
            region = "US",
            name = "nalla",
            realm = "ner'zhul",
        })
        test.assert_true(characterIdentity.same(identity, caseVariant))
        test.assert_equal(characterIdentity.compare(identity, caseVariant), 0)
    end),

    test.case("Forever full names remain indivisible and product scoped", function()
        local fullName = "Nalla-Area52 Ash"
        local forever = create({
            flavor = clientFlavor.FOREVER,
            region = "US",
            name = fullName,
        })
        local retail = create({
            flavor = clientFlavor.RETAIL,
            region = "US",
            name = "Nalla",
            realm = "Area52 Ash",
        })

        test.assert_equal(forever.name, fullName)
        test.assert_nil(forever.realm)
        test.assert_equal(forever.displayName, fullName)
        test.assert_equal(
            forever.key,
            "RGMS:CHARACTER:FOREVER:1:2:US:"
                .. tostring(#fullName) .. ":" .. fullName
        )
        test.assert_equal(forever.displayName, retail.displayName)
        test.assert_false(characterIdentity.same(forever, retail))
    end),

    test.case("Forever surnames and regions independently namespace keys", function()
        local ash = create({
            flavor = clientFlavor.FOREVER,
            region = "US",
            name = "Avery Ash",
        })
        local birch = create({
            flavor = clientFlavor.FOREVER,
            region = "US",
            name = "Avery Birch",
        })
        local europeanAsh = create({
            flavor = clientFlavor.FOREVER,
            region = "eu",
            name = "Avery Ash",
        })

        test.assert_false(characterIdentity.same(ash, birch))
        test.assert_false(characterIdentity.same(ash, europeanAsh))
        test.assert_equal(europeanAsh.region, "EU")
        test.assert_equal(ash.displayName, europeanAsh.displayName)
    end),

    test.case("Forever construction preserves exact bytes and whitespace", function()
        local composed = "\195\137lodie  Ash-Realm"
        local decomposed = "E\204\129lodie  Ash-Realm"
        local first = create({
            flavor = clientFlavor.FOREVER,
            region = "US",
            name = composed,
        })
        local second = create({
            flavor = clientFlavor.FOREVER,
            region = "US",
            name = decomposed,
        })
        local caseVariant = create({
            flavor = clientFlavor.FOREVER,
            region = "US",
            name = "\195\137LODIE  Ash-Realm",
        })

        test.assert_equal(first.displayName, composed)
        test.assert_equal(first.name, composed)
        test.assert_false(characterIdentity.same(first, second))
        test.assert_false(characterIdentity.same(first, caseVariant))
    end),

    test.case("GUID is optional correlation metadata and never key material", function()
        local withoutGuid = create({
            flavor = clientFlavor.FOREVER,
            region = "US",
            name = "Avery Ash",
        })
        local withGuid = create({
            flavor = clientFlavor.FOREVER,
            region = "US",
            name = "Avery Ash",
            guid = "Player-18-00000001",
        })

        test.assert_nil(withoutGuid.guid)
        test.assert_equal(withGuid.guid, "Player-18-00000001")
        test.assert_equal(withGuid.key, withoutGuid.key)
        test.assert_true(characterIdentity.same(withGuid, withoutGuid))
    end),

    test.case("repeated construction is stable and input remains untouched", function()
        local input = {
            flavor = clientFlavor.FOREVER,
            region = "us",
            name = "Avery  Ash-Realm",
            guid = "Player-18-00000001",
        }
        local first = create(input)
        local second = create(input)

        test.assert_equal(first, second)
        test.assert_equal(input.region, "us")
        test.assert_equal(input.name, "Avery  Ash-Realm")
    end),

    test.case("construction reports every unavailable identity input", function()
        assertCreateError(nil, "character identity input must be a table")
        assertCreateError({
            region = "US",
            name = "Avery Ash",
        }, "character flavor is unavailable")
        assertCreateError({
            flavor = clientFlavor.UNSUPPORTED,
            region = "US",
            name = "Avery Ash",
        }, "character flavor is unavailable")
        assertCreateError({
            flavor = "classic",
            region = "US",
            name = "Avery Ash",
        }, "character flavor is unsupported")
        assertCreateError({
            flavor = clientFlavor.FOREVER,
            name = "Avery Ash",
        }, "character region is unavailable")
        assertCreateError({
            flavor = clientFlavor.FOREVER,
            region = "Unknown",
            name = "Avery Ash",
        }, "character region is unsupported")
        assertCreateError({
            flavor = clientFlavor.FOREVER,
            region = "US",
        }, "character name is unavailable")
        assertCreateError({
            flavor = clientFlavor.RETAIL,
            region = "US",
            name = "Nalla",
        }, "Retail character realm is unavailable")
    end),

    test.case("Forever construction requires a complete two-part name", function()
        for _, incompleteName in ipairs({
            "Avery",
            "   ",
            " Avery Ash",
            "Avery Ash ",
            "Avery Ash Stone",
        }) do
            assertCreateError({
                flavor = clientFlavor.FOREVER,
                region = "US",
                name = incompleteName,
            }, "Forever character name must be a complete two-part value")
        end

        local repeatedSeparator = create({
            flavor = clientFlavor.FOREVER,
            region = "US",
            name = "Avery  Ash",
        })
        test.assert_equal(repeatedSeparator.displayName, "Avery  Ash")
    end),

    test.case("construction rejects realm misuse and malformed GUID metadata", function()
        assertCreateError({
            flavor = clientFlavor.FOREVER,
            region = "US",
            name = "Avery Ash",
            realm = "Not-A-Realm",
        }, "Forever character realm must be unavailable")
        assertCreateError({
            flavor = clientFlavor.FOREVER,
            region = "US",
            name = "Avery Ash",
            guid = "",
        }, "character GUID must be a non-empty string when provided")
    end),

    test.case("validation rejects noncanonical identity records", function()
        local identity = create({
            flavor = clientFlavor.FOREVER,
            region = "US",
            name = "Avery Ash",
        })
        test.assert_true(characterIdentity.validate(identity))

        identity.displayName = "Avery"
        local valid, validationError = characterIdentity.validate(identity)
        test.assert_nil(valid)
        test.assert_equal(
            validationError,
            "character identity displayName is not canonical"
        )
    end),

    test.case("comparison uses deterministic separate sort inputs", function()
        local beta = create({
            flavor = clientFlavor.FOREVER,
            region = "US",
            name = "Beta Ash",
        })
        local alphaUS = create({
            flavor = clientFlavor.FOREVER,
            region = "US",
            name = "alpha Ash",
        })
        local alphaEU = create({
            flavor = clientFlavor.FOREVER,
            region = "EU",
            name = "alpha Ash",
        })

        test.assert_equal(characterIdentity.compare(alphaUS, beta), -1)
        test.assert_equal(characterIdentity.compare(beta, alphaUS), 1)

        local regionalOrder = characterIdentity.compare(alphaUS, alphaEU)
        test.assert_true(regionalOrder == -1 or regionalOrder == 1)
        test.assert_equal(
            characterIdentity.compare(alphaEU, alphaUS),
            -regionalOrder
        )
    end),

    test.case("comparison preserves equal-key ordering equivalence", function()
        local retail = create({
            flavor = clientFlavor.RETAIL,
            region = "US",
            name = "Alpha",
            realm = "Realm Name",
        })
        local retailCaseVariant = create({
            flavor = clientFlavor.RETAIL,
            region = "US",
            name = "alpha",
            realm = "realm name",
        })
        local forever = create({
            flavor = clientFlavor.FOREVER,
            region = "US",
            name = "alpha-realm name",
        })

        test.assert_equal(characterIdentity.compare(retail, retailCaseVariant), 0)
        local retailOrder = characterIdentity.compare(retail, forever)
        test.assert_true(retailOrder == -1 or retailOrder == 1)
        test.assert_equal(
            characterIdentity.compare(retailCaseVariant, forever),
            retailOrder
        )
    end),

    test.case("Forever framing remains unambiguous around delimiters", function()
        local first = create({
            flavor = clientFlavor.FOREVER,
            region = "US",
            name = "A:1 B:23",
        })
        local second = create({
            flavor = clientFlavor.FOREVER,
            region = "US",
            name = "A:1:2 B:3",
        })

        test.assert_false(characterIdentity.same(first, second))
        test.assert_false(first.key == second.key)
    end),

    test.case("addon loading exposes identity after its dependencies", function()
        local addon = {
            ClientFlavor = clientFlavor,
            RosterNames = names,
        }
        local loaded = assert(loadfile("Core/CharacterIdentity.lua"))(
            "RGMS",
            addon
        )
        test.assert_equal(addon.CharacterIdentity, loaded)

        local manifest = readAll("RGMS.toc")
        local flavorAt = assert(string.find(
            manifest,
            "Core\\ClientFlavor.lua",
            1,
            true
        ))
        local namesAt = assert(string.find(
            manifest,
            "Roster\\Names.lua",
            1,
            true
        ))
        local identityAt = assert(string.find(
            manifest,
            "Core\\CharacterIdentity.lua",
            1,
            true
        ))
        local dateTimeAt = assert(string.find(
            manifest,
            "Core\\DateTime.lua",
            1,
            true
        ))

        test.assert_true(flavorAt < namesAt)
        test.assert_true(namesAt < identityAt)
        test.assert_true(identityAt < dateTimeAt)
    end),
}
