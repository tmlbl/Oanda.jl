using Oanda,
      FactCheck,
      LevelDB,
      Base.Dates

facts("Encodes the query string") do
  @fact qstring(("a", "b"), ("c", :d)) --> "?a=b&c=d"
  @fact qstring(("date", Dates.unix2datetime(1424888079))) --> "?date=1424888079"
end

start_time = DateTime("2015-07-22T21:10:13")
end_time = DateTime("2015-07-28T21:28:13")

# Fetch some historical data
c = oa_candles(:EUR_USD, :M1, start_time, end_time)
@show c
# Oanda.validate(c)

facts("Saves candles to the database") do
  save_candles(c)
  cans = db_candles(:EUR_USD, :M1, start_time, end_time)
  @show cans
end

facts("Minds the gaps") do
  cans = candles(:EUR_USD, :M1, start_time - Minute(5), end_time + Minute(5))
  @show cans
end
