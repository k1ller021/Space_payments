local ox = exports.ox_lib

local phoneProp = nil

local animDict = "cellphone@"
local animName = "cellphone_text_in"
local phonePropName = "prop_phone_ing"

local function StopPhoneAnim()
    ClearPedTasks(cache.ped)
    SetModelAsNoLongerNeeded(GetHashKey(phonePropName))
    if phoneProp then
        DeleteEntity(phoneProp)
        phoneProp = nil
    end
    RemoveAnimDict(animDict)
end

local function StartPhoneAnim()
    StopPhoneAnim() -- Chama o stop pra garantir que o ped não esteja em outra animação
    lib.requestAnimDict(animDict)
    lib.requestModel(phonePropName)
    TaskPlayAnim(cache.ped, animDict, animName, 8.0, -8.0, -1, 50, 0, false, false, false)
    phoneProp = CreateObject(GetHashKey(phonePropName), GetEntityCoords(cache.ped), true, true, true)
    AttachEntityToEntity(
        phoneProp,
        cache.ped,
        GetPedBoneIndex(cache.ped, 28422),
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        true,
        true,
        false,
        true,
        1,
        true
    )
end

local function getAcceptedPaymentTypes()
    local acceptedTypes = {}
    for k, v in pairs(Config.PaymentTypes) do
        Log.debug("Adicionando tipo de pagamento: %s (%s)", v, k)
        acceptedTypes[#acceptedTypes + 1] = {label = v, value = k}
    end
    return acceptedTypes
end

local function generateInputDialog(inputType)
    local title = inputType == "pay" and locale("ui.titlePay") or locale("ui.titleBill")
    local valueLabel = inputType == "pay" and locale("ui.valuePay") or locale("ui.valueBill")
    return lib.inputDialog(
        title,
        {
            {type = "number", label = locale("ui.targetId"), placeholder = "5", icon = "user", required = true},
            {type = "number", label = valueLabel, placeholder = "500", icon = "dollar-sign", required = true},
            {
                type = "select",
                label = locale("ui.paymentType"),
                icon = "credit-card",
                options = getAcceptedPaymentTypes(),
                required = true
            }
        }
    )
end

local function executeAction(action)
    StartPhoneAnim() -- <-- começa a animação e prop

    local input = generateInputDialog(action)

    StopPhoneAnim() -- <-- quando fechar, para animação e remove prop

    Log.debug("Dados inseridos: %s", json.encode(input, {indent = true}))
    if not input then
        return
    end

    local data = {
        action = action,
        targetId = tonumber(input[1]),
        amount = tonumber(input[2]),
        paymentType = input[3]
    }

    lib.callback.await("space_payments:Server:ExecuteAction", false, data)
end

lib.callback.register(
    "space_payments:Client:Call",
    function(action, args)
        Log.debug(locale("logs.executeAction", action))
        if action == "pay" or action == "bill" then
            executeAction(action)
        else
            Log.error(locale("logs.invalidAction", action))
        end
        return true
    end
)

lib.callback.register(
    "space_payments:Client:Bill",
    function(data)
        Log.debug(locale("logs.data", json.encode(data, {indent = true})))
        local senderId = data.senderId
        local senderName = data.senderName
        local amount = data.amount
        local paymentType = data.paymentType
        local alert =
            lib.alertDialog(
            {
                header = locale("ui.paymentRequest"),
                content = locale("ui.paymentRequestContent", senderName, Config.MoneyUnit, amount, Config.PaymentTypes[paymentType]),
                centered = true,
                cancel = true,
                labels = {confirm = locale("ui.confirm"), cancel = locale("ui.cancel")},
            }
        )

        return alert == "confirm" and true or false
    end
)
