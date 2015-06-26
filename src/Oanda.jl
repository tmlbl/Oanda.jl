module Oanda

using Requests,
      Dates,
      JSON

export prices,
       past

include("Qstring.jl")

const baseuri = "http://api-sandbox.oanda.com/"
const defheaders = Dict{String,String}("X-Accept-Datetime-Format" => "UNIX")

immutable Candle
  time::DateTime
  bid::Float64
  ask::Float64
end

function prices(from::DateTime, to::DateTime, instrument::String)
  println("Loading candles for "*instrument*" from "*string(from)*" to "*string(to))
  query = qstring(("start", from), ("end", to), ("instrument", instrument))
  uri = string(baseuri, "v1/candles", query)
  candles = Array{Candle,1}()
  for c in JSON.parse(get(uri, headers = defheaders).data)["candles"]
    push!(candles, Candle(Dates.unix2datetime(parse(c["time"])), c["closeAsk"], c["closeBid"]))
  end
  println("Loaded "*string(length(candles))*" candles")
  candles
end

past(hours::Int) = prices(Dates.now() - Dates.Hour(hours), Dates.now(), "USD_CAD")

end # module Oanda
