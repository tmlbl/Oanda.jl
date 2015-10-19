using HttpCommon
using HTTPClient: HTTPC

include("db.jl")

const baseuris = Dict{AbstractString,AbstractString}(
  "sandbox" => "http://api-sandbox.oanda.com",
  "practice" => "https://api-fxpractice.oanda.com",
  "live" => "https://api-fxtrade.oanda.com"
)

type OandaClient
  token::AbstractString
  env::AbstractString
  uri::AbstractString

  function OandaClient(token, env, uri)
    global oa = new(token, env, uri)
    oa
  end
end

OandaClient(token, env) = OandaClient(token, env, baseuris[env])

# Default sandbox client. For easier function calls we assume one client per
# Julia process.
oa = OandaClient("", "sandbox")

function headers(oa::OandaClient)
  return [("Authorization", "Bearer $(oa.token)"),
    ("X-Accept-Datetime-Format", "UNIX"),
    ("Content-Type", "application/x-www-form-urlencoded")]
end

function oa_err(res::HTTPC.Response)
  error(JSON.parse(bytestring(res.body))["message"])
end

function oa_request(resource::AbstractString, params::Tuple{AbstractString,Any}...; verb="GET")
  query = qstring(params...)
  uri = string(oa.uri, resource, query)
  println(uri)
  opts = RequestOptions(headers = headers(oa))
  res = HTTPC.custom(uri, verb, opts)
  if res.http_code != 200
    oa_err(res)
  end
  res
end

function oa_post(resource::AbstractString, params::Tuple{AbstractString,Any}...)
  query = replace(qstring(params...), '?', "")
  uri = string(oa.uri, resource)
  println("POST $query $uri")
  res = post(uri, query, headers = headers(oa))
  if res.http_code != 200
    oa_err(res)
  end
  res
end

type OandaAccount
  id::Int64
  name::AbstractString
  currency::AbstractString
  marginRate::Float64
end

function oa_accounts()
  res = oa_request("/v1/accounts")
  map(JSON.parse(bytestring(res.body))["accounts"]) do acct
    OandaAccount(
      acct["accountId"],
      acct["accountName"],
      acct["accountCurrency"],
      acct["marginRate"]
    )
  end
end

function oa_orders(acct::OandaAccount)
  res = oa_request("/v1/accounts/$(acct.id)/orders")
  JSON.parse(bytestring(res.body))["orders"]
end

function oa_market_buy(acct::OandaAccount, inst::Symbol, units::Int64)
  res = oa_post("/v1/accounts/$(acct.id)/orders",
    ("instrument", inst), ("units", units), ("side", "buy"),
    ("type", "market"))
  JSON.parse(bytestring(res.body))
end

function oa_series(inst::Symbol, gran::Symbol, from::DateTime, to::DateTime)
  println("Requesting candles from $from to $to")
  res = oa_request("/v1/candles", ("start", from), ("end", to),
    ("instrument", inst), ("granularity", gran))

  candle_data = JSON.parse(bytestring(res.body))["candles"]

  timestamps = Array{DateTime,1}(length(candle_data))
  colnames = ASCIIString["openBid", "openAsk", "closeBid", "closeAsk",
    "highBid", "highAsk", "lowBid", "lowAsk"]
  values = zeros(length(candle_data),8)

  for i = 1:length(candle_data)
    c = candle_data[i]

    setindex!(timestamps,
      unix2datetime(Int64(parse(c["time"]) / 1000000)), i)

    values[i,1] = c["openBid"]
    values[i,2] = c["openAsk"]
    values[i,3] = c["closeBid"]
    values[i,4] = c["closeAsk"]
    values[i,5] = c["highBid"]
    values[i,6] = c["highAsk"]
    values[i,7] = c["lowBid"]
    values[i,8] = c["lowAsk"]
  end

  TimeArray(timestamps, values, colnames)
end

roundup(f::Float64) = Int(floor(f) < f ? floor(f + 1) : floor(f))

function combine(t1::TimeArray, t2::TimeArray)
  values = vcat(t1.values, t2.values)
  timestamps = vcat(t1.timestamp, t2.timestamp)
  TimeArray(timestamps, values, t1.colnames)
end

function num_candles(gran::Granularity, from::DateTime, to::DateTime)
  Int64(floor(Int64(to - from) / toms(gran.period)))
end

function oa_candles(inst::Symbol, gran::Symbol, from::DateTime, to::DateTime)
  g = Granularity(gran)
  numcandles = num_candles(g, from, to)
  println("There should be $numcandles $gran candles from $from to $to")
  # If there are more than 5000 we need to request them in batches
  reqs = roundup(numcandles / 5000)
  println("We need to make $reqs request(s)")

  if reqs == 1
    series = oa_series(inst, gran, from, to)
  else
    interval = (to - from) / reqs
    println("interval $interval g $g")
    series = oa_series(inst, gran, from, from + interval)
    cur_time = from + interval + g.period
    for i = 2:reqs
      series = combine(series, oa_series(inst, gran, cur_time, cur_time + interval))
      cur_time += interval + g.period
    end
  end

  candles = Candles(inst, gran, series)
  save_candles(candles)
  candles
end
