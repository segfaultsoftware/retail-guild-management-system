local test = require("Tests.lib.runner")

return {
    test.case("debug logging is session-only, opt-in, and uses its own prefix", function()
        local previousChatFrame = DEFAULT_CHAT_FRAME
        local previousCreateFrame = CreateFrame
        local messages = {}

        DEFAULT_CHAT_FRAME = {
            AddMessage = function(_, message)
                messages[#messages + 1] = message
            end,
        }
        CreateFrame = function()
            return {
                RegisterEvent = function()
                end,
                SetScript = function()
                end,
            }
        end

        local fakeRGMS = {}
        local chunk = assert(loadfile("Core/Bootstrap.lua"))
        chunk("RGMS", fakeRGMS)

        test.assert_false(fakeRGMS.DebugEnabled)
        test.assert_false(fakeRGMS.Debug("hidden"))
        test.assert_equal(messages, {})

        test.assert_true(fakeRGMS.ToggleDebug())
        test.assert_true(fakeRGMS.Debug("tab 1=0"))
        test.assert_equal(messages, {
            "|cff33ff99RGMS|r [debug]: tab 1=0",
        })

        test.assert_false(fakeRGMS.ToggleDebug())
        test.assert_false(fakeRGMS.Debug("hidden again"))
        test.assert_equal(#messages, 1)

        DEFAULT_CHAT_FRAME = previousChatFrame
        CreateFrame = previousCreateFrame
    end),
}
