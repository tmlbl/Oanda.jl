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

Base.get(s::Symbol) = begin
  if haskey(granularities, s)
    granularities[s]
  elseif haskey(instruments, s)
    instruments[s]
  else
    error("Symbol $s not found")
  end
end

type Candles
  symbol::Symbol
  granularity::Symbol
  series::TimeArray
end

Base.show(io::IO, c::Candles) = begin
  print("\n$(c.symbol) $(c.granularity)\n\n")
  show(io, c.series)
end
