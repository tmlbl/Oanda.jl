module Oanda

using HTTP, URIs, JSON, Unmarshal

export use!,
       candles

struct Environment
    name::String
    uri::String
end

Practice = Environment("Practice", "https://api-fxpractice.oanda.com")
Live = Environment("Live", "https://api-fxtrade.oanda.com")

mutable struct Client
    token::String
    env::Environment
    activeAccount::String
end

Client(token::String, env::Environment) = Client(token, env, "")

function headers(c::Client)
    return [("Authorization", "Bearer $(c.token)"),
    ("X-Accept-Datetime-Format", "UNIX"),
    ("Content-Type", "application/x-www-form-urlencoded")]
end

function request(c::Client, resource::String,
    params::Dict{String,String}; verb="GET")

    uri = string(c.env.uri, resource)
    if length(params) > 0
        uri = string(uri, "?", escapeuri(params))
    end

    println("$verb $uri")

    return HTTP.request(verb, uri; headers=headers(c))
end

function request(c::Client, resource::String; verb="GET")
    return request(c, resource, Dict{String,String}(); verb=verb)
end

struct Account
    id::String
    tags::Vector{String}
end

function accounts(c::Client)
    resp = request(c, "/v3/accounts")
    js = JSON.parse(String(resp.body))
    unmarshal(Vector{Account}, js["accounts"])
end

function accountinfo(c::Client, id::String)
    resp = request(c, "/v3/accounts/$id")
    js = JSON.parse(String(resp.body))
    js["account"]
end

accountinfo(c::Client, a::Account) = accountinfo(c, a.id)

function use!(c::Client, account::Account)
    c.activeAccount = account.id
end

function candles(c::Client, instrument::String, granularity::String)
    params = Dict{String,String}("granularity" => granularity, "price" => "BA")
    resource = "/v3/accounts/$(c.activeAccount)/instruments/$instrument/candles"
    resp = request(c, resource, params)
    JSON.parse(String(resp.body))
end

end # module
