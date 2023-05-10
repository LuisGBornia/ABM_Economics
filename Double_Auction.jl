using Agents, DataFrames, CSV, Plots, Statistics

mutable struct Agente <: AbstractAgent
    id::Int
    qtde::Int
    cash::Float32
    preco::Float32
    util::Float32
    status::String # B - Buyer / S - Seller #
    sold::Bool
    runs::Int
    f_util::String # A - "Avesso ao risco" / N - "Neutro ao risco" / P - "Propenso ao risco" #
end

function initialize(;n_ag= 12)
    model = ABM(Agente, scheduler=Schedulers.randomly)
    id = 0
    prod_qtde = 0
    for i in 1:n_ag
        id += 1
        qtde = rand(100:300)
        prod_qtde += qtde
        cash = rand(5000:10000)
        preco_compra = rand(10:100)
        util = ((qtde*10)^(acao)) * (cash^(din))
        sold = false
        runs = 0
        if i % 3 == 1
            f_util = "A"
        elseif i % 3 == 2
            f_util = "P"
        else
            f_util = "N"
        end
        if cash - preco_compra > 0
            if (((qtde+1)*preco_compra)^(acao))*((cash-preco_compra)^(din)) > util
                add_agent!(Agente(id, qtde, cash, preco_compra, util, "B", sold, runs, f_util),model)
            else
                add_agent!(Agente(id, qtde, cash, preco_compra, util, "S", sold, runs, f_util),model)
            end
        else
            add_agent!(Agente(id, qtde, cash, preco_compra, util, "S", sold, runs, f_util),model)
        end
    end
    return model
end

function utilidade(agente::Agente,atual::Bool)
    if length(buyers()) > 0
        preco = buyers()[1][2]
    else
        preco = agente.preco
    end
    if atual == true
        if agente.f_util == "A"
            utilidade = ((agente.qtde*preco)^(acao-1/4))*((agente.cash)^(din+1/4))
        elseif agente.f_util == "P"
            utilidade = ((agente.qtde*preco)^(acao+1/4))*((agente.cash)^(din-1/4))
        else
            utilidade = ((agente.qtde*preco)^(acao))*((agente.cash)^(din))
        end
    elseif length(sellers()) != 0
        if agente.f_util == "A"
            utilidade = (((agente.qtde+1)*preco)^(acao-1/4))*((agente.cash-sellers()[1][2])^(din+1/4))
        elseif agente.f_util == "P"
            utilidade = (((agente.qtde+1)*preco)^(acao+1/4))*((agente.cash-sellers()[1][2])^(din-1/4))
        else
            utilidade = (((agente.qtde+1)*preco)^(acao))*((agente.cash-sellers()[1][2])^(din))
        end
    else
        utilidade = 0
    end
    return utilidade
end

function buyers()
    list = []
    for i in allagents(model)
        if i.status == "B"
            push!(list, [i.id,i.preco])
        end
    end
    return sort(list, rev=true)
end

function sellers()
    list = []
    for i in allagents(model)
        if i.status == "S"
            if i.sold == false
                push!(list, [i.id,i.preco])
            end
        end
    end
    return sort(list, rev=false)
end

function new_util(x::Agente)
    if x.f_util == "A"
        cashutil = ((x.qtde*x.preco)^(acao-1/4))*(x.cash^(din+1/4))
    elseif x.f_util == "P"
        cashutil = ((x.qtde*x.preco)^(acao+1/4))*(x.cash^(din-1/4))
    else
        cashutil = ((x.qtde*x.preco)^(acao))*(x.cash^(din))
    end
    if length(sellers()) > 0 && x.cash > sellers()[1][2]
        if x.f_util == "A"
            stockutil = (((x.qtde+1)*x.preco)^(acao-1/4)) * ((x.cash-sellers()[1][2])^(din+1/4))
        elseif x.f_util == "P"
            stockutil = (((x.qtde+1)*x.preco)^(acao+1/4)) * ((x.cash-sellers()[1][2])^(din-1/4))
        else
            stockutil = (((x.qtde+1)*x.preco)^(acao)) * ((x.cash-sellers()[1][2])^(din))
        end
    elseif x.cash > x.preco
        if x.f_util == "A"
            stockutil = (((x.qtde+1)*x.preco)^(acao-1/4)) * ((x.cash-x.preco)^(din+1/4))
        elseif x.f_util == "P"
            stockutil = (((x.qtde+1)*x.preco)^(acao+1/4)) * ((x.cash-x.preco)^(din-1/4))
        else
            stockutil = (((x.qtde+1)*x.preco)^(acao)) * ((x.cash-x.preco)^(din))
        end
    else
        stockutil = 0
    end
    if stockutil - cashutil ≥ 0
        return true
    else
        return false
    end
