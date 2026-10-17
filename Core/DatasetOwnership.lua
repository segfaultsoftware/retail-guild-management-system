-- Transactional guild ownership for roster and bank observations. Scanners
-- work on detached dataset copies and only publish them after a complete
-- successful observation.

local _, RGMS = ...

local DatasetOwnership = {}
local Realm = type(RGMS) == "table"
    and RGMS.Realm
    or require("Core.Realm")

local DATASET_CHANGE_MESSAGES = {
    roster = "Detected guild change; resetting roster data",
    bank = "Detected guild change; resetting bank data",
}

local function validDatasetName(datasetName)
    return DATASET_CHANGE_MESSAGES[datasetName] ~= nil
end

-- realm.slug is the canonical realm value captured from the Retail API. Realm
-- identity is case-insensitive; the remaining fields are metadata and
-- deliberately do not affect ownership.
function DatasetOwnership.sameGuild(left, right)
    return type(left) == "table"
        and type(right) == "table"
        and type(left.realm) == "table"
        and type(right.realm) == "table"
        and type(left.name) == "string"
        and left.name ~= ""
        and left.name == right.name
        and type(left.realm.slug) == "string"
        and left.realm.slug ~= ""
        and Realm.key(left.realm.slug) == Realm.key(right.realm.slug)
end

function DatasetOwnership.create(dependencies)
    local controller = {}

    local function beginAccountDataset(datasetName, capturedGuild)
        local currentModel = dependencies.getSavedData()
        local currentState = dependencies.accountData.load(currentModel)
        if not currentState.enabled then
            return nil, currentState.error
        end

        local guild = dependencies.accountData.findGuild(
            currentState.model,
            capturedGuild
        )
        local sourceDataset
        if guild then
            sourceDataset = guild[datasetName]
        else
            sourceDataset = dependencies.savedData.newModel()[datasetName]
        end

        -- Reusing SavedData's replacement path gives the transaction a
        -- detached, fully validated dataset without exposing account state.
        local detached, detachError = dependencies.savedData.replaceDataset(
            dependencies.savedData.newModel(),
            datasetName,
            sourceDataset
        )
        if not detached then
            return nil, detachError
        end
        detached[datasetName].guild = capturedGuild

        return {
            datasetName = datasetName,
            guild = capturedGuild,
            dataset = detached[datasetName],
            finished = false,
        }
    end

    function controller:begin(datasetName, guildIdentity)
        if not validDatasetName(datasetName) then
            return nil, "dataset name must be roster or bank"
        end
        if guildIdentity == nil then
            return nil, "guild identity is unavailable"
        end

        local capturedGuild, identityError = dependencies.savedData.copyGuildIdentity(
            guildIdentity
        )
        if not capturedGuild then
            return nil, identityError
        end

        if dependencies.accountData then
            return beginAccountDataset(datasetName, capturedGuild)
        end

        local currentModel = dependencies.getSavedData()
        local currentState = dependencies.savedData.load(currentModel)
        if not currentState.enabled then
            return nil, currentState.error
        end

        local currentGuild = currentModel[datasetName].guild
        local sameGuild = currentGuild ~= nil
            and DatasetOwnership.sameGuild(currentGuild, capturedGuild)
        local workingModel
        local workingError
        if sameGuild then
            workingModel = currentState.model
        else
            workingModel, workingError = dependencies.savedData.resetDatasetObservations(
                currentModel,
                datasetName
            )
            if not workingModel then
                return nil, workingError
            end
        end

        workingModel[datasetName].guild = capturedGuild

        return {
            datasetName = datasetName,
            guild = capturedGuild,
            dataset = workingModel[datasetName],
            finished = false,
        }
    end

    function controller:finish(transaction, status)
        if type(transaction) ~= "table"
            or not validDatasetName(transaction.datasetName)
            or type(transaction.dataset) ~= "table"
            or type(transaction.guild) ~= "table" then
            return nil, "invalid dataset transaction"
        end
        if transaction.finished then
            return nil, "dataset transaction is already finished"
        end

        if status == "failed" or status == "canceled" then
            transaction.finished = true
            return false, status
        end
        if status ~= "success" then
            return nil, "transaction status must be success, failed, or canceled"
        end
        if not DatasetOwnership.sameGuild(transaction.dataset.guild, transaction.guild) then
            return nil, "transaction dataset guild does not match its captured guild"
        end

        if dependencies.accountData then
            local currentModel = dependencies.getSavedData()
            local committedModel
            local guildOrError
            if transaction.datasetName == "roster"
                and type(dependencies.reconcileRosterFeatures) == "function" then
                local currentGuild = dependencies.accountData.findGuild(
                    currentModel,
                    transaction.guild
                )
                local groups, notesOrError = dependencies.reconcileRosterFeatures(
                    transaction.dataset,
                    currentGuild and currentGuild.mainAltGroups or {},
                    currentGuild and currentGuild.characterNotes or {}
                )
                if not groups then
                    return nil, notesOrError
                end
                committedModel, guildOrError =
                    dependencies.accountData.replaceRosterAndFeatures(
                        currentModel,
                        transaction.guild,
                        transaction.dataset,
                        groups,
                        notesOrError
                    )
            else
                committedModel, guildOrError = dependencies.accountData.replaceDataset(
                    currentModel,
                    transaction.guild,
                    transaction.datasetName,
                    transaction.dataset
                )
            end
            if not committedModel then
                return nil, guildOrError
            end

            local characterModel
            if type(dependencies.prepareCharacterCommit) == "function" then
                local prepareError
                characterModel, prepareError = dependencies.prepareCharacterCommit(
                    transaction.datasetName
                )
                if not characterModel then
                    return nil, prepareError
                end
            end

            dependencies.commit(
                committedModel,
                transaction.guild,
                characterModel
            )
            transaction.finished = true
            return true, committedModel
        end

        local currentModel = dependencies.getSavedData()
        local currentGuild = currentModel[transaction.datasetName].guild
        local guildChanged = currentGuild ~= nil
            and not DatasetOwnership.sameGuild(currentGuild, transaction.guild)
        local committedModel, commitError = dependencies.savedData.replaceDataset(
            currentModel,
            transaction.datasetName,
            transaction.dataset
        )
        if not committedModel then
            return nil, commitError
        end

        dependencies.commit(committedModel)
        transaction.finished = true
        if guildChanged then
            dependencies.print(DATASET_CHANGE_MESSAGES[transaction.datasetName])
        end

        return true, committedModel
    end

    return controller
