module Oanda

using Requests,
      TimeSeries,
      Base.Dates,
      JSON

export past,
       last,
       save_candles,
       get_candles,
       qstring,
       candles

include("qstring.jl")
include("client.jl")

#
# const M1 = "M1"
#
# const EUR_USD = "EUR_USD"

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
  series::TimeArray
end

Base.last(c::Candles) = c.series[length(c.series)]

Base.show(io::IO, c::Candles) = begin
  print("\n$(c.symbol) $(c.granularity)\n\n")
  show(io, c.series)
end

include("db.jl")

end # module Oanda