end

function agent_step!(agente::Agente, model::ABM)
    sell = sellers()
    if length(sellers()) == 0 || length(buyers()) == 0
        agente.runs += 1
        novo_preco!(agente)
    else
        vendedor = model.agents[sellers()[1][1]]
        if agente.status == "B"
            if agente.preco ≥ vendedor.preco && agente.cash ≥ vendedor.preco && vendedor.qtde ≥ 1 && new_util(agente) == true
                agente.qtde += 1
                agente.cash -= sell[1][2]
                vendedor.qtde -= 1
                vendedor.cash += sell[1][2]
                vendedor.sold = true
                agente.util = utilidade(agente, true)
                vendedor.util = utilidade(vendedor, true)
            elseif new_util(agente) == false
                agente.status == "S"
            else
                agente.runs += 1
            end
        elseif agente.status == "S"
            if new_util(agente) == true
                agente.status == "B"
            elseif agente.qtde == 0
                agente.status == "B"
            else
                agente.runs += 1
            end
        end
    end
end

function novo_preco!(agente::Agente)  
    if agente.runs >= 2
        if agente.status == "B"
            agente.preco += 1
            agente.runs = 0
            if new_util(agente) == true && agente.qtde > 0
                agente.status = "B"
            elseif agente.preco < 1
                agente.preco = 1
                agente.status = "S"
            end
        elseif agente.status == "S"
            if agente.preco > 1
                agente.preco -= 1
            end
            agente.runs = 0
            if new_util(agente) == true && agente.qtde > 0
                agente.status = "B"
            else
                agente.status = "S"
            end
        end
    end
    if length(sellers()) != 0 && agente.cash > sellers()[1][2]
        if utilidade(agente, false) > agente.util
            agente.status = "B"
        else
            agente.status = "S"
        end
    else
        if new_util(agente) == true
            agente.status = "B"
        else
            agente.status = "S"
        end
    end
    if length(sellers()) > 0
        agente.preco = agente.preco + ((sellers()[1][2] - agente.preco) / agente.preco)
    else
        agente.runs += 1
    end
    if agente.qtde != 0
        agente.util = utilidade(agente, true)
    else
        agente.util = utilidade(agente, true)/2
    end
    agente.sold = false
end

function model_step!(model::ABM)
    println("Model step")   
    for agente in allagents(model)
        novo_preco!(agente)
    end
end


# Características 
global acao = 2/4
global din = 2/4
n_ag = 100
per = 20000

# Inicializar o modelo
model = initialize(;n_ag= n_ag)
adata= [:qtde,:cash,:preco,:util,:status,:sold]

# Rodar o modelo: 
# run!([modelo],[passo de cada agente], [passo do modelo (opcional)], [qtde de períodos], [adata => dados dos agentes que deve ser obtido])
teste, _ = run!(model,agent_step!,model_step!,per, adata=adata)


# Cria um DataFrame dos resultados de cada passo do modelo
df = DataFrame(teste)

# Exporta os resultados em um arquivo CSV:
CSV.write("dados_monografia.csv", df, delim= ';')

p1 = plot(legend= false)
for i in 1:n_ag
    local y = df[df.id .== i, :preco]
    plot!(y, label= "Agente $i")
end
ylabel!("Preço") # Adiciona um nome ao eixo y
xlabel!("Período") # Adiciona um nome ao eixo X
savefig("Gráfico1_$n_ag.svg")

p2 = plot(legend= false)
for i in 1:n_ag
    local y = df[df.id .== i, :qtde]
    plot!(y, label= false)
end
ylabel!("Quantidade") # Adiciona um nome ao eixo y
xlabel!("Período") # Adiciona um nome ao eixo X
savefig("Gráfico2_$n_ag.svg")

plot(p1, p2, layout= (2,1), legend= false)
savefig("Gráfico3_$n_ag.svg")

agregado = DataFrame()
agregado = df[:,1:6]
agregado = combine(groupby(agregado, :step), names(agregado, Not(:step)) .=> sum, renamecols=false)

plot(agregado.util, label= false)
ylabel!("Utilidade Total")
xlabel!("Período")
savefig("Gráfico4_$n_ag.svg")

plot(agregado.preco/n_ag, label= false)
ylabel!("Expectativa Média de Preço")
xlabel!("Período")
savefig("Gráfico5_$n_ag.svg")

std_qtde = []
for i in 0:per
    local x = df[df.step.== i, :]
    push!(std_qtde, std(x.qtde))
end
plot(std_qtde,label=false)
ylabel!("Desvio Padrão da Quantidade")
xlabel!("Período")
savefig("Gráfico6_$n_ag.svg")