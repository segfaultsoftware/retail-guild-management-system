local accountData = require("Core.AccountData")
local clientFlavor = require("Core.ClientFlavor")
local guildIdentity = require("Core.GuildIdentity")
local fixtureLoader = require("Tests.runtime_contract_fixtures")
local test = require("Tests.lib.runner")

local FOREVER_PATH = "Tests/fixtures/runtime_contract/forever.lua"

local function create(input)
    local result, createError = guildIdentity.create(input)
    if not result then
        error(createError)
    end
    return result
end

local function assertCreateError(input, expected)
    local result, createError = guildIdentity.create(input)
    test.assert_nil(result)
    test.assert_equal(createError, expected)
end

local function readAll(path)
    local file = assert(io.open(path, "rb"))
    local contents = file:read("*a")
    file:close()
    return contents
end

local function retailInput(overrides)
    local result = {
        flavor = clientFlavor.RETAIL,
        region = "US",
        name = "Night Shift",
        realm = {
            name = "Area 52",
            slug = "area-52",
        },
    }
    for key, value in pairs(overrides or {}) do
        result[key] = value
    end
    return result
end

local function foreverInput(overrides)
    local result = {
        flavor = clientFlavor.FOREVER,
        region = "US",
        name = "Night Shift",
        clubId = "Club-001",
    }
    for key, value in pairs(overrides or {}) do
        result[key] = value
    end
    return result
end

