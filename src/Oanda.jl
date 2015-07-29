module Oanda

using Requests,
      TimeSeries,
      Base.Dates,
      JSON

export past,
       last,
       save_candles,
       db_candles,
       qstring,
       oa_candles,
       candles

type Candles
  symbol::Symbol
  granularity::Symbol
  series::TimeArray
end

include("fxcommon.jl")
include("qstring.jl")
include("client.jl")
include("db.jl")
include("candles.jl")

Base.last(c::Candles) = c.series[length(c.series)]

Base.show(io::IO, c::Candles) = begin
  print("\n$(c.symbol) $(c.granularity)\n\n")
  show(io, c.series)
end

end # module Oanda
