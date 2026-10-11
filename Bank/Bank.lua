local _, RGMS = ...

-- Guild bank collection and reporting will live in this module.
RGMS.Bank = RGMS.Bank or {}

function RGMS.Bank.CanScan()
    return RGMS.Reset:canScan("the guild bank")
end

function RGMS.Bank.CanReport()
    return RGMS.Reset:canReport("the bank report")
end
