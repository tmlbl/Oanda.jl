using Oanda,
      FactCheck,
      LevelDB,
      Base.Dates

facts("Encodes the query string") do
  @fact qstring(("a", "b"), ("c", :d)) --> "?a=b&c=d"
  @fact qstring(("date", Dates.unix2datetime(1424888079))) --> "?date=1424888079"
end

facts("Has granularities") do
  @fact typeof(Granularity(:M1)) --> Granularity
  @fact Granularity(:S5).period --> Second(5)
  @fact Granularity(:H1).symbol --> :H1
  @fact Granularity(:H8).string --> "H8"
end

facts("Has instruments") do
  @fact typeof(Instrument(:EUR_USD)) --> Instrument
end

start_time = DateTime("2015-07-02T21:10:00")
end_time = DateTime("2015-07-28T21:28:00")
gran = :M5
inst = :USD_JPY

# Fetch some historical data
c = oa_candles(inst, gran, start_time, end_time)
@show c

facts("Saves candles to the database") do
  cans = db_candles(inst, gran, start_time, end_time)
  @show cans
end

facts("Minds the gaps") do
  cans = candles(inst, gran, start_time - Minute(5), end_time + Minute(5))
  @show cans
end
