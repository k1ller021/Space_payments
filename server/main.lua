QBCore = exports["qb-core"]:GetCoreObject()

lib.addCommand(
    Config.PayCommand,
    {
        help = locale("command.pay")
        -- params = {},
        -- restricted = "group.admin",
    },
    function(source, args, raw)
        lib.callback(
            "space_payments:Client:Call",
            source,
            function()
            end,
            "pay"
        )
    end
)

lib.addCommand(
    Config.BillCommand,
    {
        help = locale("command.bill")
        -- params = {},
        -- restricted = "group.admin",
    },
    function(source, args, raw)
        Log.debug("Comando de pagamento acionado:", source, args, raw)
        lib.callback(
            "space_payments:Client:Call",
            source,
            function()
            end,
            "bill"
        )
    end
)

local function notifyPlayer(playerId, message, type)
    lib.notify(playerId, {description = message, type = type or "info"})
end

local function logTransactionError(action, playerCid, data)
    Log.error(locale("logs.transactionError", action, playerCid))
    Log.debug(locale("logs.data", json.encode(data)))
end

local function transferMoney(fromPlayer, toPlayer, amount, paymentType)
    local fromCid, toCid = fromPlayer.PlayerData.citizenid, toPlayer.PlayerData.citizenid

    local reasonFrom = locale("transaction.reasonFrom", toCid)
    local reasonTo = locale("transaction.reasonTo", fromCid)

    if exports.qbx_core:RemoveMoney(fromCid, paymentType, amount, reasonFrom) then
        if exports.qbx_core:AddMoney(toCid, paymentType, amount, reasonTo) then
            local formattedAmount = string.format("%s%.2f", Config.MoneyUnit, amount)
            notifyPlayer(fromPlayer.PlayerData.source, locale("transaction.notifyFrom", formattedAmount), "success")
            notifyPlayer(toPlayer.PlayerData.source, locale("transaction.notifyTo", formattedAmount), "success")
            return true
        else
            logTransactionError("adicionar", toCid, {from = fromCid, amount = amount, paymentType = paymentType})
        end
    else
        logTransactionError("remover", fromCid, {to = toCid, amount = amount, paymentType = paymentType})
    end
    return false
end

lib.callback.register(
    "space_payments:Server:ExecuteAction",
    function(source, data)
        local src = source
        local targetId, amount, paymentType, action = data.targetId, data.amount, data.paymentType, data.action

        Log.debug(locale("logs.data", json.encode(data)))

        if src == targetId then
            Log.debug(locale("logs.selfTransaction", src))
            notifyPlayer(src, locale("transaction.selfTransaction", action == "pay" and locale("transaction.pay") or locale("transaction.bill")), "error")
            return
        end

        local Player = QBCore.Functions.GetPlayer(src)
        local Target = QBCore.Functions.GetPlayer(targetId)

        if not Player or not Target then
            Log.debug(locale("logs.playerNotFound", src, targetId))
            notifyPlayer(src, locale("logs.playerNotFound"), "error")
            return
        end

        if not paymentType or not Config.PaymentTypes[paymentType] then
            Log.debug(locale("logs.invalidPaymentType", paymentType))
            notifyPlayer(src, locale("transaction.invalidPaymentType"), "error")
            return
        end

        if not amount or amount <= 0 then
            Log.debug(locale("logs.invalidAmount", amount))
            notifyPlayer(src, locale("transaction.invalidAmount"), "error")
            return
        end

        Log.debug(locale("logs.generic", "Player", Player.PlayerData.citizenid))
        Log.debug(locale("logs.generic", "Target", Target.PlayerData.citizenid))

        if action == "pay" then
            transferMoney(Player, Target, amount, paymentType)
        elseif action == "bill" then
            local senderName =
                ("%s %s"):format(Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname)
            data.senderName = senderName
            data.targetId, data.action = nil, nil

            Log.debug(locale("logs.billRequest", targetId))
            Log.debug("%s", json.encode(data, {indent = true}))

            local accepted = lib.callback.await("space_payments:Client:Bill", targetId, data)
            if not accepted then
                Log.debug(locale("logs.billDeclined", targetId))
                notifyPlayer(src, locale("transaction.declined"), "error")
                notifyPlayer(targetId, locale("transaction.declined"), "error")
                return
            end

            Log.debug(locale("logs.billAccepted", targetId))
            transferMoney(Player, Target, amount, paymentType)
        end

        return true
    end
)
