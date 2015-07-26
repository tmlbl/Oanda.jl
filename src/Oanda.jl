module Oanda

using Requests,
      Base.Dates,
      JSON

export past,
       last,
       save_candles,
       get_candles,
       qstring,
       candles

include("Qstring.jl")

const baseuri = "http://api-sandbox.oanda.com/"
const defheaders = Dict{String,String}("X-Accept-Datetime-Format" => "UNIX")

const M1 = "M1"

const EUR_USD = "EUR_USD"

immutable Candle
  time::Int64
  openBid::Float64
  openAsk::Float64
  closeBid::Float64
  closeAsk::Float64
  highBid::Float64
  highAsk::Float64
  lowBid::Float64
  lowAsk::Float64
end

type Candles
  symbol::String
  granularity::String
  series::Array{Candle,1}
end

Base.last(c::Candles) = c.series[length(c.series)]

include("db.jl")

function candles(from::DateTime, to::DateTime, instrument::String; granularity=M1)
  println("Loading candles for "*instrument*" from "*string(from)*" to "*string(to))
  query = qstring(("start", from), ("end", to), ("instrument", instrument), ("granularity", granularity))
  uri = string(baseuri, "v1/candles", query)
  println(uri)
  candles = Array{Candle,1}()
  for c in JSON.parse(get(uri, headers = defheaders).data)["candles"]
    push!(candles, Candle(Int64(parse(c["time"]) / 1000000), c["openBid"],
      c["openAsk"], c["closeBid"], c["closeAsk"], c["highBid"], c["highAsk"],
      c["lowBid"], c["lowAsk"]))
  end
  println("Loaded "*string(length(candles))*" candles")
  Candles(EUR_USD, granularity, candles)
end

past(hours::Int) = candles(Dates.now() - Dates.Hour(hours), Dates.now(), EUR_USD)

end # module Oanda
