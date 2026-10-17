-- Transaction coordinator for complete guild-roster observations. The scanner
-- owns no WoW frames or globals; the Retail adapter and deterministic tests
-- provide those through dependencies.

local _, RGMS = ...

local Scanner = {}
Scanner.DEFAULT_TIMEOUT_SECONDS = 15

local function count(values)
    return type(values) == "table" and #values or 0
end

function Scanner.create(dependencies)
    local scanner = {
        dependencies = dependencies,
        inProgress = false,
        elapsed = 0,
        source = nil,
        timeoutSeconds = dependencies.timeoutSeconds
            or Scanner.DEFAULT_TIMEOUT_SECONDS,
    }

    local function printMessage(message)
        dependencies.print(message)
    end

    function scanner:IsInProgress()
        return self.inProgress
    end

    function scanner:SetProgress(inProgress)
        self.inProgress = inProgress
        dependencies.setInProgress(inProgress)
    end

    function scanner:FinishFailure(message, reason)
        if self.inProgress then
            self:SetProgress(false)
        end
        self.elapsed = 0
        self.source = nil
        dependencies.refreshStatus()
        printMessage("Guild roster scan failed: " .. tostring(message) .. ".")
        return nil, reason or "scan-failed"
    end

    function scanner:Request(source)
        source = source == "automatic" and "automatic" or "manual"

        if self.inProgress then
            printMessage(
                "A guild roster scan is already in progress; no second scan was started."
            )
            return nil, "scan-in-progress"
        end

        if not dependencies.api:isInGuild() then
            if source ~= "automatic" then
                printMessage(
                    "Cannot scan the guild roster because this character is not in a guild."
                )
            end
            return nil, "not-in-guild"
        end

        if not dependencies.canScan() then
            return nil, "scanning-disabled"
        end

        self.elapsed = 0
        self.source = source
        self:SetProgress(true)

        local requested, requestError = pcall(function()
            dependencies.api:requestRoster()
        end)
        if not requested then
            return self:FinishFailure(
                "the game client rejected the roster request (" .. tostring(requestError) .. ")",
                "api-failure"
            )
        end

        return true
    end

    function scanner:RequestRosterUpdate()
        if not self.inProgress then
            return false
        end

        local requested, requestError = pcall(function()
            dependencies.api:requestRoster()
        end)
        if not requested then
            return self:FinishFailure(
                "the game client rejected the roster request (" .. tostring(requestError) .. ")",
                "api-failure"
            )
        end
        return true
    end

    function scanner:OnDataUpdated()
        if not self.inProgress then
            return false
        end

        local captured, snapshot, captureState, captureError = pcall(function()
            return dependencies.api:captureSnapshot()
        end)
        if not captured then
            return self:FinishFailure(
                "the game client could not provide roster data (" .. tostring(snapshot) .. ")",
                "api-failure"
            )
        end
        if snapshot == nil then
            if captureState == "incomplete" then
                return false, "incomplete"
            end
            return self:FinishFailure(
                captureError or "the game client could not provide roster data",
                captureState or "api-failure"
            )
        end

        local transaction, beginError = dependencies.ownership:begin(
            "roster",
            snapshot.guild
        )
        if not transaction then
            return self:FinishFailure(beginError, "transaction-failure")
        end

        local reducedDataset, reduceError = dependencies.reduceRoster(
            transaction.dataset,
            snapshot
        )
        if not reducedDataset then
            return self:FinishFailure(reduceError, "transaction-failure")
        end
        transaction.dataset = reducedDataset

        local committed, commitResult = dependencies.ownership:finish(
            transaction,
            "success"
        )
        if not committed then
            return self:FinishFailure(commitResult, "transaction-failure")
        end

        self:SetProgress(false)
        self.elapsed = 0
        self.source = nil
        if type(dependencies.completeSuccess) == "function" then
            dependencies.completeSuccess()
        end
        dependencies.refreshStatus()
        printMessage(string.format(
            "Guild roster scan complete: %d members across %d ranks.",
            count(snapshot.members),
            count(snapshot.ranks)
        ))
        return true, commitResult
    end

    function scanner:Update(elapsed)
        if not self.inProgress then
            return false
        end

        self.elapsed = self.elapsed + (tonumber(elapsed) or 0)
        if self.elapsed >= self.timeoutSeconds then
            return self:FinishFailure(
                "timed out before complete guild-roster data arrived",
                "timeout"
            )
        end
        return false
    end

    return scanner
end

if type(RGMS) == "table" then
    RGMS.RosterScanner = Scanner
end

return Scanner
