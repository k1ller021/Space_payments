local function printMessage(msg, type)
    if type == "error" then
        print("^1[ERROR]^7 " .. msg)
    elseif type == "info" then
        print("^2[INFO]^7 " .. msg)
    elseif type == "debug" and Config.DebugLevel >= 3 then
        print("^5[DEBUG]^7 " .. msg)
    end
end

Log = {
    debug = function(msg, ...)
        if Config.DebugLevel < 3 then
            return
        end
        printMessage(string.format(msg, ...), "debug")
    end,
    error = function(msg, ...)
        if Config.DebugLevel < 1 then
            return
        end
        printMessage(string.format(msg, ...), "error")
    end,
    info = function(msg, ...)
        if Config.DebugLevel < 2 then
            return
        end
        printMessage(string.format(msg, ...), "info")
    end,
}

return Log