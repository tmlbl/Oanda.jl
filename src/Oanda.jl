include("Qstring.jl")

using Requests

baseuri = "http://api-sandbox.oanda.com/"
defheaders = {"X-Accept-Datetime-Format" => "UNIX"}

function getCandles(from::DateTime, to::DateTime, instrument::String)
  query = qstring(("start", from), ("end", to), ("instrument", instrument))
  uri = string(baseuri, "v1/candles", query)
  JSON.parse(get(uri, headers = defheaders).data)
end

println("Loading candle data...")
cdata = getCandles(Dates.now() - Dates.Hour(1), Dates.now(), "USD_CAD")

println("Loading events CSV...")
events = readcsv("events.csv")

evdate = events[2, 3]
DateTime(evdate)
