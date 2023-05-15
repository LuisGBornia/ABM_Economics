using Agents, Graphs, Plots, GraphPlot, DataFrames, Statistics


@agent Investidor GraphAgent begin
    cash::Float64
    stock::Int
    util::Float64
    preco::Float64
    func::String
    sit::String
end

function avesso(cash::Float64, stock::Int64)
    return log(cash^.5*stock^.5)
end
function neutro(cash::Float64, stock::Int64)
    return cash^.5*stock^.5
end
function propenso(cash::Float64, stock::Int64)
    return exp(cash^.5*stock^.5)
end

function initialize_model(;n_agent=12::Int)
    model = ABM(Investidor)
    for i in 1:n_agent
        cash = 1000.00
        stock = 100
        util = 100.0
        preco = round(cash/stock, digits=2)
        if i % 3 == 0
            func = "avesso"
            sit = avesso(cash, stock) > util ? "comprador" : "vendedor"
        elseif i % 3 == 1
            func = "propenso"
            sit = propenso(cash, stock) > util ? "comprador" : "vendedor"
        else
            func = "neutro"
            sit = neutro(cash, stock) > util ? "comprador" : "vendedor"
        end
        add_agent!(model, i,cash, stock, util, preco, func, sit)
    end
    return model
end

function agent_step!(agente::Investidor, model::ABM)
    if utilidade_stock(agente, model)
        agente.cash -= preco_medio(model)
        agente.stock += 1
        agente.preco = round(agente.cash/agente.stock, digits=2)
    elseif utilidade_cash(agente, model) && agente.stock >= 1
        agente.cash += preco_medio(model)
        agente.stock -= 1
        agente.preco = round(agente.cash/agente.stock, digits=2)
    end
    return agente
end

function model_step(model::ABM)
    println("Model step")
    for agente in allagents(model)
        cash = agente.cash
        stock = agente.stock
        if agente.func == "avesso"
            x = avesso(cash, stock)
        elseif agente.func == "propenso"
            x = propenso(cash, stock)
        else
            x = neutro(cash, stock)
        end
        agente.sit = agente.util > x ? "comprador" : "vendedor" 
        agente.util = x
        agente.preco = round(cash/stock, digits=2)
    end
end

function utilidade_stock(agente::Investidor, model::ABM)
    cash = agente.cash
    stock = agente.stock
    if agente.cash - preco_medio(model) > 0
        if agente.func == "avesso"
            x = avesso(cash, stock)
            y = avesso((cash-preco_medio(model)), (stock+1))
        elseif agente.func == "propenso"
            x = propenso(cash, stock)
            y = propenso((cash-preco_medio(model)), (stock+1))
        elseif agente.cash - preco_medio(model) > 0
            x = neutro(cash, stock)
            y = neutro((cash-preco_medio(model)), (stock+1))
        else
            x = 1
            y = 0
        end
        return y > x
    else
        println("Agente com menos dinheiro que o preço médio")
        return false
    end
end

function utilidade_cash(agente::Investidor, model::ABM)
    cash = agente.cash
    stock = agente.stock
    if agente.func == "avesso"
        x = avesso(cash, stock)
        y = avesso((cash+preco_medio(model)), (stock-1))
    elseif agente.func == "propenso"
        x = propenso(cash, stock)
        y = propenso((cash+preco_medio(model)), (stock-1))
    else
        x = neutro(cash, stock)
        y = neutro((cash+preco_medio(model)), (stock-1))
    end
    return y > x
end

function preco_medio(model::ABM)
    list = []
    for agente in model.agents
        push!(list, [agente[2].id, agente[2].preco])
    end
    return round(mean(list)[2], digits=2)
end