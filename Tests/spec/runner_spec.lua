local test = require("Tests.lib.runner")

return {
    test.case("runner records a successful assertion", function()
        local result = test.run({
            test.case("nested passing case", function()
                test.assert_equal("ready", "ready")
            end),
        }, { quiet = true })

        test.assert_equal(result.total, 1)
        test.assert_equal(result.passed, 1)
        test.assert_equal(result.failed, 0)
    end),

    test.case("runner catches a failing assertion", function()
        local result = test.run({
            test.case("nested failing case", function()
                test.assert_equal("actual", "expected")
            end),
        }, { quiet = true })

        test.assert_equal(result.total, 1)
        test.assert_equal(result.passed, 0)
        test.assert_equal(result.failed, 1)
        test.assert_matches(result.failures[1].message, "expected")
    end),
}
