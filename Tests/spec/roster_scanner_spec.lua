local datasetOwnership = require("Core.DatasetOwnership")
local dateTime = require("Core.DateTime")
local fixtures = require("Tests.fixtures")
local savedData = require("Core.SavedData")
local scannerModule = require("Roster.Scanner")
local tenure = require("Roster.Tenure")
local test = require("Tests.lib.runner")

local function successfulSnapshot(memberName)
    local guild = fixtures.guild_identity()
    local scannedAt = fixtures.timestamp({
        unixSeconds = 1717245356,
        iso8601 = "2024-06-01T12:35:56Z",
    })
    local member = fixtures.roster_member({
        name = memberName or "Newmember",
        displayName = (memberName or "Newmember") .. "-Example Realm",
        rankName = "Member",
        rankIndex = 2,
        observedAt = scannedAt,
    })
    member.rankTenureStartDate = nil
    member.lastSeenDate = nil
    member.isMissing = nil
    return {
        guild = guild,
        scannedAt = scannedAt,
        ranks = {
            fixtures.roster_rank({ index = 1, name = "Officer" }),
            fixtures.roster_rank({ index = 2, name = "Member" }),
            fixtures.roster_rank({ index = 3, name = "Empty Rank" }),
        },
        members = { member },
    }
end

local function successfulEmptySnapshot(unixSeconds)
    return {
        guild = fixtures.guild_identity(),
        scannedAt = dateTime.utcTimestamp(unixSeconds),
        ranks = { fixtures.roster_rank() },
        members = {},
    }
end

