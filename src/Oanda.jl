module Oanda

using TimeSeries,
      Base.Dates,
      JSON

using Base.Dates: toms

export past,
       last,
       playback,
       Candle,
       CandleIterator,
       Granularity,
       OandaClient,
       Instrument,
       save_candles,
       db_candles,
       qstring,
       oa_candles,
       oa_request,
       oa_accounts,
       oa_orders,
       candles

include("util.jl")
include("fxcommon.jl")
include("qstring.jl")
include("client.jl")
include("candles.jl")
include("playback.jl")

end # module Oanda
