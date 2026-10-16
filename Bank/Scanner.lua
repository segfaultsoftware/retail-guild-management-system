-- Transaction coordinator for complete guild-bank observations. The scanner
-- owns no WoW frames or globals; the Retail adapter and deterministic tests
-- provide those through dependencies.

local _, RGMS = ...

local Scanner = {}
Scanner.DEFAULT_TIMEOUT_SECONDS = 20
Scanner.EMPTY_RETRY_DELAY_SECONDS = 1
Scanner.MAX_EMPTY_ATTEMPTS = 4

local function copyTimestamp(timestamp)
    return {
        unixSeconds = timestamp.unixSeconds,
        iso8601 = timestamp.iso8601,
    }
end

function Scanner.create(dependencies)
    local scanner = {
        dependencies = dependencies,
        inProgress = false,
        elapsed = 0,
        work = nil,
        timeoutSeconds = dependencies.timeoutSeconds
            or Scanner.DEFAULT_TIMEOUT_SECONDS,
    }

    local function printMessage(message)
        dependencies.print(message)
    end

    local function debugMessage(message)
        if type(dependencies.debug) == "function" then
            dependencies.debug(message)
        end
    end

    local function activeAttempt(work)
        return work.emptyAttempts + 1
    end

    local function slotCountText(count)
        return string.format(
            "%d occupied slot%s",
            count,
            count == 1 and "" or "s"
        )
    end

    function scanner:IsInProgress()
        return self.inProgress
    end

    function scanner:SetProgress(inProgress)
        self.inProgress = inProgress
        dependencies.setInProgress(inProgress)
    end

    function scanner:ClearWork()
        self.elapsed = 0
        self.work = nil
    end

    function scanner:FinishFailure(message, reason)
        debugMessage("Guild bank scan failed: " .. tostring(message) .. ".")
        if self.inProgress then
            self:SetProgress(false)
        end
        self:ClearWork()
        dependencies.refreshStatus()
        printMessage("Guild bank scan failed: " .. tostring(message) .. ".")
        return nil, reason or "scan-failed"
    end

    function scanner:Cancel()
        if not self.inProgress then
            return false
        end

        debugMessage("Guild bank scan canceled.")
        self:SetProgress(false)
        self:ClearWork()
        dependencies.refreshStatus()
        return true
    end

    function scanner:Complete()
        local captured, scannedAt, timestampState, timestampError = pcall(function()
            return dependencies.api:captureTimestamp()
        end)
        if not captured then
            return self:FinishFailure(
                "the game client could not provide a completion time ("
                    .. tostring(scannedAt)
                    .. ")",
                "api-failure"
            )
        end
        if scannedAt == nil then
            return self:FinishFailure(
                timestampError or "the game client could not provide a completion time",
                timestampState or "api-failure"
            )
        end

        for _, slot in ipairs(self.work.slots) do
            slot.observedAt = copyTimestamp(scannedAt)
        end

        local snapshot = {
            guild = self.work.guild,
            scannedAt = scannedAt,
            tabs = self.work.tabs,
            slots = self.work.slots,
        }
        local countParts = {}
        for _, tab in ipairs(snapshot.tabs) do
            local count = self.work.tabCounts[tab.index]
            if tab.isViewable then
                countParts[#countParts + 1] = string.format(
                    "tab %d=%d",
                    tab.index,
                    count or 0
                )
            else
                countParts[#countParts + 1] = string.format(
                    "tab %d=inaccessible",
                    tab.index
                )
            end
        end
        debugMessage(
            "Guild bank scan final counts: "
                .. (#countParts > 0
                    and table.concat(countParts, ", ")
                    or "no purchased tabs")
                .. "."
        )
        local transaction, beginError = dependencies.ownership:begin(
            "bank",
            snapshot.guild
        )
        if not transaction then
            return self:FinishFailure(beginError, "transaction-failure")
        end

        local reducedDataset, reduceError = dependencies.reduceBank(
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

        local purchasedCount = #snapshot.tabs
        local accessibleCount = self.work.accessibleCount
        local occupiedCount = #snapshot.slots
        self:SetProgress(false)
        self:ClearWork()
        dependencies.refreshStatus()
        printMessage(string.format(
            "Guild bank scan complete: %d purchased tabs, %d accessible, %d occupied slots.",
            purchasedCount,
            accessibleCount,
            occupiedCount
        ))
        return true, commitResult
    end

    function scanner:RequestTab(tabIndex)
        self.work.requestedTab = tabIndex
        debugMessage(string.format(
            "Requested guild bank tab %d (attempt %d/%d).",
            tabIndex,
            activeAttempt(self.work),
            Scanner.MAX_EMPTY_ATTEMPTS
        ))
        local requested, requestError = pcall(function()
            dependencies.api:requestTab(tabIndex)
        end)
        if not requested then
            return self:FinishFailure(
                "the game client rejected tab "
                    .. tostring(tabIndex)
                    .. " ("
                    .. tostring(requestError)
                    .. ")",
                "api-failure"
            )
        end
        return true
    end

    function scanner:RequestNextTab()
        self.work.accessiblePosition = self.work.accessiblePosition + 1
        local tabIndex = self.work.accessibleTabs[self.work.accessiblePosition]
        if tabIndex == nil then
            return self:Complete()
        end

        self.work.emptyAttempts = 0
        self.work.retryAfter = nil
        return self:RequestTab(tabIndex)
    end

    function scanner:Request(source)
        source = source == "automatic" and "automatic" or "manual"

        if self.inProgress then
            printMessage(
                "A guild bank scan is already in progress; no second scan was started."
            )
            return nil, "scan-in-progress"
        end

        local checkedOpen, bankOpen = pcall(function()
            return dependencies.api:isOpen()
        end)
        if not checkedOpen or not bankOpen then
            if source ~= "automatic" then
                printMessage(
                    "Cannot scan the guild bank because the guild-bank window is closed."
                )
            end
            return nil, "bank-closed"
        end

        if not dependencies.canScan() then
            return nil, "scanning-disabled"
        end

        local captured, catalog, captureState, captureError = pcall(function()
            return dependencies.api:captureCatalog()
        end)
        if not captured then
            return self:FinishFailure(
                "the game client could not describe the guild bank ("
                    .. tostring(catalog)
                    .. ")",
                "api-failure"
            )
        end
        if catalog == nil then
            return self:FinishFailure(
                captureError or "the game client could not describe the guild bank",
                captureState or "api-failure"
            )
        end

        if type(dependencies.prepareScan) == "function" then
            local prepared, prepareResult, prepareError = pcall(function()
                return dependencies.prepareScan(catalog.guild)
            end)
            if not prepared then
                return self:FinishFailure(
                    "bank data initialization failed ("
                        .. tostring(prepareResult)
                        .. ")",
                    "migration-failure"
                )
            end
            if not prepareResult then
                return self:FinishFailure(
                    prepareError or "bank data initialization failed",
                    "migration-failure"
                )
            end
        end

        local accessibleTabs = {}
        for _, tab in ipairs(catalog.tabs) do
            if tab.isViewable then
                accessibleTabs[#accessibleTabs + 1] = tab.index
            end
        end

        self.elapsed = 0
        self.work = {
            guild = catalog.guild,
            tabs = catalog.tabs,
            slots = {},
            accessibleTabs = accessibleTabs,
            accessibleCount = #accessibleTabs,
            accessiblePosition = 0,
            requestedTab = nil,
            emptyAttempts = 0,
            retryAfter = nil,
            tabCounts = {},
        }
        debugMessage(string.format(
            "Guild bank scan started with %d purchased tab%s and %d accessible tab%s.",
            #catalog.tabs,
            #catalog.tabs == 1 and "" or "s",
            #accessibleTabs,
            #accessibleTabs == 1 and "" or "s"
        ))
        self:SetProgress(true)
        return self:RequestNextTab()
    end

    function scanner:OnSlotsChanged()
        if not self.inProgress or self.work.requestedTab == nil then
            return false
        end
        debugMessage(string.format(
            "Guild bank slot-change event received while tab %d attempt %d/%d is active.",
            self.work.requestedTab,
            activeAttempt(self.work),
            Scanner.MAX_EMPTY_ATTEMPTS
        ))
        if self.work.retryAfter ~= nil then
            debugMessage(string.format(
                "Ignored the slot-change event for guild bank tab %d while waiting to retry.",
                self.work.requestedTab
            ))
            return false, "empty-retry"
        end

        local tabIndex = self.work.requestedTab
        local captured, slots, captureState, captureError = pcall(function()
            return dependencies.api:captureTab(tabIndex)
        end)
        if not captured then
            return self:FinishFailure(
                "the game client could not read tab "
                    .. tostring(tabIndex)
                    .. " ("
                    .. tostring(slots)
                    .. ")",
                "api-failure"
            )
        end
        if slots == nil then
            if captureState == "incomplete" then
                debugMessage(string.format(
                    "Guild bank tab %d attempt %d/%d was incomplete; waiting for another slot-change event.",
                    tabIndex,
                    activeAttempt(self.work),
                    Scanner.MAX_EMPTY_ATTEMPTS
                ))
                return false, "incomplete"
            end
            return self:FinishFailure(
                captureError or ("the game client could not read tab " .. tabIndex),
                captureState or "api-failure"
            )
        end

        local attempt = activeAttempt(self.work)
        local slotCount = #slots
        if slotCount == 0 then
            self.work.emptyAttempts = self.work.emptyAttempts + 1
            if self.work.emptyAttempts < Scanner.MAX_EMPTY_ATTEMPTS then
                self.work.retryAfter = Scanner.EMPTY_RETRY_DELAY_SECONDS
                debugMessage(string.format(
                    "Guild bank tab %d attempt %d/%d returned %s; retrying in %d second.",
                    tabIndex,
                    attempt,
                    Scanner.MAX_EMPTY_ATTEMPTS,
                    slotCountText(slotCount),
                    Scanner.EMPTY_RETRY_DELAY_SECONDS
                ))
                return false, "empty-retry"
            end
            debugMessage(string.format(
                "Guild bank tab %d attempt %d/%d returned %s; accepting the tab as empty.",
                tabIndex,
                attempt,
                Scanner.MAX_EMPTY_ATTEMPTS,
                slotCountText(slotCount)
            ))
        elseif attempt > 1 then
            debugMessage(string.format(
                "Guild bank tab %d attempt %d/%d returned %s; accepting the retry result.",
                tabIndex,
                attempt,
                Scanner.MAX_EMPTY_ATTEMPTS,
                slotCountText(slotCount)
            ))
        else
            debugMessage(string.format(
                "Guild bank tab %d attempt %d/%d returned %s; accepting the result.",
                tabIndex,
                attempt,
                Scanner.MAX_EMPTY_ATTEMPTS,
                slotCountText(slotCount)
            ))
        end

        for _, slot in ipairs(slots) do
            self.work.slots[#self.work.slots + 1] = slot
        end
        self.work.tabCounts[tabIndex] = slotCount
        self.work.requestedTab = nil
        return self:RequestNextTab()
    end

    function scanner:Update(elapsed)
        if not self.inProgress then
            return false
        end

        elapsed = tonumber(elapsed) or 0
        if elapsed < 0 then
            elapsed = 0
        end
        if self.work.retryAfter ~= nil then
            local retryElapsed = math.min(elapsed, self.work.retryAfter)
            self.work.retryAfter = self.work.retryAfter - retryElapsed
            elapsed = elapsed - retryElapsed
        end
        self.elapsed = self.elapsed + elapsed
        if self.elapsed >= self.timeoutSeconds then
            return self:FinishFailure(
                "timed out before every accessible guild-bank tab was complete",
                "timeout"
            )
        end
        if self.work.retryAfter ~= nil then
            if self.work.retryAfter <= 0 then
                self.work.retryAfter = nil
                return self:RequestTab(self.work.requestedTab)
            end
        end
        return false
    end

    return scanner
end

if type(RGMS) == "table" then
    RGMS.BankScanner = Scanner
end

return Scanner