local function newHarness(options)
    options = options or {}
    local original = options.model or fixtures.saved_model()
    local current = original
    local messages = {}
    local progress = {}
    local requests = 0
    local reductions = 0
    local refreshes = 0
    local successfulCompletions = 0
    local windowOpen = true

    local ownership = datasetOwnership.create({
        savedData = savedData,
        getSavedData = function()
            return current
        end,
        commit = function(model)
            current = model
        end,
        print = function(message)
            messages[#messages + 1] = message
        end,
    })

    local api = {
        isInGuild = function()
            return options.inGuild ~= false
        end,
        requestRoster = function()
            requests = requests + 1
            if options.requestError then
                error(options.requestError)
            end
        end,
        captureSnapshot = function()
            if options.captureError then
                error(options.captureError)
            end
            if options.partial then
                return nil, "incomplete", "member list is partial"
            end
            return options.snapshot or successfulSnapshot(options.memberName)
        end,
    }

    local scanner = scannerModule.create({
        api = api,
        ownership = ownership,
        reduceRoster = function(previousDataset, snapshot)
            reductions = reductions + 1
            return tenure.reduce(previousDataset, snapshot, dateTime)
        end,
        timeoutSeconds = options.timeoutSeconds or 10,
        canScan = function()
            return options.canScan ~= false
        end,
        print = function(message)
            messages[#messages + 1] = message
        end,
        setInProgress = function(inProgress)
            progress[#progress + 1] = inProgress
        end,
        refreshStatus = function()
            refreshes = refreshes + 1
        end,
        completeSuccess = function()
            successfulCompletions = successfulCompletions + 1
        end,
    })

    return {
        scanner = scanner,
        original = original,
        current = function()
            return current
        end,
        messages = messages,
        progress = progress,
        requests = function()
            return requests
        end,
        reductions = function()
            return reductions
        end,
        refreshes = function()
            return refreshes
        end,
        successfulCompletions = function()
            return successfulCompletions
        end,
        closeWindow = function()
            windowOpen = false
        end,
        windowIsOpen = function()
            return windowOpen
        end,
    }
end

return {
    test.case("successful scan atomically replaces the current roster snapshot", function()
        local harness = newHarness({ memberName = "Latest" })

        test.assert_true(harness.scanner:Request("automatic"))
        test.assert_equal(harness.current(), harness.original)
        test.assert_true(harness.scanner:OnDataUpdated())

        test.assert_equal(harness.current().roster.members[1].displayName, "Latest-Example Realm")
        test.assert_equal(#harness.current().roster.ranks, 3)
        test.assert_equal(harness.current().roster.ranks[3].name, "Empty Rank")
        test.assert_equal(harness.current().roster.scannedAt.unixSeconds, 1717245356)
        test.assert_equal(
            harness.current().roster.members[1].rankTenureStartDate,
            "2024-06-01"
        )
        test.assert_equal(
            harness.current().roster.members[1].lastSeenDate,
            "2024-06-01"
        )
        test.assert_false(harness.current().roster.members[1].isMissing)
        test.assert_equal(harness.reductions(), 1)
        test.assert_equal(harness.progress, { true, false })
        test.assert_equal(harness.successfulCompletions(), 1)
        test.assert_matches(harness.messages[1], "scan complete")
    end),

    test.case("successful and failed transactions preserve the missing lifecycle", function()
        local startedAt = fixtures.timestamp().unixSeconds
        local firstAbsence = newHarness({
            snapshot = successfulEmptySnapshot(startedAt + 24 * 60 * 60),
        })
        test.assert_true(firstAbsence.scanner:Request("manual"))
        test.assert_true(firstAbsence.scanner:OnDataUpdated())
        local marked = firstAbsence.current()

        test.assert_true(savedData.validate(marked))
        test.assert_true(marked.roster.members[1].isMissing)
        test.assert_equal(marked.roster.members[1].lastSeenDate, "2024-06-01")

        local day21 = newHarness({
            model = marked,
            snapshot = successfulEmptySnapshot(startedAt + 21 * 24 * 60 * 60),
        })
        test.assert_true(day21.scanner:Request("manual"))
        test.assert_true(day21.scanner:OnDataUpdated())
        local retained = day21.current()

        test.assert_true(savedData.validate(retained))
        test.assert_equal(#retained.roster.members, 1)
        test.assert_true(retained.roster.members[1].isMissing)

        local failedDay22 = newHarness({
            model = retained,
            partial = true,
            timeoutSeconds = 1,
        })
        test.assert_true(failedDay22.scanner:Request("manual"))
        local completed, state = failedDay22.scanner:OnDataUpdated()
        test.assert_false(completed)
        test.assert_equal(state, "incomplete")
        failedDay22.scanner:Update(1)
        test.assert_equal(failedDay22.current(), retained)
        test.assert_equal(failedDay22.successfulCompletions(), 0)

        local day22 = newHarness({
            model = retained,
            snapshot = successfulEmptySnapshot(startedAt + 22 * 24 * 60 * 60),
        })
        test.assert_true(day22.scanner:Request("manual"))
        test.assert_true(day22.scanner:OnDataUpdated())
        test.assert_true(savedData.validate(day22.current()))
        test.assert_equal(#day22.current().roster.members, 0)
    end),

    test.case("unguilded automatic scan is silent and manual scan reports an error", function()
        local harness = newHarness({ inGuild = false })

        local started, reason = harness.scanner:Request("automatic")
        test.assert_nil(started)
        test.assert_equal(reason, "not-in-guild")
        test.assert_equal(harness.messages, {})

        started, reason = harness.scanner:Request("manual")
        test.assert_nil(started)
        test.assert_equal(reason, "not-in-guild")
        test.assert_matches(harness.messages[1], "not in a guild")
        test.assert_equal(harness.requests(), 0)
        test.assert_equal(harness.current(), harness.original)
    end),

    test.case("timeout preserves the last successful roster and reports failure", function()
        local harness = newHarness({ timeoutSeconds = 10 })
        test.assert_true(harness.scanner:Request("manual"))

        test.assert_false(harness.scanner:Update(9.5))
        local finished, reason = harness.scanner:Update(0.5)

        test.assert_nil(finished)
        test.assert_equal(reason, "timeout")
        test.assert_equal(harness.current(), harness.original)
        test.assert_false(harness.current().roster.members[1].isMissing)
        test.assert_matches(harness.messages[1], "timed out")
        test.assert_false(harness.scanner:IsInProgress())
    end),

    test.case("partial roster data waits and is discarded on timeout", function()
        local harness = newHarness({ partial = true, timeoutSeconds = 2 })
        test.assert_true(harness.scanner:Request("manual"))

        local completed, state = harness.scanner:OnDataUpdated()
        test.assert_false(completed)
        test.assert_equal(state, "incomplete")
        test.assert_equal(harness.current(), harness.original)
        test.assert_equal(harness.reductions(), 0)
        test.assert_true(harness.scanner:IsInProgress())

        harness.scanner:Update(2)
        test.assert_equal(harness.current(), harness.original)
        test.assert_false(harness.current().roster.members[1].isMissing)
        test.assert_matches(harness.messages[1], "timed out")
    end),

    test.case("duplicate requests are rejected by the shared scanner", function()
        local harness = newHarness()
        test.assert_true(harness.scanner:Request("manual"))

        local started, reason = harness.scanner:Request("manual")

        test.assert_nil(started)
        test.assert_equal(reason, "scan-in-progress")
        test.assert_equal(harness.requests(), 1)
        test.assert_matches(harness.messages[1], "already in progress")
    end),

    test.case("closing the window does not cancel an in-progress scan", function()
        local harness = newHarness({ memberName = "Background" })
        test.assert_true(harness.scanner:Request("manual"))
        harness.closeWindow()

        test.assert_false(harness.windowIsOpen())
        test.assert_true(harness.scanner:IsInProgress())
        test.assert_true(harness.scanner:OnDataUpdated())
        test.assert_equal(
            harness.current().roster.members[1].displayName,
            "Background-Example Realm"
        )
    end),

    test.case("API failures preserve prior data and finish without retrying", function()
        local harness = newHarness({ captureError = "simulated client failure" })
        test.assert_true(harness.scanner:Request("automatic"))

        local completed, reason = harness.scanner:OnDataUpdated()

        test.assert_nil(completed)
        test.assert_equal(reason, "api-failure")
        test.assert_equal(harness.current(), harness.original)
        test.assert_false(harness.current().roster.members[1].isMissing)
        test.assert_equal(harness.reductions(), 0)
        test.assert_equal(harness.requests(), 1)
        test.assert_matches(harness.messages[1], "simulated client failure")
    end),
}
