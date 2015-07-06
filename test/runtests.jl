using Oanda
using FactCheck
using LevelDB

candles = past(1)

facts("Parses the candles") do
  @fact typeof(candles.series[1].closeAsk) => Float64
  @fact typeof(candles.series[1].time) => Int64
end

facts("Saves candles to the database") do
  serialize(candles)
end
