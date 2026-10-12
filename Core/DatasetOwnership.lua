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
        getSavedData = function()
            return RGMSCharacterDB
        end,
        commit = function(model)
            RGMSCharacterDB = model
            RGMS.DB = model
            if type(RGMS.SavedDataState) == "table" then
                RGMS.SavedDataState.model = model
            end
        end,
        print = RGMS.Print,
    })
end

return DatasetOwnership
