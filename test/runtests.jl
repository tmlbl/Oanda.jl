using Oanda
using FactCheck
using LevelDB

facts("Encodes the query string") do
  @fact qstring(("a", "b"), ("c", "d")) => "?a=b&c=d"
  @fact qstring(("date", Dates.unix2datetime(1424888079))) => "?date=1424888079"
end

start_time = Dates.now() - Dates.Minute(10)
end_time = Dates.now() - Dates.Minute(5)

# Fetch some historical data
c = candles(start_time, end_time, "EUR_USD")

facts("Parses the candles") do
  @fact typeof(c) => Oanda.Candles
  @fact typeof(c.series[1].closeAsk) => Float64
  @fact typeof(c.series[1].time) => Int64
end

facts("Saves candles to the database") do
  save_candles(c)
  cans = get_candles("EUR_USD", "M1", start_time, end_time)
  println(cans.series)
  @fact typeof(cans) => Oanda.Candles
  for c in cans.series
    @fact (c.time >= Dates.datetime2unix(start_time)) => true
    @fact (c.time <= Dates.datetime2unix(end_time)) => true
  end
end