end

if type(RGMS) == "table" then
    RGMS.DatasetOwnership = DatasetOwnership.create({
        savedData = RGMS.SavedData,
        accountData = RGMS.AccountData,
        getSavedData = function()
            return RGMSAccountDB
        end,
        commit = function(model, guildIdentity, characterModel)
            RGMSAccountDB = model
            RGMS.AccountDataState = {
                enabled = true,
                status = "ready",
                model = model,
            }
            RGMS.ActiveGuildIdentity = guildIdentity
            if characterModel ~= nil then
                RGMSCharacterDB = characterModel
                RGMS.SavedDataState = {
                    enabled = true,
                    status = "ready",
                    scope = "character",
                    model = characterModel,
                }
            else
                characterModel = type(RGMS.SavedDataState) == "table"
                    and RGMS.SavedDataState.model
                    or nil
            end
            RGMS.DB = RGMS.AccountData.view(
                model,
                guildIdentity,
                characterModel and characterModel.ui or {}
            )
            if type(RGMS.Roster) == "table"
                and type(RGMS.Roster.RefreshStatus) == "function" then
                RGMS.Roster.RefreshStatus()
            end
            if type(RGMS.Bank) == "table"
                and type(RGMS.Bank.RefreshStatus) == "function" then
                RGMS.Bank.RefreshStatus()
            end
        end,
        prepareCharacterCommit = function(datasetName)
            local characterModel = type(RGMS.SavedDataState) == "table"
                and RGMS.SavedDataState.enabled
                and RGMS.SavedDataState.model
                or RGMSCharacterDB
            if datasetName == "roster" then
                return RGMS.RosterMigration.cleanup(characterModel)
            end
            return RGMS.BankMigration.cleanup(characterModel)
        end,
        reconcileRosterFeatures = function(dataset, groups, notes)
            if type(RGMS.MainsAltsGroups) ~= "table"
                or type(RGMS.MainsAltsGroups.reconcile) ~= "function" then
                return nil, "Mains/Alts roster reconciliation is unavailable"
            end
            return RGMS.MainsAltsGroups.reconcile(dataset, groups, notes)
        end,
        print = RGMS.Print,
    })
end

return DatasetOwnership
