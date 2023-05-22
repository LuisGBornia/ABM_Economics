using Agents, Graphs, Plots, GraphPlot, DataFrames, Statistics


@agent Investidor GraphAgent begin
    cash::Float64
    stock::Int
    util::Float64
    preco::Float64
    func::String
    sit::String
end

function utilidade(agente::Investidor)
    w = agente.cash*agente.stock*preco_medio(model)
    w = exp(l*w)
    if agente.func == "avesso"
        return log(w)
    elseif agente.func == "neutro"
        return w
    elseif agente.func == "propenso"
        return (w)^1.5
    else
        return error("Agente com função diferente de avesso/neutro/propenso")
    end
end

function initialize_model(;n_agent=12::Int)
    model = ABM(Investidor)
    for i in 1:n_agent
        cash = 1000.00
        stock = 100
        preco = rand(10:0.01:20)
        util = (l*cash*stock*preco)
        if i % 3 == 0
            func = "avesso"
            preco = preco > cash ? cash : preco
            local util_stock = log(l*(cash-preco)*(preco*stock+1))
            util = log(util)
        elseif i % 3 == 1
            func = "propenso"
            local util_stock = exp(l*(cash-preco)*(preco*stock+1))
            util = exp(util)
        else
            func = "neutro"
            local util_stock = (l*(cash-preco)*(preco*stock+1))
            util = (util)
        end
        sit =  util_stock > util ? "comprador" : "vendedor"
        add_agent!(model, i, cash, stock, util, preco, func, sit) # i = posição
    end
    return model
end

function agent_step!(agente::Investidor, model::ABM)
    if utilidade_adicional(agente)
        cash = agente.cash
        stock = agente.stock
        if agente.func == "avesso"
            util_cash = log((cash+preco_medio(model)) * (preco_medio(model)*(stock-1)))
            util_stock = log((cash-preco_medio(model)) * (preco_medio(model)*(stock+1)))
        elseif agente.func == "neutro"
            util_cash = (cash+preco_medio(model)) * (preco_medio(model)*(stock-1))
            util_stock = (cash-preco_medio(model)) * (preco_medio(model)*(stock+1))
        elseif agente.func == "propenso"
            util_cash = exp((cash+preco_medio(model)) * (preco_medio(model)*(stock-1)))
            util_stock = exp((cash-preco_medio(model)) * (preco_medio(model)*(stock+1)))
        end    
        if util_cash > util_stock
            agente.cash += preco_medio(model)
            agente.stock -= 1
        elseif util_stock > util_cash
            agente.cash -= preco_medio(model)
            agente.stock += 1
        else
            println("Agente: $(agente.id) Não negociou")
        end
    end
end

function model_step(model::ABM)
    println("Model step")
    for agente in allagents(model)
        agente.util = utilidade(agente)
        util_stock = (agente.cash-preco_medio(model)) * (preco_medio(model)*(agente.stock+1))
        util_cash = (agente.cash+preco_medio(model)) * (preco_medio(model)*(agente.stock-1))
        if agente.func == "avesso"
            util_cash = log(util_cash)
            util_stock = log(util_stock)
            if util_stock > agente.util
                agente.sit =  "comprador"
            else
                agente.sit = "vendedor"
            end
        elseif agente.func == "neutro"
            util_cash = (util_cash)
            util_stock = (util_stock)
            if util_stock > agente.util
                agente.sit =  "comprador"
            else
                agente.sit = "vendedor"
            end
        elseif agente.func == "propenso"
            util_cash = exp(util_cash)
            util_stock = exp(util_stock)
            if util_stock > agente.util
                agente.sit =  "comprador"
            elseif util_cash > agente.util
                agente.sit = "vendedor"
            else
                agente.sit = "neutro"
            end
        end
        ct = compradores(model)
        Vt = vendedores(model)
        agente.preco = agente.preco*exp((ct-Vt)/ß)
    end
end

function utilidade_adicional(agente::Investidor)
    cash = agente.cash
    stock = agente.stock
    util = agente.util
    util_cash = (cash+preco_medio(model)) * (preco_medio(model)*(stock-1))
    util_stock = (cash-preco_medio(model)) * (preco_medio(model)*(stock+1))
    if agente.func == "avesso"
        util_cash = log(util_cash)
        util_stock = log(util_stock)
    elseif agente.func == "neutro"
        util_cash = util_cash
        util_stock = util_stock
    elseif agente.func == "propenso"
        util_cash = exp(util_cash)
        util_stock = exp(util_stock)
    end
    if util_cash > util || util_stock > util
        println("Utilidade pode aumentar")
        return true
    else
        return false
    end
end

function preco_medio(model::ABM)
    list = []
    for agente in allagents(model)
        push!(list, [agente.id, agente.preco])
    end
    return round(mean(list)[2], digits=2)
end

function compradores(model::ABM)
    count = 0
    for agente in allagents(model)
        if agente.sit == "comprador"
            count += 1
        end
    end
    return count
end

function vendedores(model::ABM)
    count = 0
    for agente in allagents(model)
        if agente.sit == "vendedor"
            count += 1
        end
    end
    return count
end
global l = 0.00001
global ß = 100

model = initialize_model(n_agent=1200)

df, _ = run!(model, agent_step!, model_step, 100, adata=[:cash, :stock, :preco, :util])