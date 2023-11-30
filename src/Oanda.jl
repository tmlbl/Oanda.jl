module Oanda

using HTTP, URIs, JSON, Unmarshal, DataFrames, Dates, Printf

export use!,
       candles

dfmt = dateformat"yyyy-mm-ddTHH:MM:SS.sssssssssZ"

Practice = "https://api-fxpractice.oanda.com"
Live = "https://api-fxtrade.oanda.com"

mutable struct Client
    token::String
    baseUrl::String
    activeAccount::String
end

Client(token::String, baseUrl::String) = Client(token, baseUrl, "")

Client() = Client(ENV["OANDA_TOKEN"], ENV["OANDA_URL"])

globalClient = nothing

if haskey(ENV, "OANDA_TOKEN") && haskey(ENV, "OANDA_URL")
    globalClient = Client()
end

function headers(c::Client)
    return [("Authorization", "Bearer $(c.token)"),
    ("X-Accept-Datetime-Format", "UNIX"),
    ("Content-Type", "application/x-www-form-urlencoded")]
end

function jsonheaders(c::Client)
    return [("Authorization", "Bearer $(c.token)"),
    ("X-Accept-Datetime-Format", "UNIX"),
    ("Content-Type", "application/json")]
end

function request(c::Client, resource::String,
    params::Dict{String,String}; verb="GET")

    uri = string(c.baseUrl, resource)
    if length(params) > 0
        uri = string(uri, "?", escapeuri(params))
    end

    # println("$verb $uri")

    return HTTP.request(verb, uri; headers=headers(c))
end

function request(c::Client, resource::String; verb="GET")
    return request(c, resource, Dict{String,String}(); verb=verb)
end

function accountinfo(c::Client, id::String)
    resp = request(c, "/v3/accounts/$id")
    js = JSON.parse(String(resp.body))
    js["account"]
end

accountinfo() = accountinfo(globalClient, globalClient.activeAccount)

function getaccounts()
    resp = request(globalClient, "/v3/accounts")
    js = JSON.parse(String(resp.body))
    accounts = js["accounts"]
    infos = Dict{String,Dict}()
    for account in accounts 
        account = accountinfo(globalClient, account["id"])
        infos[account["alias"]] = account
    end
    return infos
end

function useaccount(alias::String)
    account = getaccounts()[alias]
    globalClient.activeAccount = account["id"]
end

function candles(instrument::String, granularity::String)
    params = Dict{String,String}("granularity" => granularity, "price" => "BA")
    resource = "/v3/accounts/$(globalClient.activeAccount)/instruments/$instrument/candles"
    resp = request(globalClient, resource, params)
    candles = JSON.parse(String(resp.body))["candles"]
    candles2df(candles)
end

function candles2df(candles::Vector{Any})
    time = Vector{DateTime}(undef, length(candles))

    bidOpen = Vector{Float64}()
    bidHigh = Vector{Float64}()
    bidLow = Vector{Float64}()
    bidClose = Vector{Float64}()
    
    askOpen = Vector{Float64}()
    askHigh = Vector{Float64}()
    askLow = Vector{Float64}()
    askClose = Vector{Float64}()
    
    volume = Vector{Int}()
    complete = Vector{Bool}()
    
    for (i, c) in enumerate(candles)
        time[i] = DateTime(c["time"], dfmt)

        append!(bidOpen, parse(Float64, c["bid"]["o"]))
        append!(bidHigh, parse(Float64, c["bid"]["h"]))
        append!(bidLow, parse(Float64, c["bid"]["l"]))
        append!(bidClose, parse(Float64, c["bid"]["c"]))

        append!(askOpen, parse(Float64, c["ask"]["o"]))
        append!(askHigh, parse(Float64, c["ask"]["h"]))
        append!(askLow, parse(Float64, c["ask"]["l"]))
        append!(askClose, parse(Float64, c["ask"]["c"]))

        append!(volume, c["volume"])
        append!(complete, c["complete"])
    end
    DataFrame(
        "Time" => time,

        "BidOpen" => bidOpen,
        "BidHigh" => bidHigh,
        "BidLow" => bidLow,
        "BidClose" => bidClose,

        "AskOpen" => askOpen,
        "AskHigh" => askHigh,
        "AskLow" => askLow,
        "AskClose" => askClose,

        "Volume" => volume,
        "Complete" => complete,
    )
end

struct TakeProfitDetails
    price::String
    timeInForce::String
end

TakeProfitDetails(price::Float64) = TakeProfitDetails((@sprintf "%.5f" price), "GTC")

struct StopLossDetails
    price::String
    timeInForce::String   
end

StopLossDetails(price::Float64) = StopLossDetails((@sprintf "%.5f" price), "GTC")

struct LimitOrder
    type::String
    instrument::String
    price::String
    units::Int
    takeProfitOnFill::TakeProfitDetails
    stopLossOnFill::StopLossDetails
end

LimitOrder(
    i::String,
    p::Float64,
    u::Int,
    tp::TakeProfitDetails,
    sl::StopLossDetails) = LimitOrder("LIMIT", i, (@sprintf "%.5f" p), u, tp, sl) 


function createorder(order::LimitOrder)
    resource = "/v3/accounts/$(globalClient.activeAccount)/orders"
    uri = string(globalClient.baseUrl, resource)
    body = json(Dict("order" => order))
    resp = HTTP.request("POST", uri; headers=jsonheaders(globalClient), body=body)
    JSON.parse(resp.body)
end

struct Position
    instrument::String
    pl::Float64
    longUnits::Int
    shortUnits::Int
end

function getpositions()
    info = accountinfo()
    p = Vector{Position}(undef, length(info["positions"]))
    for i in 1:length(info["positions"])
        pos = info["positions"][i]
        p[i] = Position(
            pos["instrument"],
            parse(Float64, pos["pl"]),
            parse(Int, pos["long"]["units"]),
            parse(Int, pos["short"]["units"])
        )
    end
    p
end

end # module
