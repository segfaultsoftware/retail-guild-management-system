local names = require("Roster.Names")
local test = require("Tests.lib.runner")

local GLOBALS = {
    "C_GuildInfo",
    "GetGuildRosterInfo",
    "GetNumGuildMembers",
    "GetNormalizedRealmName",
    "GetRealmName",
    "IsInGuild",
    "UnitFullName",
    "GuildRosterSetPublicNote",
    "GuildRosterSetOfficerNote",
}

local function withGlobals(callback)
    local saved = {}
    for _, key in ipairs(GLOBALS) do
        saved[key] = _G[key]
    end
    local completed, message = pcall(callback)
    for _, key in ipairs(GLOBALS) do
        _G[key] = saved[key]
    end
    if not completed then
        error(message, 0)
    end
end

local function loadAdapter()
    local rgms = { RosterNames = names }
    local chunk = assert(loadfile("MainsAlts/NotesRetail.lua"))
    return chunk("RGMS", rgms)
end

return {
    test.case("live-note Retail adapter captures permissions and avoids protected GUID writes", function()
        withGlobals(function()
            local writes = {}
            local protectedCalls = 0
            C_GuildInfo = {
                GetGuildRosterInfo = function(index)
                    if index == 1 then
                        return {
                            name = "Main-Area52",
                            note = " public ",
                            officerNote = " officer ",
                            guid = "Player-1",
                        }
                    end
                end,
                CanViewOfficerNote = function() return true end,
                CanEditOfficerNote = function() return false end,
                CanEditPublicNote = function() return true end,
                SetNote = function(...)
                    protectedCalls = protectedCalls + 1
                end,
                GuildRoster = function() end,
            }
            GetNumGuildMembers = function() return 1 end
            GetNormalizedRealmName = function() return "Area52" end
            IsInGuild = function() return true end
            UnitFullName = function() return "Main", "Area52" end
            GuildRosterSetPublicNote = function(index, value)
                writes[#writes + 1] = { "public", index, value }
            end
            GuildRosterSetOfficerNote = function(index, value)
                writes[#writes + 1] = { "officer", index, value }
            end

            local api = loadAdapter().createApi()
            local snapshot = api:captureRoster()
            local member = snapshot.members["main-area52"]
            test.assert_equal(member.publicNote, " public ")
            test.assert_equal(member.officerNote, " officer ")
            test.assert_true(member.isSelf)
            test.assert_true(snapshot.permissions.viewOfficer)
            test.assert_false(snapshot.permissions.editOfficer)
            test.assert_true(snapshot.permissions.editPublic)

            test.assert_true(api:writeNote(member, "public", " exact "))
            test.assert_true(api:writeNote(member, "officer", "officer"))
            test.assert_equal(writes, {
                { "public", 1, " exact " },
                { "officer", 1, "officer" },
            })
            test.assert_equal(protectedCalls, 0)
        end)
    end),

    test.case("live-note Retail adapter rejects protected-only writes safely", function()
        withGlobals(function()
            local protectedCalls = 0
            C_GuildInfo = {
                SetNote = function()
                    protectedCalls = protectedCalls + 1
                end,
                GuildRoster = function() end,
            }
            GuildRosterSetPublicNote = nil
            GuildRosterSetOfficerNote = nil

            local api = loadAdapter().createApi()
            local written, message = api:writeNote({
                guid = "Player-1",
                index = 1,
            }, "public", "note")

            test.assert_nil(written)
            test.assert_matches(message, "protected")
            test.assert_equal(protectedCalls, 0)
        end)
    end),

    test.case("live-note Retail adapter falls back to indexed guild-note APIs", function()
        withGlobals(function()
            local writes = {}
            C_GuildInfo = { GuildRoster = function() end }
            GetNumGuildMembers = function() return 1 end
            GetNormalizedRealmName = function() return "Area52" end
            IsInGuild = function() return true end
            UnitFullName = function() return "Other", "Area52" end
            GetGuildRosterInfo = function()
                return "Main-Area52", "Member", 3, 80, "Mage", "City",
                    "public", "officer", true, 0, "MAGE", 0, 0, false,
                    false, 0, nil
            end
            GuildRosterSetPublicNote = function(index, value)
                writes[#writes + 1] = { "public", index, value }
            end
            GuildRosterSetOfficerNote = function(index, value)
                writes[#writes + 1] = { "officer", index, value }
            end

            local api = loadAdapter().createApi()
            local member = api:captureRoster().members["main-area52"]
            test.assert_true(api:writeNote(member, "public", "one"))
            test.assert_true(api:writeNote(member, "officer", "two"))
            test.assert_equal(writes, {
                { "public", 1, "one" },
                { "officer", 1, "two" },
            })
        end)
    end),
}
