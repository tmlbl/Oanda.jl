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
cdata = getCandles(Dates.now() - Dates.Hour(2), Dates.now(), "USD_CAD")

println("Loading events CSV...")
events = readcsv("julia/fix/events.csv")

events[4]
# A type to store the event data
type Event
  title::String
  impact::Int
  time::DateTime
  country::String
end

# An array of events
forexevents = Array(Event, int(length(events) / 4))

map((rawevent) -> 10, forexevents)

Event("Bool", Dates.now(), 1, "f")

for i = events
  forexevents[i] = Event(events[i]["title"])
end

function getEventDelta(e::Event)
  e[1]
end
