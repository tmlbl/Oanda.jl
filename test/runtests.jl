using Oanda
using FactCheck
using LevelDB

facts("Encodes the query string") do
  @fact qstring(("a", "b"), ("c", "d")) --> "?a=b&c=d"
  @fact qstring(("date", Dates.unix2datetime(1424888079))) --> "?date=1424888079"
end

start_time = DateTime("2015-07-28T21:10:13")
end_time = DateTime("2015-07-28T21:28:13")

# Fetch some historical data
c = candles(start_time, end_time, "EUR_USD")
@show c

facts("Parses the candles") do

end

facts("Saves candles to the database") do
  save_candles(c)
  cans = get_candles("EUR_USD", "M1", start_time, end_time)
  println(cans.series)
end
