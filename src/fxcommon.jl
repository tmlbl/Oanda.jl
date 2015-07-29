granularities = Dict{Symbol,TimePeriod}(
  :M1 => Minute(1),
  :M5 => Minute(5),
  :H1 => Hour(1)
)

type Instrument
  name::String
end

instruments = Dict{Symbol,Instrument}(
  :EUR_USD => Instrument("EUR_USD")
)