return {
    test.case("Retail construction preserves established account partition keys", function()
        local input = retailInput({
            region = "us",
            name = "Ner'zhul Society",
            realm = {
                name = "Ner'Zhul-Ner'zhul-Ne",
                slug = "Ner'Zhul-Ner'zhul-Ne",
            },
        })
        local identity = create(input)
        local establishedKey = "16:Ner'zhul Society:ner'zhul"

        test.assert_equal(identity.key, establishedKey)
        test.assert_equal(assert(accountData.guildKey(identity)), establishedKey)
        test.assert_equal(
            identity.key,
            "16:Ner'zhul Society:ner'zhul"
        )
        test.assert_equal(identity.region, "US")
        test.assert_equal(identity.name, "Ner'zhul Society")
        test.assert_equal(identity.displayName, "Ner'zhul Society")
        test.assert_equal(identity.realm, {
            name = "Ner'Zhul",
            slug = "Ner'Zhul",
        })
        test.assert_nil(identity.clubId)
    end),

    test.case("Retail realm normalization preserves ownership boundaries", function()
        local original = create(retailInput({
            realm = {
                name = "Area 52",
                slug = "Area-52-Area-52-Ar",
            },
        }))
        local realmCaseVariant = create(retailInput({
            realm = {
                name = "AREA 52",
                slug = "AREA-52",
            },
        }))
        local differentRealm = create(retailInput({
            realm = { name = "Illidan", slug = "illidan" },
        }))
        local nameCaseVariant = create(retailInput({
            name = "Night shift",
        }))

        test.assert_true(guildIdentity.same(original, realmCaseVariant))
        test.assert_false(guildIdentity.same(original, differentRealm))
        test.assert_false(guildIdentity.same(original, nameCaseVariant))
        test.assert_equal(original.realm.slug, "Area-52")
    end),

    test.case("Retail and Forever ownership keys cannot collide", function()
        local retail = create(retailInput({
            name = "Night Shift",
            realm = { name = "Club 001", slug = "Club-001" },
        }))
        local forever = create(foreverInput({
            name = retail.displayName,
        }))

        test.assert_equal(retail.displayName, forever.displayName)
        test.assert_false(retail.key == forever.key)
        test.assert_false(guildIdentity.same(retail, forever))
    end),

    test.case("Forever ownership uses region and stable club ID only", function()
        local original = create(foreverInput())
        local renamed = create(foreverInput({ name = "Renamed Guild" }))
        local european = create(foreverInput({ region = "eu" }))
        local differentClub = create(foreverInput({ clubId = "Club-002" }))

        test.assert_equal(
            original.key,
            "RGMS:GUILD:FOREVER:1:2:US:8:Club-001"
        )
        test.assert_true(guildIdentity.same(original, renamed))
        test.assert_equal(original.key, renamed.key)
        test.assert_false(original.displayName == renamed.displayName)
        test.assert_false(guildIdentity.same(original, european))
        test.assert_false(guildIdentity.same(original, differentClub))
        test.assert_nil(original.realm)
    end),

    test.case("numeric and string Forever club IDs normalize identically", function()
        local numeric = create(foreverInput({ clubId = 123456 }))
        local textual = create(foreverInput({ clubId = "123456" }))

        test.assert_equal(numeric.clubId, "123456")
        test.assert_equal(numeric.key, textual.key)
        test.assert_true(guildIdentity.same(numeric, textual))
    end),

    test.case("construction fails closed for unavailable common inputs", function()
        assertCreateError(nil, "guild identity input must be a table")
        assertCreateError({
            region = "US",
            name = "Night Shift",
        }, "guild flavor is unavailable")
        assertCreateError({
            flavor = clientFlavor.UNSUPPORTED,
            region = "US",
            name = "Night Shift",
        }, "guild flavor is unavailable")
        assertCreateError({
            flavor = "classic",
            region = "US",
            name = "Night Shift",
        }, "guild flavor is unsupported")
        assertCreateError({
            flavor = clientFlavor.FOREVER,
            name = "Night Shift",
            clubId = "Club-001",
        }, "guild region is unavailable")
        assertCreateError(foreverInput({ region = "Unknown" }),
            "guild region is unsupported")
        assertCreateError(foreverInput({ name = "" }),
            "guild name is unavailable")
    end),

    test.case("Retail construction requires canonicalizable realm metadata", function()
        local missingRealm = retailInput()
        missingRealm.realm = nil
        assertCreateError(missingRealm,
            "Retail guild realm is unavailable")
        assertCreateError(retailInput({ realm = "area-52" }),
            "Retail guild realm is unavailable")
        assertCreateError(retailInput({
            realm = { name = "Area 52", slug = "" },
        }), "Retail guild realm requires a name and slug")
        assertCreateError(retailInput({ clubId = "Club-001" }),
            "Retail guild club ID must be unavailable")
    end),

    test.case("Forever construction requires the approved club ID without fallback", function()
        local missingClubId = foreverInput()
        missingClubId.clubId = nil
        assertCreateError(missingClubId,
            "Forever guild club ID is unavailable")
        assertCreateError(foreverInput({ clubId = "" }),
            "Forever guild club ID is unavailable")
        for _, invalidClubId in ipairs({ 0, -1, 1.5, math.huge, {}, true }) do
            assertCreateError(foreverInput({ clubId = invalidClubId }),
                "Forever guild club ID is unavailable")
        end
        assertCreateError(foreverInput({
            realm = { name = "Not A Realm", slug = "not-a-realm" },
        }), "Forever guild realm must be unavailable")
    end),

    test.case("construction is stable and leaves caller input untouched", function()
        local input = retailInput({
            region = "us",
            realm = {
                name = "Area 52-Area 52-Ar",
                slug = "Area-52-Area-52-Ar",
            },
        })
        local first = create(input)
        local second = create(input)

        test.assert_equal(first, second)
        test.assert_equal(input.region, "us")
        test.assert_equal(input.realm.name, "Area 52-Area 52-Ar")
        test.assert_equal(input.realm.slug, "Area-52-Area-52-Ar")
    end),

    test.case("validation and equality reject noncanonical identities", function()
        local retail = create(retailInput())
        test.assert_true(guildIdentity.validate(retail))

        retail.realm.slug = "area-52-area-52-ar"
        local valid, validationError = guildIdentity.validate(retail)
        test.assert_nil(valid)
        test.assert_equal(
            validationError,
            "guild identity realm.slug is not canonical"
        )

        local same, sameError = guildIdentity.same(nil, create(foreverInput()))
        test.assert_nil(same)
        test.assert_equal(
            sameError,
            "left guild identity is invalid: guild identity must be a table"
        )
    end),

    test.case("Forever framing remains unambiguous around delimiters", function()
        local first = create(foreverInput({ clubId = "A:1" }))
        local second = create(foreverInput({ clubId = "A:1:2" }))

        test.assert_false(first.key == second.key)
        test.assert_false(guildIdentity.same(first, second))
    end),

    test.case("Feature 1.1 Forever fixtures construct one stable guild identity", function()
        local fixture = assert(fixtureLoader.load(FOREVER_PATH))
        local expected
        local constructed = 0
        for _, session in ipairs(fixture.sessions) do
            for _, observation in ipairs(session.observations) do
                if observation.guild.clubId ~= nil
                    and observation.guild.name ~= nil then
                    local actual = create({
                        flavor = clientFlavor.FOREVER,
                        region = session.runtime.region,
                        name = observation.guild.name,
                        clubId = observation.guild.clubId,
                    })
                    expected = expected or actual
                    test.assert_equal(actual, expected)
                    constructed = constructed + 1
                end
            end
        end

        test.assert_true(constructed > 0)
        assertCreateError({
            flavor = clientFlavor.FOREVER,
            region = fixture.sessions[1].runtime.region,
            name = expected.name,
        }, "Forever guild club ID is unavailable")
    end),

    test.case("addon loading exposes guild identity after its dependencies", function()
        local addon = {
            ClientFlavor = clientFlavor,
            Realm = require("Core.Realm"),
        }
        local loaded = assert(loadfile("Core/GuildIdentity.lua"))(
            "RGMS",
            addon
        )
        test.assert_equal(addon.GuildIdentity, loaded)

        local manifest = readAll("RGMS.toc")
        local flavorAt = assert(string.find(
            manifest,
            "Core\\ClientFlavor.lua",
            1,
            true
        ))
        local realmAt = assert(string.find(
            manifest,
            "Core\\Realm.lua",
            1,
            true
        ))
        local identityAt = assert(string.find(
            manifest,
            "Core\\GuildIdentity.lua",
            1,
            true
        ))
        local savedDataAt = assert(string.find(
            manifest,
            "Core\\SavedData.lua",
            1,
            true
        ))

        test.assert_true(flavorAt < identityAt)
        test.assert_true(realmAt < identityAt)
        test.assert_true(identityAt < savedDataAt)
    end),
}
