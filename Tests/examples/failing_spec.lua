local test = require("Tests.lib.runner")

return {
    test.case("intentional failure proves the process exits non-zero", function()
        test.assert_equal("actual", "expected")
    end),
}
