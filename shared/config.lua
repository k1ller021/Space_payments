Config = {
    DebugLevel = 3, -- 0 = desativado, 1 = erro, 2 = info, 3 = debug
    PaymentTypes = {
        ["cash"] = "Dinheiro", -- Acho isso errado: zap⚡, mas vou deixar aqui...
        ["bank"] = "Banco"
    },
    PayCommand = "pagar", -- Nome do comando
    BillCommand = "cobrar", -- Nome do comando
    MoneyUnit = "R$", -- Unidade monetária, pode ser alterada para "$" ou "€" ou qualquer outra coisa
}

return Config
